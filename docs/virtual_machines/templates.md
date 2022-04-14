# Templates

!!! Note
    By deploying KubeVirt on top of OpenShift the user can benefit from the [OpenShift Template](https://docs.openshift.com/container-platform/4.10/virt/vm_templates/virt-creating-vm-template.html) functionality.

## Virtual machine templates

### What is a virtual machine template?

The KubeVirt projects provides a set of
[templates](https://docs.okd.io/latest/openshift_images/using-templates.html) to
create VMs to handle common usage scenarios. These templates provide a
combination of some key factors that could be further customized and
processed to have a Virtual Machine object. The key factors which define
a template are

-   Workload Most Virtual Machine should be **server** or **desktop** to have maximum
    flexibility; the **highperformance** workload trades some of this
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

```console
    $ export VERSION=$(curl -s https://api.github.com/repos/kubevirt/common-templates/releases | grep tag_name | grep -v -- '-rc' | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
    $ oc create -f https://github.com/kubevirt/common-templates/releases/download/$VERSION/common-templates-$VERSION.yaml
```

#### Editable fields

You can edit the fields of the templates which define the amount of
resources which the VMs will receive.

Each template can list a different set of fields that are to be
considered editable. The fields are used as hints for the user
interface, and also for other components in the cluster.

The editable fields are taken from annotations in the template. Here is
a snippet presenting a couple of most commonly found editable fields:

```console
    metadata:
      annotations:
        template.kubevirt.io/editable: |
          /objects[0].spec.template.spec.domain.cpu.sockets
          /objects[0].spec.template.spec.domain.cpu.cores
          /objects[0].spec.template.spec.domain.cpu.threads
          /objects[0].spec.template.spec.domain.resources.requests.memory
```

Each entry in the editable field list must be a
[jsonpath](https://kubernetes.io/docs/reference/kubectl/jsonpath/). The
jsonpath root is the objects: element of the template. The actually
editable field is the last entry (the "leaf") of the path. For example,
the following minimal snippet highlights the fields which you can edit:

```console
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
```

### Relationship between templates and VMs

Once processed the templates produce VM objects to be used in the cluster. The VMs
produced from templates will have a `vm.kubevirt.io/template` label,
whose value will be the name of the parent template, for example
`fedora-desktop-medium`:

```console
      metadata:
        labels:
          vm.kubevirt.io/template: fedora-desktop-medium
```

In addition, these VMs can include an optional label
`vm.kubevirt.io/template-namespace`, whose value will be the namespace
of the parent template, for example:

```console
      metadata:
        labels:
          vm.kubevirt.io/template-namespace: openshift
```

If this label is not defined, the template is expected to belong to the
same namespace as the VM.

This make it possible to query for all the VMs built from any template.

Example:

```console
    oc process -o yaml -f dist/templates/rhel8-server-tiny.yaml NAME=rheltinyvm SRC_PVC_NAME=rhel SRC_PVC_NAMESPACE=kubevirt
```

And the output:

```console
    apiVersion: v1
    items:
    - apiVersion: kubevirt.io/v1alpha3
      kind: VirtualMachine
      metadata:
        annotations:
          vm.kubevirt.io/flavor: tiny
          vm.kubevirt.io/os: rhel8
          vm.kubevirt.io/validations: |
            [
              {
                "name": "minimal-required-memory",
                "path": "jsonpath::.spec.domain.resources.requests.memory",
                "rule": "integer",
                "message": "This VM requires more memory.",
                "min": 1610612736
              }
            ]
          vm.kubevirt.io/workload: server
        labels:
          app: rheltinyvm
          vm.kubevirt.io/template: rhel8-server-tiny
          vm.kubevirt.io/template.revision: "45"
          vm.kubevirt.io/template.version: 0.11.3
        name: rheltinyvm
      spec:
        dataVolumeTemplates:
        - apiVersion: cdi.kubevirt.io/v1beta1
          kind: DataVolume
          metadata:
            name: rheltinyvm
          spec:
            pvc:
              accessModes:
              - ReadWriteMany
              resources:
                requests:
                  storage: 30Gi
            source:
              pvc:
                name: rhel
                namespace: kubevirt
        running: false
        template:
          metadata:
            labels:
              kubevirt.io/domain: rheltinyvm
              kubevirt.io/size: tiny
          spec:
            domain:
              cpu:
                cores: 1
                sockets: 1
                threads: 1
              devices:
                disks:
                - disk:
                    bus: virtio
                  name: rheltinyvm
                - disk:
                    bus: virtio
                  name: cloudinitdisk
                interfaces:
                - masquerade: {}
                  name: default
                networkInterfaceMultiqueue: true
                rng: {}
              resources:
                requests:
                  memory: 1.5Gi
            networks:
            - name: default
              pod: {}
            terminationGracePeriodSeconds: 180
            volumes:
            - dataVolume:
                name: rheltinyvm
              name: rheltinyvm
            - cloudInitNoCloud:
                userData: |-
                  #cloud-config
                  user: cloud-user
                  password: lymp-fda4-m1cv
                  chpasswd: { expire: False }
              name: cloudinitdisk
    kind: List
    metadata: {}
```

You can add the VM from the template to the cluster in one go

```console
    oc process rhel8-server-tiny NAME=rheltinyvm SRC_PVC_NAME=rhel SRC_PVC_NAMESPACE=kubevirt | oc apply -f -
```

Please note that after the generation step VM and template objects have no relationship with each other besides the aforementioned label.  Changes in templates do not automatically affect VMs or vice versa.

### common template customization

The templates provided by the kubevirt project provide a set of
conventions and annotations that augment the basic feature of the
[openshift
templates](https://docs.okd.io/latest/openshift_images/using-templates.html). You can
customize your kubevirt-provided templates editing these annotations, or
you can add them to your existing templates to make them consumable by
the kubevirt services.

Here's a description of the kubevirt annotations. Unless otherwise
specified, the following keys are meant to be top-level entries of the
template metadata, like

```console
    apiVersion: v1
    kind: Template
    metadata:
      name: windows-10
      annotations:
        openshift.io/display-name: "Generic demo template"
```

All the following annotations are prefixed with
`defaults.template.kubevirt.io`, which is omitted below for brevity. So
the actual annotations you should use will look like

```console
    apiVersion: v1
    kind: Template
    metadata:
      name: windows-10
      annotations:
        defaults.template.kubevirt.io/disk: default-disk
        defaults.template.kubevirt.io/volume: default-volume
        defaults.template.kubevirt.io/nic: default-nic
        defaults.template.kubevirt.io/network: default-network
```

Unless otherwise specified, all annotations are meant to be safe
defaults, both for performance and compatibility, and hints for the
CNV-aware UI and tooling.

#### disk

See the section `references` below.

Example:

```console
    apiVersion: v1
    kind: Template
    metadata:
      name: Linux
      annotations:
        defaults.template.kubevirt.io/disk: rhel-disk
```

#### nic

See the section `references` below.

Example:

```console
    apiVersion: v1
    kind: Template
    metadata:
      name: Windows
      annotations:
        defaults.template.kubevirt.io/nic: my-nic
```

#### volume

See the section `references` below.

Example:

```console
    apiVersion: v1
    kind: Template
    metadata:
      name: Linux
      annotations:
        defaults.template.kubevirt.io/volume: custom-volume
```

#### network

See the section `references` below.

Example:

```console
    apiVersion: v1
    kind: Template
    metadata:
      name: Linux
      annotations:
        defaults.template.kubevirt.io/network: fast-net
```

#### references

The default values for network, nic, volume, disk are meant to be the
**name** of a section later in the document that the UI will find and
consume to find the default values for the corresponding types. For
example, considering the annotation
`defaults.template.kubevirt.io/disk: my-disk`: we assume that later in
the document it exists an element called `my-disk` that the UI can use
to find the data it needs. The names actually don't matter as long as
they are legal for kubernetes and consistent with the content of the
document.

#### complete example

`demo-template.yaml`

```console
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

```console
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
[templates](https://github.com/kubevirt/kubevirt/tree/main/examples) to
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

### Openshift Console

VMs can be created through [OpenShift Cluster Console UI ](https://github.com/openshift/console).
This UI supports creation VM using templates and templates
features - flavors and workload profiles. To create VM from template, choose
WorkLoads in the left panel >> choose Virtualization >> press to the "Create Virtual Machine"
blue button >> choose "Create from wizard". Next, you have to see
"Create Virtual Machine" window

### Common-templates

There is the [common-templates](https://github.com/kubevirt/common-templates/) subproject. It provides official prepared and useful templates. You can also create templates by hand. You can find an example below, in the "Example template" section.

### Example template

In order to create a virtual machine via OpenShift CLI, you need to
provide a template defining the corresponding object and its metadata.

**NOTE** Only `VirtualMachine` object is currently supported.

Here is an example template that defines an instance of the
`VirtualMachine` object:

```console
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: fedora-desktop-large
  annotations:
    openshift.io/display-name: "Fedora 32+ VM"
    description: >-
      Template for Fedora 32 VM or newer.
      A PVC with the Fedora disk image must be available.
      Recommended disk image:
      https://download.fedoraproject.org/pub/fedora/linux/releases/32/Cloud/x86_64/images/Fedora-Cloud-Base-32-1.6.x86_64.qcow2
    tags: "hidden,kubevirt,virtualmachine,fedora"
    iconClass: "icon-fedora"
    openshift.io/provider-display-name: "KubeVirt"
    openshift.io/documentation-url: "https://github.com/kubevirt/common-templates"
    openshift.io/support-url: "https://github.com/kubevirt/common-templates/issues"
    template.openshift.io/bindable: "false"
    template.kubevirt.io/version: v1alpha1
    defaults.template.kubevirt.io/disk: rootdisk
    template.kubevirt.io/editable: |
      /objects[0].spec.template.spec.domain.cpu.sockets
      /objects[0].spec.template.spec.domain.cpu.cores
      /objects[0].spec.template.spec.domain.cpu.threads
      /objects[0].spec.template.spec.domain.resources.requests.memory
      /objects[0].spec.template.spec.domain.devices.disks
      /objects[0].spec.template.spec.volumes
      /objects[0].spec.template.spec.networks
    name.os.template.kubevirt.io/fedora32: Fedora 32 or higher
    name.os.template.kubevirt.io/fedora33: Fedora 32 or higher
    name.os.template.kubevirt.io/silverblue32: Fedora 32 or higher
    name.os.template.kubevirt.io/silverblue33: Fedora 32 or higher
  labels:
    os.template.kubevirt.io/fedora32: "true"
    os.template.kubevirt.io/fedora33: "true"
    os.template.kubevirt.io/silverblue32: "true"
    os.template.kubevirt.io/silverblue33: "true"
    workload.template.kubevirt.io/desktop: "true"
    flavor.template.kubevirt.io/large: "true"
    template.kubevirt.io/type: "base"
    template.kubevirt.io/version: "0.11.3"
objects:
- apiVersion: kubevirt.io/v1alpha3
  kind: VirtualMachine
  metadata:
    name: ${NAME}
    labels:
      vm.kubevirt.io/template: fedora-desktop-large
      vm.kubevirt.io/template.version: "0.11.3"
      vm.kubevirt.io/template.revision: "45"
      app: ${NAME}
    annotations:
      vm.kubevirt.io/os: "fedora"
      vm.kubevirt.io/workload: "desktop"
      vm.kubevirt.io/flavor: "large"
      vm.kubevirt.io/validations: |
        [
          {
            "name": "minimal-required-memory",
            "path": "jsonpath::.spec.domain.resources.requests.memory",
            "rule": "integer",
            "message": "This VM requires more memory.",
            "min": 1073741824
          }
        ]
  spec:
    dataVolumeTemplates:
    - apiVersion: cdi.kubevirt.io/v1beta1
      kind: DataVolume
      metadata:
        name: ${NAME}
      spec:
        pvc:
          accessModes:
            - ReadWriteMany
          resources:
            requests:
              storage: 30Gi
        source:
          pvc:
            name: ${SRC_PVC_NAME}
            namespace: ${SRC_PVC_NAMESPACE}
    running: false
    template:
      metadata:
        labels:
          kubevirt.io/domain: ${NAME}
          kubevirt.io/size: large
      spec:
        domain:
          cpu:
            sockets: 2
            cores: 1
            threads: 1
          resources:
            requests:
              memory: 8Gi
          devices:
            rng: {}
            networkInterfaceMultiqueue: true
            inputs:
              - type: tablet
                bus: virtio
                name: tablet
            disks:
            - disk:
                bus: virtio
              name: ${NAME}
            - disk:
                bus: virtio
              name: cloudinitdisk
            interfaces:
            - masquerade: {}
              name: default
        terminationGracePeriodSeconds: 180
        networks:
        - name: default
          pod: {}
        volumes:
        - dataVolume:
            name: ${NAME}
          name: ${NAME}
        - cloudInitNoCloud:
            userData: |-
              #cloud-config
              user: fedora
              password: ${CLOUD_USER_PASSWORD}
              chpasswd: { expire: False }
          name: cloudinitdisk
parameters:
- description: VM name
  from: 'fedora-[a-z0-9]{16}'
  generate: expression
  name: NAME
- name: SRC_PVC_NAME
  description: Name of the PVC to clone
  value: 'fedora'
- name: SRC_PVC_NAMESPACE
  description: Namespace of the source PVC
  value: kubevirt-os-images
- description: Randomized password for the cloud-init user fedora
  from: '[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}'
  generate: expression
  name: CLOUD_USER_PASSWORD
```

Note that the template above defines free parameters (`NAME`,
`SRC_PVC_NAME`, `SRC_PVC_NAMESPACE`, `CLOUD_USER_PASSWORD`) and the `NAME`
parameter does not have specified default value.

An OpenShift template has to be converted into the JSON file via
`oc process` command, that also allows you to set the template
parameters.

A complete example can be found in the [KubeVirt
repository](https://raw.githubusercontent.com/kubevirt/kubevirt/main/examples/vm-template-fedora.yaml).

!> You need to be logged in by `oc login` command.

```console
$ oc process -f cluster/vmi-template-fedora.yaml\
    -p NAME=testvmi \
    -p SRC_PVC_NAME=fedora \
    -p SRC_PVC_NAMESPACE=kubevirt \
{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
```

The JSON file is usually applied directly by piping the processed output
to `oc create` command.

```console
$ oc process -f cluster/examples/vm-template-fedora.yaml \
    -p NAME=testvm \
    -p SRC_PVC_NAME=fedora \
    -p SRC_PVC_NAMESPACE=kubevirt \
    | oc create -f -
virtualmachine.kubevirt.io/testvm created
```

The command above results in creating a Kubernetes object according to
the specification given by the template \\(in this example it is an
instance of the VirtualMachine object\\).

It's possible to get list of available parameters using the following
command:

```console
$ oc process -f dist/templates/fedora-desktop-large.yaml --parameters
NAME                  DESCRIPTION                                          GENERATOR           VALUE
NAME                  VM name                                              expression          fedora-[a-z0-9]{16}
SRC_PVC_NAME          Name of the PVC to clone                                                 fedora
SRC_PVC_NAMESPACE     Namespace of the source PVC                                              kubevirt-os-images
CLOUD_USER_PASSWORD   Randomized password for the cloud-init user fedora   expression          [a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}
```

## Starting virtual machine from the created object

The created object is now a regular VirtualMachine object and from now
it can be controlled by accessing Kubernetes API resources. The
preferred way how to do this from within the OpenShift environment is to
use `oc patch` command.

```console
$ oc patch virtualmachine testvm --type merge -p '{"spec":{"running":true}}'
virtualmachine.kubevirt.io/testvm patched
```

Do not forget about virtctl tool. Using it in the real cases instead of
using kubernetes API can be more convenient. Example:

```console
$ virtctl start testvm
VM testvm was scheduled to start
```

As soon as VM starts, Kubernetes creates new type of object -
VirtualMachineInstance. It has similar name to VirtualMachine. Example
(not full output, it's too big):

```console
$ kubectl describe vm testvm
name:         testvm
Namespace:    myproject
Labels:       kubevirt-vm=vm-testvm
              kubevirt.io/os=fedora33
Annotations:  <none>
API Version:  kubevirt.io/v1alpha3
Kind:         VirtualMachine
```

## Cloud-init script and parameters

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, supports
[cloud-init scripts](https://cloudinit.readthedocs.io/en/latest/)

## **Hack** - use pre-downloaded image

Kubevirt VM templates, just like kubevirt VM/VMI yaml configs, can use
pre-downloaded VM image, which can be a useful feature especially in the
debug/development/testing cases. No special parameters required in the
VM template or VM/VMI yaml config. The main idea is to create Kubernetes
PersistentVolume and PersistentVolumeClaim corresponding to existing
image in the file system. Example:

```console
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

## Using DataVolumes

Kubevirt VM templates are using dataVolumeTemplates.
Before using dataVolumes, CDI has to be installed in
cluster. After that, source Datavolume can be created.

```console
---
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: fedora-datavolume-original
  namespace: kubevirt
spec:
  source:
    registry:
      url: "image_url"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 30Gi
```

After import is completed, VM can be created:
```console
$ oc process -f cluster/examples/vm-template-fedora.yaml \
    -p NAME=testvmi \
    -p SRC_PVC_NAME=fedora-datavolume-original \
    -p SRC_PVC_NAMESPACE=kubevirt \
    | oc create -f -
virtualmachine.kubevirt.io/testvm created
```

## Additional information
You can follow [Virtual Machine Lifecycle Guide](./lifecycle.md) for further reference.
