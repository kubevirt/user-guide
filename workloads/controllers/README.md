# Controllers

Controllers provide the logic to manage virtual machine instances in a way that
addresses specific use-cases:

 * [VirtualMachineInstanceReplicaSet](workloads/controllers/virtual-machine-replica-set): Replicating stateless Virtual Machines.
 * [VirtualMachine](workloads/controllers/virtual-machine): Stateful Virtual Machine, similar to a StatefulSet with replicas set to 1.
