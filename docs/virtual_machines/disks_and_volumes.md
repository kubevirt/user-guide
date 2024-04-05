# Filesystems, Disks and Volumes

Making persistent storage in the cluster (**volumes**) accessible to VMs consists of three parts. First, volumes are specified in `spec.volumes`. Second, disks are added to the VM by specifying them in `spec.domain.devices.disks`. Finally, a reference to the specified volume is added to the disk specification by name.

## Disks

Like all other vmi devices a `spec.domain.devices.disks` element has a
mandatory `name`, and furthermore, the disk's `name` must reference the
`name` of a volume inside `spec.volumes`.

A disk can be made accessible via four different types:

-   [**lun**](#lun)

-   [**disk**](#disk)

-   [**cdrom**](#cdrom)

-   [**fileystems**](#filesystems)

All possible configuration options are available in the [Disk API
Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_disk).

All types allow you to specify the `bus` attribute. The `bus` attribute
determines how the disk will be presented to the guest operating system.

### lun

A `lun` disk will expose the volume as a LUN device to the VM. This
allows the VM to execute arbitrary iSCSI command passthrough.

A minimal example which attaches a `PersistentVolumeClaim` named `mypvc`
as a `lun` device to the VM:

```yaml
metadata:
  name: testvmi-lun
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        # This makes it a lun device
        lun: {}
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```
#### persistent reservation
It is possible to reserve a LUN through the the SCSI Persistent Reserve commands.
In order to issue privileged SCSI ioctls, the VM requires activation of the
persistent resevation flag:

```yaml
devices:
  disks:
  - name: mypvcdisk
    lun:
      reservation: true
```

This feature is enabled by the feature gate `PersistentReservation`:

```yaml
configuration:
  developerConfiguration:
    featureGates:
    -  PersistentReservation
```

> **Note:** The persistent reservation feature enables an additional privileged
> component to be deployed together with virt-handler. Because this feature allows
> for sensitive security procedures, it is disabled by default and requires cluster
> administrator configuration.

### disk

A `disk` disk will expose the volume as an ordinary disk to the VM.

A minimal example which attaches a `PersistentVolumeClaim` named `mypvc`
as a `disk` device to the VM:

```yaml
metadata:
  name: testvmi-disk
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        # This makes it a disk
        disk: {}
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

You can set the disk `bus` type, overriding the defaults, which in turn
depends on the chipset the VM is configured to use:

```yaml
metadata:
  name: testvmi-disk
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        # This makes it a disk
        disk:
          # This makes it exposed as /dev/vda, being the only and thus first
          # disk attached to the VM
          bus: virtio
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```
### cdrom

A `cdrom` disk will expose the volume as a cdrom drive to the VM. It is
read-only by default.

A minimal example which attaches a `PersistentVolumeClaim` named `mypvc`
as a `cdrom` device to the VM:

```yaml
metadata:
  name: testvmi-cdrom
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        # This makes it a cdrom
        cdrom:
          # This makes the cdrom writeable
          readOnly: false
          # This makes the cdrom be exposed as SATA device
          bus: sata
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

### filesystems
A `filesystem` device will expose the volume as a filesystem to the VM.
`filesystems` rely on `virtiofs` to make visible external filesystems to `KubeVirt` VMs. 
Further information about `virtiofs` can be found at the [Official Virtiofs Site](https://virtio-fs.gitlab.io/).

Compared with `disk`, `filesystems` allow changes in the source to be dynamically reflected in the volumes inside the VM.
For instance, if a given `configMap` is shared with `filesystems` any change made on it will be reflected in the
VMs.
However, it is important to note that `filesystems` **do not allow live migration**.

Additionally, `filesystem` devices must be mounted inside the VM.
This can be done through [cloudInitNoCloud](#cloudinitnocloud) or manually connecting to the VM shell and targeting the same
command.
The main challenge is to understand how the device tag used to identify the new filesystem and mount it with the 
`mount -t virtiofs [device tag] [path]` command.
For that purpose, the tag is assigned to the filesystem in the VM spec `spec.domain.devices.filesystems.name`.
For instance, if in a given VM spec is `spec.domain.devices.filesystems.name: foo`, the required command inside the VM
to mount the filesystem in the `/tmp/foo` path will be `mount -t virtiofs foo /tmp/foo`:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: testvmi-filesystems
spec:
  domain:
    devices:
      filesystems:
        - name: foo
          virtiofs: {}
      disks:
        - name: containerdisk
          disk:
            bus: virtio
        - name: cloudinitdisk
          disk:
            bus: virtio
    volumes:
      - containerDisk:
          image: quay.io/containerdisks/fedora:latest
        name: containerdisk 
      - cloudInitNoCloud:
            userData: |-
              #cloud-config
              chpasswd:
                expire: false
              password: fedora
              user: fedora
              bootcmd:
                - "sudo mkdir /tmp/foo"
                - "sudo mount -t virtiofs foo /tmp/foo"
      - persistentVolumeClaim:
          claimName: mypvc
        name: foo
```
> **Note:** As stated, `filesystems` rely on `virtiofs`. Moreover, `virtiofs` requires kernel linux support to work in 
> the VM.
> To check if the linux image of the VM has the required support, you can address the following command: `modprobe virtiofs`.
> If the command output is `modprobe: FATAL: Module virtiofs not found`, **the linux image of the VM does not support virtiofs**.
> Also, you can check if the kernel version is up to 5.4 in any linux distribution or up to 4.18 in centos/rhel. 
> To check this, you can target the following command: `uname -r`.

Refer to section [Sharing Directories with VMs](#sharing-directories-with-vms) for usage examples of `filesystems`.

### error policy

The error policy controls how the hypervisor should behave when an IO error occurs on a disk read or write. The default behaviour is to stop the guest and a Kubernetes event is generated. However, it is possible to change the value to either:

- `report`: the error is reported in the guest
- `ignore`: the error is ignored, but the read/write failure goes undetected
- `enospace`: error when there isn't enough space on the disk

The error policy can be specified per disk or lun.

Example:
```yaml
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
        errorPolicy: "report"
      - lun:
          bus: scsi
        name: scsi-disk
        errorPolicy: "report"
```

## Volumes

Supported volume sources are

-   [**cloudInitNoCloud**](#cloudinitnocloud)

-   [**cloudInitConfigDrive**](#cloudinitconfigdrive)

-   [**persistentVolumeClaim**](#persistentvolumeclaim)

-   [**dataVolume**](#datavolume)

-   [**ephemeral**](#ephemeral)

-   [**containerDisk**](#containerdisk)

-   [**emptyDisk**](#emptydisk)

-   [**hostDisk**](#hostdisk)

-   [**configMap**](#configmap)

-   [**secret**](#secret)

-   [**serviceAccount**](#serviceaccount)

-   [**downwardMetrics**](#downwardmetrics)

All possible configuration options are available in the [Volume API
Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_volume).

### cloudInitNoCloud

Allows attaching `cloudInitNoCloud` data-sources to the VM. If the VM
contains a proper cloud-init setup, it will pick up the disk as a
user-data source.

A simple example which attaches a `Secret` as a cloud-init `disk`
datasource may look like this:

```yaml
metadata:
  name: testvmi-cloudinitnocloud
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mybootdisk
        lun: {}
      - name: mynoclouddisk
        disk: {}
  volumes:
    - name: mybootdisk
      persistentVolumeClaim:
        claimName: mypvc
    - name: mynoclouddisk
      cloudInitNoCloud:
        secretRef:
          name: testsecret
```
### cloudInitConfigDrive

Allows attaching `cloudInitConfigDrive` data-sources to the VM. If the
VM contains a proper cloud-init setup, it will pick up the disk as a
user-data source.

A simple example which attaches a `Secret` as a cloud-init `disk`
datasource may look like this:

```yaml
metadata:
  name: testvmi-cloudinitconfigdrive
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mybootdisk
        lun: {}
      - name: myconfigdrivedisk
        disk: {}
  volumes:
    - name: mybootdisk
      persistentVolumeClaim:
        claimName: mypvc
    - name: myconfigdrivedisk
      cloudInitConfigDrive:
        secretRef:
          name: testsecret
```

The `cloudInitConfigDrive` can also be used to configure VMs with Ignition.
You just need to replace the cloud-init data by the Ignition data.

### persistentVolumeClaim

Allows connecting a `PersistentVolumeClaim` to a VM disk.

Use a PersistentVolumeClaim when the VirtualMachineInstance's disk needs
to persist after the VM terminates. This allows for the VM's data to
remain persistent between restarts.

A `PersistentVolume` can be in "filesystem" or "block" mode:

-   Filesystem: For KubeVirt to be able to consume the disk present on a
    PersistentVolume's filesystem, the disk must be named `disk.img` and
    be placed in the root path of the filesystem. Currently the disk is
    also required to be in raw format. **> Important:** The
    `disk.img` image file needs to be owned by the user-id `107` in
    order to avoid permission issues.

    > **Note:** If the `disk.img` image file has not been created manually
    > before starting a VM then it will be created automatically with the
    > `PersistentVolumeClaim` size. Since not every storage provisioner
    > provides volumes with the exact usable amount of space as requested (e.g.
    > due to filesystem overhead), KubeVirt tolerates up to 10% less available
    > space. This can be configured with the
    > `developerConfiguration.pvcTolerateLessSpaceUpToPercent` value in the
    > KubeVirt CR (`kubectl edit kubevirt kubevirt -n kubevirt`).

-   Block: Use a block volume for consuming raw block devices. Note: you
    need to enable the `BlockVolume`
    [feature gate](../operations/activating_feature_gates.md#how-to-activate-a-feature-gate).

A simple example which attaches a `PersistentVolumeClaim` as a `disk`
may look like this:

```yaml
metadata:
  name: testvmi-pvc
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        lun: {}
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

#### Thick and thin volume provisioning

Sparsification can make a disk thin-provisioned, in other words it allows to
convert the freed space within the disk image into free space back on the host.
The [fstrim](https://man7.org/linux/man-pages/man8/fstrim.8.html#:~:text=fstrim%20is%20used%20on%20a,unused%20blocks%20in%20the%20filesystem)
utility can be used on a mounted filesystem to discard the blocks not used by the filesystem.
In order to be able to sparsify a disk inside the guest, the disk needs to be configured in the
[libvirt xml](https://libvirt.org/formatdomain.html) with the option `discard=unmap`.
In KubeVirt, every disk is passed as default with this option enabled. It is
possible to check if the trim configuration is supported in the guest by
running`lsblk -D`, and check the discard options supported on every disk.

Example:
```bash
$ lsblk -D
NAME   DISC-ALN DISC-GRAN DISC-MAX DISC-ZERO
loop0         0        4K       4G         0
loop1         0       64K       4M         0
sr0           0        0B       0B         0
rbd0          0       64K       4M         0
vda         512      512B       2G         0
└─vda1        0      512B       2G         0
```

However, in certain cases like preallocaton or when the disk is thick
provisioned, the option needs to be disabled. The disk's PVC has to be marked
with an annotation that contains `/storage.preallocation` or
`/storage.thick-provisioned`, and set to true. If the volume is preprovisioned
using [CDI](https://github.com/kubevirt/containerized-data-importer) and the
[preallocation](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/preallocation.md)
is enabled, then the PVC is automatically annotated with: `cdi.kubevirt.io/storage.preallocation: true`
and the discard passthrough option is disabled.

Example of a PVC definition with the annotation to disable discard passthrough:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
  annotations:
    user.custom.annotation/storage.thick-provisioned: "true"
spec:
  storageClassName: local
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 1Gi
```

#### dataVolume

DataVolumes are a way to automate importing virtual machine disks onto
PVCs during the virtual machine's launch flow. Without using a
DataVolume, users have to prepare a PVC with a disk image before
assigning it to a VM or VMI manifest. With a DataVolume, both the PVC
creation and import is automated on behalf of the user.

#### DataVolume VM Behavior

DataVolumes can be defined in the VM spec directly by adding the
DataVolumes to the `dataVolumeTemplates` list. Below is an example.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-alpine-datavolume
  name: vm-alpine-datavolume
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-alpine-datavolume
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
        resources:
          requests:
            memory: 64M
      volumes:
      - dataVolume:
          name: alpine-dv
        name: datavolumedisk1
  dataVolumeTemplates:
  - metadata:
      name: alpine-dv
    spec:
      pvc:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi
      source:
        http:
          url: http://cdi-http-import-server.kubevirt/images/alpine.iso
```

You can see the DataVolume defined in the dataVolumeTemplates section
has two parts. The **source** and **pvc**

The **source** part declares that there is a disk image living on an
http server that we want to use as a volume for this VM. The **pvc**
part declares the spec that should be used to create the PVC that hosts
the **source** data.

When this VM manifest is posted to the cluster, as part of the launch
flow a PVC will be created using the spec provided and the source data
will be automatically imported into that PVC before the VM starts. When
the VM is deleted, the storage provisioned by the DataVolume will
automatically be deleted as well.

#### DataVolume VMI Behavior

For a VMI object, DataVolumes can be referenced as a volume source for
the VMI. When this is done, it is expected that the referenced
DataVolume exists in the cluster. The VMI will consume the DataVolume,
but the DataVolume's life-cycle will not be tied to the VMI.

Below is an example of a DataVolume being referenced by a VMI. It is
expected that the DataVolume *alpine-datavolume* was created prior to
posting the VMI manifest to the cluster. It is okay to post the VMI
manifest to the cluster while the DataVolume is still having data
imported. KubeVirt knows not to start the VMI until all referenced
DataVolumes have finished their clone and import phases.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-alpine-datavolume
  name: vmi-alpine-datavolume
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: disk1
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: disk1
    dataVolume:
      name: alpine-datavolume
```

#### Enabling DataVolume support.

A DataVolume is a custom resource provided by the Containerized Data
Importer (CDI) project. KubeVirt integrates with CDI in order to provide
users a workflow for dynamically creating PVCs and importing data into
those PVCs.

In order to take advantage of the DataVolume volume source on a VM or
VMI, CDI must be installed.

**Installing CDI**

Go to the [CDI release
page](https://github.com/kubevirt/containerized-data-importer/releases)

Pick the latest stable release and post the corresponding
cdi-controller-deployment.yaml manifest to your cluster.

### ephemeral

An ephemeral volume is a local COW (copy on write) image that uses a
network volume as a read-only backing store. With an ephemeral volume,
the network backing store is never mutated. Instead all writes are
stored on the ephemeral image which exists on local storage. KubeVirt
dynamically generates the ephemeral images associated with a VM when the
VM starts, and discards the ephemeral images when the VM stops.

Ephemeral volumes are useful in any scenario where disk persistence is
not desired. The COW image is discarded when VM reaches a final state
(e.g., succeeded, failed).

Currently, only `PersistentVolumeClaim` may be used as a backing store
of the ephemeral volume.

Up-to-date information on supported backing stores can be found in the
[KubeVirt
API](http://kubevirt.io/api-reference/master/definitions.html#_v1_ephemeralvolumesource).

```yaml
metadata:
  name: testvmi-ephemeral-pvc
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        lun: {}
  volumes:
    - name: mypvcdisk
      ephemeral:
        persistentVolumeClaim:
          claimName: mypvc
```

### containerDisk

**containerDisk was originally registryDisk, please update your code
when needed.**

The `containerDisk` feature provides the ability to store and distribute
VM disks in the container image registry. `containerDisks` can be
assigned to VMs in the disks section of the VirtualMachineInstance spec.

No network shared storage devices are utilized by `containerDisks`. The
disks are pulled from the container registry and reside on the local
node hosting the VMs that consume the disks.

#### When to use a containerDisk

`containerDisks` are ephemeral storage devices that can be assigned to
any number of active VirtualMachineInstances. This makes them an ideal
tool for users who want to replicate a large number of VM workloads that
do not require persistent data. `containerDisks` are commonly used in
conjunction with VirtualMachineInstanceReplicaSets.

#### When Not to use a containerDisk

`containerDisks` are not a good solution for any workload that requires
persistent root disks across VM restarts.

#### containerDisk Workflow Example

Users can inject a VirtualMachineInstance disk into a container image in
a way that is consumable by the KubeVirt runtime. Disks must be placed
into the `/disk` directory inside the container. Raw and qcow2 formats
are supported. Qcow2 is recommended in order to reduce the container
image's size. `containerdisks` can and should be based on `scratch`. No
content except the image is required.

> **Note:** Prior to kubevirt 0.20, the containerDisk image needed to
> have **kubevirt/container-disk-v1alpha** as base image.

> **Note:** The containerDisk needs to be readable for the user with the UID
> 107 (qemu).

Example: Inject a local VirtualMachineInstance disk into a container image.

    cat << END > Dockerfile
    FROM scratch
    ADD --chown=107:107 fedora25.qcow2 /disk/
    END

    docker build -t vmidisks/fedora25:latest .

Example: Inject a remote VirtualMachineInstance disk into a container image.

    cat << END > Dockerfile
    FROM scratch
    ADD --chown=107:107 https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2 /disk/
    END

Example: Upload the ContainerDisk container image to a registry.

    docker push vmidisks/fedora25:latest

Example: Attach the ContainerDisk as an ephemeral disk to a VM.

```yaml
metadata:
  name: testvmi-containerdisk
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: containerdisk
        disk: {}
  volumes:
    - name: containerdisk
      containerDisk:
        image: vmidisks/fedora25:latest
```

Note that a `containerDisk` is file-based and therefore cannot be
attached as a `lun` device to the VM.

#### Custom disk image path

ContainerDisk also allows to store disk images in any folder, when
required. The process is the same as previous. The main difference is,
that in custom location, kubevirt does not scan for any image. It is
your responsibility to provide full path for the disk image. Providing
image `path` is optional. When no `path` is provided, kubevirt searches
for disk images in default location: `/disk`.

Example: Build container disk image:

    cat << END > Dockerfile
    FROM scratch
    ADD fedora25.qcow2 /custom-disk-path/fedora25.qcow2
    END

    docker build -t vmidisks/fedora25:latest .
    docker push vmidisks/fedora25:latest

Create VMI with container disk pointing to the custom location:

```yaml
metadata:
  name: testvmi-containerdisk
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: containerdisk
        disk: {}
  volumes:
    - name: containerdisk
      containerDisk:
        image: vmidisks/fedora25:latest
        path: /custom-disk-path/fedora25.qcow2
```

### emptyDisk

An `emptyDisk` works similar to an `emptyDir` in Kubernetes. An extra
sparse `qcow2` disk will be allocated and it will live as long as the
VM. Thus it will survive guest side VM reboots, but not a VM
re-creation. The disk `capacity` needs to be specified.

Example: Boot cirros with an extra `emptyDisk` with a size of `2GiB`:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: testvmi-nocloud
spec:
  terminationGracePeriodSeconds: 5
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: containerdisk
        disk:
          bus: virtio
      - name: emptydisk
        disk:
          bus: virtio
  volumes:
    - name: containerdisk
      containerDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
    - name: emptydisk
      emptyDisk:
        capacity: 2Gi
```
#### When to use an emptyDisk

Ephemeral VMs very often come with read-only root images and limited
tmpfs space. In many cases this is not enough to install application
dependencies and provide enough disk space for the application data.
While this data is not critical and thus can be lost, it is still needed
for the application to function properly during its lifetime. This is
where an `emptyDisk` can be useful. An emptyDisk is often used and
mounted somewhere in `/var/lib` or `/var/run`.

### hostDisk

A `hostDisk` volume type provides the ability to create or use a disk
image located somewhere on a node. It works similar to a `hostPath` in
Kubernetes and provides two usage types:

-   `DiskOrCreate` if a disk image does not exist at a given location
    then create one

-   `Disk` a disk image must exist at a given location

Note: you need to enable the HostDisk feature gate.

Example: Create a 1Gi disk image located at /data/disk.img and attach it
to a VM.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-host-disk
  name: vmi-host-disk
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: host-disk
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - hostDisk:
      capacity: 1Gi
      path: /data/disk.img
      type: DiskOrCreate
    name: host-disk
status: {}
```

### configMap
A `configMap` is a reference to a
[ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
in Kubernetes. 
A `configMap` can be presented to the VM as disks or as a filesystem. Each method is described in the following
sections and both have some advantages and disadvantages, e.g. `disk` does not support dynamic change propagation and
`filesystem` does not support live migration.
Therefore, depending on the use-case, one or the other may be more suitable.
 

#### As a disk
By using disk, an extra `iso` disk will be allocated which has to be
mounted on a VM. To mount the `configMap` users can use `cloudInit` and
the disk's serial number. The `name` needs to be set for a reference to
the created kubernetes `ConfigMap`.

> **Note:** Currently, ConfigMap update is not propagate into the VMI. If
> a ConfigMap is updated, only a pod will be aware of changes, not
> running VMIs.

> **Note:** Due to a Kubernetes CRD
> [issue](https://github.com/kubernetes/kubernetes/issues/68466), you
> cannot control the paths within the volume where ConfigMap keys are
> projected.

Example: Attach the `configMap` to a VM and use `cloudInit` to mount the
`iso` disk:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
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
        name: app-config-disk
        # set serial
        serial: CVLY623300HK240D
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: containerdisk
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
        bootcmd:
          # mount the ConfigMap
          - "sudo mkdir /mnt/app-config"
          - "sudo mount /dev/$(lsblk --nodeps -no name,serial | grep CVLY623300HK240D | cut -f1 -d' ') /mnt/app-config"
    name: cloudinitdisk
  - configMap:
      name: app-config
    name: app-config-disk
status: {}
```

#### As a filesystem

By using filesystem, `configMaps` are shared through `virtiofs`. In contrast with using disk for sharing `configMaps`,
`filesystem` allows you to dynamically propagate changes on `configMaps` to VMIs (i.e. the VM does not need to be rebooted).

> **Note:** Currently, VMIs can not be live migrated since `virtiofs` does not support live migration.
 
To share a given `configMap`, the following VM definition could be used:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    devices:
      filesystems:
        - name: config-fs
          virtiofs: {}
      disks:
      - disk:
          bus: virtio
        name: containerdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: containerdisk
    containerDisk:
      image: quay.io/containerdisks/fedora:latest
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        chpasswd:
          expire: false
        password: fedora
        user: fedora
        bootcmd:
          # mount the ConfigMap
          - "sudo mkdir /mnt/app-config"
          - "sudo mount -t virtiofs config-fs /mnt/app-config"
    name: cloudinitdisk      
  - configMap:
      name: app-config
    name: config-fs
```

### secret

A `secret` is a reference to a
[Secret](https://kubernetes.io/docs/concepts/configuration/secret/) in
Kubernetes.
A `secret` can be presented to the VM as disks or as a filesystem. Each method is described in the following
sections and both have some advantages and disadvantages, e.g. `disk` does not support dynamic change propagation and
`filesystem` does not support live migration.
Therefore, depending on the use-case, one or the other may be more suitable.

#### As a disk
By using disk, an extra `iso` disk will be allocated which has to be
mounted on a VM. To mount the `secret` users can use `cloudInit` and the
disks serial number. The `secretName` needs to be set for a reference to
the created kubernetes `Secret`.

> **Note:** Currently, Secret update propagation is not supported. If a
> Secret is updated, only a pod will be aware of changes, not running
> VMIs.

> **Note:** Due to a Kubernetes CRD
> [issue](https://github.com/kubernetes/kubernetes/issues/68466), you
> cannot control the paths within the volume where Secret keys are
> projected.

Example: Attach the `secret` to a VM and use `cloudInit` to mount the
`iso` disk:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
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
        name: app-secret-disk
        # set serial
        serial: D23YZ9W6WA5DJ487
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: containerdisk
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
        bootcmd:
          # mount the Secret
          - "sudo mkdir /mnt/app-secret"
          - "sudo mount /dev/$(lsblk --nodeps -no name,serial | grep D23YZ9W6WA5DJ487 | cut -f1 -d' ') /mnt/app-secret"
    name: cloudinitdisk
  - secret:
      secretName: app-secret
    name: app-secret-disk
status: {}
```

#### As a filesystem

By using filesystem, `secrets` are shared through `virtiofs`. In contrast with using disk for sharing `secrets`,
`filesystem` allows you to dynamically propagate changes on `secrets` to VMIs (i.e. the VM does not need to be rebooted).

> **Note:** Currently, VMIs can not be live migrated since `virtiofs` does not support live migration.
 
To share a given `secret`, the following VM definition could be used:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    devices:
      filesystems:
        - name: app-secret-fs
          virtiofs: {}
      disks:
        - disk:
            bus: virtio
          name: containerdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
    - name: containerdisk
      containerDisk:
        image: quay.io/containerdisks/fedora:latest
    - cloudInitNoCloud:
        userData: |-
          #cloud-config
          chpasswd:
            expire: false
          password: fedora
          user: fedora
          bootcmd:
            # mount the Secret
            - "sudo mkdir /mnt/app-secret"
            - "sudo mount -t virtiofs app-secret-fs /mnt/app-secret"
      name: cloudinitdisk
    - secret:
        secretName: app-secret
      name: app-secret-fs
```

### serviceAccount

A `serviceAccount` volume references a Kubernetes
[`ServiceAccount`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).
A `serviceAccount` can be presented to the VM as disks or as a filesystem. Each method is described in the following
sections and both have some advantages and disadvantages, e.g. `disk` does not support dynamic change propagation and
`filesystem` does not support live migration.
Therefore, depending on the use-case, one or the other may be more suitable.

#### As a disk
By using disk, a new `iso` disk will be allocated with the content of the service
account (`namespace`, `token` and `ca.crt`), which needs to be mounted
in the VM. For automatic mounting, see the `configMap` and `secret`
examples above.

> **Note:** Currently, ServiceAccount update propagation is not supported. If a
> ServiceAccount is updated, only a pod will be aware of changes, not running
> VMIs.

Example:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    devices:
      disks:
      - disk:
        name: containerdisk
      - disk:
        name: serviceaccountdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: containerdisk
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
  - name: serviceaccountdisk
    serviceAccount:
      serviceAccountName: default
```

#### As a filesystem

By using filesystem, `serviceAccounts` are shared through `virtiofs`. In contrast with using disk for sharing `serviceAccounts`,
`filesystem` allows you to dynamically propagate changes on `serviceAccounts` to VMIs (i.e. the VM does not need to be rebooted).

> **Note:** Currently, VMIs can not be live migrated since `virtiofs` does not support live migration.
 
To share a given `serviceAccount`, the following VM definition could be used:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    devices:
      filesystems:
        - name: serviceaccount-fs
          virtiofs: {}
      disks:
        - disk:
            bus: virtio
          name: containerdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
    - name: containerdisk
      containerDisk:
        image: quay.io/containerdisks/fedora:latest
    - cloudInitNoCloud:
        userData: |-
          #cloud-config
          chpasswd:
            expire: false
          password: fedora
          user: fedora
          bootcmd:
            # mount the ConfigMap
            - "sudo mkdir /mnt/serviceaccount"
            - "sudo mount -t virtiofs serviceaccount-fs /mnt/serviceaccount"
      name: cloudinitdisk
    - name: serviceaccount-fs
      serviceAccount:
        serviceAccountName: default
```

### downwardMetrics

`downwardMetrics` expose a limited set of VM and host metrics to the
guest. The format is compatible with [vhostmd](https://github.com/vhostmd/vhostmd).

Getting a limited set of host and VM metrics is in some cases required to allow
third-parties diagnosing performance issues on their appliances. One prominent
example is SAP HANA.

In order to expose `downwardMetrics` to VMs, the methods `disk` and `virtio-serial port` are supported.

> **Note:** The **DownwardMetrics** feature gate
> [must be enabled](../operations/activating_feature_gates.md#how-to-activate-a-feature-gate)
> to use the metrics. Available starting with KubeVirt v0.42.0.
 
#### Disk

A volume is created, and it is exposed to the guest as a raw block volume. 
KubeVirt will update it periodically (by default, every 5 seconds).

Example:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: metrics
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: containerdisk
    containerDisk:
      image: quay.io/containerdisks/fedora:latest
  - name: metrics
    downwardMetrics: {}
```

#### Virtio-serial port

This method uses a virtio-serial port to expose the metrics data to the VM.
KubeVirt creates a port named `/dev/virtio-ports/org.github.vhostmd.1` inside the VM, in which the Virtio Transport protocol
is supported. `downwardMetrics` can be retrieved from this port.
See [vhostmd documentation](https://github.com/vhostmd/vhostmd/blob/master/README) under `Virtio Transport` for further
information.

To expose the metrics using a virtio-serial port, a `downwardMetrics` device must be added (i.e.,
`spec.domain.devices.downwardMetrics: {}`).

Example:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    devices:
      downwardMetrics: {}
      disks:
      - disk:
          bus: virtio
        name: containerdisk
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: containerdisk
    containerDisk:
      image: quay.io/containerdisks/fedora:latest
```
#### Accessing Metrics Data

To access the DownwardMetrics shared with a disk or a virtio-serial port, the `vm-dump-metrics` tool can be used:

```xml
$ sudo dnf install -y vm-dump-metrics
$ sudo vm-dump-metrics
<metrics>
  <metric type="string" context="host">
    <name>HostName</name>
    <value>node01</value>
[...]
  <metric type="int64" context="host" unit="s">
    <name>Time</name>
    <value>1619008605</value>
  </metric>
  <metric type="string" context="host">
    <name>VirtualizationVendor</name>
    <value>kubevirt.io</value>
  </metric>
</metrics>
```

`vm-dump-metrics` is useful as a standalone tool to verify the serial port is working and to inspect the metrics. 
However, applications that consume metrics will usually connect to the virtio-serial port themselves.

> **Note:** The tool `vm-dump-metrics` provides the option `--virtio` in case the virtio-serial port is used.
> Please, refer to `vm-dump-metrics --help` for further information.

## High Performance Features

### IOThreads

Libvirt has the ability to use IOThreads for dedicated disk access (for
supported devices). These are dedicated event loop threads that perform
block I/O requests and improve scalability on SMP systems. KubeVirt
exposes this libvirt feature through the `ioThreadsPolicy` setting.
Additionally, each `Disk` device exposes a `dedicatedIOThread` setting.
This is a boolean that indicates the specified disk should be allocated
an exclusive IOThread that will never be shared with other disks.

Currently valid policies are `shared` and `auto`. If `ioThreadsPolicy`
is omitted entirely, use of IOThreads will be disabled. However, if any
disk requests a dedicated IOThread, `ioThreadsPolicy` will be enabled
and default to `shared`.

#### Shared

An `ioThreadsPolicy` of `shared` indicates that KubeVirt should use one
thread that will be shared by all disk devices. This policy stems from
the fact that large numbers of IOThreads is generally not useful as
additional context switching is incurred for each thread.

Disks with `dedicatedIOThread` set to `true` will not use the shared
thread, but will instead be allocated an exclusive thread. This is
generally useful if a specific Disk is expected to have heavy I/O
traffic, e.g. a database spindle.

#### Auto

`auto` IOThreads indicates that KubeVirt should use a pool of IOThreads
and allocate disks to IOThreads in a round-robin fashion. The pool size
is generally limited to twice the number of VCPU's allocated to the VM.
This essentially attempts to dedicate disks to separate IOThreads, but
only up to a reasonable limit. This would come in to play for systems
with a large number of disks and a smaller number of CPU's for instance.

As a caveat to the size of the IOThread pool, disks with
`dedicatedIOThread` will always be guaranteed their own thread. This
effectively diminishes the upper limit of the number of threads
allocated to the rest of the disks. For example, a VM with 2 CPUs would
normally use 4 IOThreads for all disks. However if one disk had
`dedicatedIOThread` set to true, then KubeVirt would only use 3
IOThreads for the shared pool.

There is always guaranteed to be at least one thread for disks that will
use the shared IOThreads pool. Thus if a sufficiently large number of
disks have dedicated IOThreads assigned, `auto` and `shared` policies
would essentially result in the same layout.

#### IOThreads with Dedicated (pinned) CPUs

When guest's vCPUs are pinned to a host's physical CPUs, it is also best
to pin the IOThreads to specific CPUs to prevent these from floating
between the CPUs. KubeVirt will automatically calculate and pin each
IOThread to a CPU or a set of CPUs, depending on the ration between
them. In case there are more IOThreads than CPUs, each IOThread will be
pinned to a CPU, in a round-robin fashion. Otherwise, when there are
fewer IOThreads than CPU, each IOThread will be pinned to a set of CPUs.

#### IOThreads with QEMU Emulator thread and Dedicated (pinned) CPUs

To further improve the vCPUs latency, KubeVirt can allocate an
additional dedicated physical CPU<sup>[1](./virtual_hardware.md#cpu)</sup>, exclusively for the emulator thread, to which it will
be pinned. This will effectively "isolate" the emulator thread from the vCPUs
of the VMI. When `ioThreadsPolicy` is set to `auto` IOThreads will also be
"isolated" from the vCPUs and placed on the same physical CPU as the QEMU
emulator thread.

### Examples

#### Shared IOThreads

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-shared
  name: vmi-shared
spec:
  domain:
    ioThreadsPolicy: shared
    cpu:
      cores: 2
    devices:
      disks:
      - disk:
          bus: virtio
        name: vmi-shared_disk
      - disk:
          bus: virtio
        name: emptydisk
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk2
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk3
      - disk:
          bus: virtio
        name: emptydisk4
      - disk:
          bus: virtio
        name: emptydisk5
      - disk:
          bus: virtio
        name: emptydisk6
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  volumes:
  - name: vmi-shared_disk
    persistentVolumeClaim:
      claimName: vmi-shared_pvc
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk2
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk3
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk4
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk5
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk6
```

In this example, emptydisk and emptydisk2 both request a dedicated IOThread. vmi-shared_disk, and emptydisk 3 through 6 will all shared one IOThread.

    mypvc:        1
    emptydisk:    2
    emptydisk2:   3
    emptydisk3:   1
    emptydisk4:   1
    emptydisk5:   1
    emptydisk6:   1

#### Auto IOThreads

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-shared
  name: vmi-shared
spec:
  domain:
    ioThreadsPolicy: auto
    cpu:
      cores: 2
    devices:
      disks:
      - disk:
          bus: virtio
        name: mydisk
      - disk:
          bus: virtio
        name: emptydisk
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk2
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk3
      - disk:
          bus: virtio
        name: emptydisk4
      - disk:
          bus: virtio
        name: emptydisk5
      - disk:
          bus: virtio
        name: emptydisk6
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  volumes:
  - name: mydisk
    persistentVolumeClaim:
      claimName: mypvc
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk2
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk3
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk4
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk5
  - emptyDisk:
      capacity: 1Gi
    name: emptydisk6
```

This VM is identical to the first, except it requests auto IOThreads.
`emptydisk` and `emptydisk2` will still be allocated individual
IOThreads, but the rest of the disks will be split across 2 separate
iothreads (twice the number of CPU cores is 4).

Disks will be assigned to IOThreads like this:

    mypvc:        1
    emptydisk:    3
    emptydisk2:   4
    emptydisk3:   2
    emptydisk4:   1
    emptydisk5:   2
    emptydisk6:   1

### Virtio Block Multi-Queue

Block Multi-Queue is a framework for the Linux block layer that maps
Device I/O queries to multiple queues. This splits I/O processing up
across multiple threads, and therefor multiple CPUs. libvirt recommends
that the number of queues used should match the number of CPUs allocated
for optimal performance.

This feature is enabled by the `BlockMultiQueue` setting under
`Devices`:

```yaml
spec:
  domain:
    devices:
      blockMultiQueue: true
      disks:
      - disk:
          bus: virtio
        name: mydisk
```

**Note:** Due to the way KubeVirt implements CPU allocation,
blockMultiQueue can only be used if a specific CPU allocation is
requested. If a specific number of CPUs hasn't been allocated to a
VirtualMachine, KubeVirt will use all CPU's on the node on a best effort
basis. In that case the amount of CPU allocation to a VM at the host
level could change over time. If blockMultiQueue were to request a
number of queues to match all the CPUs on a node, that could lead to
over-allocation scenarios. To avoid this, KubeVirt enforces that a
specific slice of CPU resources is requested in order to take advantage
of this feature.

#### Example

```yaml
metadata:
  name: testvmi-disk
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
        cpu: 4
    devices:
      blockMultiQueue: true
      disks:
      - name: mypvcdisk
        disk:
          bus: virtio
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

This example will enable Block Multi-Queue for the disk `mypvcdisk` and
allocate 4 queues (to match the number of CPUs requested).

### Disk device cache

KubeVirt supports `none`, `writeback`, and `writethrough` KVM/QEMU cache modes.

-   `none` I/O from the guest is not cached on the host. Use this option
    for guests with large I/O requirements. This option is generally the
    best choice.

-   `writeback` I/O from the guest is cached on the host and written through
    to the physical media when the guest OS issues a flush.

-   `writethrough` I/O from the guest is cached on the host but must be written
    through to the physical medium before the write operation completes.
    
> **Important:** `none` cache mode is set as default if the file system
> supports direct I/O, otherwise, `writethrough` is used.

> **Note:** It is possible to force a specific cache mode, although if
> `none` mode has been chosen and the file system does not support
> direct I/O then started VMI will return an error.

Example: force `writethrough` cache mode

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-pvc
  name: vmi-pvc
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: pvcdisk
        cache: writethrough
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: pvcdisk
    persistentVolumeClaim:
      claimName: disk-alpine
status: {}
```

### Disk sharing

Shareable disks allow multiple VMs to share the same underlying storage. In order to use this feature, special care is required because this could lead to data corruption and the loss of important data. Shareable disks demand either data synchronization at the application level or the use of clustered filesystems. These advanced configurations are not within the scope of this documentation and are use-case specific.

If the `shareable` option is set, it indicates to libvirt/QEMU that the disk is going to be accessed by multiple VMs and not to create a lock for the writes.

In this example, we use Rook Ceph in order to dynamically provisioning the PVC.
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: block-pvc
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Block
  resources:
    requests:
      storage: 1Gi
  storageClassName: rook-ceph-block
```
```bash
$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
block-pvc   Bound    pvc-0a161bb2-57c7-4d97-be96-0a20ff0222e2   1Gi        RWO            rook-ceph-block   51s
```
Then, we can declare 2 VMs and set the `shareable` option to true for the shared disk.
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-block-1
  name: vm-block-1
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-block-1
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
              bus: virtio
            shareable: true
            name: block-disk
        machine:
          type: ""
        resources:
          requests:
            memory: 2G
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
      - name: block-disk
        persistentVolumeClaim:
          claimName: block-pvc
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-block-2
  name: vm-block-2
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-block-2
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: kubevirt.io/vm
                operator: In
                values:
                - vm-block-1
            topologyKey: "kubernetes.io/hostname"
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
              bus: virtio
            shareable: true
            name: block-disk
        machine:
          type: ""
        resources:
          requests:
            memory: 2G
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
      - name: block-disk
        persistentVolumeClaim:
          claimName: block-pvc                                        
```
We can now attempt to write a string from the first guest and then read the string from the second guest to test that the sharing is working.
```bash
$ virtctl console vm-block-1
$ printf "Test awesome shareable disks" | sudo dd  of=/dev/vdc bs=1 count=150 conv=notrunc
28+0 records in
28+0 records out
28 bytes copied, 0.0264182 s, 1.1 kB/s
# Log into the second guest
$ virtctl console vm-block-2
$ sudo dd  if=/dev/vdc bs=1 count=150 conv=notrunc
Test awesome shareable disks150+0 records in
150+0 records out
150 bytes copied, 0.136753 s, 1.1 kB/s
```

If you are using local devices or RWO PVCs, setting the affinity on the VMs that share the storage guarantees they will be scheduled on the same node. In the example, we set the affinity on the second VM using the label used on the first VM. If you are using shared storage with RWX PVCs, then the affinity rule is not necessary as the storage can be attached simultaneously on multiple nodes.

## Sharing Directories with VMs

`Virtiofs` allows to make visible external filesystems to `KubeVirt` VMs.
`Virtiofs` is a shared file system that lets VMs access a directory tree on the host.
Further details can be found at [Official Virtiofs Site](https://virtio-fs.gitlab.io/).

### Non-Privileged and Privileged Sharing Modes

KubeVirt supports two PVC sharing modes: non-privileged and privileged.

The **non-privileged mode** is enabled by default. This mode has the advantage of not requiring any
administrative privileges for creating the VM. However, it has some limitations:

- The virtiofsd daemon (the daemon in charge of sharing the PVC with the VM) will run with the QEMU UID/GID (107),
  and cannot switch between different UIDs/GIDs.
  Therefore, it will only have access to directories and files that UID/GID 107 has permission to.
  Additionally, when creating new files they will always be created with QEMU's UID/GID regardless of the UID/GID of the
  process within the guest.
- Extended attributes are not supported. 
 
To switch to the **privileged mode**, the feature gate **ExperimentalVirtiofsSupport** has to be enabled. Take into account
that this mode requires privileges to run rootful containers. 

### Sharing Persistent Volume Claims
#### Cluster Configuration

We need to create a new VM definition including the `spec.devices.disk.filesystems.virtiofs` and a PVC.
Example:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: testvmi-fs
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
      filesystems:
        - name: virtiofs-disk
          virtiofs: {}
    resources:
      requests:
        memory: 1024Mi
  volumes:
    - name: containerdisk
      containerDisk:
        image: quay.io/containerdisks/fedora:latest
    - cloudInitNoCloud:
        userData: |-
          #cloud-config
          password: fedora
          chpasswd: { expire: False }
      name: cloudinitdisk
    - name: virtiofs-disk
      persistentVolumeClaim:
        claimName: mypvc
```

#### Configuration Inside the VM
The following configuration can be done in using startup script. See [cloudInitNoCloud](#cloudinitnocloud) section for 
more details. 
However, we can do it manually by logging in to the VM and mounting it. 
Here are examples of how to mount it in a linux and windows VMs:

- Linux Example

```bash
$ sudo mkdir -p /mnt/disks/virtio
$ sudo mount -t virtiofs virtiofs-disk /mnt/disks/virtio
```

- Windows Example

  See [this](https://virtio-fs.gitlab.io/howto-windows.html) guide for details on startup steps needed for Windows VMs.

### Sharing Node Directories

It is allowed using [hostpaths](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath).
The following configuration example is shown for illustrative purposes.
However, the [PVCs](#sharing-persistent-volume-claims) method is preferred since using hostpath is generally discouraged for
security reasons.


#### Configuration Inside the Node

To share the directory with the VMs, we need to log in to the node, create the shared directory (if it does not already
exist), and set the proper SELinux context label `container_file_t` to the shared directory.
In this example we are going to share a new directory `/mnt/data` (if the desired directory is an existing one, you can
skip the `mkdir` command):

```shell
$ mkdir /tmp/data
$ sudo chcon -t container_file_t /tmp/data
```

> **Note:** If you are attempting to share an existing directory, you must first check the SELinux context label with the
> command `ls -Z <directory>`. In the case that the label is not present or is not `container_file_t` you need to label 
> it with the `chcon`  command.

#### Cluster Configuration

We need a `StorageClass` which uses the provider `no-provisioner`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: no-provisioner-storage-class
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

To make the shared directory available for VMs, we need to create a PV and a PVC that could be consumed by the VMs:

```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: hostpath
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/tmp/data"
  storageClassName: "no-provisioner-storage-class"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node01
---  
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hostpath-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: "no-provisioner-storage-class"
  resources:
    requests:
      storage: 10Gi
```
> **Note:** Change the `node01` value for the node name where you want the shared directory will be located.


The VM definitions have to request the PVC `hostpath-claim` and attach it as a virtiofs filesystem:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: hostpath-vm
  name: hostpath
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: hostpath
        kubevirt.io/vm: hostpath
    spec:
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          filesystems:
            - name: vm-hostpath
              virtiofs: {}
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              masquerade: {}
          rng: {}
        resources:
          requests:
            memory: 1Gi
      networks:
        - name: default
          pod: {}
      terminationGracePeriodSeconds: 180
      volumes:
        - containerDisk:
            image: quay.io/containerdisks/fedora:latest
          name: containerdisk
        - cloudInitNoCloud:
            userData: |-
              #cloud-config
              chpasswd:
                expire: false
              password: password
              user: fedora
          name: cloudinitdisk
        - name: vm-hostpath
          persistentVolumeClaim:
            claimName: hostpath-claim
```

#### Configuration Inside the VM

We need to log in to the VM and mount the shared directory:

```shell
$ sudo mount -t virtiofs vm-hostpath /mnt
```
