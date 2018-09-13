# Disks and Volumes

Making persistent storage in the cluster \(**volumes**\) accessible to VMs consists of three parts. First, volumes are specified in `spec.volumes`. Second, disks are added to the VM by specifying them in `spec.domain.devices.disks`. Finally, a refererence to the specified volume is added to the disk specification by name.

## Disks

Like all other vmi devices a `spec.domain.devices.disks` element has a mandatory `name`, and furthermore, it has a mandatory `volumeName` entry which references a volume inside `spec.volumes`.

A disk can be made accessible via four different types:

* **disk**
* **cdrom**
* **floppy**
* **lun**

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

* **cloudInitNoCloud**
* **ephemeral**
* **persistentVolumeClaim**
* **registryDisk**
* **emptyDisk**
* **dataVolume**
* **configMap**
* **secret**

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

For KubeVirt to be able to consume the disk present on a PersistentVolume's filesystem, the disk must be named `disk.img` and be placed in the root path of the filesystem. Currently the disk is also required to be in raw format.

**Important:** The `disk.img` image file needs to be owned by the user-id `107` in order to avoid permission issues.

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

### registryDisk

The Registry Disk feature provides the ability to store and distribute VM disks in the container image registry. Registry Disks can be assigned to VMs in the disks section of the VirtualMachineInstance spec.

No network shared storage devices are utilized by Registry Disks. The disks are pulled from the container registry and reside on the local node hosting the VMs that consume the disks.

#### When to use a registryDisk

Registry Disks are ephemeral storage devices that can be assigned to any number of active VirtualMachineInstances. This makes them an ideal tool for users who want to replicate a large number of VM workloads that do not require persistent data. Registry Disks are commonly used in conjunction with VirtualMachineInstanceReplicaSets.

#### When Not to use a registryDisk

Registry Disks are not a good solution for any workload that requires persistent disks across VM restarts, or workloads that require VM live migration support. It is possible Registry Disks may gain live migration support in the future, but at the moment live migrations are incompatible with Registry Disks.

#### registryDisk Workflow Example

Users push VM disks into the container registry using a KubeVirt base image designed to work with the Registry Disk feature. The latest base container image is **kubevirt/registry-disk-v1alpha**.

Using this base image, users can inject a VirtualMachineInstance disk into a container image in a way that is consumable by the KubeVirt runtime. Disks placed into the base container must be placed into the /disk directory. Raw and qcow2 formats are supported. Qcow2 is recommended in order to reduce the container image's size.

Example: Inject a VirtualMachineInstance disk into a container image.

```yaml
cat << END > Dockerfile
FROM kubevirt/registry-disk-v1alpha
ADD fedora25.qcow2 /disk
END

docker build -t vmidisks/fedora25:latest .
```

Example: Upload the RegistryDisk container image to a registry.

```yaml
docker push vmidisks/fedora25:latest
```

Example: Attach the RegistryDisk as an ephemeral disk to a VM.

```yaml
metadata:
  name: testvmi-registrydisk
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
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
        image: vmidisks/fedora25:latest
```

Note that a `registryDisk` is file-based and therefore cannot be attached as a `lun` device to the VM.

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
      - name: registrydisk
        volumeName: registryvolume
        disk:
          bus: virtio
      - name: emptydisk
        volumeName: emptydiskvolume
        disk:
          bus: virtio
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
    - name: emptydiskvolume
      emptyDisk:
        capacity: 2Gi
```

#### When to use an emptyDisk

Ephemeral VMs very often come with read-only root images and limited tmpfs space. In many cases this is not enough to install application dependencies and provide enough disk space for the application data. While this data is not critical and thus can be lost, it is still needed for the application to function properly during its lifetime. This is where an `emptyDisk` can be useful. An emptyDisk is often used and mounted somewhere in `/var/lib` or `/var/run`.

### DataVolume

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

Below is an example of how to enable DataVolume support using the kubevit-config
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

> **Note:** Currently, the ConfigMap update propagation is not supported. After the update, only a pod will be aware of changes, not running VMIs.

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
        name: registrydisk
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
    registryDisk:
      image: registry:5000/kubevirt/fedora-cloud-registry-disk-demo:devel
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

> **Note:** Currently, the Secret update propagation is not supported. After the update, only a pod will be aware of changes, not running VMIs.

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
        name: registrydisk
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
    registryDisk:
      image: registry:5000/kubevirt/fedora-cloud-registry-disk-demo:devel
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
