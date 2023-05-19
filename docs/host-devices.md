# Host Devices Assignment

KubeVirt provides a mechanism for assigning host devices to a virtual machine.
This mechanism is generic and allows various types of PCI devices,
such as accelerators (including GPUs) or any other devices attached to
a PCI bus, to be assigned. It also allows [Linux Mediated
devices](https://www.kernel.org/doc/html/latest/driver-api/vfio-mediated-device.html),
such as pre-configured virtual GPUs to be assigned using the same
mechanism.


## Host preparation for PCI Passthrough

 * Host Devices passthrough requires the virtualization extension and the IOMMU extension
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

 * The vfio-pci kernel module should be enabled on the host.
```
# modprobe vfio-pci
```

## Preparation of PCI devices for passthrough

At this time, KubeVirt is only able to assign PCI devices that are using the `vfio-pci` driver. To prepare a specific device for device assignment, it should first be unbound from its original driver and bound to the `vfio-pci` driver.

 * Find the PCI address of the desired device:

```
$ lspci -DD|grep NVIDIA
0000.65:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)
```

 * Bind that device to the `vfio-pci` driver:
```
echo 0000:65:00.0 > /sys/bus/pci/drivers/nvidia/unbind
echo "vfio-pci" > /sys/bus/pci/devices/0000\:65\:00.0/driver_override
echo 0000:65:00.0 > /sys/bus/pci/drivers/vfio-pci/bind
```

## Preparation of mediated devices such as vGPU

In general, configuration of a Mediated devices (mdevs), such as vGPUs, should be done according to the vendor directions. 
KubeVirt can now facilitate the creation of the mediated devices / vGPUs on the cluster nodes. This assumes that the required vendor driver is already installed on the nodes.
See the [Mediated devices and virtual GPUs](<../operations/mediated_devices_configuration.md>) to learn more about this functionality.

Once the mdev is configured, KubeVirt will be able to discover and use it for device assignment.

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

 * `pciVendorSelector` is a PCI vendor ID and product ID tuple in the form `vendor_id:product_id`.  This tuple can identify specific types of devices on a host. For example, the identifier `10de:1eb8`, shown above, can be found using `lspci`.

        $ lspci -nnv|grep -i nvidia
        65:00.0 3D controller [0302]: NVIDIA Corporation TU104GL [Tesla T4] [10de:1eb8] (rev a1)

 * `mdevNameSelector` is a name of a Mediated device type that can identify specific types of Mediated devices on a host.

    You can see what mediated types a given PCI device supports by
    examining the contents of
    `/sys/bus/pci/devices/SLOT:BUS:DOMAIN.FUNCTION/mdev_supported_types/TYPE/name`.
    For example, if you have an NVIDIA T4 GPU on your system, and you substitute in the `SLOT`, `BUS`, `DOMAIN`, and `FUNCTION` values that are correct for your system into the above path name, you will see that a `TYPE` of `nvidia-226` contains the selector string `GRID T4-2A` in its `name` file.

    Taking `GRID T4-2A` and specifying it as the `mdevNameSelector` allows KubeVirt to find a corresponding mediated device by matching it against `/sys/class/mdev_bus/SLOT:BUS:DOMAIN.FUNCTION/$mdevUUID/mdev_type/name` for some values of `SLOT:BUS:DOMAIN.FUNCTION` and `$mdevUUID`.

 * External providers:
`externalResourceProvider` field indicates that this resource is being provided by an external device plugin. In this case, KubeVirt will only permit the usage of this device in the cluster but will leave the allocation and monitoring to an external device plugin.


## Starting a Virtual Machine

Host devices can be assigned to virtual machines via the `gpus` and
`hostDevices` fields.  The `deviceNames` can reference both PCI
and Mediated device resource names.

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

## NVMe PCI passthrough

In order to passthrough an NVMe device the procedure is very similar to the gpu case. The device needs to be listed under the `permittedHostDevice` and under `hostDevices` in the VM declaration. 

Currently, the KubeVirt device plugin doesn't allow the user to select a specific device by specifying the address. Therefore, if multiple NVMe devices with the same vendor and product id exist in the cluster, they could be randomly assigned to a VM. If the devices are not on the same node, then the nodeSelector mitigates the issue.

Example:

Modify the `permittedHostDevice`

```yaml
    configuration:
      permittedHostDevices:
        pciHostDevices:
        - pciVendorSelector: 8086:5845
          resourceName: devices.kubevirt.io/nvme
```

VMI declaration:
```yaml
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-nvme
  name: vmi-nvme
spec:
  nodeSelector: 
    kubernetes.io/hostname: node03   # <--
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      hostDevices:  # <--
      - name: nvme  # <--
        deviceName: devices.kubevirt.io/nvme  # <--
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

