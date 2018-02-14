# Volumes and Disks

Making persistent storage in the cluster (**volumes**) accessible to vms
consists of three parts. First, referencing volumes in `spec.volumes`. Second
configuring **disks** in `spec.domain.discs` to add a disk to the vm. Third,
adding a refererence to the defined volume on to the disk.

## Disks

Like all other vm devices a `spec.domain.devices.disks` element has a mandatory
`name`. Furhter it has a mandatory `volumeName` entry which references a volume
inside `spec.volumes`.

A disk can be made accessible via four different types:

 * **disk**
 * **cdrom**
 * **floppy**
 * **lun**

All possible configuration options are available in the
[Disk API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_disk).

All types but **floppy** allow you to specify the `Bus` attribute. The `Bus` attribute determine
how the disk will be presented to the Guest Operating System. **floppy** disks don't support
the `Bus` attribute: they are always attached to the `fdc` bus.

### lun

A `lun` disk will expose the volume as a LUN device to the vm. This allows the
vm to execute arbitrary iscsi command passthrough.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a
`lun` device to the vm:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        # This makes it a lun device
        lun: {}
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

### disk

A `disk` disk will expose the volume as an ordinary disk to the vm.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a
`disk` device to the vm:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        # This makes it a disk
        disk:
          # This makes it exposed as /dev/vda, being the only and thus first
          # disk attached to the VM
          bus: virtio
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

### floppy

A `floppy` disk will expose the volume as a floppy drive to the vm.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a
`floppy` device to the vm:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        # This makes it a floppy
        floppy: {}
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

### cdrom

A `cdrom` disk will expose the volume as a cdrom drive to the vm. It is
read-only by default.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a
`floppy` device to the vm:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        # This makes it a cdrom
        cdrom:
          # This makes the cdrom writeable
          readOnly: false
          # This makes the cdrom be exposed as SATA device
          bus: sata
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

## Volumes

Supported volume sources are

 * **cloudInitNoCloud**
 * **iscsi**
 * **persistentVolumeClaim**
 * **registryDisk**

All possible configuration options are available in the
[Volume API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_volume).

### cloudInitNoCloud

Allows attaching `cloudInitNoCloud` data-sources to the vm. If the vm contains
a proper cloud-init setup, it will pick up the disk as a user-data source.

A simple example which attaches a `Secret` as a cloud-init `disk` datasource
may look like this:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mybootdisk
        volumeName: mypvc
        lun: {}
      - name: mynoclouddisk
        volumeName: mynocloudvolume
        disk: {}
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
    - name: mynoclouddisk
      cloudInitNoCloud:
        secretRef:
          name: testsecret
```

### iscsi

Allows connecting ISCSI block storage to a vm disk.

A simple example which attaches an `iscsi` block storage as a `cdrom` may look
like this:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: myiscsidisk
        volumeName: myiscsi
        cdrom: {}
  volumes:
    - name: myiscsi
      iscsi:
        iqn: iqn.2017-01.io.kubevirt:sn.42
        lun: 2
        targetPortal: iscsi-demo-target.kube-system.svc.cluster.local
```

### PersistentVolumeClaim

Allows connecting a `PersistentVolumeClaim` to a vm disk. Currently only
support `PersistentVolumes` which are backed by `iscsi` volumes.

A simple example which attaches a `PersistentVolumeClaim` as a `disk` may look
like this:

```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        lun: {}
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

### registryDisk

The Registry Disk feature provides the ability to store and distribute Virtual
Machine disks in the container image registry. Registry Disks can be assigned
to Virtual Machines in the disks section of the Virtual Machine spec.

No network shared storage devices are utilized by Registry Disks. The disks are
pulled from the container registry and reside on the local node hosting the
Virtual Machines that consume the disks.

#### When to use a registryDisk

Registry Disks are ephemeral storage devices that can be assigned to any number
of active Virtual Machines. This makes them an ideal tool for users who want
to replicate a large number of Virtual Machine workloads that do not require
persistent data. Registry Disks are commonly used in conjunction with Virtual
Machine Replica Sets.

#### When Not to use a registryDisk

Registry Disks are not a good solution for any workload that requires persistent
disks across Virtual Machine restarts, or workloads that require Virtual
Machine live migration support. It is possible Registry Disks may gain live
migration support in the future, but at the moment live migrations are
incompatible with Registry Disks.

#### registryDisk Workflow Example

Users push Virtual Machine disks into the container registry using a KubeVirt
base designed to work with the Registry Disk feature. The latest base container
image is **kubevirt.io/registry-disk-v1alpha**.

Using this base image, users can inject a Virtual Machine disk into a container
image in a way that is consumable by the KubeVirt runtime. Disks placed into
the base container must be placed into the /disk directory. Raw and qcow2
formats are supported. Qcow2 is recommended in order to reduce the container
image's size.

Example: Inject a Virtual Machine disk into a container image.
```
cat << END > Dockerfile
FROM kubevirt.io/registry-disk-v1alpha
ADD fedora25.qcow2 /disk
END

docker build -t vmdisks/fedora25:latest .
```

Example: Upload the RegistryDisk container image to a registry.
```
docker push vmdisks/fedora25:latest
```

Example: Attach the RegistryDisk as an ephemeral disk to a virtual machine.
```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk: {}
  volumes:
    - name: registryvolume
      registryDisk:
        image: vmdisks/fedora25:latest
```

Note that a `registryDisk` is file-based and can therefore not be attached as a
`lun` device to the vm.
