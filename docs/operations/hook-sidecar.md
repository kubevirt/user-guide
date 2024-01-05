# Hook Sidecar Container

## Introduction

In KubeVirt, a Hook Sidecar container is a sidecar container (a secondary container that runs along with the main
application container within the same Pod) used to apply customizations before the Virtual Machine is initialized. This
ability is provided since 100% of the [libvirt domain XML](https://libvirt.org/formatdomain.html) elements and
attributes are not configurable/customizable using the VMI specification.

The sidecar containers communicate with the main container over a socket with a gRPC protocol. There are two main
sidecar hooks:

1. `onDefineDomain`: This hook helps to customize libvirt's XML and return the new XML over gRPC for the VM creation.
2. `preCloudInitIso`: This hook helps to customize the cloud-init configuration. It operates on and returns JSON
   formatted cloud-init data.

## Enabling Sidecar feature gate

To be able to use the sidecar hooks, the Sidecar feature gate must be enabled on the cluster. If you're using a
development cluster backed by KubeVirt CI, you could enable it using the following steps:
```shell
# export FEATURE_GATES=<feature-gate-1>,<feature-gate-2>
# e.g. to enable Sidecar and HotplugNICs feature gates run below
$ export FEATURE_GATES=Sidecar,HotplugNICs
$ make cluster-sync
```

For non-development clusters, it can be enabled by following the steps mentioned in [Activating feature
gates](../activating_feature_gates).

## Sidecar-shim container image

To reduce the amount of boilerplate that developers need to do in order to run VM with custom modifications, we provide
the [sidecar-shim-image](https://quay.io/repository/kubevirt/sidecar-shim) that takes care of implementing the
communication with the main container.

The image contains the `sidecar-shim` binary built using
[`sidecar_shim.go`](https://github.com/kubevirt/kubevirt/blob/main/cmd/sidecars/sidecar_shim.go) which should be kept
as the entrypoint of the container. This binary will search in `$PATH` for binaries named after the hook names (e.g
`onDefineDomain` and `preCloudInitIso`) and run them. User must provide the necessary arguments as command line options
(flags).

In the case of `onDefineDomain`, the arguments will be the VMI information as JSON string, (e.g `--vmi vmiJSON`) and
the current domain XML (e.g `--domain domainXML`). As standard output it expects the modified domain XML.

In the case of `preCloudInitIso`, the arguments will be the VMI information as JSON string, (e.g `--vmi vmiJSON`) and
the CloudInitData (e.g `--cloud-init cloudInitJSON`). As standard output it expects the modified CloudInitData (as
JSON).

Besides a binary, one could also execute shell or python scripts by making them available at the expected location.

## Go, Python, Shell - pick any one

Although a binary doesn't strictly need to be generated from Go code, and a script doesn't strictly need to be one
among Shell or Python, for the purpose of this guide, we will use those as examples.

### Go binary

Example Go code modifiying the [SMBIOS system
information](https://libvirt.org/formatdomain.html#smbios-system-information) can be found in the [KubeVirt
repo](https://github.com/kubevirt/kubevirt/tree/main/cmd/sidecars/smbios). Binary generated from this code, when
available under `/usr/bin/ondefinedomain` in the sidecar-shim-image, is run right before VMI creation and the baseboard
manufacturer value is modified to reflect what's provided in the `smbios.vm.kubevirt.io/baseBoardManufacturer`
annotation in [VMI spec](https://github.com/kubevirt/kubevirt/blob/main/examples/vmi-with-sidecar-hook.yaml).

### Shell or Python script

If you pefer writing a shell or python script instead of a Go program, create a Kubernetes ConfigMap and use
annotations to make sure the script is run before the VMI creation. The flow would be as below:

1. Create a ConfigMap containing the shell or python script you want to run
1. Create a VMI containing the annotation `hooks.kubevirt.io/hookSidecars` and mention the ConfigMap information in it.

#### ConfigMap with shell script

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config-map
data:
  my_script.sh: |
    #!/bin/sh
    tempFile=`mktemp --dry-run`
    echo $4 > $tempFile
    sed -i "s|<baseBoard></baseBoard>|<baseBoard><entry name='manufacturer'>Radical Edward</entry></baseBoard>|" $tempFile
    cat $tempFile
```

#### ConfigMap with python script

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config-map
data:
  my_script.sh: |
    #!/usr/bin/env python

    import xml.etree.ElementTree as ET
    import sys

    def main(s):
        # write to a temporary file
        f = open("/tmp/orig.xml", "w")
        f.write(s)
        f.close()

        # parse xml from file
        xml = ET.parse("/tmp/orig.xml")
        # get the root element
        root = xml.getroot()
        # find the baseBoard element
        baseBoard = root.find("sysinfo").find("baseBoard")

        # prepare new element to be inserted into the xml definition
        element = ET.Element("entry", {"name": "manufacturer"})
        element.text = "Radical Edward"
        # insert the element
        baseBoard.insert(0, element)

        # write to a new file
        xml.write("/tmp/new.xml")
        # print file contents to stdout
        f = open("/tmp/new.xml")
        print(f.read())
        f.close()

    if __name__ == "__main__":
        main(sys.argv[4])
```

After creating one of the above ConfigMap, create the VMI using the manifest in [this
example](https://github.com/kubevirt/kubevirt/blob/main/examples/vmi-with-sidecar-hook-configmap.yaml). Of importance
here is the ConfigMap information stored in the annotations:

```yaml
annotations:
  hooks.kubevirt.io/hookSidecars: >
    [
        {
            "args": ["--version", "v1alpha2"],
            "image": "registry:5000/kubevirt/sidecar-shim:devel",
            "configMap": {"name": "my-config-map", "key": "my_script.sh", "hookPath": "/usr/bin/onDefineDomain"}
        }
    ]
```


The `name` field indicates the name of the ConfigMap on the cluster which contains the script you want to execute. The
`key` field indicates the key in the ConfigMap which contains the script to be executed. Finally, `hookPath` indicates
the path where you want the script to be mounted. It could be either of `/usr/bin/onDefineDomain` or
`/usr/bin/preCloudInitIso` depending upon the hook you want to execute.

### Verify everything works

Whether you used the Go binary or a Shell/Python script from above examples, you would be able to see the newly created
VMI have the modified baseboard manufacturer information. After creating the VMI, verify that it is in the `Running`
state, and connect to its console and see if the desired changes to baseboard manufacturer get reflected:

```shell
# Once the VM is ready, connect to its display and login using name and password "fedora"
cluster/virtctl.sh vnc vmi-with-sidecar-hook-configmap

# Check whether the base board manufacturer value was successfully overwritten
sudo dmidecode -s baseboard-manufacturer
```
