# Snapshot Restore API

The `snapshot.kubevirt.io` API Group defines resources for snapshotting and restoring KubeVirt `VirtualMachines`

## Prerequisites

### VolumeSnapshotClass

KubeVirt leverages the `VolumeSnapshot` functionality of Kubernetes [CSI drivers](https://kubernetes-csi.github.io/docs/drivers.html) for capturing persistent `VirtualMachine` state.  So, you should make sure that your `VirtualMachine` uses `DataVolumes` or `PersistentVolumeClaims` backed by a `StorageClass` that supports `VolumeSnapshots` and a `VolumeSnapshotClass` is properly configured for that `StorageClass`.

KubeVirt looks for Kubernetes Volume Snapshot related APIs/resources in the `v1` version. To make sure that KubeVirt's snapshot controller is able to snapshot the VirtualMachine and referenced volumes as expected, Kubernetes Volume Snapshot APIs must be served from `v1` version.

To list `VolumeSnapshotClasses`:

```bash
kubectl get volumesnapshotclass
```

Make sure the `provisioner` property of your `StorageClass` matches the `driver` property of the `VolumeSnapshotClass`

Even if you have no `VolumeSnapshotClasses` in your cluster, `VirtualMachineSnapshots` are not totally useless.  They will still backup your `VirtualMachine` configuration.

### Snapshot Feature Gate

Snapshot/Restore support must be enabled in the feature gates to be supported. The
[feature gates](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `Snapshot` to it.


## Snapshot a VirtualMachine

Snapshotting a virtualMachine is supported for online and offline vms.

When snapshotting a running vm the controller will check for qemu guest agent in the vm. If the agent exists it will freeze the vm filesystems before taking the snapshot and unfreeze after the snapshot. It is recommended to take online snapshots with the guest agent for a better snapshot, if not present a best effort snapshot will be taken.

> *Note* To check if your vm has a qemu-guest-agent check for 'AgentConnected' in the vm status.

There will be an indication in the vmSnapshot status if the snapshot was taken online and with or without guest agent participation.

> *Note* Online snapshot with hotplugged disks is supported, only persistent hotplugged disks will be included in the snapshot.


To snapshot a `VirtualMachine` named `larry`, apply the following yaml.

```yaml
apiVersion: snapshot.kubevirt.io/v1beta1
kind: VirtualMachineSnapshot
metadata:
  name: snap-larry
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: larry
```

You can check the vmSnapshot phase in the vmSnapshot status. It can be one of the following:

- InProgress
- Succeeded
- Failed.

The vmSnapshot has a default deadline of 5 minutes. If the vmSnapshot has not successfully completed before the deadline, it will be marked as Failed. The VM will be unfrozen and the created snapshot content will be cleaned up if necessary. The vmSnapshot object will remain in Failed state until deleted by the user. To change the default deadline add 'FailureDeadline' to the VirtualMachineSnapshot spec with a new value. The allowed format is a [duration](https://pkg.go.dev/time#ParseDuration) string which is a possibly signed sequence of decimal numbers, each with optional fraction and a unit suffix, such as "300ms", "-1.5h" or "2h45m"

```yaml
apiVersion: snapshot.kubevirt.io/v1beta1
kind: VirtualMachineSnapshot
metadata:
  name: snap-larry
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: larry
  failureDeadline: 1m
```

In order to set an infinite deadline you can set it to 0 (not recommended).

To wait for a snapshot to complete, execute:

```bash
kubectl wait vmsnapshot snap-larry --for condition=Ready
```

You can verify your snapshot's state and composition by examining the following fields in the `snapshot.status`:

- `readyToUse` - indicates whether you can restore from the snapshot. It is possible that after the snapshot completed something happened to the volumeSnapshot (like someone deleted it by accident) making the snapshot unrestorable.
- `includedVolumes/excludedVolumes` - list of the volumes that were included or excluded in the snapshot, user should verify all the expected volumes are there.
- `indications` - array of indications that represents how the snapshot was taken:<br>
    - `Online` indicates the snapshot was taken while the VM was running.
    - `GuestAgent` indicates the QEMU guest agent was active and successfully froze (quiesced) the guest filesystem for the online snapshot. This delivers an application-consistent snapshot, ensuring high data integrity as if applications gracefully shut down before the snapshot.
    - `NoGuestAgent` indicates the QEMU guest agent was not installed, or not ready to quiesce the filesystem during the online snapshot. This results in a crash-consistent snapshot, capturing the VM's state like an abrupt power-off. There's no guarantee of application consistency, risking data issues for critical apps. Installing and running the guest agent, or retrying the snapshot, is highly recommended for better reliability.
    - `QuiesceFailed` indicates an attempt to freeze the filesystem failed during the online snapshot process. Even though the snapshot completed, it's not necessarily application-consistent. Retrying the snapshot is generally advisable to achieve proper consistency.

## Restoring a VirtualMachine

To restore the `VirtualMachine` `larry` from `VirtualMachineSnapshot` `snap-larry`, Stop the VM, wait for it to be stopped and then apply the following yaml.

```yaml
apiVersion: snapshot.kubevirt.io/v1beta1
kind: VirtualMachineRestore
metadata:
  name: restore-larry
spec:
  target:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: larry
  virtualMachineSnapshotName: snap-larry
```

To wait for a restore to complete, execute:

```bash
kubectl wait vmrestore restore-larry --for condition=Ready
```

## Target readiness policies

When restoring a `VirtualMachineSnapshot` on an already existing target (like the parent VM of the snapshot), a readiness policy can be specified to adjust how the restore happens if the target VM is not ready. The target VM is considered ready when it is fully stopped. The policy is controlled by setting `targetReadinessPolicy` to one of the available types.

The following policies are available:

- **WaitGracePeriod** (default policy): Wait 5 minutes for the target VM to be ready. If not ready in time, the restore will fail.
- **StopTarget**: Stop the target VM so that the restore can continue immediately.
- **FailImmediate**: Don't wait for the target to be ready before trying to restore. If it is not ready, the restore fails immediately.
- **WaitEventually**: Kubevirt keeps the `VirtualMachineRestore` around until the target is ready. The restore is started as soon as the target is ready.

## Cleanup

Keep `VirtualMachineSnapshots` (and their corresponding `VirtualMachineSnapshotContents`) around as long as you may want to restore from them again.

Feel free to delete `restore-larry` as it is not needed once the restore is complete.
