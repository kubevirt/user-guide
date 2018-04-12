# Virtual Machine Creation

## Overview

KubeVirt adds new types to the Kubernetes API to manage Virtual Machines and, in OpenShift, you can interact with these new resources via `oc` command as you would with any other Kubernetes API resource.

In order to create a virtual machine via OpenShift CLI, you need to provide a template defining the corresponding object and its metadata.

!> Only `OfflineVirtualMachine` object is currently supported.


## Example template

Here is an example template that defines an instance of the `OfflineVirtualMachine` object:

\([cluster/vm-template-fedora.yaml](cluster/vm-template-fedora.yaml)\):

```yaml
apiVersion: v1
kind: Template
metadata:
  name: fedora-vm-template
  annotations:
    description: "OpenShift KubeVirt Fedora VM template"
    tags: "kubevirt,openshift,template,linux"
  labels:
    kubevirt.io/os: fedora27
    miq.github.io/kubevirt-is-vm-template: "true"
objects:
- apiVersion: kubevirt.io/v1alpha1
  kind: OfflineVirtualMachine
  metadata:
    name: ${NAME}
    labels:
      kubevirt-ovm: ovm-${NAME}
  spec:
    template:
      metadata:
        labels:
          kubevirt-ovm: ovm-${NAME}
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
                volumeName: registryvolume
                disk:
                  bus: virtio
              - name: disk1
                volumeName: cloudinitvolume
                disk:
                  bus: virtio
        volumes:
          - name: registryvolume
            registryDisk:
              image: kubevirt/fedora-cloud-registry-disk-demo:latest
          - name: cloudinitvolume
            cloudInitNoCloud:
              userDataBase64: I2Nsb3VkLWNvbmZpZwpwYXNzd29yZDogYXRvbWljCnNzaF9wd2F1dGg6IFRydWUKY2hwYXNzd2Q6IHsgZXhwaXJlOiBGYWxzZSB9Cg==
parameters:
- name: NAME
  description: Name for the new VM
- name: MEMORY
  description: Amount of memory
  value: 4096Mi
- name: CPU_CORES
  description: Amount of cores
  value: "4"
```

Note that the template above defines three free parameters \(`NAME`, `MEMORY` and `CPU_CORES`\) and `NAME` does not have specified default value.

An OpenShift template has to be converted into the JSON file via `oc process` command, that also allows you to set the template parameters.

!> You need to be logged in by `oc login` command.

```bash
$ oc process -f cluster/vm-template-fedora.yaml\
    -p NAME=testvm \
    -p CPU_CORES=2 \
```

The JSON file is usually applied directly by piping the processed output to `oc create` command.

```bash
$ oc process -f cluster/vm-template-fedora.yaml \
    -p NAME=testvm \
    -p CPU_CORES=2 \
    | oc create -f -
```

The command above results in creating a Kubernetes object according to the specification given by the template \(in this example it is an instance of the OfflineVirtualMachine object\).


## Starting virtual machine from the created object

The virtual machine can be then started by patching Kubernetes API resources.

``` bash
$ oc patch offlinevirtualmachine testvm --type merge -p '{"spec":{"running":true}}'
```
