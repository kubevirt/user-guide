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

When snapshotting a running vm the controller will check for qemu guest agent in the vm. If the agent exists it will freeze the vm filesystems before taking the snapshot and unfreeze after the snapshot. It is recommended to take online snapshots with the guest agent for a better snapshot, if not present a best effort snapshot will be taken. To keep the filesystems frozen only briefly, see [External snapshot mode](#external-snapshot-mode).

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

## External snapshot mode

**FEATURE STATE:** KubeVirt v1.10 (Alpha)

External mode is alpha and must be enabled via the `ExternalVMSnapshot` and `UtilityVolumes` [feature gates](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate).

By default the guest filesystems stay frozen until every `VolumeSnapshot` is created, which can take a while on a VM with many disks. In External mode the guest is only frozen while QEMU switches the disks onto copy-on-write overlays. The guest keeps writing to the overlays while the `VolumeSnapshots` are taken from the unchanged disks, and the overlays are committed back into the disks once every `VolumeSnapshot` is ready.

External mode only applies to a running VM with a connected guest agent. A snapshot of a stopped VM is rejected, and if the filesystems cannot be frozen the snapshot fails instead of falling back to a crash-consistent snapshot.

```yaml
apiVersion: snapshot.kubevirt.io/v1beta1
kind: VirtualMachineSnapshot
metadata:
  name: snap-larry
spec:
  snapshotMode: External
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: larry
```

The snapshot is `Succeeded` and ready to restore once every `VolumeSnapshot` is ready. The overlays are committed after that, and the VM keeps `status.snapshotInProgress` set until the commit is done and the scratch PVC is deleted. Another snapshot of the VM waits until then.

### The scratch PVC

The overlays are kept on a scratch PVC named `snap-scratch-<VirtualMachineSnapshotContent UID>`, created in the VM namespace with the storage class of the first VM disk and deleted after the commit. Its size covers the guest writes until the failure deadline, up to the size of the snapshotted disks plus 10%. It can be set with `overlayScratchSize`:

```yaml
spec:
  snapshotMode: External
  overlayScratchSize: 10Gi
```

If the scratch PVC gets 70% full, the overlays are committed early so that the guest is not paused by a full volume. The snapshot fails if its `VolumeSnapshots` were not ready by then.

### While the overlays are active

The VMI reports the overlays with the `OverlaySnapshotActive` condition:

- `True` with reason `OverlayPreparing`, `OverlaysReady`, `OverlayCommitting` or `OverlayCommitFailed`: the disks may be on their overlays.
- `False` with reason `OverlayCommitted` or `OverlaySnapshotFailed`: every disk is back on its own volume.

While the condition is `True`:

- The VMI cannot be live migrated, and volume migration is rejected.
- Volumes cannot be hotplugged or unplugged.
- Backups are rejected.
- Online disk expansion waits until the overlays are committed.

If the commit fails, an `OverlayCommitFailed` warning event is recorded on the `VirtualMachineSnapshotContent` and the commit is retried.

Stopping the VM commits the overlays before the guest is shut down, within its `terminationGracePeriodSeconds`. If the commit does not finish in time, the VM needs [recovery](#recovering-a-vm-with-uncommitted-overlays). Deleting the VM also attempts the commit, but discards whatever is left and records a `SnapshotOverlayDataDiscarded` warning event, since PVCs that outlive the VM can then be missing the latest writes.

The persistent TPM and EFI state of the VM is not put on an overlay, so it can be captured at a slightly different point in time than the disks.

### Recovering a VM with uncommitted overlays

If `virt-launcher` stops abruptly while the overlays are active, the latest guest writes exist only in the overlays on the scratch PVC. The VM gets the `ManualRecoveryRequired` condition with reason `UncommittedOverlays`, and KubeVirt refuses to start it. A snapshot that was not complete yet is marked as Failed.

```yaml
status:
  conditions:
  - message: Uncommitted writes remain on scratch PVC `snap-scratch-...`. Startup is blocked. ...
    reason: UncommittedOverlays
    status: "True"
    type: ManualRecoveryRequired
```

Do not delete the scratch PVC or remove its finalizer. To recover, either:

- Restore a completed snapshot of the VM, losing the writes made after that snapshot. The scratch PVC is released once the restore completes.
- Commit the overlays into the disks manually, as described below, to keep the writes.

Deleting the VM also discards the overlays.

#### Committing the overlays manually

The commit runs with `qemu-img` while the VM stays stopped. Keep `ManualRecoveryRequired` set until every overlay is committed.

1. Make sure the old `virt-launcher` pod and its hotplug pod are gone, and find the scratch PVC:

    ```bash
    NS=default
    VM=larry
    SNAP=snap-larry

    CONTENT=$(kubectl -n $NS get vmsnapshot $SNAP -o jsonpath='{.status.virtualMachineSnapshotContentName}')
    SCRATCH=snap-scratch-$(kubectl -n $NS get vmsnapshotcontent $CONTENT -o jsonpath='{.metadata.uid}')
    SCRATCH_UID=$(kubectl -n $NS get pvc $SCRATCH -o jsonpath='{.metadata.uid}')
    ```

2. Map each overlay to its disk. The overlay of volume `<volume>` is `ovl-<volume>.qcow2` at the root of the scratch PVC, and the content records the PVC of each volume:

    ```bash
    kubectl -n $NS get vmsnapshotcontent $CONTENT -o json | jq -r '.spec.volumeBackups[] |
      [.volumeName, .persistentVolumeClaim.metadata.name, .persistentVolumeClaim.metadata.uid,
       (.persistentVolumeClaim.spec.volumeMode // "Filesystem")] | @tsv'
    ```

    Check that each PVC still has the recorded UID. Stop if one differs.

    > *Note* If the VM stopped while its overlays were being committed, some disks may have no overlay left. Those disks are already committed. `virt-launcher` keeps the guest paused from the moment a disk switches back to its volume until that overlay is deleted, so an overlay that remains never predates writes on its disk and is always safe to commit.

3. For each overlay, start a pod with the scratch PVC and the matching disk PVC, using the `virt-launcher` image of the installed KubeVirt version. The example is for a `Filesystem` PVC holding `disk.img`:

    ```bash
    VOLUME=<volume>
    BASE_PVC=<pvc of the volume>
    IMAGE=$(kubectl get kubevirt -A -o jsonpath='{.items[0].status.observedKubeVirtRegistry}/virt-launcher:{.items[0].status.observedKubeVirtVersion}')

    kubectl -n $NS apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: overlay-commit
    spec:
      restartPolicy: Never
      securityContext:
        runAsNonRoot: true
        runAsUser: 107
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: commit
        image: $IMAGE
        command: ["sleep", "infinity"]
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        volumeMounts:
        - name: scratch
          mountPath: /scratch
        - name: base
          mountPath: /base
      volumes:
      - name: scratch
        persistentVolumeClaim:
          claimName: $SCRATCH
      - name: base
        persistentVolumeClaim:
          claimName: $BASE_PVC
    EOF
    kubectl -n $NS wait pod overlay-commit --for=condition=Ready --timeout=3m
    ```

    For a `Block` PVC, attach it with `volumeDevices` and `devicePath: /dev/base` instead, and use `host_device` and `/dev/base` for the backing image below.

4. Commit the overlay and compare the result:

    ```bash
    CHAIN="driver=qcow2,file.driver=file,file.filename=/scratch/ovl-$VOLUME.qcow2,backing.driver=raw,backing.file.driver=file,backing.file.filename=/base/disk.img"

    kubectl -n $NS exec overlay-commit -- qemu-img commit -p -d --image-opts "$CHAIN"
    kubectl -n $NS exec overlay-commit -- qemu-img compare --image-opts "$CHAIN" "driver=raw,file.driver=file,file.filename=/base/disk.img"
    kubectl -n $NS delete pod overlay-commit
    ```

    `--image-opts` points the overlay at the mounted disk instead of the path recorded by `virt-launcher`, and `-d` keeps the overlay intact, so the step can be repeated while the VM is stopped. `qemu-img compare` must report `Images are identical`.

5. Once every overlay is committed and no pod uses the scratch PVC, mark the overlays as committed with the UID of the scratch PVC:

    ```bash
    kubectl -n $NS annotate vm $VM snapshot.kubevirt.io/overlays-committed=$SCRATCH_UID
    ```

    KubeVirt checks that the UID matches the scratch PVC of the condition, deletes the scratch PVC, and removes the annotation and the `ManualRecoveryRequired` condition. The VM then starts according to its run strategy.

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

## Volume restore policies

When restoring a `VirtualMachineSnapshot`, one of the steps is restoring the volumes of that snapshot. The `volumeRestorePolicy` setting gives the user some control on how that restore process is done.

The following policies are available:

- **RandomizeNames** (default policy): The names of restored PVCs are randomly generated using the UID of the restore job. This policy guarantees there's no collisions, but it may be a problem when using GitOps, as the IDs are not predictable.
- **InPlace**: This policy overwrites the original volumes with the restored ones. If the source PVCs still exist, they are **deleted before creating the restored PVCs**. It is useful when restoring over the original VM while wanting to keep the same volume names.
- **PrefixTargetName**: The names of restored PVCs are generated by prefixing the volume name with the target VM name: `{targetVMName}-{volumeName}`. This provides predictable, deterministic naming while avoiding collisions when restoring the same snapshot to different target VMs. Names are truncated to 63 characters to comply with DNS label length limits.

## Volume ownership policies

When restoring a `VirtualMachineSnapshot`, KubeVirt will try its best to find an owner for all the volumes restored.

The default policy is to give ownership of the restored volumes to the VM if no other owner can be found (for example, a parent DataVolume).
This behaviour might not be desired by the user, as deleting the restored VM will also propagate the deletion to the restored volumes.

The `.volumeOwnershipPolicy` field gives the user control over ownership of the restored volumes.

Policy **VM** (default policy) has the following behaviour:

- Volumes restored as part of the VM's `.dataVolumeTemplate` are owned by the `DataVolumes` of the `dataVolumeTemplate`
- Volumes that are `DataVolumes` are restored as PVCs, owned by the VM (because the original DataVolume is not kept)
- Volumes restored with `VolumeRestorePolicy` **InPlace** as part of `DataVolumes` are restored as PVCs, owned by the DataVolume (because the original DataVolume is rebound to the PVC)
- Volumes that are PVCs are restored as PVCs and owned by the VM

**Note**: This behaviour is altered by a [bug](https://github.com/kubevirt/kubevirt/issues/12785) where this policy only applies correctly if the VM already exists, but the volumes have been deleted.

Policy **None** has the following behaviour:

- Volumes restored as part of the VM's `.dataVolumeTemplate` are owned by the `DataVolumes` of the `dataVolumeTemplate`
- Volumes that are `DataVolumes` are restored as PVCs, not owned by anything
- Volumes restored with `VolumeRestorePolicy` **InPlace** as part of `DataVolumes` are restored as PVCs, owned by the DataVolume (because the original DataVolume is rebound to the PVC)
- Volumes that are PVCs are restored as PVCs not owned by anything

## Volume restore overrides

When restoring a `VirtualMachineSnapshot`, the user might want to modify the volumes as they are being restored. This is possible using the `volumeRestoreOverrides`. Overrides are provided in a list, where each element targets a volume within the snapshot and applies changes to it.

The syntax for a volume restore override is the following:

```yaml
volumeRestoreOverrides:
  - volumeName: "original-volume" # Required - the original name of the volume within the snapshot
    # Optional - the new name of the restored volume
    # If combined with volumeRestorePolicy "InPlace", the PVC that has that name will be deleted before the volume is restored
    restoreName:
    # Optional - used to add or modify labels 
    labels:
      newLabel: "value"
      oldLabel: "newValue"
    # Optional - used to add or modify annotations
    annotations:
      newAnnotation: "value"
      oldAnnotation: "newValue"
```

## Restoring in a GitOps friendly way

Restoring VMs in KubeVirt may not be completely compatible with a GitOps workflow unless some adjustements are made.

The problem when restoring a VM "in place" (as in overwriting it with the content of the snapshot) is that the original VM gets modified with new information. For example, any volume mounted as a `DataVolume` is replaced by a PVC, and the names of all the volumes are changed with randomly generated UIDs.

This means that GitOps tools such as **ArgoCD** will report the original VM as *out of sync* and prompt the user the resynchronize it. If the VM is resynchronized, the restored volumes will end up unmounted and the VM will go back to its original state, which is usually not the intended effect.

To restore VMs while not causing desynchronization between the content of the Git and the cluster, it is recommended to apply the following changes to `VirtualMachineRestores`:

- Use `volumeRestorePolicy` **InPlace** so that volumes have a predictable name identical to the original volume, or **PrefixTargetName** for predictable names based on the target VM name
- Use `volumeRestoreOverrides` if you want to change the name of the restored volume
- Avoid using `dataVolumeTemplates` within VMs, as they get edited when the restored DataVolume is created (if not using `volumeRestorePolicy` InPlace)
- If using `DataVolumes`, mount them as `PersistentVolumeClaims` (DataVolumes create PVCs that have the same name as themselves, making both mount types compatible) 
 
```yaml
# This DataVolume can be mounted on the VM as a persistentVolumeClaim or as a dataVolume.
# It doesn't really change anything, as both mount types are compatible, but one is GitOps safe and the other is not.

---
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: volume
spec:
  ...

---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example
spec:
  template:
    spec:
      ...
      volumes:
      # This is not going to be overwritten by the VMRestore if volumeRestorePolicy is InPlace. It is GitOps-safe.
      - name: volume 
        persistentVolumeClaim:
          claimName: datavol
      # This will be transformed into the same volume mount as the one above, using a persistentVolumeName.
      # It will cause a desynchronization between the Git and the cluster. Avoid using this syntax.
      - name: volume
        dataVolume:
          name: datavol
```

## Cleanup

Keep `VirtualMachineSnapshots` (and their corresponding `VirtualMachineSnapshotContents`) around as long as you may want to restore from them again.

Feel free to delete `restore-larry` as it is not needed once the restore is complete.
