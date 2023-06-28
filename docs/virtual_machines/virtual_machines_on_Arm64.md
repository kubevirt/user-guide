# Virtual Machines on Arm64

This page summaries all unsupported Virtual Machines configurations and different default setups on Arm64 platform.

## Virtual hardware

### Machine Type

Currently, we only support one machine type, `virt`, which is set by default.

### BIOS/UEFI

On Arm64 platform, we only support UEFI boot which is set by default. UEFI secure boot is not supported.

### CPU

#### Node-labeller

Currently, Node-labeller is partially supported on Arm64 platform. It does not yet support parsing virsh_domcapabilities.xml and capabilities.xml, and extracting related information such as CPU features.

#### Model

`host-passthrough` is the only model that supported on Arm64. The CPU model is set by default on Arm64 platform.

### Clock

`kvm` and `hyperv` timers are not supported on Arm64 platform.

### Video and Graphics Device

We do not support vga devices but use virtio-gpu by default.

### Hugepages

Hugepages are not supported on Arm64 platform.

### Resources Requests and Limits

CPU pinning is supported on Arm64 platform.

## NUMA

As Hugepages are a precondition of the NUMA feature, and Hugepages are not enabled on the Arm64 platform, the NUMA feature does not work on Arm64.

## Disks and Volumes

Arm64 only supports virtio and scsi disk bus types.

## Interface and Networks
### macvlan

We do not support `macvlan` network because the project https://github.com/kubevirt/macvtap-cni does not support Arm64.

### SRIOV

This class of devices is not verified on the Arm64 platform.

## Liveness and Readiness Probes

`Watchdog` device is not supported on Arm64 platform.
