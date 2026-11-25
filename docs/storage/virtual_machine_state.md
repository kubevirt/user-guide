# VirtualMachineState

**FEATURE STATE:** KubeVirt v1.0.0

Some VM state must survive the virt-launcher pod, which is ephemeral. KubeVirt persists that state on a per-VM PersistentVolumeClaim called the **VirtualMachineState** PVC. It holds:

- **persistent TPM** state (see [Persistent TPM and UEFI state](../compute/persistent_tpm_and_uefi_state.md#tpm-with-persistent-state)),
- **persistent UEFI** (EFI VARS) state (see [Persistent TPM and UEFI state](../compute/persistent_tpm_and_uefi_state.md#efi-with-persistent-vars)), and
- **Changed Block Tracking (CBT)** metadata, which incremental backups use to find the blocks that changed since the last backup.

!!! note
    "VirtualMachineState", "backend storage" and "persistent state" all refer to this same PVC. Earlier KubeVirt releases and docs used the terms interchangeably.

KubeVirt creates the PVC implicitly whenever a VM needs it. Since v1.10, the opt-in [declarative VirtualMachineState](#declarative-virtualmachinestate) API lets you expose the PVC in the VM manifest instead, so you can size, reuse and manage it explicitly. Either way, the live PVC is reported in the VM's status:

```bash
kubectl get vm my-vm -o jsonpath='{.status.virtualMachineStateVolume.name}'
```

## Storage configuration

By default the PVC uses the cluster's default storage class. To choose a different one, set `vmStateStorageClass` in the KubeVirt CR:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    vmStateStorageClass: "nfs-csi"
```

### Access modes

The VirtualMachineState PVC is created as either `ReadWriteMany` (RWX) or `ReadWriteOnce` (RWO), derived from the [storage profile](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/storageprofile.md) of its storage class: RWX when the storage profile advertises a Filesystem RWX access mode, and RWO otherwise. The access mode matters because [live migration](#live-migration-of-the-virtualmachinestate) of an RWO PVC needs a `volumeClaimTemplate`.

!!! note "Exact access-mode rules"
    The PVC is RWX when any of these is true, and RWO otherwise:

    - the storage profile advertises a Filesystem RWX access mode;
    - `vmStateStorageClass` is set and no storage profile exists for it;
    - `vmStateStorageClass` is set and its storage profile lists no access modes.

### Storage sizing

By default KubeVirt requests a small PVC, 10 MiB, which is enough for TPM and UEFI state. When CBT is enabled (since v1.8) an extra 512 MiB is added for its metadata. On storage with a large minimum volume size, the actual allocation per VM is larger. The size is set when the PVC is created; an existing PVC is not resized.

CBT metadata grows with the VM's disks, so on long-lived VMs you may want more than the default. Pre-provision a larger PVC with the [declarative](#declarative-virtualmachinestate) `volumeClaimTemplate`.

!!! note "Requirement: fsGroup support for CBT on RWX"
    On RWX storage, CBT only initializes if the storage class's CSI driver applies the pod's `fsGroup` to the volume. The common default `fsGroupPolicy: ReadWriteOnceWithFSType` does not do this for `ReadWriteMany` volumes, so CBT fails to initialize there. Use a CSI driver configured with `fsGroupPolicy: File`.

## Declarative VirtualMachineState

**FEATURE STATE:** KubeVirt v1.10 (alpha)

With implicit creation, the VirtualMachineState PVC is provisioned with a randomly generated name that is not exposed anywhere in the VM manifest. That is convenient, but it means the PVC cannot be reused across VMs, its size cannot be pre-provisioned, and external tooling has no reliable way to discover or manage it.

The `virtualMachineState` field in the VM template spec makes the PVC **declarative**: you either template a PVC that KubeVirt owns, or point at an existing PVC to adopt. This lets you reuse the PVC across VMs for migration, templating and cloning, and control its size, storage class and lifecycle from the VM manifest, which fits GitOps workflows.

The declarative path is opt-in. VMs without `virtualMachineState` keep using the implicit path unchanged, and the two can coexist in the same cluster.

### Enabling the feature

`virtualMachineState` is gated behind the alpha `DeclarativeVMState` [feature gate](../cluster_admin/activating_feature_gates.md):

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - DeclarativeVMState
```

!!! note
    The feature gate controls **API admission only**. A VM that was created with `virtualMachineState` in its spec keeps using the declarative path even if the gate is later disabled.

### The `virtualMachineState` field

`virtualMachineState` has two optional fields; set at least one:

| Field | Description |
|---|---|
| `volumeClaimTemplate` | A `PersistentVolumeClaimTemplate` that KubeVirt uses to create and own the PVC, generating its name. KubeVirt also uses it for any PVC it creates later, such as on live migration. Because the name is generated, `metadata.name` is rejected; for a fixed name, pre-create the PVC and use `source` instead. |
| `source` | References an existing PVC (by `name`) to adopt as the starting state. KubeVirt does not take ownership of a PVC referenced this way. |

The combinations are:

- **`volumeClaimTemplate` only:** KubeVirt creates and owns the PVC.
- **`source` only:** adopt an existing PVC as-is.
- **both:** adopt `source` as the starting PVC, and use the template for any PVC the controller creates afterwards. This is what enables RWO live migration on the adoption path (see [Live migration](#live-migration-of-the-virtualmachinestate)).

The referenced PVC must use `Filesystem` volume mode; other modes are rejected. The `virtualMachineState` fields are immutable after VM creation, except for the template's storage capacity and `storageClassName`.

When `virtualMachineState` is set, any enabled TPM or EFI device is treated as persistent even without `persistent: true`, because providing a state PVC already implies the state should be kept:

```yaml
spec:
  template:
    spec:
      domain:
        devices:
          tpm: {}              # automatically persistent
        firmware:
          bootloader:
            efi: {}            # automatically persistent
      virtualMachineState:
        volumeClaimTemplate: {}
```

Setting `persistent: false` on a device is still honored: the device stays ephemeral and its state is not written to the PVC, but the PVC is still provisioned or adopted. If `virtualMachineState` is set with no persistent TPM/EFI and no CBT, the PVC is created empty.

### Status and conditions

`status.virtualMachineStateVolume` reports the live PVC and is the authoritative source for its name, which may differ from `source` after a live migration. Relevant conditions and statuses:

| Reason / status | Meaning |
|---|---|
| `VirtualMachineStatePVCNotFound` | The PVC referenced by `source` does not exist, or was deleted while the VM exists. |
| `ErrorVMStateInUse` | Another running VM already uses the referenced VirtualMachineState PVC. The VM is prevented from starting until the current holder stops. |
| `VirtualMachineStateNotLiveMigratable` | The VM cannot be live migrated because its VirtualMachineState PVC is on RWO storage and no `volumeClaimTemplate` is available to create a destination PVC. |

A VirtualMachineState PVC can only be used by one running VM at a time. Another VM may adopt it only while the current holder is stopped; starting a second VM against a PVC that is still in use fails with `ErrorVMStateInUse`.

### Examples

#### Template an owned PVC

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: my-vm
spec:
  template:
    spec:
      domain:
        devices:
          tpm: {}
      virtualMachineState:
        volumeClaimTemplate:
          spec:
            resources:
              requests:
                storage: 100Mi
```

#### Adopt an existing PVC

```yaml
virtualMachineState:
  source:
    name: existing-vmstate-pvc
```

#### Adopt an existing PVC with RWO live migration support

The source PVC seeds the initial state; the template drives any PVC the controller creates on migration.

```yaml
virtualMachineState:
  source:
    name: existing-vmstate-pvc
  volumeClaimTemplate:
    spec:
      storageClassName: fast
      resources:
        requests:
          storage: 100Mi
```

#### Migrate a VM's state to a new VM

Delete the original VM while keeping its VirtualMachineState PVC, then create a new VM that adopts it:

```bash
kubectl delete vm original-vm --cascade=orphan
```

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: migrated-vm
spec:
  template:
    spec:
      domain:
        devices:
          tpm: {}
      virtualMachineState:
        source:
          name: original-vm-state
```

### PVC layout and portability

The declarative path stores state in a canonical, VM-agnostic layout, with no VM name or UUID in the paths, so any VM can adopt the PVC as-is. A legacy PVC created by the implicit path is normalized to this layout automatically the first time a VM adopts it.

!!! warning
    CBT metadata tracks block changes for one specific VM's disks and is meaningless to another VM. When a *different* VM adopts a VirtualMachineState PVC, KubeVirt clears its CBT metadata. The next backup of the adopting VM is therefore a full backup.

### Live migration of the VirtualMachineState

- **RWX storage:** the source and target pods mount the same PVC, so no second PVC is needed.
- **RWO storage with a `volumeClaimTemplate`:** KubeVirt creates a new PVC on the destination from the template, migrates the state to it, and records the new PVC name in `status.virtualMachineStateVolume`. This covers both `volumeClaimTemplate` alone and the adoption path (`source` + `volumeClaimTemplate`).
- **RWO storage with `source` only (no template):** KubeVirt has no template to create a destination PVC, so live migration is blocked with the `VirtualMachineStateNotLiveMigratable` reason. The VM still starts and can be cold-migrated. Add a `volumeClaimTemplate` to enable RWO live migration on an adopted PVC.

### Garbage collection

- A PVC created from `volumeClaimTemplate` gets an owner reference to the VM and is deleted with it. When a live migration replaces it, KubeVirt deletes the old PVC too.
- A PVC referenced via `source` is never deleted by KubeVirt, since it may not have created it. You own its lifecycle, including any PVC left behind after a migration.

## Snapshot, restore and cloning

Since KubeVirt v1.4, VMs that use a VirtualMachineState PVC support both online and offline [snapshots](snapshot_restore_api.md), which can be restored back into the same VirtualMachine.

Since v1.10, a snapshot can also be restored into a different VirtualMachine (a clone), as long as the VirtualMachineState PVC was included in the snapshot or the restore target sets a `volumeClaimTemplate`.
