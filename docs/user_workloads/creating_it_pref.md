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
