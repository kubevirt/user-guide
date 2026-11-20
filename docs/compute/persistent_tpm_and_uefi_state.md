# Persistent TPM and UEFI state

**FEATURE STATE:** KubeVirt v1.0.0

For both TPM and UEFI, libvirt supports persisting data created by a virtual machine as files on the virtualization host.  
In KubeVirt, the virtualization host is the virt-launcher pod, which is ephemeral (created on VM start and destroyed on VM stop).  
As of v1.0.0, KubeVirt supports using a PVC to persist those files. KubeVirt usually refers to that storage area as "backend storage".

## Backend storage

KubeVirt automatically creates backend storage PVCs for VMs that need it. However, to persist TPM and UEFI state, the admin must first enable the `VMPersistentState` feature gate. The KubeVirt CR configuration option `vmStateStorageClass` may be used to manually specify a storage class, otherwise the default storage class will be used.

Here's an example of KubeVirt CR that sets both:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    vmStateStorageClass: "nfs-csi"
    developerConfiguration:
      featureGates:
      - VMPersistentState
```

### Volume mode

Backend storage PVCs are always `Filesystem`. `Block` is not supported, and a
`volumeClaimTemplate` requesting it is overridden. `Block` support has been proposed, but
no design has been found that is reliable, race-free, and still fits in a single volume:
libvirt persists TPM and UEFI state as regular files that the source and target
virt-launcher pods must agree on across a live migration. Treat `Filesystem` as a hard
requirement rather than as a gap that is about to be filled.

This is rarely a real constraint. A
[storage profile](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/storageprofile.md)
that only advertises `Block` is usually an omission, not a limitation of the storage: CSI
drivers that provision raw block volumes almost always serve the same pool as filesystem
volumes, formatting and mounting the device instead of handing it to the pod raw. Adding
the missing `Filesystem` claim property sets to the storage profile is normally all it
takes. To confirm first, try provisioning a 10Mi `Filesystem` PVC from that storage class
by hand: if it binds and a pod can mount it, the storage class is a valid
`vmStateStorageClass`.

### Access mode

KubeVirt reads the access mode from the storage profile of the storage class, looking only
at `claimPropertySets` entries whose volume mode is `Filesystem`. RWX is used if any such
entry offers it, otherwise RWO. If the storage profile is missing, empty, or lists no
`Filesystem` entry, the fallback is RWX when `vmStateStorageClass` is set, and RWO when it
is not.

RWO is enough for every backend storage feature, including live migration: when the PVC is
not RWX, KubeVirt creates a second PVC for the migration target and hands the state over
during the migration.

This is why a missing `Filesystem` entry is the first thing to check when the backend
storage PVC stays `Pending`: it sends KubeVirt to the RWX fallback, which storage that
only does RWO will never satisfy.

### Notes:

#### Snapshot and restore compatibility

Since KubeVirt v1.4, VirtualMachines that use backend state storage support both online and offline snapshots. These snapshots can be successfully restored as long as they are restored back into the same VirtualMachine.

Restoring a snapshot into a different VirtualMachine (VM Clone) is not currently supported.

Support for snapshot-based VM cloning with backend storage is planned to be revisited in a future release.

## TPM with persistent state

Since KubeVirt v0.53.0, a TPM device can be added to a VM (with just `tpm: {}`). However, the data stored in it does not persist across reboots.  
Support for persistence was added in v1.0.0 using a simple `persistent` boolean parameter that default to false, to preserve previous behavior.  
Of course, backend storage must first be configured before adding a persistent TPM to a VM. See above.  
Here's a portion of a VM definition that includes a persistent TPM:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm
spec:
  template:
    spec:
      domain:
        devices:
          tpm:
            persistent: true
```


### Uses
- The Microsoft Windows 11 installer requires the presence of a TPM device, even though it doesn't use this. Persistence is not required in this case however.
- Some disk encryption software have optional/mandatory TPM support. For example, Bitlocker requires a persistent TPM device.

### Notes
- The TPM device exposed to the virtual machine is fully emulated (vTPM). The worker nodes do not need to have a TPM device.
- When TPM persistence is enabled, the `tpm-crb` model is used (instead of `tpm-tis` for non-persistent vTPMs)
- A virtual TPM does not provide the same security guarantees as a physical one.

## EFI with persistent VARS

EFI support is handled by libvirt using OVMF. OVMF data usually consists of 2 files, CODE and VARS. VARS is where persistent data from the guest can be stored.  
When EFI persistence is enabled on a VM, the VARS file will be persisted inside the backend storage.  
Of course, backend storage must first be configured before enabling EFI persistence on a VM. See above.  
Here's a portion of a VM definition that includes a persistent EFI:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm
spec:
  template:
    spec:
      domain:
        firmware:
          bootloader:
            efi:
              persistent: true
```

### Uses
- Preserving user-created Secure Boot certificates.
- Preserving EFI firmware settings, like language or display resolution.

### Notes
- The boot entries/order can, and most likely will, get overriden by libvirt. This is to satisfy the VM specfications. Do not expect manual boot setting changes to persist.
