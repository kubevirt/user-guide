# Backup API

The `backup.kubevirt.io` API Group defines resources for taking full and incremental backups of running KubeVirt `VirtualMachines`. Backups rely on Changed Block Tracking (CBT): KubeVirt tracks the blocks written to each [eligible](#enabling-cbt) volume, so an incremental backup contains only the blocks that changed since the previous backup. CBT does not depend on any CSI capability and works with any storage backend.

The API exposes backup primitives. It is intended for backup vendors and tools that store, catalog and restore the backed-up data.

!!! Note
    KubeVirt does not provide a restore API. Restoring a backup is the responsibility of the backup consumer. See [Restoring a backup](#restoring-a-backup) for a manual example.

## Prerequisites

### VM state storage

KubeVirt stores the CBT metadata of a VM on its [VM state PVC](../compute/persistent_tpm_and_uefi_state.md#backend-storage), and creates that PVC if the VM does not have one.

- **Storage cost:** the VM state PVC of a CBT-enabled VM is requested with an additional 512 MiB. On storage with a large minimum volume size, the actual allocation per VM is larger. The overhead is applied when the PVC is created; an existing VM state PVC is not resized.
- **`fsGroup` support:** the CSI driver of the `vmStateStorageClass` (or the default storage class) must apply the pod's `fsGroup` to the volume. The CSI default `fsGroupPolicy: ReadWriteOnceWithFSType` does not apply `fsGroup` to `ReadWriteMany` volumes, so with such a driver CBT fails to initialize on a `ReadWriteMany` VM state PVC. Use a driver with `fsGroupPolicy: File`.

## Enabling CBT

A VM must have CBT enabled before it can be backed up. CBT is enabled by the cluster admin with `changedBlockTrackingLabelSelectors` in the KubeVirt CR, which supports two selectors:

- `namespaceLabelSelector` enables CBT on all VMs in namespaces whose labels match.
- `virtualMachineLabelSelector` enables CBT on VMs whose labels match, in any namespace.

A VM has CBT enabled if it matches either selector. Both selectors can be set at the same time.

To enable CBT on all VMs in a namespace:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    changedBlockTrackingLabelSelectors:
      namespaceLabelSelector:
        matchLabels:
          changedBlockTracking: "true"
```

```bash
kubectl label namespace example-namespace changedBlockTracking=true
```

To enable CBT on individual VMs:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    changedBlockTrackingLabelSelectors:
      virtualMachineLabelSelector:
        matchLabels:
          changedBlockTracking: "true"
```

```bash
kubectl label vm example-vm changedBlockTracking=true
```

CBT applies only to volumes that meet all of the following:

- The volume source is `persistentVolumeClaim` or `dataVolume`, in either `Filesystem` or `Block` mode.
- The volume is attached as a `disk`. Volumes attached as `cdrom` or `lun`, or exposed as a `filesystem`, are not eligible.
- The disk is writable. Disks with `readOnly: true` are not eligible.
- The disk is not shareable. Disks with `shareable: true` are not eligible.

Ineligible volumes are not tracked and are not included in backups. Hotplugged volumes that meet these criteria are tracked from the moment they are attached.

### CBT state

The CBT state is reported in `status.changedBlockTracking.state` of the VM and VMI:

| State | Description |
|---|---|
| `PendingRestart` | The VM was selected or deselected while running. A restart is required to apply the change. |
| `Initializing` | CBT is being set up. A stopped VM remains in this state until it is started. |
| `Enabled` | CBT is active. The VM can be backed up. |
| `Disabled` | The VM no longer matches the selectors and CBT has been removed. |
| `IncrementalBackupFeatureGateDisabled` | The VM matches the selectors, but the `IncrementalBackup` feature gate is disabled. |

Enabling or disabling CBT on a running VM requires a restart:

```bash
$ kubectl get vm example-vm -o jsonpath='{.status.changedBlockTracking.state}'
PendingRestart
$ virtctl restart example-vm
$ kubectl get vm example-vm -o jsonpath='{.status.changedBlockTracking.state}'
Enabled
```

## Backup resources

All backup resources are namespaced and must be created in the namespace of the VM.

### VirtualMachineBackupTracker

A `VirtualMachineBackupTracker` records the checkpoint of the latest backup taken through it. A backup that references a tracker is incremental relative to that checkpoint. A VM can have multiple trackers, each maintaining an independent backup chain, for example one per backup consumer.

```yaml
apiVersion: backup.kubevirt.io/v1beta1
kind: VirtualMachineBackupTracker
metadata:
  name: example-tracker
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: example-vm
```

The tracker `spec` is immutable. `status.latestCheckpoint` is updated after each successful backup:

```yaml
status:
  latestCheckpoint:
    name: example-backup-2026-10-28_10-12-41
    creationTime: "2026-10-28T10:12:41Z"
```

A tracker cannot be deleted while a backup that references it is running.

### VirtualMachineBackup

A `VirtualMachineBackup` runs a single backup. Only one backup can run per VM at a time. The VM must be running: a backup of a stopped VM remains `Progressing` with reason `Initializing` until the VM starts.

| Field | Description |
|---|---|
| `source` | Required. A `VirtualMachine` (`apiGroup: kubevirt.io`) or a `VirtualMachineBackupTracker` (`apiGroup: backup.kubevirt.io`). |
| `mode` | `Push` (default) or `Pull`. See [Backup modes](#backup-modes). |
| `pvcName` | Required. A `Filesystem` PVC. Receives the backup output in push mode; used as scratch space in pull mode. |
| `forceFullBackup` | Take a full backup even if the tracker has a checkpoint. |
| `skipQuiesce` | Do not freeze guest filesystems before the backup. |
| `tokenSecretRef` | Required in pull mode. Secret holding the token for the pull mode endpoints. |
| `ttlDuration` | Pull mode only. Maximum lifetime of the backup, counted from its creation. Defaults to `2h`. |

The backup `spec` is immutable.

### Full and incremental backups

The backup type is determined when the backup starts:

- A backup with a `VirtualMachine` source is full. Its checkpoint is not recorded for later backups.
- A backup with a tracker source is full if the tracker has no checkpoint or `forceFullBackup` is set, and incremental relative to the tracker's `latestCheckpoint` otherwise.

The type is determined per volume. A volume whose CBT data is missing or invalid is backed up in full, while the other volumes remain incremental. This applies, for example, to a volume that was hot-unplugged and replugged, moved with [volume migration](volume_migration.md), or affected by an unclean VM shutdown. The type of each volume is reported in `status.includedVolumes`:

```yaml
status:
  checkpointName: example-backup-2026-10-28_10-12-41
  includedVolumes:
    - volumeName: rootdisk
      type: Incremental
    - volumeName: datadisk
      type: Full
```

!!! Note
    A backup that references a tracker with a checkpoint can contain `Full` volumes. Backup consumers must use `status.includedVolumes` to determine the type of each volume.

### Filesystem quiescing

Unless `skipQuiesce` is set, KubeVirt freezes the guest filesystems through the guest agent before the backup starts. The result is reported in the `Quiesced` condition. If the freeze fails, the backup still completes, with reason `CompletedWithWarning`, and its data is crash-consistent rather than application-consistent.

### Status conditions

| Condition | Reasons |
|---|---|
| `Progressing` | `Initializing`, `Initiated`, `PreparingExport`, `ExportReady`, `Aborting` |
| `Complete` | `Completed`, `CompletedWithWarning` |
| `Failed` | `Failed`, `SourceLost`, `SourceUnhealthy`, `DeletedDuringInit` |
| `Quiesced` | `QuiesceSucceeded`, `QuiesceFailed`, `QuiesceSkipped` |

To wait for a push mode backup to complete:

```bash
kubectl wait vmbackup example-backup --for condition=Complete
```

## Backup modes

### Push mode

In push mode, KubeVirt writes the backup to the PVC referenced by `pvcName`. The PVC is attached to the virt-launcher pod for the duration of the backup.

```yaml
apiVersion: backup.kubevirt.io/v1beta1
kind: VirtualMachineBackup
metadata:
  name: example-backup
spec:
  source:
    apiGroup: backup.kubevirt.io
    kind: VirtualMachineBackupTracker
    name: example-tracker
  mode: Push
  pvcName: example-backup-pvc
```

Each volume is written as a sparse QCOW2 file:

```
<vm>/<backup>-<start time>/<backup>-<volume>.qcow2
```

For example:

```
example-vm/example-backup-2026-10-28_10-12-41/example-backup-rootdisk.qcow2
```

A full backup file contains all allocated data of the volume; an incremental backup file contains only the changed blocks. The target PVC must have enough capacity for the data it receives, which for a full backup is up to the size of the VM's disks. If the PVC runs out of space, the backup fails. A PVC can hold multiple backups.

Copying the backup out of the PVC is the responsibility of the consumer.

Deleting a push mode backup while it is running cancels it. The backup is marked `Failed` and the tracker is not updated.

### Pull mode

In pull mode, KubeVirt serves the backup over HTTPS through the [Export API](export_api.md), and the consumer reads it. The backup remains `Progressing` with reason `ExportReady` until the consumer finishes it.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: example-token
stringData:
  token: 1234567890ab
---
apiVersion: backup.kubevirt.io/v1beta1
kind: VirtualMachineBackup
metadata:
  name: example-backup
spec:
  source:
    apiGroup: backup.kubevirt.io
    kind: VirtualMachineBackupTracker
    name: example-tracker
  mode: Pull
  pvcName: example-scratch-pvc
  tokenSecretRef: example-token
  ttlDuration: 1h
```

The scratch PVC holds the original content of blocks that the guest overwrites while the backup is being read. Its required size depends on how much data the guest writes during the backup.

KubeVirt creates a `VirtualMachineExport` owned by the backup. When the export is ready, the endpoints of each volume are published in `status.links`, under `internal` (in-cluster service) and `external` (export proxy), each with its own CA certificate:

```yaml
status:
  includedVolumes:
    - volumeName: rootdisk
      type: Incremental
  links:
    internal:
      cert: |
        -----BEGIN CERTIFICATE-----
        ...
      volumes:
        - volumeName: rootdisk
          dataEndpoint: https://virt-export-example-backup.default.svc:443/exports/rootdisk/data
          mapEndpoint: https://virt-export-example-backup.default.svc:443/exports/rootdisk/map
    external:
      cert: ""
      volumes:
        - volumeName: rootdisk
          dataEndpoint: https://virt-exportproxy-kubevirt.example.com/api/export.kubevirt.io/v1/namespaces/default/virtualmachineexports/example-backup/exports/rootdisk/data
          mapEndpoint: https://virt-exportproxy-kubevirt.example.com/api/export.kubevirt.io/v1/namespaces/default/virtualmachineexports/example-backup/exports/rootdisk/map
```

`external` is populated only if the export proxy is exposed outside the cluster. See [Export API](export_api.md).

#### Endpoints

Requests are authenticated with the token, passed in the `x-kubevirt-export-token` header or query parameter.

| Endpoint | Description |
|---|---|
| `GET .../exports/<volume>/map` | Returns the extents of the volume as JSON. Query parameters: `offset`, `length`, `page_size` (default `512`). |
| `GET .../exports/<volume>/data` | Returns raw volume data as `application/octet-stream`. Query parameters: `offset`, `length`. |

`offset` defaults to `0`. If `length` is omitted, the response extends to the end of the volume, so a request without parameters returns the whole volume.

A map response contains one page of extents and the offset of the next page, or `null` after the last page:

```json
{
  "extents": [
    {"offset": 0, "length": 1048576, "type": 1, "description": "dirty"},
    {"offset": 1048576, "length": 66060288, "type": 0, "description": "clean"},
    {"offset": 67108864, "length": 2097152, "type": 3, "description": "dirty,zero"}
  ],
  "next_offset": 69206016
}
```

`type` is the state of the extent and `description` is its textual form. The possible values depend on the type of the volume.

`Incremental` volumes:

| `type` | `description` | Meaning | Consumer action |
|---|---|---|---|
| `0` | `clean` | Unchanged since the checkpoint. | Skip. |
| `1` | `dirty` | Changed since the checkpoint. | Read from `data`. |
| `2` | `zero` | Unchanged since the checkpoint; reads as zeroes. | Skip. |
| `3` | `dirty,zero` | Changed since the checkpoint; reads as zeroes, for example after a guest discard. | Write zeroes without reading. |

`Full` volumes:

| `type` | `description` | Meaning | Consumer action |
|---|---|---|---|
| `0` | `data` | Allocated, or allocation unknown. Contents unknown. | Read from `data`. |
| `1` | `hole` | Not allocated. Contents undefined (may be backed by another layer). | Read from `data`. |
| `2` | `zero` | Allocated, or allocation unknown. Reads as zeroes. | Write zeroes without reading. |
| `3` | `hole,zero` | Not allocated. Reads as zeroes. | Skip, or write zeroes. |

For example, to read the changed blocks of an incremental volume, page through `map` and request `data` for the `offset` and `length` of each `dirty` extent:

```bash
curl --cacert ca.crt -H "x-kubevirt-export-token: $TOKEN" \
  "$MAP_ENDPOINT?offset=0&page_size=1000"

curl --cacert ca.crt -H "x-kubevirt-export-token: $TOKEN" \
  "$DATA_ENDPOINT?offset=0&length=1048576" -o chunk.bin
```

#### Finishing a pull mode backup

The consumer finishes a pull mode backup by deleting the `VirtualMachineBackup`. KubeVirt then ends the backup, removes the export, detaches the scratch PVC and updates the tracker's `latestCheckpoint` to this backup.

```bash
kubectl delete vmbackup example-backup
```

!!! Warning
    Deleting the backup updates the tracker regardless of how much data was read. If the consumer did not read the backup completely, the next incremental backup does not contain the missed changes. In that case, set `forceFullBackup: true` on the next backup.

If the backup is not deleted within `ttlDuration`, KubeVirt cancels the backup and removes the export. The backup is marked `Failed` and the tracker is not updated. This also applies to a backup deleted after its `ttlDuration` has passed. `ttlDuration` counts from the creation of the backup, including any time it spends waiting to start.

## Interaction with other operations

- **Live migration:** a backup and a migration do not run at the same time. A backup created during a migration waits for the migration to finish. A migration created during a backup waits, with the `migrationBlockedByBackup` condition, until the backup ends. A migration with `priority: system-critical`, such as one triggered by a node drain, cancels the running backup instead. The migration then waits for the backup PVC to be detached, for up to `migrationConfiguration.utilityVolumesTimeout` (default 150 seconds), measured from when the backup ends. CBT data is migrated with the VM, so incremental backups continue after migration.
- **VM restart:** checkpoints and CBT data persist across a clean restart. After an unclean shutdown, affected volumes fall back to a full backup.
- **VM shutdown:** if the VM stops while a backup is running, the backup fails.
- **Snapshot restore:** after restoring a VM from a `VirtualMachineSnapshot`, set `forceFullBackup: true` on the next backup.
- **Re-enabling CBT:** writes made while CBT was disabled are not tracked. After CBT is enabled again, set `forceFullBackup: true` on the next backup.

## Restoring a backup

!!! Note
    KubeVirt does not provide a restore API. The following is a manual example.

Push mode output can be restored with `qemu-img` by rebasing each incremental backup onto the previous one, oldest first, and converting the result to a raw image:

```bash
qemu-img rebase -u -f qcow2 -F qcow2 -b full.qcow2 incremental-1.qcow2
qemu-img rebase -u -f qcow2 -F qcow2 -b incremental-1.qcow2 incremental-2.qcow2
qemu-img convert -f qcow2 -O raw incremental-2.qcow2 restored.img
```

The resulting image can be imported into a PVC, for example with [CDI upload](containerized_data_importer.md).
