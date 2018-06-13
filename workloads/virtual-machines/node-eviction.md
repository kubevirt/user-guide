# VirtualMachineInstance Node Eviction

Before removing a kubernetes node from the cluster, users will want to ensure
that VirtualMachineInstances have been gracefully terminated before powering down the
node. Since all VirtualMachineInstances are backed by a Pod, the recommended method
of evicting VirtualMachineInstances is to use the **kubectl drain** command, or in the
case of OpenShift the **oc adm drain** command.

## How to Evict all VMs on a Node

Select the node you'd like to evict VirtualMachineInstances from by identifying the
node from the list of cluster nodes.

```kubectl get nodes```

The following command will gracefully terminate all VMs on a specific node.
Replace **<node name>** with the target node you want the eviction to occur on.

```kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher```

Below is a break down of why each argument passed to the drain command is
required.

- ```kubectl drain <node name>``` is selecting a specific node as a target for
the eviction

- ```--delete-local-data``` is a required flag that is necessary for removing
any pod that utilizes an emptyDir volume. The VirtualMachineInstance Pod does use
emptryDir volumes, however the data in those volumes are ephemeral which means
it is safe to delete after termination.

- ```--ignore-daemonsets=true``` is a required flag because every node running
a VirtualMachineInstance will also be running our helper DaemonSet called virt-handler.
DaemonSets are not allowed to be evicted using **kubectl drain**. By default,
if this command encounters a DaemonSet on the target node, the command will
fail. This flag tells the command it is safe to proceed with the eviction and
to just ignore DaemonSets.

- ```--force``` is a required flag because VirtualMachineInstance pods are not owned by
a ReplicaSet or DaemonSet controller. This means kubectl can't guarantee that
the pods being terminated on the target node will get re-scheduled replacements
placed else where in the cluster after the pods are evicted. KubeVirt has its
own controllers which manage the underlying VirtualMachineInstance pods. Each
controller behaves differently to a VirtualMachineInstance being evicted. That behavior
is outlined futher down in this document. 

- ```--pod-selector=kubevirt.io=virt-launcher``` means only VirtualMachineInstance pods
managed by KubeVirt will be removed from the node.

## How to Evict all VMs and Pods on a Node

By removing the **--pod-selector** argument from the previous command, we can
issue the eviction of all Pods on a node. This command ensures Pods
associated with VMs as well as all other Pods are evicted from the target node. 

```kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force```

## Re-enabling a Node after Eviction

The **kubectl drain** will result in the target node being marked as
unschedulable. This means the node will not be eligible for running new
VirtualMachineInstances or Pods.

If it is decided that the target node should become schedulable again, the
following command must be run.

```kubectl uncordon <node name>```

or in the case of OpenShift

```oc adm uncordon <node name```

## Shutting down a Node after Eviction

From KubeVirt's perspective, a node is safe to shutdown once all VirtualMachineInstances
have been evicted from the node. In a multi-use cluster where VirtualMachineInstances
are being scheduled along side other containerized workloads, it is up to the
cluster admin to ensure all other pods have been safely evicted before powering
down the node.

## VirtualMachine Evictions

The eviction of any VirtualMachineInstance that is owned by a VirtualMachine
set to **running=true** will result in the VirtualMachineInstance being re-scheduled to
another node.

The VirtualMachineInstance in this case will be forced to power down and restart on
another node. In the future once KubeVirt introduces live migration support,
the VM will be able to seamlessly migrate to another node during eviction.

## VirtualMachineInstanceReplicaSet Eviction Behavior

The eviction of VirtualMachineInstances owned by a VirtualMachineInstanceReplicaSet will result
in the VirtualMachineInstanceReplicaSet scheduling replacements for the evicted
VirtualMachineInstances on other nodes in the cluster.

## VirtualMachineInstance Eviction Behavior

VirtualMachineInstances not backed by either a VirtualMachineInstanceReplicaSet or an
VirtualMachine object will not be re-scheduled after eviction.


