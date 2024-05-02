# Creating VirtualMachines

The virtctl sub command `create vm` allows easy creation of VirtualMachine
manifests from the command line. It leverages
[instance types and preferences](../user_workloads/instancetypes.md) and inference by
default (see
[Specifying or inferring instance types and preferences](#specifying-or-inferring-instance-types-and-preferences))
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

# Creating Instance Types

The virtctl subcommand `create instancetype` allows easy creation of an instance type
manifest from the command line. The command also provides several flags that can be used
to create your desired manifest.

There are two required flags that need to be specified: the number of vCPUs and the amount of
memory to be requested. Additionally, there are several optional flags that can be used, such as specifying
a list of GPUs for passthrough, choosing the desired IOThreadsPolicy, or simply providing
the name of our instance type.

By default, the command creates the cluster-wide resource. If the user wants to create the namespaced version,
they need to provide the namespaced flag. The namespace name can be specified by using the namespace flag.

For a complete list of flags and their descriptions, use the following command:

```shell
virtctl create instancetype -h
```

## Examples

Create a manifest for a VirtualMachineClusterInstancetype with the required --cpu and --memory flags
```shell
virtctl create instancetype --cpu 2 --memory 256Mi
```

Create a manifest for a VirtualMachineInstancetype with a specified namespace
```shell
virtctl create instancetype --cpu 2 --memory 256Mi --namespace my-namespace
```

Create a manifest for a VirtualMachineInstancetype without a specified namespace name
```shell
virtctl create instancetype --cpu 2 --memory 256Mi --namespaced
```

# Creating Preferences

The virtctl subcommand `create preference` allows easy creation of a preference
manifest from the command line. This command serves as a starting point to create
the basic structure of a manifest, as it does not allow specifying all of the options that
are supported in preferences.

The current set of flags allows us, for example, to specify the preferred CPU topology, machine type
or a storage class.

By default, the command creates the cluster-wide resource. If the user wants to create the namespaced version,
they need to provide the namespaced flag. The namespace name can be specified by using the namespace flag.

For a complete list of flags and their descriptions, use the following command:

```shell
virtctl create preference -h
```

## Examples

Create a manifest for a VirtualMachineClusterPreference with a preferred cpu topology
```shell
virtctl create preference --cpu-topology preferSockets
```

Create a manifest for a VirtualMachinePreference with a specified namespace
```shell
virtctl create preference --namespace my-namespace
```

Create a manifest for a VirtualMachinePreference with the preferred storage class
```shell
virtctl create preference --namespaced --volume-storage-class my-storage
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

To explicitly
infer [instance types and/or preferences](../user_workloads/instancetypes.md#inferFromVolume)
from the volume used to boot the virtual machine add the following flags:

```shell
virtctl create vm --infer-instancetype --infer-preference
```

The implicit default is to always try inferring an instancetype and
preference from the boot volume. This feature makes use of the
`IgnoreInferFromVolumeFailure` policy, which suppresses failures on inference
of instancetypes and preferences. If one of the above switches was provided
explicitly, then the `RejectInferFromVolumeFailure` policy is used instead.
This way users are made aware of potential issues during the virtual machine
creation.

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
# Put your cloud-init user data into a file.
# This will add an authorized key to the default user.
# To get the default username read the documentation for the cloud image
$ cat cloud-init.txt
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAA...

# Base64 encode the contents of the file without line wraps and store it in a variable
$ CLOUD_INIT_USERDATA=$(base64 -w 0 cloud-init.txt)

# Show the contents of the variable
$ echo $CLOUD_INIT_USERDATA I2Nsb3VkLWNvbmZpZwpzc2hfYXV0aG9yaXplZF9rZXlzOgogIC0gc3NoLXJzYSBBQUFBLi4uCg==
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
