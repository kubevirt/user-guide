# Hotplug Volumes

KubeVirt supports hotplugging persistent volumes into running Virtual Machines. The volumes may be represented as disks, LUNs, or CD-ROMs.

## Enabling hotplug volume support

Hotplug volume support must be enabled in the feature gates to be supported. The
[feature gates](../cluster_admin/activating_and_deactivating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `DeclarativeHotplugVolumes` to it.

> **_NOTE:_**  `DeclarativeHotplugVolumes` is incompatible with the the deprecated `HotplugVolumes` feature gate. If both are declared, `HotplugVolumes` will have precedence until the time that `HotplugVolumes` is retired.

## Supported disk busses

|       |  sata  | virtio |  scsi  |
|-------|--------|--------|--------|
| cdrom |    X   |        |        |
| disk  |        |    X   |    X   |
| lun   |        |        |    X   |

The scsi bus should be used if a large number of disks will be hotplugged concurrently. There are a limited number of VirtIO ports available. The scsi bus is [very close in performance](https://mpolednik.github.io/2017/01/23/virtio-blk-vs-virtio-scsi/) to virtio.

## Available VirtIO Ports

The following table lists the minimum number of VirtIO ports that will be available for hotplug disks.

| Memory | Ports |
|:------:|:-----:|
|  <= 2G |   3   |
|  > 2G  |   6   |

> **_NOTE:_**  available VirtIO ports are reduced for each [hotplug network interface](../network/hotplug_interfaces.md)

## Declarative API

Hotplug [DataVolume](./disks_and_volumes.md/#persistentvolumeclaim) and [PersistentVolumeClaim](./disks_and_volumes.md/#persistentvolumeclaim) volumes may be defined for VirtualMachines in a declarative, GitOps compatible way.

### Virtual Machine Definition

The following VirtualMachine has no persistent disks and an empty CD-ROM.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - cdrom:
              bus: sata
            name: cdrom
          - disk:
              bus: virtio
            name: disk0
        resources:
          requests:
            memory: 128Mi
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/alpine-container-disk-demo:v1.6.0
        name: disk0
```

### Test Volume

The following yaml will create volume containing a copy of VirtualMachine's root disk

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: hotplug-disk
spec:
  source:
    registry:
      url: "docker://quay.io/kubevirt/alpine-container-disk-demo:v1.6.0"
  storage:
    resources:
      requests:
        storage: 300Mi
```

### Inject CD-ROM

To inject a CD-ROM into a running VirtualMachine, a `cdrom` type disk must be declared on the VM when it is started. Then at any time later, a hotplug volume may be added to the `spec.template.spec.volumes` section of the VirtualMachine.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - cdrom:
              bus: sata
            name: cdrom
          - disk:
              bus: virtio
            name: disk0
        resources:
          requests:
            memory: 128Mi
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/alpine-container-disk-demo:v1.6.0
        name: disk0
      - dataVolume:
          name: hotplug-disk
          hotpluggable: true
        name: cdrom
```

### Eject CD-ROM

Remove the `cdrom` volume from the `spec.template.spec.volumes` section of the VirtualMachine.

### Hotplug Disk/LUN

To hotplug a disk/LUN into a running VirtualMachine, a new disk/LUN must be added to the `spec.template.spec.domain.devices.disks` section of the VM as well as a new volume in `spec.template.spec.volumes`.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - cdrom:
              bus: sata
            name: cdrom
          - disk:
              bus: virtio
            name: disk0
          - disk:
              bus: virtio
            name: disk1
        resources:
          requests:
            memory: 128Mi
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/alpine-container-disk-demo:v1.6.0
        name: disk0
      - dataVolume:
          name: hotplug-disk
          hotpluggable: true
        name: disk1
```

### Unplug Disk/LUN

Remove `disk1` from the `spec.template.spec.domain.devices.disks` section of the VirtualMachine and remove `disk1` from `spec.template.spec.volumes`

## Virtctl support

Volumes may also be added to VirtualMachines with virtctl. Virtctl is also the only way to hotplug a volume directly into a VirtualMachineInstance. Virtctl does not support CD-ROM inject/eject.

### Add a disk to a VirtualMachine

```bash
$ virtctl addvolume testvm --volume-name=hotplug-disk --persist
```

### Add a disk to a VirtualMachineInstance

You can only hotplug a disk to a VirtualMachineInstance (VMI) if it was created independent of a higher level resource. For instance, this operation will fail if the VMI is owned by a VirtualMachine.

```bash
$ virtctl addvolume testvmi --volume-name=hotplug-disk
```

### Add a LUN to a VirtualMachine

```bash
$ virtctl addvolume testvm --volume-name=hotplug-disk --persist --disk-type=lun
```

### Additional `addvolume` args

`--bus <bus type>` to specify the disk/LUN bus

`--cache <cache type>` to specify the disk cache type (default|none|writethrough|writeback|directsync)

`--serial <serial>` to specify the disk serial number (canonical way to identify a particular disk in the guest)

### Unplug a disk/LUN from a VirtualMachine

```bash
$ virtctl removevolume testvm --volume-name=hotplug-disk --persist
```

### VolumeStatus

VMI objects have a `status.VolumeStatus` field. This is an array containing each disk, hotplugged or not. For example:

```yaml
volumeStatus:
- containerDiskVolume:
    checksum: 538764798
  name: disk0
  target: vda
- hotplugVolume:
    attachPodName: hp-volume-phzmq
    attachPodUID: 3eea974f-85ad-4a58-97a2-46c463f9b639
  message: Successfully attach hotplugged volume blank-disk to VM
  name: blank-disk
  persistentVolumeClaimInfo:
    accessModes:
    - ReadWriteMany
    capacity:
      storage: 300Mi
    claimName: blank-disk
    filesystemOverhead: "0"
    requests:
      storage: "314572800"
    volumeMode: Block
  phase: Ready
  reason: VolumeReady
  target: sda
```

In this example, `vda` is the container disk that contains the OS. As you can see it just contains the name and target used when assigning them to the VM. The target is the value passed to QEMU when specifying the disks. The target value is unique for the VM and does *NOT* represent the naming inside the guest. For instance for a Windows Guest OS the target has no meaning. The same will be true for hotplugged volumes. The target is just a unique identifier meant for QEMU, inside the guest the disk can be assigned a different name.

The `hotplugVolume` has some extra information that regular volume statuses do not have. The `attachPodName` is the name of the pod that was used to attach the volume to the node that the VMI is running on. If this pod is deleted it will also stop the VMI as we cannot guarantee that the volume will remain attached to the node. The other fields are similar to conditions and indicate the status of the hotplug process. Once a Volume is ready, it can be used by the VM.
