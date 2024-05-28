# Hotplug Volumes

KubeVirt now supports hotplugging volumes into a running Virtual Machine Instance (VMI). The volume must be either a block volume or contain a disk image. When a VM that has hotplugged volumes is rebooted, the hotplugged volumes will be attached to the restarted VM. If the volumes are persisted they will become part of the VM spec, and will not be considered hotplugged. If they are not persisted, the volumes will be reattached as hotplugged volumes

## Enabling hotplug volume support

Hotplug volume support must be enabled in the feature gates to be supported. The
[feature gates](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `HotplugVolumes` to it.

## Virtctl support

In order to hotplug a volume, you must first prepare a volume. This can be done by using a DataVolume (DV). In the example we will use a blank DV in order to add some extra storage to a running VMI

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: example-volume-hotplug
spec:
  source:
    blank: {}
  storage:
    resources:
      requests:
        storage: 5Gi
```
In this example we are using `ReadWriteOnce` accessMode, and the default FileSystem volume mode. Volume hotplugging supports all combinations of block volume mode and `ReadWriteMany`/`ReadWriteOnce`/`ReadOnlyMany` accessModes, if your storage supports the combination.

### Addvolume

Now lets assume we have started a VMI like the [Fedora VMI in examples](https://github.com/kubevirt/kubevirt/blob/main/examples/vmi-fedora.yaml) and the name of the VMI is 'vmi-fedora'. We can add the above blank volume to this running VMI by using the 'addvolume' command  available with virtctl

```bash
$ virtctl addvolume vmi-fedora --volume-name=example-volume-hotplug
```

This will hotplug the volume into the running VMI, and set the serial of the disk to the volume name. In this example it is set to example-hotplug-volume.

#### Why virtio-scsi
The bus of hotplug disk is specified as a `scsi` disk. Why is it not specified as `virtio` instead, like regular disks? The reason is a limitation of `virtio` disks that each disk uses a pcie slot in the virtual machine and there is a maximum of 32 slots. This means there is a low limit on the maximum number of disks you can hotplug especially given that other things will also need pcie slots. Another issue is these slots need to be reserved ahead of time. So if the number of hotplugged disks is not known ahead of time, it is impossible to properly reserve the required number of slots. To work around this issue, each VM has a virtio-scsi controller, which allows the use of a `scsi` bus for hotplugged disks. This controller allows for hotplugging of over 4 million disks. `virtio-scsi` is [very close in performance](https://mpolednik.github.io/2017/01/23/virtio-blk-vs-virtio-scsi/) to `virtio`

#### Serial
You can change the serial of the disk by specifying the --serial parameter, for example:
```bash
$ virtctl addvolume vmi-fedora --volume-name=example-volume-hotplug --serial=1234567890
```

The serial will be used in the guest so you can identify the disk inside the guest by the serial. For instance in Fedora the disk by id will contain the serial.
```bash
$ virtctl console vmi-fedora

Fedora 32 (Cloud Edition)
Kernel 5.6.6-300.fc32.x86_64 on an x86_64 (ttyS0)

SSH host key: SHA256:c8ik1A9F4E7AxVrd6eE3vMNOcMcp6qBxsf8K30oC/C8 (ECDSA)
SSH host key: SHA256:fOAKptNAH2NWGo2XhkaEtFHvOMfypv2t6KIPANev090 (ED25519)
eth0: 10.244.196.144 fe80::d8b7:51ff:fec4:7099
vmi-fedora login:fedora
Password:fedora
[fedora@vmi-fedora ~]$ ls /dev/disk/by-id
scsi-0QEMU_QEMU_HARDDISK_1234567890
[fedora@vmi-fedora ~]$ 
```
As you can see the serial is part of the disk name, so you can uniquely identify it.

The format and length of serials are specified according to the libvirt documentation:
```
    If present, this specify serial number of virtual hard drive. For example, it may look like <serial>WD-WMAP9A966149</serial>. Not supported for scsi-block devices, that is those using disk type 'block' using device 'lun' on bus 'scsi'. Since 0.7.1

    Note that depending on hypervisor and device type the serial number may be truncated silently. IDE/SATA devices are commonly limited to 20 characters. SCSI devices depending on hypervisor version are limited to 20, 36 or 247 characters.

    Hypervisors may also start rejecting overly long serials instead of truncating them in the future so it's advised to avoid the implicit truncation by testing the desired serial length range with the desired device and hypervisor combination.

```

#### Supported Disk types
Kubevirt supports hotplugging disk devices of type [disk](../storage/disks_and_volumes.md/#disk) and [lun](../storage/disks_and_volumes.md/#lun). As with other volumes, using type `disk` will expose the hotplugged volume as a regular disk, while using `lun` allows additional functionalities like the execution of iSCSI commands.

You can specify the desired type by using the --disk-type parameter, for example:

```bash
# Allowed values are lun and disk. If no option is specified, we use disk by default.
$ virtctl addvolume vmi-fedora --volume-name=example-lun-hotplug --disk-type=lun
```

### Retain hotplugged volumes after restart
In many cases it is desirable to keep hotplugged volumes after a VM restart. It may also be desirable to be able to unplug these volumes after the restart. The `persist` option makes it impossible to unplug the disks after a restart. If you don't specify `persist` the default behaviour is to retain hotplugged volumes as hotplugged volumes after a VM restart. This makes the `persist` flag mostly obsolete unless you want to make a volume permanent on restart.

### Persist
In some cases you want a hotplugged volume to become part of the standard disks after a restart of the VM.
For instance if you added some permanent storage to the VM. We also assume that the running VMI has a matching VM that defines it specification.
You can call the addvolume command with the --persist flag. This will update the VM domain disks section in addition to updating the VMI domain disks.
This means that when you restart the VM, the disk is already defined in the VM, and thus in the new VMI.

```bash
$ virtctl addvolume vm-fedora --volume-name=example-volume-hotplug --persist
```

In the VM spec this will now show as a new disk
```yaml
spec:
domain:
    devices:
        disks:
        - disk:
            bus: virtio
            name: containerdisk
        - disk:
            bus: virtio
            name: cloudinitdisk
        - disk:
            bus: scsi
            name: example-volume-hotplug
    machine:
      type: ""
```

### Removevolume
In addition to hotplug plugging the volume, you can also unplug it by using the 'removevolume' command available with virtctl
```bash
$ virtctl removevolume vmi-fedora --volume-name=example-volume-hotplug
```

> *NOTE* You can only unplug volumes that were dynamically added with addvolume, or using the API.

### VolumeStatus
VMI objects have a new `status.VolumeStatus` field. This is an array containing each disk, hotplugged or not. For example, after hotplugging the volume in the addvolume example, the VMI status will contain this:
```yaml
volumeStatus:
- name: cloudinitdisk
  target: vdb
- name: containerdisk
  target: vda
- hotplugVolume:
    attachPodName: hp-volume-7fmz4
    attachPodUID: 62a7f6bf-474c-4e25-8db5-1db9725f0ed2
  message: Successfully attach hotplugged volume volume-hotplug to VM
  name: example-volume-hotplug
  phase: Ready
  reason: VolumeReady
  target: sda
```
Vda is the container disk that contains the Fedora OS, vdb is the cloudinit disk. As you can see those just contain the name and target used when assigning them to the VM. The target is the value passed to QEMU when specifying the disks. The value is unique for the VM and does *NOT* represent the naming inside the guest. For instance for a Windows Guest OS the target has no meaning. The same will be true for hotplugged volumes. The target is just a unique identifier meant for QEMU, inside the guest the disk can be assigned a different name.

The hotplugVolume has some extra information that regular volume statuses do not have. The attachPodName is the name of the pod that was used to attach the volume to the node the VMI is running on. If this pod is deleted it will also stop the VMI as we cannot guarantee the volume will remain attached to the node. The other fields are similar to conditions and indicate the status of the hot plug process. Once a Volume is ready it can be used by the VM.

## Live Migration
Currently Live Migration is enabled for any VMI that has volumes hotplugged into it. 
> *NOTE* However there is a known issue that the migration may fail for VMIs with hotplugged block volumes if the target node uses CPU manager with static policy and `runc` prior to version `v1.0.0`.
