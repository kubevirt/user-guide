# Virtual Machine Creation

## Overview

The KubeVirt projects provides a set of
[templates](https://docs.okd.io/latest/dev_guide/templates.html) to
create VMs to handle common usage scenarios. These templates provide a
combination of some key factors that could be further customized and
processed to have a Virtual Machine object.

The key factors which define a template are - Workload Most Virtual
Machine should be **server** or **desktop** to have maximum flexibility;
the **highperformance** workload trades some of this flexibility to
provide better performances. - Guest Operating System (OS) This allow to
ensure that the emulated hardware is compatible with the guest OS.
Furthermore, it allows to maximize the stability of the VM, and allows
performance optimizations. - Size (flavor) Defines the amount of
resources (CPU, memory) to allocate to the VM.

## WebUI

Kubevirt project has [the official UI](https://github.com/kubevirt/web-ui).
This UI supports creation VM using templates and templates
features - flavors and workload profiles. To create VM from template, choose
WorkLoads in the left panel >> press to the "Create Virtual Machine"
blue button >> choose "Create from Wizzard". Next, you have to see
"Create Virtual Machine" window

## Common-templates

There is the [common-templates
subproject](https://github.com/kubevirt/common-templates/)
subproject. It provides official prepaired and useful templates.
[Additional doc available](templates/common-templates.md).
You can also create templates by hand. You can find an example below, in
the "Example template" section.

## Example template

In order to create a virtual machine via OpenShift CLI, you need to
provide a template defining the corresponding object and its metadata.

**NOTE** Only `VirtualMachine` object is currently supported.

Here is an example template that defines an instance of the
`VirtualMachine` object:

```
apiVersion: v1
kind: Template
metadata:
  annotations:
    description: OCP KubeVirt Fedora 27 VM template
    iconClass: icon-fedora
    tags: kubevirt,ocp,template,linux,virtualmachine
  labels:
    kubevirt.io/os: fedora27
    miq.github.io/kubevirt-is-vm-template: "true"
  name: vm-template-fedora
objects:
- apiVersion: kubevirt.io/v1alpha3
  kind: VirtualMachine
  metadata:
    labels:
      kubevirt-vm: vm-${NAME}
      kubevirt.io/os: fedora27
    name: ${NAME}
  spec:
    running: false
    template:
      metadata:
        creationTimestamp: null
        labels:
          kubevirt-vm: vm-${NAME}
          kubevirt.io/os: fedora27
      spec:
        domain:
          cpu:
            cores: ${{CPU_CORES}}
          devices:
            disks:
              - name: disk0
        volumes:
          - name: disk0
            persistentVolumeClaim:
              claimName: myroot
            - disk:
                bus: virtio
              name: registrydisk
              volumeName: registryvolume
            - disk:
                bus: virtio
              name: cloudinitdisk
              volumeName: cloudinitvolume
          machine:
            type: ""
          resources:
            requests:
              memory: ${MEMORY}
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
          name: cloudinitvolume
  status: {}
parameters:
- description: Name for the new VM
  name: NAME
- description: Amount of memory
  name: MEMORY
  value: 4096Mi
- description: Amount of cores
  name: CPU_CORES
  value: "4"
```
Note that the template above defines free parameters (`NAME` and
`CPU_CORES`) and the `NAME` parameter does not have specified default
value.

An OpenShift template has to be converted into the JSON file via
`oc process` command, that also allows you to set the template
parameters.

A complete example can be found in the [KubeVirt
repository](https://github.com/kubevirt/kubevirt/blob/master/cluster/examples/vm-template-fedora.yaml).

!> You need to be logged in by `oc login` command.

```
$ oc process -f cluster/vmi-template-fedora.yaml\
    -p NAME=testvmi \
    -p CPU_CORES=2
{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
```

The JSON file is usually applied directly by piping the processed output
to `oc create` command.

```
$ oc process -f cluster/examples/vm-template-fedora.yaml \
    -p NAME=testvm \
    -p CPU_CORES=2 \
    | oc create -f -
virtualmachine.kubevirt.io/testvm created
```

The command above results in creating a Kubernetes object according to
the specification given by the template \\(in this example it is an
instance of the VirtualMachine object\\).

It’s possible to get list of available parameters using the following
command:

```
$ oc process -f cluster/examples/vmi-template-fedora.yaml --parameters
NAME                DESCRIPTION           GENERATOR           VALUE
NAME                Name for the new VM                       
MEMORY              Amount of memory                          4096Mi
CPU_CORES           Amount of cores                           4
```

## Starting virtual machine from the created object

The created object is now a regular VirtualMachine object and from now
it can be controlled by accessing Kubernetes API resources. The
preferred way how to do this from within the OpenShift environment is to
use `oc patch` command.

```
$ oc patch virtualmachine testvm --type merge -p '{"spec":{"running":true}}'
virtualmachine.kubevirt.io/testvm patched
```

Do not forget about virtctl tool. Using it in the real cases instead of
using kubernetes API can be more convinient. Example:

```
$ virtctl start testvm
VM testvm was scheduled to start
```

As soon as VM starts, kubernates creates new type of object -
VirtualMachineInstance. It has similar name to VirtualMachine. Example
(not full output, it’s too big):

```
$ kubectl describe vm testvm
name:         testvm
Namespace:    myproject
Labels:       kubevirt-vm=vm-testvm
              kubevirt.io/os=fedora27
Annotations:  <none>
API Version:  kubevirt.io/v1alpha2
Kind:         VirtualMachine
```

## Cloud-init script and parameters

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, supports
[cloud-init scripts](https://cloudinit.readthedocs.io/en/latest/)

## Using registry images

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, supports
creating VM’s disks from registry. ContainerDisk is a special type volume
which supports downloading images from user-defined registry server.

## **Hack** - use pre-downloaded image

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, can use
pre-downloaded VM image, which can be a useful feature especially in the
debug/development/testing cases. No special parameters required in the
VM template or VM/VMI yaml config. The main idea is to create Kubernetes
PersistentVolume and PersistentVolumeClaim corresponding to existing
image in the file system. Example:

```
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: mypv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10G
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/sda1/images/testvm"
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mypvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10G

```

## Cloud-init script and parameters

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, supports
[cloud-init scripts](https://cloudinit.readthedocs.io/en/latest/)

## Using Container Images

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, supports
creating VM’s disks from registry. ContainerDisk is a special type volume
which supports downloading images from user-defined registry server.

## **Hack** - use pre-downloaded image

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, can use
pre-downloaded VM image, which can be a useful feature especially in the
debug/development/testing cases. No special parameters required in the
VM template or VM/VMI yaml config. The main idea is to create Kubernetes
PersistentVolume and PersistentVolumeClaim corresponding to existing
image in the file system. Example:

```
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: mypv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10G
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/sda1/images/testvm"
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mypvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10G

```

If you create this PV/PVC, then you have to put VM image in the file
path

```bash
/mnt/sda1/images/testvm/disk.img
```
Avaible in the each OpenShift/Kubevirt compute nodes.

## Additional information You can follow [Virtual Machine Lifecycle
Guide](usage/life-cycle.md) for further reference.
