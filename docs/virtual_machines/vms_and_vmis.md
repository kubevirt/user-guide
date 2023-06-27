# Virtual Machine types
There are two main virtual machine user facing API objects: a `VirtualMachine`,
and a `VirtualMachineInstance`.

## Virtual Machine Instance
A
[VirtualMachineInstance](https://kubevirt.io/user-guide/virtual_machines/virtual_machine_instances/)
represents a single **running** virtual machine.

It is encapsulated in a pod.

When used without a controlling VMI object, it should be limited to running
stateless workloads.

Removing the VMI object represents stopping the Virtual Machine.

## Virtual Machine
A [VirtualMachine](http://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine)
in the other hand, represents a VM that is not running or in a stopped state.

The `VirtualMachine` holds the template from which to create the VirtualMachineInstance.

By setting the 
[VM.Spec](http://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachinespec)
`running` property to `true`, the Virtual Machine is started (a corresponding
VMI object is created).

The status of a running VM should be retrieved from the associated VMI object,
since the VM object does not provide runtime status.

When the user deletes the associated VMI object, the KubeVirt controller just
schedules another VMI - since the user has declared (via the `running`
attribute) that the VM should be running.

## Feature matrix per workload type

|Feature name |Virtual Machine|Virtual Machine Instance|
|-------------|---------------|------------------------|
|LiveMigration|   supported   |      supported         |

TODO: does it makes sense to have a table here ?... 
