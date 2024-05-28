# Device Status on Arm64

This page is based on https://github.com/kubevirt/kubevirt/issues/8916

Devices | Description | Status on Arm64
-- | -- | --
DisableHotplug |   | supported
Disks | sata/ virtio bus | support virtio bus
Watchdog | i6300esb | not supported
UseVirtioTransitional | virtio-transitional | supported
Interfaces | e1000/ virtio-net-device | support virtio-net-device
Inputs | tablet virtio/usb bus | supported
AutoattachPodInterface | connect to /net/tun (devices.kubevirt.io/tun) | supported
AutoattachGraphicsDevice | create a virtio-gpu device / vga device | support virtio-gpu
AutoattachMemBalloon | virtio-balloon-pci-non-transitional | supported
AutoattachInputDevice | auto add tablet | supported
Rng | virtio-rng-pci-non-transitional host:/dev/urandom | supported
BlockMultiQueue | "driver":"virtio-blk-pci-non-transitional","num-queues":$cpu_number | supported
NetworkInterfaceMultiQueue | -netdev tap,fds=21:23:24:25,vhost=on,vhostfds=26:27:28:29,id=hostua-default#fd number equals to queue number | supported
GPUs |   | not verified
Filesystems | virtiofs, vhost-user-fs-pci, need to enable featuregate: ExperimentalVirtiofsSupport | supported
ClientPassthrough | https://www.linaro.org/blog/kvm-pciemsi-passthrough-armarm64/on x86_64, iommu need to be enabled | not verified
Sound | ich9/ ac97 | not supported
TPM | tpm-tis-devicehttps://qemu.readthedocs.io/en/latest/specs/tpm.html | supported
Sriov | vfio-pci | not verified
