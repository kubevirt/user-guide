# Virtual machine templates

## What is a virtual machine template?

The KubeVirt projects provides a set of [templates](https://docs.okd.io/latest/dev_guide/templates.html) to create VMs to handle common usage scenarios.
These templates provide a combination of some key factors that could be further customized and processed to have a Virtual Machine object.
The key factors which define a template are

- Workload
  Most Virtual Machine should be *generic* to have maximum flexibility; the *highperformance* workload trades some of this flexibility to
  provide better performances.
- Guest Operating System (OS)
  This allow to ensure that the emulated hardware is compatible with the guest OS. Furthermore, it allows to maximize the stability
  of the VM, and allows performance optimizations.
- Size (flavor) 
  Defines the amount of resources (CPU, memory) to allocate to the VM.

More documentation is available in the [common templates subproject](https://github.com/kubevirt/common-templates)

## Accessing the virtual machine templates

If you installed KubeVirt using a supported method you should find the common templates preinstalled in the cluster.
Should you want to upgrade the templates, or install them from scratch, you can use one of the [supported releases](https://github.com/kubevirt/common-templates/releases)

To install the templates:
```bash
$ export VERSION="v0.3.1"
$ oc create -f https://github.com/kubevirt/common-templates/releases/download/$VERSION/common-templates-$VERSION.yaml
```

## Editable fields

You can edit the fields of the templates which define the amount of resources which the VMs will receive.

Each template can list a different set of fields that are to be considered editable.
The fields are used as hints for the user interface, and also for other components in the cluster.

The editable fields are taken from annotations in the template. Here is a snippet presenting a couple of most
commonly found editable fields:

```yaml
metadata:
  annotations:
    template.cnv.io/editable: |
      /objects[0].spec.template.spec.domain.cpu.cores
      /objects[0].spec.template.spec.domain.resources.requests.memory
```

Each entry in the editable field list must be a [jsonpath](https://kubernetes.io/docs/reference/kubectl/jsonpath/).
The actually editable field is the last entry (the "leaf") of the path. For example, the following minimal snippet highlights
the fields which you can edit:
```yaml
objects:
  spec:
    template:
      spec:
        domain:
          cpu:
            cores:
              VALUE # this is editable
          resources:
            requests:
              memory:
                VALUE # this is editable
```

## Relationship between templates and VMs

Once [processed](https://docs.openshift.com/enterprise/3.0/dev_guide/templates.html#creating-from-templates-using-the-cli), the templates produce VM objects to be
used in the cluster. The VMs produced from templates will have a `vm.cnv.io/template` label, whose value will be the name of the parent template,
for example `fedora-generic-medium`:
```yaml
  metadata:
    labels:
      vm.cnv.io/template: fedora-generic-medium
```
This make it possible to query for all the VMs built from any template.

Example:
```bash
oc process -o yaml rhel7-generic-tiny PVCNAME=mydisk NAME=rheltinyvm
```

And the output:
```yaml
apiVersion: v1
items:
- apiVersion: kubevirt.io/v1alpha2
  kind: VirtualMachine
  metadata:
    labels:
      vm.cnv.io/template: rhel7-generic-tiny
    name: rheltinyvm
    osinfoname: rhel7.0
  spec:
    running: false
    template:
      spec:
        domain:
          cpu:
            cores: 1
          devices:
            disks:
            - disk:
                bus: virtio
              name: rootdisk
              volumeName: rootvolume
            rng: {}
          resources:
            requests:
              memory: 1G
        terminationGracePeriodSeconds: 0
        volumes:
        - name: rootvolume
          persistentVolumeClaim:
            claimName: mydisk
        - cloudInitNoCloud:
            userData: |-
              #cloud-config
              password: redhat
              chpasswd: { expire: False }
          name: cloudinitvolume
kind: List
metadata: {}
```

You can add add the VM from the template to the cluster in one go
```bash
oc process rhel7-generic-tiny PVCNAME=mydisk NAME=rheltinyvm | oc apply -f -
```

Please note that, after the generation step, VM objects and template objects have no relationship with each other besides the aforementioned label (e.g. changes
in templates do not automatically affect VMs, or vice versa).

## common template customization

### template customization - memory, CPU

There are three options to customize VM memory and CPU:

 * select flavor - tiny, small, medium, etc. Each flavor grants to VM different amount of RAM and CPU cores.
 * setting up directly editable fields spec.template.spec.domain.cpu.cores and spec.template.spec.domain.resources.requests.memory, example:

```bash
oc patch virtualmachine testguest --type merge -p '{"spec":{"template":{"spec":{"domain":{"cpu":{"cores":'3'}}}}}}'
virtualmachine.kubevirt.io/testguest patched
```
 * use WebUI: WebUI supports different flavors and Workload Profiles. Also it supports custom amount of memory and CPUs

### template customization - networking

There are two options to customize Networking in VM:
 * setting up directly editable field(see example above): spec.template.spec.networks. You can edit following:
   * name (of interface)
   * pod
 * edit networking in webUI. Please note: WebUI also edits spec.domain.interfaces and supports changing mac address

### template customization - disks

There are two options to customize disks:

 * Setting up sole variable - name of PersistentVolumeClaim(PVC)
 * Choose workload profile
 * Choose editable fields

#### Setting up name of PVC
Each template has only one variable for disk customization - name of PersistentVolumeClaim(PVC).  Note: PVC should exist before you start your VM at first time. 

#### Choose worload profile
In a case if high performance workload profile choosed, then kubevirt enables [IOThread](https://libvirt.org/formatdomain.html#elementsIOThreadsAllocation) qemu feature for disk. 
Note: not each operation system has an option of high performance workload profile.  

### Editable fields related with disks
Each template has ability to direct edit editable fields (see details and example above). By fact it provides same ability to choose name of PVC in comparison with changing variable

Note: WebUI cant create specific disk in the Create Virtual Machine wizzard - only attach existing PVC
