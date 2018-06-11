# Virtual Machine Creation

## Overview

The [OpenShift's template mechanism](https://docs.openshift.org/latest/dev_guide/templates.html) allows user to create a set of objects from a template.  KubeVirt takes benefit from this template mechanism to create VirtualMachines.

In order to create a virtual machine via OpenShift CLI, you need to provide a template defining the corresponding object and its metadata.

!> Only `VirtualMachine` object is currently supported.


## Example template

Here is an example template that defines an instance of the `VirtualMachine` object:

```yaml
apiVersion: v1
kind: Template
metadata:
  name: fedora-vmi-template
  annotations:
    description: "OpenShift KubeVirt Fedora VM template"
    tags: "kubevirt,openshift,template,linux"
  labels:
    kubevirt.io/os: fedora27
    miq.github.io/kubevirt-is-vmi-template: "true"
objects:
- apiVersion: kubevirt.io/v1alpha2
  kind: VirtualMachine
  metadata:
    name: ${NAME}
    labels:
      kubevirt-vm: vm-${NAME}
  spec:
    template:
      metadata:
        labels:
          kubevirt-vm: vm-${NAME}
      spec:
        domain:
          cpu:
            cores: ${{CPU_CORES}}
          resources:
            requests:
              memory: ${{MEMORY}}
          devices:
            disks:
              - name: disk0
                volumeName: root
        volumes:
          - name: root
            persistentVolumeClaim:
              claimName: myroot
parameters:
- name: NAME
  description: Name for the new VM
- name: CPU_CORES
  description: Amount of cores
  value: "4"
```

Note that the template above defines free parameters \(`NAME` and `CPU_CORES`\) and  the `NAME` parameter does not have specified default value.

An OpenShift template has to be converted into the JSON file via `oc process` command, that also allows you to set the template parameters.

A complete example can be found in the [KubeVirt repository](https://github.com/kubevirt/kubevirt/blob/master/cluster/vmi-template-fedora.yaml).

!> You need to be logged in by `oc login` command.

```bash
$ oc process -f cluster/vmi-template-fedora.yaml\
    -p NAME=testvmi \
    -p CPU_CORES=2
{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
...
```

The JSON file is usually applied directly by piping the processed output to `oc create` command.

```bash
$ oc process -f cluster/vmi-template-fedora.yaml \
    -p NAME=testvmi \
    -p CPU_CORES=2 \
    | oc create -f -
virtualmachine "testvmi" created
```

The command above results in creating a Kubernetes object according to the specification given by the template \(in this example it is an instance of the VirtualMachine object\).


## Starting virtual machine from the created object

The created object is now a regular VirtualMachine object and from now it can be controlled by accessing Kubernetes API resources.  The preferred way how to do this from within the OpenShift environment is to use `oc patch` command.

``` bash
$ oc patch virtualmachine testvmi --type merge -p '{"spec":{"running":true}}'
virtualmachine "testvmi" patched
```

You can follow [Virtual Machine Lifecycle Guide](/workloads/virtual-machines/life-cycle) for further reference.
