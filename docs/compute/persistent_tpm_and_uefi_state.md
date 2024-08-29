# Persistent TPM and UEFI state

**FEATURE STATE:** KubeVirt v1.0.0

For both TPM and UEFI, libvirt supports persisting data created by a virtual machine as files on the virtualization host.  
In KubeVirt, the virtualization host is the virt-launcher pod, which is ephemeral (created on VM start and destroyed on VM stop).  
As of v1.0.0, KubeVirt supports using a PVC to persist those files. KubeVirt usually refers to that storage area as "backend storage".

## Backend storage

KubeVirt automatically creates backend storage PVCs for VMs that need it. However, to persist TPM and UEFI state, the admin must first enable the `VMPersistentState` feature gate.

If [live migration](live_migration.md) is required, then the `vmStateStorageClass` configuration parameter should be set, and must reference a storage class that supports read-write-many (RWX) in filesystem mode (FS).

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

### Notes:
- If no storage class is specified, the default storage class will be used
- If the storage class has a storage profile that indicates it only supports read-write-once (RWO) then a RWO PVC will be created and the VMI will be marked as non-migratable.
- Backend storage is currently incompatible with VM snapshot. It is planned to add snapshot support in the future.

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
