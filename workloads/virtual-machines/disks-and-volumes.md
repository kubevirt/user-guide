# Disks and Volumes

Making persistent storage in the cluster \(**volumes**\) accessible to VMs consists of three parts. First, volumes are specified in `spec.volumes`. Second, disks are added to the VM by specifying them in `spec.domain.devices.disks`. Finally, a refererence to the specified volume is added to the disk specification by name.

## Disks

Like all other vmi devices a `spec.domain.devices.disks` element has a mandatory `name`, and furthermore, it has a mandatory `volumeName` entry which references a volume inside `spec.volumes`.

A disk can be made accessible via four different types:

* [**lun**](#lun)
* [**disk**](#disk)
* [**cdrom**](#cdrom)
* [**floppy**](#floppy)

All possible configuration options are available in the [Disk API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_disk).

All types, with the exception of **floppy**, allow you to specify the `bus` attribute. The `bus` attribute determines how the disk will be presented to the guest operating system. **floppy** disks don't support the `bus` attribute: they are always attached to the `fdc` bus.

### lun

A `lun` disk will expose the volume as a LUN device to the VM. This allows the VM to execute arbitrary iSCSI command passthrough.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a `lun` device to the VM:

```yaml
metadata:
  name: testvmi-lun
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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

A `disk` disk will expose the volume as an ordinary disk to the VM.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a `disk` device to the VM:

```yaml
metadata:
  name: testvmi-disk
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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
        disk: {}
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

You can set the disk `bus` type, overriding the defaults, which in turn depends on the chipset the VM is configured to use:

```yaml
metadata:
  name: testvmi-disk
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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

A `floppy` disk will expose the volume as a floppy drive to the VM.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a `floppy` device to the VM:

```yaml
metadata:
  name: testvmi-floppy
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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

A `cdrom` disk will expose the volume as a cdrom drive to the VM. It is read-only by default.

A minimal example which attaches a `PersistentVolumeClame` named `mypvc` as a `floppy` device to the VM:

```yaml
metadata:
  name: testvmi-cdrom
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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

* [**cloudInitNoCloud**](#cloudInitNoCloud)
* [**persistentVolumeClaim**](#persistentVolumeClaim)
* [**ephemeral**](#ephemeral)
* [**containerDisk**](#containerDisk)
* [**emptyDisk**](#emptyDisk)
* [**hostDisk**](#hostDisk)
* [**dataVolume**](#dataVolume)
* [**configMap**](#configMap)
* [**secret**](#secret)
* [**serviceAccount**](#serviceAccount)

All possible configuration options are available in the [Volume API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_volume).

### cloudInitNoCloud

Allows attaching `cloudInitNoCloud` data-sources to the VM. If the VM contains a proper cloud-init setup, it will pick up the disk as a user-data source.

A simple example which attaches a `Secret` as a cloud-init `disk` datasource may look like this:

```yaml
metadata:
  name: testvmi-cloudinitnocloud
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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

### persistentVolumeClaim

Allows connecting a `PersistentVolumeClaim` to a VM disk.

Use a PersistentVolumeClain when the VirtualMachineInstance's disk needs to persist after the VM terminates. This allows for the VM's data to remain persistent between restarts.

A `PersistentVolume` can be in "filesystem" or "block" mode:

- Filesystem: For KubeVirt to be able to consume the disk present on a PersistentVolume's filesystem, the disk must be named `disk.img` and be placed in the root path of the filesystem. Currently the disk is also required to be in raw format.
	> **Important:** The `disk.img` image file needs to be owned by the user-id `107` in order to avoid permission issues.

	> **Note:** If the `disk.img` image file has not been created manually before starting a VM then it will be created automatically
	with the `PersistentVolumeClaim` size. Since not every storage provisioner provides volumes with the exact usable amount of space
	as requested (e.g. due to filesystem overhead), KubeVirt tolerates up to 10% less available space. This can be configured with the
	`pvc-tolerate-less-space-up-to-percent` value in the `kubevirt-config` ConfigMap.
- Block: Use a block volume for consuming raw block devices. Note: you need to enable the BlockVolume feature gate.


A simple example which attaches a `PersistentVolumeClaim` as a `disk` may look like this:

```yaml
metadata:
  name: testvmi-pvc
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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

### ephemeral

An ephemeral volume is a local COW \(copy on write\) image that uses a network volume as a read-only backing store. With an ephemeral volume, the network backing store is never mutated. Instead all writes are stored on the ephemeral image which exists on local storage. KubeVirt dynamically generates the ephemeral images associated with a VM when the VM starts, and discards the ephemeral images when the VM stops.

Ephemeral volumes are useful in any scenario where disk persistence is not desired. The COW image is discarded when VM reaches a final state \(e.g., succeeded, failed\).

Currently, only `PersistentVolumeClaim` may be used as a backing store of the ephemeral volume.

Up-to-date information on supported backing stores can be found in the [KubeVirt API](http://www.kubevirt.io/api-reference/master/definitions.html#_v1_ephemeralvolumesource).

```yaml
metadata:
  name: testvmi-ephemeral-pvc
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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
      ephemeral:
        persistentVolumeClaim:
          claimName: mypvc
```

### containerDisk

**containerDisk was originally registryDisk, please update your code when needed.**

The Registry Disk feature provides the ability to store and distribute VM disks in the container image registry. Registry Disks can be assigned to VMs in the disks section of the VirtualMachineInstance spec.

No network shared storage devices are utilized by Registry Disks. The disks are pulled from the container registry and reside on the local node hosting the VMs that consume the disks.

#### When to use a containerDisk

Registry Disks are ephemeral storage devices that can be assigned to any number of active VirtualMachineInstances. This makes them an ideal tool for users who want to replicate a large number of VM workloads that do not require persistent data. Registry Disks are commonly used in conjunction with VirtualMachineInstanceReplicaSets.

#### When Not to use a containerDisk

Registry Disks are not a good solution for any workload that requires persistent disks across VM restarts, or workloads that require VM live migration support. It is possible Registry Disks may gain live migration support in the future, but at the moment live migrations are incompatible with Registry Disks.

#### containerDisk Workflow Example

Users push VM disks into the container registry using a KubeVirt base image designed to work with the Registry Disk feature. The latest base container image is **kubevirt/container-disk-v1alpha**.

Using this base image, users can inject a VirtualMachineInstance disk into a container image in a way that is consumable by the KubeVirt runtime. Disks placed into the base container must be placed into the `/disk` directory. Raw and qcow2 formats are supported. Qcow2 is recommended in order to reduce the container image's size.

Example: Inject a VirtualMachineInstance disk into a container image.

```yaml
cat << END > Dockerfile
FROM kubevirt/container-disk-v1alpha
ADD fedora25.qcow2 /disk
END

docker build -t vmidisks/fedora25:latest .
```

Example: Upload the ContainerDisk container image to a registry.

```yaml
docker push vmidisks/fedora25:latest
```

Example: Attach the ContainerDisk as an ephemeral disk to a VM.

```yaml
metadata:
  name: testvmi-containerdisk
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: containerdisk
        volumeName: registryvolume
        disk: {}
  volumes:
    - name: registryvolume
      containerDisk:
        image: vmidisks/fedora25:latest
```

Note that a `containerDisk` is file-based and therefore cannot be attached as a `lun` device to the VM.

#### Custom disk image path

ContainerDisk also allows to store disk images in any folder, when required. The process is the same as previous.
The main difference is, that in custom location, kubevirt does not scan for any image. It is your responsibility
to provide full path for the disk image. Providing image `path` is optional. When no `path` is provided, kubevirt
searches for disk images in default location: `/disk`.

Example: Build container disk image:

```yaml
cat << END > Dockerfile
FROM kubevirt/container-disk-v1alpha
ADD fedora25.qcow2 /custom-disk-path
END

docker build -t vmidisks/fedora25:latest .
docker push vmidisks/fedora25:latest
```

Create VMI with container disk pointing to the custom location:

```yaml
metadata:
  name: testvmi-containerdisk
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: containerdisk
        volumeName: registryvolume
        disk: {}
  volumes:
    - name: registryvolume
      containerDisk:
        image: vmidisks/fedora25:latest
        path: /custom-disk-path/fedora.qcow2
```

### emptyDisk

An `emptyDisk` works similar to an `emptyDir` in Kubernetes. An extra sparse `qcow2` disk will be allocated and it will live as long as the VM. Thus it will survive guest side VM reboots, but not a VM re-creation. The disk `capacity` needs to be specified.

Example: Boot cirros with an extra `emptyDisk` with a size of `2GiB`:

```yaml
apiVersion: kubevirt.io/v1alpha2
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
        volumeName: registryvolume
        disk:
          bus: virtio
      - name: emptydisk
        volumeName: emptydiskvolume
        disk:
          bus: virtio
  volumes:
    - name: registryvolume
      containerDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
    - name: emptydiskvolume
      emptyDisk:
        capacity: 2Gi
```

#### When to use an emptyDisk

Ephemeral VMs very often come with read-only root images and limited tmpfs space. In many cases this is not enough to install application dependencies and provide enough disk space for the application data. While this data is not critical and thus can be lost, it is still needed for the application to function properly during its lifetime. This is where an `emptyDisk` can be useful. An emptyDisk is often used and mounted somewhere in `/var/lib` or `/var/run`.

### hostDisk

A ```hostDisk``` volume type provides the ability to create or use a disk image located somewhere on a node.
It works similar to a ```hostPath``` in Kubernetes and provides two usage types:

* ```DiskOrCreate``` if a disk image does not exist at a given location then create one
* ```Disk``` a disk image must exist at a given location

Example: Create a 1Gi disk image located at /data/disk.img and attach it to a VM.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        volumeName: hostdiskvolume
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
    name: hostdiskvolume
status: {}
```

### dataVolume

DataVolumes are a way to automate importing virtual machine disks onto pvcs
during the virtual machine's launch flow. Without using a DataVolume, users
have to prepare a pvc with a disk image before assigning it to a VM or VMI
manifest. With a DataVolume, both the pvc creation and import is automated on
behalf of the user.

#### DataVolume VM Behavior

DataVolumes can be defined in the VM spec directly by adding the DataVolumes to
the dataVolumeTemplates list. Below is an example.

```
apiVersion: kubevirt.io/v1alpha2
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
            volumeName: datavolumevolume1
        resources:
          requests:
            memory: 64M
      volumes:
      - dataVolume:
          name: alpine-dv
        name: datavolumevolume1
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
          url: http://cdi-http-import-server.kube-system/images/alpine.iso
```

You can see the DataVolume defined in the dataVolumeTemplates section has two
parts. The **source** and **pvc**

The **source** part declares that there is a disk image living on an http server
that we want to use as a volume for this VM. The **pvc** part declares the spec
that should be used to create the pvc that hosts the **source** data.

When this VM manifest is posted to the cluster, as part of the launch flow a
pvc will be created using the spec provided and the source data will be
automatically imported into that pvc before the VM starts. When the VM is
deleted, the storage provisioned by the DataVolume will automatically be
deleted as well.

#### DataVolume VMI Behavior

For a VMI object, DataVolumes can be referenced as a volume source for the VMI.
When this is done, it is expected that the referenced DataVolume exists in
the cluster. The VMI will consume the DataVolume, but the DataVolume's
life-cycle will not be tied to the VMI.

Below is an example of a DataVolume being referenced by a VMI. It is expected
that the DataVolume *alpine-datavolume* was created prior to posting the VMI
manifest to the cluster. It is okay to post the VMI manifest to the cluster
while the DataVolume is still having data imported. KubeVirt knows not to start
the VMI until all referenced DataVolumes have finished their clone and import
phases.


```
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        volumeName: volume1
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: volume1
    dataVolume:
      name: alpine-datavolume
```

#### Enabling DataVolume support.

A DataVolume is a custom resource provided by the Containerized Data Importer
(CDI) project. KubeVirt integrates with CDI in order to provide users a workflow
for dynamically creating pvcs and importing data into those pvcs.

In order to take advantage of the DataVolume volume source on a VM or VMI, the
**DataVolumes** feature gate must be enabled in the **kubevirt-config** config
map before KubeVirt is installed. CDI must also be installed.

**Installing CDI**

Go to the [CDI release page](https://github.com/kubevirt/containerized-data-importer/releases)

Pick the latest stable release and post the corresponding
cdi-controller-deployment.yaml manifest to your cluster.

**Enabling the DataVolumes feature gate**

Below is an example of how to enable DataVolume support using the kubevirt-config
config map.

```
cat <<EOF | _kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kube-system
  labels:
    kubevirt.io: ""
data:
  feature-gates: "DataVolumes"

```

This config map assumes KubeVirt will be installed in the kube-system namespace.
Change the namespace to suite your installation.

First post the configmap above, then install KubeVirt. At that point DataVolume
integration will be enabled.

### configMap

A `configMap` is a reference to a [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) in Kubernetes. An extra `iso` disk will be allocated which has to be mounted on a VM. To mount the `configMap` users can use `cloudInit` and the disks serial number. The `name` needs to be set for a reference to the created kubernetes `ConfigMap`.

> **Note:** Currently, ConfigMap update propagation is not supported. If a ConfigMap is updated, only a pod will be aware of changes, not running VMIs.

> **Note:** Due to a Kubernetes CRD [issue](https://github.com/kubernetes/kubernetes/issues/68466), you cannot control the paths within the volume where ConfigMap keys are projected.

Example: Attach the `configMap` to a VM and use `cloudInit` to mount the `iso` disk:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        volumeName: registryvolume
      - disk:
          bus: virtio
        name: cloudinitdisk
        volumeName: cloudinitvolume
      - disk: {}
        name: app-config-disk
        volumeName: configmap-volume
        # set serial
        serial: CVLY623300HK240D
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: registryvolume
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
        bootcmd:
          # mount the ConfigMap
          - "mkdir /mnt/app-config"
          - "mount /dev/$(lsblk --nodeps -no name,serial | grep CVLY623300HK240D | cut -f1 -d' ') /mnt/app-config"
    name: cloudinitvolume
  - configMap:
      name: app-config
    name: configmap-volume
status: {}
```

### secret

A `secret` is a reference to a [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) in Kubernetes. An extra `iso` disk will be allocated which has to be mounted on a VM. To mount the `secret` users can use `cloudInit` and the disks serial number. The `secretName` needs to be set for a reference to the created kubernetes `Secret`.

> **Note:** Currently, Secret update propagation is not supported. If a Secret is updated, only a pod will be aware of changes, not running VMIs.

> **Note:** Due to a Kubernetes CRD [issue](https://github.com/kubernetes/kubernetes/issues/68466), you cannot control the paths within the volume where Secret keys are projected.

Example: Attach the `secret` to a VM and use `cloudInit` to mount the `iso` disk:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        volumeName: registryvolume
      - disk:
          bus: virtio
        name: cloudinitdisk
        volumeName: cloudinitvolume
      - disk: {}
        name: app-secret-disk
        volumeName: secret-volume
        # set serial
        serial: D23YZ9W6WA5DJ487
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: registryvolume
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
        bootcmd:
          # mount the Secret
          - "mkdir /mnt/app-secret"
          - "mount /dev/$(lsblk --nodeps -no name,serial | grep D23YZ9W6WA5DJ487 | cut -f1 -d' ') /mnt/app-secret"
    name: cloudinitvolume
  - secret:
      secretName: app-secret
    name: secret-volume
status: {}
```

### serviceAccount

A `serviceAccount` volume references a Kubernetes [`ServiceAccount`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).
A new `iso` disk will be allocated with the content of the service account (`namespace`, `token` and `ca.crt`), which needs to be mounted in the VM. For automatic mounting,
see the `configMap` and `secret` examples above.

Example:

```yaml
apiVersion: kubevirt.io/v1alpha2
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
        volumeName: registryvolume
      - disk:
          bus: virtio
        name: serviceaccountdisk
        volumeName: serviceaccountvolume
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: registryvolume
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
  - name: serviceaccountvolume
    serviceAccount:
      serviceAccountName: default
```

## High Performance Features

### IOThreads

Libvirt has the ability to use IOThreads for dedicated disk access (for supported devices). These are dedicated event loop threads that perform block I/O requests and improve scalability on SMP systems. KubeVirt exposes this libvirt feature through the `ioThreadsPolicy` setting. Additionaly, each `Disk` device exposes a `dedicatedIOThread` setting. This is a boolean that indicates the specified disk should be allocated an exclusive IOThread that will never be shared with other disks.

Currently valid policies are `shared` and `auto`. If `ioThreadsPolicy` is omitted entirely, use of IOThreads will be disabled. However, if any disk requests a dedicated IOThread, `ioThreadsPolicy` will be enabled and default to `shared`.

#### Shared

An `ioThreadsPolicy` of `shared` indicates that KubeVirt should use one thread that will be shared by all disk devices. This policy stems from the fact that large numbers of IOThreads is generally not useful as additional context switching is incurred for each thread.

Disks with `dedicatedIOThread` set to `true` will not use the shared thread, but will instead be allocated an exclusive thread. This is generally useful if a specific Disk is expected to have heavy I/O traffic, e.g. a database spindle.

#### Auto

`auto` IOThreads indicates that KubeVirt should use a pool of IOThreads and allocate disks to IOThreads in a round-robin fashion. The pool size is generally limited to twice the number of VCPU's allocated to the VM. This essentially attempts to dedicate disks to separate IOThreads, but only up to a reasonable limit. This would come in to play for systems with a large number of disks and a smaller number of CPU's for instance.

As a caveat to the size of the IOThread pool, disks with `dedicatedIOThread` will always be guaranteed their own thread. This effectively diminishes the upper limit of the number of threads allocated to the rest of the disks. For example, a VM with 2 CPUs would normally use 4 IOThreads for all disks. However if one disk had `dedicatedIOThread` set to true, then KubeVirt would only use 3 IOThreads for the shared pool.

There is always guaranteed to be at least one thread for disks that will use the shared IOThreads pool. Thus if a sufficiently large number of disks have dedicated IOThreads assigned, `auto` and `shared` policies would essentially result in the same layout.

#### IOThreads with Dedicated (pinned) CPUs
When guest's vCPUs are pinned to a host's physical CPUs, it is also best to pin the IOThreads to specific CPUs to prevent these from floating between the CPUs.
KubeVirt will automatically calculate and pin each IOThread to a CPU or a set of CPUs, depending on the ration between them.
In case there are more IOThreads than CPUs, each IOThread will be pinned to a CPU, in a round-robin fashion.
Otherwise, when there are fewer IOThreads than CPU, each IOThread will be pinned to a set of CPUs.

### Examples

#### Shared IOThreads

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        name: mydisk
        volumeName: myvolume
      - disk:
          bus: virtio
        name: emptydisk
        volumeName: emptydiskvolume
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk2
        volumeName: emptydiskvolume2
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk3
        volumeName: emptydiskvolume3
      - disk:
          bus: virtio
        name: emptydisk4
        volumeName: emptydiskvolume4
      - disk:
          bus: virtio
        name: emptydisk5
        volumeName: emptydiskvolume5
      - disk:
          bus: virtio
        name: emptydisk6
        volumeName: emptydiskvolume6
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  volumes:
  - name: mypvc
    persistentVolumeClaim:
      claimName: mypvc
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume2
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume3
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume4
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume5
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume6
```

In this example, emptydisk and emptydisk2 both request a dedicated IOThread. mydisk, and emptydisk 3 through 6 will all shared one IOThread.

```
mypvc:        1
emptydisk:    2
emptydisk2:   3
emptydisk3:   1
emptydisk4:   1
emptydisk5:   1
emptydisk6:   1
```

#### Auto IOThreads

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        volumeName: mypvc
      - disk:
          bus: virtio
        name: emptydisk
        volumeName: emptydiskvolume
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk2
        volumeName: emptydiskvolume2
        dedicatedIOThread: true
      - disk:
          bus: virtio
        name: emptydisk3
        volumeName: emptydiskvolume3
      - disk:
          bus: virtio
        name: emptydisk4
        volumeName: emptydiskvolume4
      - disk:
          bus: virtio
        name: emptydisk5
        volumeName: emptydiskvolume5
      - disk:
          bus: virtio
        name: emptydisk6
        volumeName: emptydiskvolume6
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  volumes:
  - name: mypvc
    persistentVolumeClaim:
      claimName: mypvc
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume2
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume3
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume4
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume5
  - emptyDisk:
      capacity: 1Gi
    name: emptydiskvolume6
```

This VM is identical to the first, except it requests auto IOThreads. `emptydisk` and `emptydisk2` will still be allocated individual IOThreads, but the rest of the disks will be split across 2 separate iothreads (twice the number of CPU cores is 4).

Disks will be assigned to IOThreads like this:

```
mypvc:        1
emptydisk:    3
emptydisk2:   4
emptydisk3:   2
emptydisk4:   1
emptydisk5:   2
emptydisk6:   1
```

### Virtio Block Multi-Queue

Block Multi-Queue is a framework for the Linux block layer that maps Device I/O
queries to multiple queues. This splits I/O processing up across multiple
threads, and therefor multiple CPUs. libvirt recommends that the number of
queues used should match the number of CPUs allocated for optimal performance.

This feature is enabled by the `BlockMultiQueue` setting under `Devices`:

```yaml
spec:
  domain:
    devices:
      blockMultiQueue: true
      disks:
      - disk:
          bus: virtio
        name: mydisk
        volumeName: mypvc
```

**Note:** Due to the way KubeVirt implements CPU allocation, blockMultiQueue
can only be used if a specific CPU allocation is requested. If a specific
number of CPUs hasn't been allocated to a VirtualMachine, KubeVirt will use all
CPU's on the node on a best effort basis. In that case the amount of CPU
allocation to a VM at the host level could change over time. If blockMultiQueue
were to request a number of queues to match all the CPUs on a node, that could
lead to over-allocation scenarios. To avoid this, KubeVirt enforces that a
specific slice of CPU resources is requested in order to take advantage of this
feature.

#### Example


```yaml
metadata:
  name: testvmi-disk
apiVersion: kubevirt.io/v1alpha2
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
        volumeName: mypvc
        disk:
          bus: virtio
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

This example will enable Block Multi-Queue for the disk `mypvcdisk` and
allocate 4 queues (to match the number of CPUs requested).

### Disk device cache

KubeVirt supports `none` and `writethrough` KVM/QEMU cache modes.

* `none` I/O from the guest is not cached on the host. Use this option for guests with large I/O requirements. This option is generally the best choice.
* `writethrough` I/O from the guest is cached on the host but written through to the physical medium.

> **Important:** `none` cache mode is set as default if the file system supports direct I/O, otherwise, `writethrough` is used.

> **Note:** It is possible to force a specific cache mode, although if `none` mode has been chosen and the file system does not support direct I/O then started VMI will return an error.

Example: force `writethrough` cache mode

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
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
        volumeName: pvcvolume
        cache: writethrough
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: pvcvolume
    persistentVolumeClaim:
      claimName: disk-alpine
status: {}
```
