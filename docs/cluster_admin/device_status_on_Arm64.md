# Device Status on arm64

This document tracks the status of KubeVirt device support on the arm64 architecture.

Reference: https://github.com/kubevirt/kubevirt/issues/8916

## Status Definitions

 **SUPPORTED**: The device is supported on arm64 and verified by CI
 **UNSUPPORTED**: The device is not supported on arm64
 **UNVERIFIED**: The device is expected to work on arm64 but is not verified by CI

## CI Test Coverage

The arm64 CI lanes run tests labeled with `wg-arm64`. Tests are excluded if they:

- Require AMD64-specific features (ACPI, specific CPU models, SEV/TDX)
- Require multiple schedulable nodes (limited by CI infrastructure)
- Require specialized hardware (GPU, SR-IOV)

Current test lane:

1. **wg-arm64**: Basic functional tests (serial execution)

**Note**: The **sig-compute-migrations-wg-arm64** lane for live migration tests is defined in `automation/test.sh` but is not yet configured to run in CI.

## Device Support Status

Device | Description | Status
-- | -- | --
DisableHotplug | Disable hotplug capability | UNVERIFIED
Disks | SATA/virtio bus | SUPPORTED (virtio bus)
Watchdog | i6300esb watchdog device | UNSUPPORTED
UseVirtioTransitional | virtio-transitional devices | UNVERIFIED
Interfaces | e1000/virtio-net-device | SUPPORTED (virtio-net-device)
Inputs | Tablet virtio/USB bus | UNVERIFIED
AutoattachPodInterface | Connect to /net/tun (devices.kubevirt.io/tun) | SUPPORTED
AutoattachGraphicsDevice | virtio-gpu/vga device | UNVERIFIED (virtio-gpu works)
AutoattachMemBalloon | virtio-balloon-pci-non-transitional | UNVERIFIED
AutoattachInputDevice | Auto add tablet input device | UNVERIFIED
Rng | virtio-rng-pci-non-transitional (host:/dev/urandom) | UNVERIFIED
BlockMultiQueue | virtio-blk-pci-non-transitional with multiple queues | UNVERIFIED
NetworkInterfaceMultiQueue | Multi-queue networking with vhost | SUPPORTED
GPUs | GPU passthrough | UNVERIFIED
Filesystems | virtiofs (VirtIOFSGate feature gate - deprecated) | UNVERIFIED
HostDevices | PCI/PCIE passthrough ([Linaro blog](https://www.linaro.org/blog/kvm-pciemsi-passthrough-armarm64/)) | UNVERIFIED
Sound | ich9/ac97 audio devices | UNSUPPORTED
TPM | tpm-tis-device ([QEMU TPM](https://qemu.readthedocs.io/en/latest/specs/tpm.html)) | UNVERIFIED
SRIOV | vfio-pci SR-IOV passthrough | UNVERIFIED

## Notes

### Devices with CI Verification (SUPPORTED)

The following devices have been tested in the active arm64 CI lane:

- **Disks (virtio bus)**: Tested in container disk and storage tests
- **Interfaces (virtio-net-device)**: Tested in network lifecycle tests
- **AutoattachPodInterface**: Tested in network tests (connection to /net/tun)
- **NetworkInterfaceMultiQueue**: Tested in network tests

### Architecture-Specific Limitations

The following devices are marked UNSUPPORTED due to architecture-specific requirements:

- **Watchdog (i6300esb)**: x86_64-only device
- **Sound (ich9/ac97)**: x86_64-only devices

### Devices Expected to Work (UNVERIFIED)

The following devices are expected to work on arm64 based on QEMU/KVM support, but lack automated CI testing:

- virtio-based devices (virtio-gpu, virtio-balloon, virtio-rng, virtio-blk with multiqueue)
- TPM (tpm-tis-device)
- Input devices (tablet)
- Transitional virtio devices

### Hardware Passthrough (UNVERIFIED)

The following passthrough features require specialized hardware and cannot be tested in standard CI:

- **GPUs**: GPU passthrough requires arm64 systems with compatible GPUs
- **HostDevices**: PCI/PCIe passthrough is supported by KVM on arm64 ([reference](https://www.linaro.org/blog/kvm-pciemsi-passthrough-armarm64/))
- **SRIOV**: SR-IOV passthrough via vfio-pci requires compatible network cards

### Contributing

To improve arm64 device test coverage, add the `decorators.WgArm64` label to device tests in:

- `tests/` directory for the wg-arm64 lane
- Ensure tests don't require excluded features (ACPI, multiple nodes, AMD64-specific hardware)
