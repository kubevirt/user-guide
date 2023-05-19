# Creating VirtualMachines

The virtctl sub command `create vm` allows easy creation of VirtualMachine
manifests from the command line. It
leverages [instance types and preferences](./instancetypes.md)
and provides several flags to control details of the created virtual machine.

For example there are flags to specify the name or run strategy of a
virtual machine or flags to add volumes to a virtual machine. Instance types
and preferences can either be specified directly or it is possible to let
KubeVirt infer those from the volume used to boot the virtual machine.

For a full set of flags and their description use the following command:

```shell
virtctl create vm -h
```

## Creating VirtualMachines on a cluster

The output of virtctl `create vm` can be piped into `kubectl` to directly
create a VirtualMachine on a cluster, e.g.:

```shell
# Create a VM with name my-vm on the cluster
virtctl create vm --name my-vm | kubectl create -f -
virtualmachine.kubevirt.io/my-vm created
```

## Specifying or inferring instance types and preferences

Instance types and preference can be specified with the appropriate flags, e.g.:

```shell
virtctl create vm --instancetype my-instancetype --preference my-preference
```

The type of the instance type or preference (namespaced or cluster scope)
can be
controlled by prefixing the instance type or preference name with the
corresponding CRD name, e.g.:

```shell
# Using a cluster scoped instancetype and a namespaced preference
virtctl create vm \
  --instancetype virtualmachineclusterinstancetype/my-instancetype \
  --preference virtualmachinepreference/my-preference
```

If a prefix was not supplied the cluster scoped resources will be used by
default.

To
infer [instance types and/or preferences](./instancetypes.md#inferFromVolume)
from the volume used to boot the virtual machine add the following flags:

```shell
virtctl create vm --infer-instancetype --infer-preference
```

## Boot order of added volumes

Please note that volumes of different kinds currently have the following fixed
boot order regardless of the order their flags were specified on the
command line:

1. ContainerDisk
2. DataSource
3. Cloned PVC
4. Directly used PVC

If multiple volumes of the same kind were specified their order is
determined by the order in which their flags were specified.

## Specifying cloud-init user data

To pass cloud-init user data to virtctl it needs to be encoded into a base64
string. Here is an example how to do it:

```shell
# Put your cloud-init user data into a file
$ cat cloud-init.txt
#cloud-config
users:
  - name: admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAA...

# Base64 encode the contents of the file without line wraps and store it in a variable
$ CLOUD_INIT_USERDATA=$(base64 -w 0 cloud-init.txt)

# Show the contents of the variable
$ echo $CLOUD_INIT_USERDATA
I2Nsb3VkLWNvbmZpZwp1c2VyczoKICAtIG5hbWU6IGFkbWluCiAgICBzdWRvOiBBTEw9KEFMTCkgTk9QQVNTV0Q6QUxMCiAgICBzc2hfYXV0aG9yaXplZF9rZXlzOgogICAgICAtIHNzaC1yc2EgQUFBQS4uLgo=
```

You can now use this variable as an argument to the `--cloud-init-user-data`
flag:

```shell
virtctl create vm --cloud-init-user-data $CLOUD_INIT_USERDATA
```

## Examples

Create a manifest for a VirtualMachine with a random name:

```shell
virtctl create vm
```

Create a manifest for a VirtualMachine with a specified name and RunStrategy
Always

```shell
virtctl create vm --name=my-vm --run-strategy=Always
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineClusterInstancetype

```shell
virtctl create vm --instancetype=my-instancetype
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineInstancetype (namespaced)

```shell
virtctl create vm --instancetype=virtualmachineinstancetype/my-instancetype
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineClusterPreference

```shell
virtctl create vm --preference=my-preference
```

Create a manifest for a VirtualMachine with a specified
VirtualMachinePreference (namespaced)

```shell
virtctl create vm --preference=virtualmachinepreference/my-preference
```

Create a manifest for a VirtualMachine with an ephemeral containerdisk volume

```shell
virtctl create vm --volume-containerdisk=src:my.registry/my-image:my-tag
```

Create a manifest for a VirtualMachine with a cloned DataSource in namespace and
specified size

```shell
virtctl create vm --volume-datasource=src:my-ns/my-ds,size:50Gi
```

Create a manifest for a VirtualMachine with a cloned DataSource and inferred
instancetype and preference

```shell
virtctl create vm --volume-datasource=src:my-annotated-ds --infer-instancetype --infer-preference
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and cloned PVC

```shell
virtctl create vm --volume-clone-pvc=my-ns/my-pvc
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and directly used PVC

```shell
virtctl create vm --volume-pvc=my-pvc
```

Create a manifest for a VirtualMachine with a clone DataSource and a blank
volume

```shell
virtctl create vm --volume-datasource=src:my-ns/my-ds --volume-blank=size:50Gi
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and cloned DataSource

```shell
virtctl create vm --instancetype=my-instancetype --preference=my-preference --volume-datasource=src:my-ds
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and two cloned DataSources (flag
can be provided multiple times)

```shell
virtctl create vm --instancetype=my-instancetype --preference=my-preference --volume-datasource=src:my-ds1 --volume-datasource=src:my-ds2
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and directly used PVC

```shell
virtctl create vm --instancetype=my-instancetype --preference=my-preference --volume-pvc=my-pvc
```
