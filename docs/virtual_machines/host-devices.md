# Host Devices Assignment

KubeVirt provides a mechanism for assigning host devices to a virtual machine.
This mechanism is generic and allows various types of PCI devices, such as GPU
or any other devices attached to a PCI bus, to be assigned. It also allows
Mediated devices, such as pre-configured virtual GPUs to be assigned using the
same mechanism.


## Host preparation for PCI Passthrough

 * Host Devices passthrough requires virtualization extension and IOMMU extension
(Intel VT-d or AMD IOMMU) to be enabled in the BIOS.

 * To enable IOMMU, depending on the CPU type, a host should be booted with an additional kernel parameter, `intel_iommu=on` for Intel and `amd_iommu=on`
for AMD.

Append these parameters to the end of the GRUB_CMDLINE_LINUX line in the grub
configuration file.

```
# vi /etc/default/grub
...
GRUB_CMDLINE_LINUX="nofb splash=quiet console=tty0 ... intel_iommu=on
...

# grub2-mkconfig -o /boot/grub2/grub.cfg

# reboot
```

 * vfio-pci kernel module should be enabled on the host.
```
# modprobe vfio-pci
```

## Preparation of PCI devices for passthrough

At this time, KubeVirt is able to assign PCI devices that are using the `vfio-pci` driver. To prepare a desired device for device assignment, it should first be unbound from its original driver and bound to `vfio-pci`

 * Find PCI address of a device

```
$ lspci -DD|grep NVIDIA
0000.65:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)
```

 * Bind the device to vfio-pci driver
```
echo 0000:65:00.0 > /sys/bus/pci/drivers/nvidia/unbind
echo "vfio-pci" > /sys/bus/pci/devices/0000\:65\:00.0/driver_override
echo 0000:65:00.0 > /sys/bus/pci/drivers/vfio-pci/bind
```

## Preparation of mediated devices such as vGPU

At this time, configuration of a mediated device (mdev) should be done according to the vendor directions. Once the mdev is configured, KubeVirt will be able to discover and use it for device assignment.

## Listing permitted devices

Administrators can control which host devices are exposed and permitted to be used in the
cluster. Permitted host devices in the cluster will need to be allowlisted in KubeVirt CR by its `vendor:product` selector for PCI devices or mediated device names.

```
configuration:
  permittedHostDevices:
    pciHostDevices:
    - pciVendorSelector: "10DE:1EB8"
      resourceName: "nvidia.com/TU104GL_Tesla_T4"
      externalResourceProvider: true
    - pciVendorSelector: "8086:6F54"
      resourceName: "intel.com/qat"
    mediatedDevices:
    - mdevNameSelector: "GRID T4-1Q"
      resourceName: "nvidia.com/GRID_T4-1Q"
```

 * `pciVendorSelector` is a combination of a `vendor_id:product_id` required for a device identification on a host. This identifier `10de:1eb8` can be found using `lspci`.

        $ lspci -nnv|grep -i nvidia
        65:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)

 * `mdevNameSelector` is a name of a mediated device type required for a device identification on a host.

    For example, mediated device type `nvidia-226` represents `GRID T4-2A`. The selector is matched against the content of `/sys/class/mdev_bus/$mdevUUID/mdev_type/name`.

 * External providers:
`externalResourceProvider` field indicates that this resource is being provided by an external device plugin. KubeVirt in this case will only permit the usage of this device in the cluster but will leave the allocation and monitoring to an external device plugin.


## Staring a Virtual Machine

HostDevices, as well as the existing GPUs field, will be able to reference both
PCI and mediated devices

```
kind: VirtualMachineInstance
spec:
  domain:
    devices:
      gpus:
      - deviceName: nvidia.com/TU104GL_Tesla_T4
        name: gpu1
      - deviceName: nvidia.com/GRID_T4-1Q
        name: gpu2
      hostDevices:
      - deviceName: intel.com/qat
        name: quickaccess1
```
