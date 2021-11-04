# Snapshot Restore API

The `snapshot.kubevirt.io` API Group defines resources for snapshotting and restoring KubeVirt `VirtualMachines`

## Prerequesites

### VolumeSnapshotClass

KubeVirt leverages the `VolumeSnapshot` functionality of Kubernetes [CSI drivers](https://kubernetes-csi.github.io/docs/drivers.html) for capturing persistent `VirtualMachine` state.  So, you should make sure that your `VirtualMachine` uses `DataVolumes` or `PersistentVolumeClaims` backed by a `StorageClass` that supports `VolumeSnapshots` and a `VolumeSnapshotClass` is properly configured for that `StorageClass`.

To list `VolumeSnapshotClasses`:

```bash
kubectl get volumesnapshotclass
```

Make sure the `provisioner` property of your `StorageClass` matches the `driver` property of the `VolumeSnapshotClass`

Even if you have no `VolumeSnapshotClasses` in your cluster, `VirtualMachineSnapshots` are not totally useless.  They will still backup your `VirtualMachine` configuration.

### Snapshot Feature Gate

Snapshot/Restore support must be enabled in the feature gates to be supported. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `Snapshot` to it.


## Snapshot a VirtualMachine

Snapshotting a virtualMachine is supported for online and offline vms.

When snapshotting a running vm the controller will check for qemu guest agent in the vm. If the agent exists it will freeze the vm filesystems before taking the snapshot and unfreeze after the snapshot. It is recommended to take online snapshots with the guest agent for a better snapshot, if not present a best effort snapshot will be taken.

> *Note* To check if your vm has a qemu-guest-agent check for 'AgentConnected' in the vm status.

There will be an indication in the vmSnapshot status if the snapshot was taken online and with or without guest agent participation.

> *Note* Online snapshot with hotplugged disks is supported, only persistent hotplugged disks will be included in the snapshot.


To snapshot a `VirtualMachine` named `larry`, apply the following yaml.

```yaml
apiVersion: snapshot.kubevirt.io/v1alpha1
kind: VirtualMachineSnapshot
metadata:
  name: snap-larry
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: larry
```

To wait for a snapshot to complete, execute:

```bash
kubectl wait vmsnapshot snap-larry --for condition=Ready
```

You can check the vmSnapshot phase in the vmSnapshot status. It can be one of the following:
* InProgress
* Succeeded
* Failed.

The vmSnapshot has a default deadline of 5 minutes. If the vmSnapshot has not succeessfully completed before the deadline, it will be marked as Failed. The VM will be unfrozen and the created snapshot content will be cleaned up if necessary. The vmSnapshot object will remain in Failed state until deleted by the user. To change the default deadline add 'FailureDeadline' to the VirtualMachineSnapshot spec with a new value. The allowed format is a [duration](https://pkg.go.dev/time#ParseDuration) string which is a possibly signed sequence of decimal numbers, each with optional fraction and a unit suffix, such as "300ms", "-1.5h" or "2h45m" 

```yaml
apiVersion: snapshot.kubevirt.io/v1alpha1
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

## Restoring a VirtualMachine

To restore the `VirtualMachine` `larry` from `VirtualMachineSnapshot` `snap-larry`, apply the following yaml.

```yaml
apiVersion: snapshot.kubevirt.io/v1alpha1
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

## Cleanup

Keep `VirtualMachineSnapshots` (and their corresponding `VirtualMachineSnapshotContents`) around as long as you may want to restore from them again.

Feel free to delete `larry-restore` as it is not needed once the restore is complete.
