# Virtual machine templates

## What is a virtual machine template?

The KubeVirt projects provides [templates](https://docs.okd.io/latest/dev_guide/templates.html) to create VMs to handle common scenarios.
A template provides a combination of some key factors that could be further customized and processed to have a Virtual Machine object.
The key factors which define a template are
- Workload
most Virtual Machine should be *generic* to have maximum flexibility; the *highperformance* workload trades some of this flexibility to
provide better performance
- Guest Operating System (OS)
Enable optimizations depending on the OS which is going to run on the guest.
- Size (flavor) 
Amount of resources (CPU, memory) to allocate to the VM

More documentation is available in the [common templates subproject](https://github.com/kubevirt/common-templates)

## Accessing the virtual machine templates

If you installed KubeVirt using a supported method you should find the common templates preinstalled in the cluster.
Should you want to upgrade the templates, or installed them from scratch, you can use one of the [supported release](https://github.com/kubevirt/common-templates/releases)

To install the templates:
```bash
$ export VERSION="v0.3.1"
$ oc create -f https://github.com/kubevirt/common-templates/releases/download/$VERSION/common-templates-$VERSION.yaml
```
