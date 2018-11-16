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
Should you want to upgrade the templates, or installed them from scratch, you can use one of the [supported release](https://github.com/kubevirt/common-templates/releases)

To install the templates:
```bash
$ export VERSION="v0.3.1"
$ oc create -f https://github.com/kubevirt/common-templates/releases/download/$VERSION/common-templates-$VERSION.yaml
```

## Editable fields

You can edit the fields of the templates which define the amount of resources which the VMs will receive.
The list of fields includes:

- spec.template.spec.domain.cpu.cores
- spec.template.spec.domain.resources.requests.memory
- spec.template.spec.domain.devices.disks
- spec.template.spec.volumes
- spec.template.spec.networks


## Relationship between templates and VMs

Once [processed](), the templates produce VM objects to be used in the cluster. The VMs produced from templates will have a `vm.cnv.io/template` label, whose
value will be the name of the parent template, for example `fedora-generic-medium`:
```yaml
  metadata:
    labels:
      vm.cnv.io/template: fedora-generic-medium
```
This make it possible to query for all the VMs built from any template.

Please note that, after the generation step, VM objects and template objects have no relationship with each other besides the aforementioned label (e.g. changes
in templates do not automatically affect VMs, or vice versa).
