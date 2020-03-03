Life-cycle
==========

Every `VirtualMachineInstance` represents a single virtual machine
*instance*. In general, the management of VirtualMachineInstances is
kept similar to how `Pods` are managed: Every VM that is defined in the
cluster is expected to be running, just like Pods. Deleting a
VirtualMachineInstance is equivalent to shutting it down, this is also
equivalent to how Pods behave.

FIXME needs to be reworked.

Overview
--------

Launching a virtual machine
---------------------------

In order to start a VirtualMachineInstance, you just need to create a
`VirtualMachineInstance` object using `kubectl`:

    $ kubectl create -f vmi.yaml

Listing virtual machines
------------------------

VirtualMachineInstances can be listed by querying for
VirtualMachineInstance objects:

    $ kubectl get vmis

Retrieving a virtual machine definition
---------------------------------------

A single VirtualMachineInstance definition can be retrieved by getting
the specific VirtualMachineInstance object:

    $ kubectl get vmis testvmi

Stopping a virtual machine
--------------------------

To stop the VirtualMachineInstance, you just need to delete the
corresponding `VirtualMachineInstance` object using `kubectl`.

    $ kubectl delete -f vmi.yaml
    # OR
    $ kubectl delete vmis testvmi

> Note: Stopping a VirtualMachineInstance implies that it will be
> deleted from the cluster. You will not be able to start this
> VirtualMachineInstance object again.
