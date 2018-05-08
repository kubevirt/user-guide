# Controllers

Controllers provide the logic to manage virtual machine instances in a way that
addresses specific use-cases:

 * [VirtualMachineReplicaSet](workloads/controllers/virtual-machine-replica-set): Replicating stateless Virtual Machines.
 * [OfflineVirtualMachine](workloads/controllers/offline-virtual-machine): Stateful Virtual Machine, similar to a StatefulSet with replicas set to 1.
