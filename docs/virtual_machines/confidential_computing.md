# Confidential computing

## AMD Secure Encrypted Virtualization (SEV)

**FEATURE STATE:** KubeVirt v0.49.0 (experimental support)

[Secure Encrypted Virtualization (SEV)](https://developer.amd.com/sev/) is a feature of AMD's EPYC CPUs that allows the memory of a virtual machine to be encrypted on the fly.

KubeVirt supports running confidential VMs on AMD EPYC hardware with SEV feature.

### Preconditions

In order to run an SEV guest the following condition must be met:

- `WorkloadEncryptionSEV` [feature gate](../operations/activating_feature_gates.md#how-to-activate-a-feature-gate) must be enabled.
- The guest must support [UEFI boot](virtual_hardware.md#biosuefi)
- SecureBoot must be disabled for the guest VM

### Running an SEV guest

SEV memory encryption can be requested by setting the `spec.domain.launchSecurity.sev` element in the VMI definition:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    launchSecurity:
      sev: {}
    firmware:
      bootloader:
        efi:
          secureBoot: false
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      rng: {}
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: registry:5000/kubevirt/fedora-with-test-tooling-container-disk:devel
    name: containerdisk
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
    name: cloudinitdisk
```

### Current limitations

- SEV-encrypted VMs cannot contain directly-accessible host devices (that is, PCI passthrough)
- Live Migration is not supported
- The VMs are not attested
