# Lifecycle

Every `VirtualMachineInstance` represents a single virtual machine
*instance*. In general, the management of VirtualMachineInstances is
kept similar to how `Pods` are managed: Every VM that is defined in the
cluster is expected to be running, just like Pods. Deleting a
VirtualMachineInstance is equivalent to shutting it down, this is also
equivalent to how Pods behave.


## Launching a virtual machine

In order to start a VirtualMachineInstance, you just need to create a
`VirtualMachineInstance` object using `kubectl`:

    $ kubectl create -f vmi.yaml


## Listing virtual machines

VirtualMachineInstances can be listed by querying for
VirtualMachineInstance objects:

    $ kubectl get vmis


## Retrieving a virtual machine instance definition

A single VirtualMachineInstance definition can be retrieved by getting
the specific VirtualMachineInstance object:

    $ kubectl get vmis testvmi


## Stopping a virtual machine instance

To stop the VirtualMachineInstance, you just need to delete the
corresponding `VirtualMachineInstance` object using `kubectl`.

    $ kubectl delete -f vmi.yaml
    # OR
    $ kubectl delete vmis testvmi

> **Note:** Stopping a VirtualMachineInstance implies that it will be
> deleted from the cluster. You will not be able to start this
> VirtualMachineInstance object again.

## Starting and stopping a virtual machine

Virtual machines, in contrast to VirtualMachineInstances, have a running state. Thus on VM you can define if it
should be running, or not. VirtualMachineInstances are, if they are defined in the cluster, always running and consuming resources.

`virtctl` is used in order to start and stop a VirtualMachine:

    $ virtctl start my-vm
    $ virtctl stop my-vm
    
> **Note:** You can force stop a VM (which is like pulling the power cord,
> with all its implications like data inconsistencies or
> [in the worst case] data loss) by

    $ virtctl stop my-vm --grace-period 0 --force

## Pausing and unpausing a virtual machine

> **Note:** Pausing in this context refers to libvirt's `virDomainSuspend` command:  
> "The process is frozen without further access to CPU resources and I/O but the memory used by the domain at the hypervisor level will stay allocated"

To pause a virtual machine, you need the `virtctl` command line tool. Its `pause` command works on either `VirtualMachine` s
or `VirtualMachinesInstance` s:

    $ virtctl pause vm testvm
    # OR
    $ virtctl pause vmi testvm

Paused VMIs have a `Paused` condition in their status:

    $ kubectl get vmi testvm -o=jsonpath='{.status.conditions[?(@.type=="Paused")].message}'
    VMI was paused by user

Unpausing works similar to pausing:

    $ virtctl unpause vm testvm
    # OR
    $ virtctl unpause vmi testvm


## Renaming a Virtual Machine

> **Note:** Renaming a Virtual Machine is only possible when a Virtual Machine
> is stopped, or has a 'Halted' run strategy.

    $ virtctl rename vm_name new_vm_name
