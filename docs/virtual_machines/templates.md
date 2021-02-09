# Templates

!&gt; This only works on OpenShift so far (See [Installation
Guide](/installation/README) for more information on how to deploy
KubeVirt on OpenShift).

By deploying KubeVirt on top of OpenShift the user can benefit from the
[OpenShift
Template](https://docs.openshift.org/latest/dev_guide/templates.html)
functionality.

## Virtual machine templates

### What is a virtual machine template?

The KubeVirt projects provides a set of
[templates](https://docs.okd.io/latest/dev_guide/templates.html) to
create VMs to handle common usage scenarios. These templates provide a
combination of some key factors that could be further customized and
processed to have a Virtual Machine object. The key factors which define
a template are

-   Workload Most Virtual Machine should be *generic* to have maximum
    flexibility; the *highperformance* workload trades some of this
    flexibility to provide better performances.

-   Guest Operating System (OS) This allow to ensure that the emulated
    hardware is compatible with the guest OS. Furthermore, it allows to
    maximize the stability of the VM, and allows performance
    optimizations.

-   Size (flavor) Defines the amount of resources (CPU, memory) to
    allocate to the VM.

More documentation is available in the [common templates
subproject](https://github.com/kubevirt/common-templates)

### Accessing the virtual machine templates

If you installed KubeVirt using a supported method you should find the
common templates preinstalled in the cluster. Should you want to upgrade
the templates, or install them from scratch, you can use one of the
[supported
releases](https://github.com/kubevirt/common-templates/releases)

To install the templates:

    $ export VERSION="v0.3.1"
    $ oc create -f https://github.com/kubevirt/common-templates/releases/download/$VERSION/common-templates-$VERSION.yaml

#### Editable fields

You can edit the fields of the templates which define the amount of
resources which the VMs will receive.

Each template can list a different set of fields that are to be
considered editable. The fields are used as hints for the user
interface, and also for other components in the cluster.

The editable fields are taken from annotations in the template. Here is
a snippet presenting a couple of most commonly found editable fields:

    metadata:
      annotations:
        template.kubevirt.io/editable: |
          /objects[0].spec.template.spec.domain.cpu.sockets
          /objects[0].spec.template.spec.domain.cpu.cores
          /objects[0].spec.template.spec.domain.cpu.threads
          /objects[0].spec.template.spec.domain.resources.requests.memory

Each entry in the editable field list must be a
[jsonpath](https://kubernetes.io/docs/reference/kubectl/jsonpath/). The
jsonpath root is the objects: element of the template. The actually
editable field is the last entry (the “leaf”) of the path. For example,
the following minimal snippet highlights the fields which you can edit:

    objects:
      spec:
        template:
          spec:
            domain:
              cpu:
                sockets:
                  VALUE # this is editable
                cores:
                  VALUE # this is editable
                threads:
                  VALUE # this is editable
              resources:
                requests:
                  memory:
                    VALUE # this is editable

### Relationship between templates and VMs

Once
[processed](https://docs.openshift.com/enterprise/3.0/dev_guide/templates.html#creating-from-templates-using-the-cli),
the templates produce VM objects to be used in the cluster. The VMs
produced from templates will have a `vm.kubevirt.io/template` label,
whose value will be the name of the parent template, for example
`fedora-desktop-medium`:

      metadata:
        labels:
          vm.kubevirt.io/template: fedora-desktop-medium

In addition, these VMs can include an optional label
`vm.kubevirt.io/template-namespace`, whose value will be the namespace
of the parent template, for example:

      metadata:
        labels:
          vm.kubevirt.io/template-namespace: openshift

If this label is not defined, the template is expected to belong to the
same namespace as the VM.

This make it possible to query for all the VMs built from any template.

Example:

    oc process -o yaml rhel7-server-tiny PVCNAME=mydisk NAME=rheltinyvm

And the output:

    apiversion: v1
    items:
    - apiVersion: kubevirt.io/v1alpha3
      kind: VirtualMachine
      metadata:
        labels:
          vm.kubevirt.io/template: rhel7-server-tiny
        name: rheltinyvm
        osinfoname: rhel7.0
      spec:
        running: false
        template:
          spec:
            domain:
              cpu:
                sockets: 1
                cores: 1
                threads: 1
              devices:
                disks:
                - disk:
                    bus: virtio
                  name: rootdisk
                rng: {}
              resources:
                requests:
                  memory: 1G
            terminationGracePeriodSeconds: 0
            volumes:
            - name: rootdisk
              persistentVolumeClaim:
                claimName: mydisk
            - cloudInitNoCloud:
                userData: |-
                  #cloud-config
                  password: redhat
                  chpasswd: { expire: False }
              name: cloudinitdisk
    kind: List
    metadata: {}

You can add the VM from the template to the cluster in one go

    oc process rhel7-server-tiny PVCNAME=mydisk NAME=rheltinyvm | oc apply -f -

Please note that, after the generation step, VM objects and template
objects have no relationship with each other besides the aforementioned
label (e.g. changes in templates do not automatically affect VMs, or
vice versa).

### common template customization

The templates provided by the kubevirt project provide a set of
conventions and annotations that augment the basic feature of the
[openshift
templates](https://docs.okd.io/latest/dev_guide/templates.html). You can
customize your kubevirt-provided templates editing these annotations, or
you can add them to your existing templates to make them consumable by
the kubevirt services.

Here’s a description of the kubevirt annotations. Unless otherwise
specified, the following keys are meant to be top-level entries of the
template metadata, like

    apiVersion: v1
    kind: Template
    metadata:
      name: windows-10
      annotations:
        openshift.io/display-name: "Generic demo template"

All the following annotations are prefixed with
`defaults.template.kubevirt.io`, which is omitted below for brevity. So
the actual annotations you should use will look like

    apiVersion: v1
    kind: Template
    metadata:
      name: windows-10
      annotations:
        defaults.template.kubevirt.io/disk: default-disk
        defaults.template.kubevirt.io/volume: default-volume
        defaults.template.kubevirt.io/nic: default-nic
        defaults.template.kubevirt.io/network: default-network

Unless otherwise specified, all annotations are meant to be safe
defaults, both for performance and compatibility, and hints for the
CNV-aware UI and tooling.

#### disk

See the section `references` below.

Example:

    apiVersion: v1
    kind: Template
    metadata:
      name: Linux
      annotations:
        defaults.template.kubevirt.io/disk: rhel-disk

#### nic

See the section `references` below.

Example:

    apiVersion: v1
    kind: Template
    metadata:
      name: Windows
      annotations:
        defaults.template.kubevirt.io/nic: my-nic

#### volume

See the section `references` below.

Example:

    apiVersion: v1
    kind: Template
    metadata:
      name: Linux
      annotations:
        defaults.template.kubevirt.io/volume: custom-volume

#### network

See the section `references` below.

Example:

    apiVersion: v1
    kind: Template
    metadata:
      name: Linux
      annotations:
        defaults.template.kubevirt.io/network: fast-net

#### references

The default values for network, nic, volume, disk are meant to be the
**name** of a section later in the document that the UI will find and
consume to find the default values for the corresponding types. For
example, considering the annotation
`defaults.template.kubevirt.io/disk: my-disk`: we assume that later in
the document it exists an element called `my-disk` that the UI can use
to find the data it needs. The names actually don’t matter as long as
they are legal for kubernetes and consistent with the content of the
document.

#### complete example

`demo-template.yaml`

```
apiversion: v1
items:
- apiversion: kubevirt.io/v1alpha3
  kind: virtualmachine
  metadata:
    labels:
      vm.kubevirt.io/template: rhel7-generic-tiny
    name: rheltinyvm
    osinfoname: rhel7.0
    defaults.template.kubevirt.io/disk: rhel-default-disk
    defaults.template.kubevirt.io/nic: rhel-default-net
  spec:
    running: false
    template:
      spec:
        domain:
          cpu:
            sockets: 1
            cores: 1
            threads: 1
          devices:
            rng: {}
          resources:
            requests:
              memory: 1g
        terminationgraceperiodseconds: 0
        volumes:
        - containerDisk:
          image: registry:5000/kubevirt/cirros-container-disk-demo:devel
          name: rhel-default-disk
        networks:
        - genie:
          networkName: flannel
          name: rhel-default-net
kind: list
metadata: {}
```

once processed becomes:
`demo-vm.yaml`

```
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    vm.kubevirt.io/template: rhel7-generic-tiny
  name: rheltinyvm
  osinfoname: rhel7.0
spec:
  running: false
  template:
    spec:
      domain:
        cpu:
          sockets: 1
          cores: 1
          threads: 1
        resources:
          requests:
            memory: 1g
        devices:
          rng: {}
          disks:
          - disk:
            name: rhel-default-disk
        interfaces:
        - bridge: {}
          name: rhel-default-nic
      terminationgraceperiodseconds: 0
      volumes:
      - containerDisk:
          image: registry:5000/kubevirt/cirros-container-disk-demo:devel
        name: containerdisk
      networks:
      - genie:
          networkName: flannel
        name: rhel-default-nic
```

## Virtual machine creation

### Overview

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

### WebUI

Kubevirt project has [the official UI](https://github.com/kubevirt/web-ui).
This UI supports creation VM using templates and templates
features - flavors and workload profiles. To create VM from template, choose
WorkLoads in the left panel >> press to the "Create Virtual Machine"
blue button >> choose "Create from wizard". Next, you have to see
"Create Virtual Machine" window

### Common-templates

There is the [common-templates
subproject](https://github.com/kubevirt/common-templates/)
subproject. It provides official prepared and useful templates.
[Additional doc available](templates/common-templates.md).
You can also create templates by hand. You can find an example below, in
the "Example template" section.

### Example template

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
using kubernetes API can be more convenient. Example:

```
$ virtctl start testvm
VM testvm was scheduled to start
```

As soon as VM starts, Kubernetes creates new type of object -
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

## Using container images

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
Available in the each OpenShift/Kubevirt compute nodes.

## Additional information
You can follow [Virtual Machine Lifecycle Guide](usage/life-cycle.md) for further reference.
