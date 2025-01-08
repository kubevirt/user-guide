# Creating VirtualMachines by using virtctl

The virtctl sub command `create vm` allows easy creation of VirtualMachine
manifests from the command line. It leverages
[instance types and preferences](../user_workloads/instancetypes.md) and
inference by default (see
[Using instance types and preferences](#using-instance-types-and-preferences))
and it provides several flags to control details of the created virtual machine.

For example there are flags to specify the name or run strategy of a
virtual machine or flags to add volumes to a virtual machine. Instance types
and preferences can either be specified directly or it is possible to let
KubeVirt infer those from the volume used to boot the virtual machine.

For a full set of flags and their description use the following command:

```shell
virtctl create vm -h
```

## Creating VirtualMachines on a cluster

The output of `virtctl create vm` can be piped directly into `kubectl` to
create a VirtualMachine on a cluster, e.g.:

```shell
# Create a VM with name my-vm on the cluster
virtctl create vm --name my-vm | kubectl create -f -
virtualmachine.kubevirt.io/my-vm created
```

## Using instance types and preferences

Instance types and preferences can be used with the appropriate flags. If
they are not otherwise specified, instance types and preferences are inferred
from the boot volume of a virtual machine by default. For more information
about inference, see [below](#inference-of-instance-type-andor-preference).

The following example creates a VM specifying an instance type and preference by
using the appropriate flags:

```shell
virtctl create vm --instancetype my-instancetype --preference my-preference
```

The type of the instance type or preference (namespaced or cluster scope)
can be controlled by prefixing the instance type or preference name with the
corresponding CRD name, e.g.:

```shell
# Using a cluster scoped instance type and a namespaced preference
virtctl create vm \
  --instancetype virtualmachineclusterinstancetype/my-instancetype \
  --preference virtualmachinepreference/my-preference
```

If a prefix was not supplied the cluster scoped resources will be used by
default.

### Inference of instance type and/or preference

To explicitly
infer [instance types and/or preferences](../user_workloads/instancetypes.md#inferFromVolume)
from the volume used to boot the virtual machine add the following flags:

```shell
virtctl create vm --infer-instancetype --infer-preference
```

The implicit default is to always try to infer an instance type and
preference from the boot volume. This feature makes use of the
`IgnoreInferFromVolumeFailure` policy, which suppresses failures on inference
of instance types and preferences. If one of the above switches has been
explicitly specified, the `RejectInferFromVolumeFailure` policy is used
instead. This way users are made aware of potential issues during the
virtual machine creation.

To infer an instance type or preference from another volume than the volume used
to boot the virtual machine, use the `--infer-instancetype-from` and
`--infer-preference-from` flags to specify any of the virtual machine's volumes.

```shell
# This virtual machine will boot from volume-a, but the instance type and
# preference are inferred from volume-b.
virtctl create vm \
  --volume-import=type:pvc,src:my-ns/my-pvc-a,name:volume-a \
  --volume-import=type:pvc,src:my-ns/my-pvc-b,name:volume-b \
  --infer-instancetype-from volume-b \
  --infer-preference-from volume-b
```

## Boot order of added volumes

Please note that volumes of different kinds currently have the following fixed
boot order regardless of the order their flags were specified on the
command line:

1. Containerdisks
2. Directly used PVCs
3. DataSources
4. Cloned PVCs
5. Blank volumes
6. Imported volumes (through the `--volume-import` flag)

If multiple volumes of the same kind were specified their order is
determined by the order in which their flags were specified.

## Generating cloud-init user data

To generate cloud-init user data with `virtctl create vm` the following
flags can be used.

!!! Note
    Generating cloud-init user data is mutually exclusive with [specifying custom cloud-init user data](#specifying-custom-cloud-init-user-data), as explained below.

### `--user` flag

Specify the main user of the virtual machine that is created by cloud-init. It
sets the `user` parameter in the generated cloud-init user data.

### `--password-file` flag

Specify a file to read the password for the virtual machine's main user from.
In the generated cloud-init user data, it sets the value of the `password`
parameter to the read in value and the value of the `chpasswd` parameter to
`{ expire: False }`.

### `--ssh-key` flag

Specify one or more SSH authorized keys for the virtual machine's main user.
It sets the `ssh_authorized_keys` parameter in the generated cloud-init user
data.

### `--ga-manage-ssh` flag

When this flag is set, a command enabling the `qemu-guest-agent` to manage SSH
authorized keys is added to the generated cloud-init user data. The command
is added to the `runcmd` parameter which is required on SELinux enabled
distributions that would otherwise not allow the `qemu-guest-agent` to manage
SSH authorized keys in the home directories of users.

### Example

```shell
$ virtctl create vm --user myuser --access-cred=src:my-keys --ga-manage-ssh
```

This command will generate the following cloud-init user data:

```yaml
volumes:
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        user: myuser
        runcmd:
          - [ setsebool, -P, 'virt_qemu_ga_manage_ssh', 'on' ]
    name: cloudinitdisk
```

By passing the `--ga-manage-ssh` flag explicitly, the `qemu-guest-agent` is
able to manage the credentials read from the Secret `my-keys` specified as
source parameter to the `--access-cred` flag. Note that if `--ga-manage-ssh`
was not explicitly set to `false`, this is also the default behavior.

## Specifying custom cloud-init user data

To pass custom cloud-init user data to virtctl it needs to be encoded into a
base64 string.

!!! Note
    Specifying custom cloud-init user data is mutually exclusive with [generating cloud-init user data](#generating-cloud-init-user-data), as explained above.

Here is an example how to do it:

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
$ echo $CLOUD_INIT_USERDATA
I2Nsb3VkLWNvbmZpZwpzc2hfYXV0aG9yaXplZF9rZXlzOgogIC0gc3NoLXJzYSBBQUFBLi4uCg==
```

You can now use this variable as an argument to the `--cloud-init-user-data`
flag:

```shell
virtctl create vm --cloud-init-user-data $CLOUD_INIT_USERDATA
```

## Adding access credentials to a virtual machine

By using the `--access-cred` flag, the `virtctl create vm` command can configure
[access credentials](./accessing_virtual_machines.md#dynamic-ssh-public-key-injection-via-qemu-guest-agent)
in a created virtual machine. It supports SSH authorized key and password
access credentials and can configure them to be injected either through the
`qemu-guest-agent` or through cloud-init metadata. The supported parameters of
the flag depend on the chosen `type` and `method`. The flag can be passed
multiple times to configure more than one access credential.

This flag interacts with the flags used to
[generate cloud-init user data](#generating-cloud-init-user-data), namely it
inherits the same `--user` for SSH key injection, and it enables
`qemu-guest-agent` to manage SSH authorized keys (`--ga-manage-ssh`), if it
is not explicitly disabled by the user.

### Example

```shell
$ virtctl create vm --user myuser --access-cred=src:my-keys
```

This command will generate the following access credentials and cloud-init user
data:

```
[...]
accessCredentials:
  - sshPublicKey:
      propagationMethod:
        qemuGuestAgent:
          users:
            - myuser
      source:
        secret:
          secretName: my-keys
volumes:
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        user: myuser
        runcmd:
          - [ setsebool, -P, 'virt_qemu_ga_manage_ssh', 'on' ]
    name: cloudinitdisk
```

## Adding a sysprep volume

A [sysprep volume](startup_scripts.md#sysprep-examples) can be added to
created virtual machines by passing the `--volume-sysprep` flag to the `virtctl
create vm` command.

The flag supports adding a sysprep volume from both a `ConfigMap` or a
`Secret`.

See the examples on how to do it.

## Short examples

Create a manifest for a VirtualMachine with a random name:

```shell
virtctl create vm
```

Create a manifest for a VirtualMachine with a specified name and RunStrategy
Always:

```shell
virtctl create vm --name=my-vm --run-strategy=Always
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineClusterInstancetype:

```shell
virtctl create vm --instancetype=my-instancetype
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineInstancetype (namespaced):

```shell
virtctl create vm --instancetype=virtualmachineinstancetype/my-instancetype
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineClusterPreference:

```shell
virtctl create vm --preference=my-preference
```

Create a manifest for a VirtualMachine with a specified
VirtualMachinePreference (namespaced):

```shell
virtctl create vm --preference=virtualmachinepreference/my-preference
```

Create a manifest for a VirtualMachine with specified memory and an ephemeral
containerdisk volume:

```shell
virtctl create vm --memory=1Gi \
  --volume-containerdisk=src:my.registry/my-image:my-tag
```

Create a manifest for a VirtualMachine with a cloned DataSource in namespace and
specified size:

```shell
virtctl create vm --volume-import=type:ds,src:my-ns/my-ds,size:50Gi
```

Create a manifest for a VirtualMachine with a cloned DataSource and inferred
instance type and preference:

```shell
virtctl create vm --volume-import=type:ds,src:my-annotated-ds \
  --infer-instancetype --infer-preference
```

Create a manifest for a VirtualMachine with multiple volumes and specified boot
order:

```shell
virtctl create vm --volume-containerdisk=src:my.registry/my-image:my-tag \
  --volume-import=type:ds,src:my-ds,bootorder:1
```

Create a manifest for a VirtualMachine with multiple volumes and inferred
instance type and preference with specified volumes:

```shell
virtctl create vm --volume-import=type:ds,src:my-annotated-ds \
  --volume-pvc=my-annotated-pvc --infer-instancetype=my-annotated-ds \
  --infer-preference=my-annotated-pvc
```

Create a manifest for a VirtualMachine with a cloned PVC:

```shell
virtctl create vm --volume-import=type:pvc,src:my-ns/my-pvc
```

Create a manifest for a VirtualMachine using a PVC without cloning it:

```shell
virtctl create vm --volume-pvc=src:my-pvc
```

Create a manifest for a VirtualMachine with a clone DataSource and a blank
volume:

```shell
virtctl create vm --volume-import=type:ds,src:my-ns/my-ds \
  --volume-import=type:blank,size:50Gi
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and cloned DataSource:

```shell
virtctl create vm --instancetype=my-instancetype --preference=my-preference \
  --volume-import=type:ds,src:my-ds
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and two cloned DataSources (flag
can be provided multiple times):

```shell
virtctl create vm --instancetype=my-instancetype --preference=my-preference \
  --volume-import=type:ds,src:my-ds1 --volume-import=type:ds,src:my-ds2
```

Create a manifest for a VirtualMachine with a specified
VirtualMachineCluster{Instancetype,Preference} and directly used PVC:

```shell
virtctl create vm --instancetype=my-instancetype --preference=my-preference \
  --volume-pvc=my-pvc
```

Create a manifest for a VirtualMachine with a specified DataVolumeTemplate:

```shell
virtctl create vm \
  --volume-import=type:pvc,name:my-pvc,namespace:default,size:256Mi
```

Create a manifest for a VirtualMachine with a generated cloud-init config
setting the user and adding an ssh authorized key:

```shell
virtctl create vm --user=cloud-user --ssh-key="ssh-ed25519 AAAA...."
```

Create a manifest for a VirtualMachine with a generated cloud-init config
setting the user and setting the password from a file:

```shell
virtctl create vm --user=cloud-user --password-file=/path/to/file
```

Create a manifest for a VirtualMachine with SSH public keys injected into the VM
from a secret called my-keys to the user also specified in the cloud-init
config:

```shell
virtctl create vm --user=cloud-user --access-cred=type:ssh,src:my-keys
```

Create a manifest for a VirtualMachine with SSH public keys injected into the VM
from a secret called my-keys to a user specified as param:

```shell
virtctl create vm --access-cred=type:ssh,src:my-keys,user:myuser
```

Create a manifest for a VirtualMachine with password injected into the VM from a
secret called my-pws:

```shell
virtctl create vm --access-cred=type:password,src:my-pws
```

Create a manifest for a VirtualMachine with a Containerdisk and a Sysprep
volume (source ConfigMap needs to exist):

```shell
virtctl create vm --memory=1Gi \
  --volume-containerdisk=src:my.registry/my-image:my-tag \
  --volume-sysprep=src:my-cm
```

## Complex examples

These examples show how `virtctl create vm` can be used in more complex
scenarios.

### First example

Creating a VirtualMachine with the following settings:

- Run strategy: `Manual`
- Termination grace period: `123` seconds
- Instancetype: `u1.small`
- Prefernce: `fedora`
- Using the `quay.io/containerdisks/fedora` containerdisk as first volume
- Adding a second blank volume with a size of `1Gi`
- The main user is named `myuser`
- Logins with the main user are possible with the specified authorized key

```shell
virtctl create vm --run-strategy=Manual --termination-grace-period=123 \
  --instancetype=u1.small --preference=fedora \
  --volume-containerdisk=src:quay.io/containerdisks/fedora \
  --volume-import=type:blank,size:1Gi \
  --user=myuser --ssh-key='ssh-ed25519 AAAA...'
```

### Second example

Creating a VirtualMachine with the following settings and using a secret
for configuring access credentials:

- Instancetype: `u1.small`
- Prefernce: `fedora`
- Using the `quay.io/containerdisks/fedora` containerdisk as first volume
- Adding a second blank volume with a size of `1Gi`
- The main user is named `myuser`
- Logins with the main user are possible with the specified authorized key
  in the access credentials

```shell
# First create the secret with the public key:
kubectl create secret generic my-keys --from-file=$HOME/.ssh/id_ed25519.pub

# Then create the VM on the cluster
virtctl create vm --name my-vm --instancetype=u1.small --preference=fedora \
  --volume-containerdisk=src:quay.io/containerdisks/fedora \
  --volume-import=type:blank,size:1Gi --user=myuser \
  --access-cred=src:my-keys | kubectl create -f -

# Login via SSH once the VM is ready
virtctl ssh -i $HOME/.ssh/id_ed25519 myuser@my-vm
```
