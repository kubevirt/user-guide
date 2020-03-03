VirtualMachineInstance Node Eviction
====================================

Before removing a kubernetes node from the cluster, users will want to
ensure that VirtualMachineInstances have been gracefully terminated
before powering down the node. Since all VirtualMachineInstances are
backed by a Pod, the recommended method of evicting
VirtualMachineInstances is to use the **kubectl drain** command, or in
the case of OKD the **oc adm drain** command.

How to Evict all VMs on a Node
------------------------------

Select the node you’d like to evict VirtualMachineInstances from by
identifying the node from the list of cluster nodes.

`kubectl get nodes`

The following command will gracefully terminate all VMs on a specific
node. Replace \*\* with the target node you want the eviction to occur
on.

`kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher`

Below is a break down of why each argument passed to the drain command
is required.

-   `kubectl drain <node name>` is selecting a specific node as a target
    for the eviction

-   `--delete-local-data` is a required flag that is necessary for
    removing any pod that utilizes an emptyDir volume. The
    VirtualMachineInstance Pod does use emptryDir volumes, however the
    data in those volumes are ephemeral which means it is safe to delete
    after termination.

-   `--ignore-daemonsets=true` is a required flag because every node
    running a VirtualMachineInstance will also be running our helper
    DaemonSet called virt-handler. DaemonSets are not allowed to be
    evicted using **kubectl drain**. By default, if this command
    encounters a DaemonSet on the target node, the command will fail.
    This flag tells the command it is safe to proceed with the eviction
    and to just ignore DaemonSets.

-   `--force` is a required flag because VirtualMachineInstance pods are
    not owned by a ReplicaSet or DaemonSet controller. This means
    kubectl can’t guarantee that the pods being terminated on the target
    node will get re-scheduled replacements placed else where in the
    cluster after the pods are evicted. KubeVirt has its own controllers
    which manage the underlying VirtualMachineInstance pods. Each
    controller behaves differently to a VirtualMachineInstance being
    evicted. That behavior is outlined futher down in this document.

-   `--pod-selector=kubevirt.io=virt-launcher` means only
    VirtualMachineInstance pods managed by KubeVirt will be removed from
    the node.

How to Evict all VMs and Pods on a Node
---------------------------------------

By removing the **–pod-selector** argument from the previous command, we
can issue the eviction of all Pods on a node. This command ensures Pods
associated with VMs as well as all other Pods are evicted from the
target node.

`kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force`

How to evacuate VMIs via Live Migration from a Node
---------------------------------------------------

If the **LiveMigration** feature gate is enabled, it is possible to
specify an `evictionStrategy` on VMIs which will react with
live-migrations on specific taints on nodes. The following snipped on a
VMI ensures that the VMI is migrated if the
`kubevirt.io/drain:NoSchedule` taint is added to a nodes:

    spec:
      evictionStrategy: LiveMigrate

Here a full VMI:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: testvmi-nocloud
    spec:
      terminationGracePeriodSeconds: 30
      evictionStrategy: LiveMigrate
      domain:
        resources:
          requests:
            memory: 1024M
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - disk:
              bus: virtio
            name: cloudinitdisk
      volumes:
      - name: containerdisk
        containerDisk:
          image: kubevirt/fedora-cloud-container-disk-demo:latest
      - name: cloudinitdisk
        cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }

Once the VMI is created, taint the node with

    kubectl taint nodes foo kubevirt.io/drain=draining:NoSchedule

which will trigger a migration.

Behind the scenes a **PodDisruptionBudget** is created for each VMI
which has an **evictionStrategy** defined. This ensures that evictions
are be blocked on these VMIs and that we can guarantee that a VMI will
be migrated instead of shut off.

**Note:** While the **evictionStrategy** blocks the shutdown of VMIs
during evictions, the live migration process is detached from the drain
process itselve. Therefore it is necessary to add specified taints as
part of the drain process explicitly, until we have a better integrated
solution.

By default KubeVirt will rewact with live migrations if the taint
`kubevirt.io/drain:NoSchedule` is added to the node. It is possible to
configure a different key in the `kubevirt-config` config map, by
setting in the migration options the `nodeDrainTaintKey`:

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      feature-gates: "LiveMigration"
      migrations: |-
        nodeDrainTaintKey: mytaint/drain

The default value is `kubevirt.io/drain`. With the change above
migrations can be triggered with

    kubectl taint nodes foo mytaint/drain=draining:NoSchedule

Here a full drain flow for nodes which includes VMI live migrations with
the default setting:

    kubectl taint nodes foo kubevirt.io/drain=draining:NoSchedule
    kubectl drain foo --delete-local-data --ignore-daemonsets=true --force

To make the node schedulable again, run

    kubectl taint nodes foo kubevirt.io/drain-
    kubectl uncordon foo

Re-enabling a Node after Eviction
---------------------------------

The **kubectl drain** will result in the target node being marked as
unschedulable. This means the node will not be eligible for running new
VirtualMachineInstances or Pods.

If it is decided that the target node should become schedulable again,
the following command must be run.

`kubectl uncordon <node name>`

or in the case of OKD.

`oc adm uncordon <node name>`

Shutting down a Node after Eviction
-----------------------------------

From KubeVirt’s perspective, a node is safe to shutdown once all
VirtualMachineInstances have been evicted from the node. In a multi-use
cluster where VirtualMachineInstances are being scheduled along side
other containerized workloads, it is up to the cluster admin to ensure
all other pods have been safely evicted before powering down the node.

VirtualMachine Evictions
------------------------

The eviction of any VirtualMachineInstance that is owned by a
VirtualMachine set to **running=true** will result in the
VirtualMachineInstance being re-scheduled to another node.

The VirtualMachineInstance in this case will be forced to power down and
restart on another node. In the future once KubeVirt introduces live
migration support, the VM will be able to seamlessly migrate to another
node during eviction.

VirtualMachineInstanceReplicaSet Eviction Behavior
--------------------------------------------------

The eviction of VirtualMachineInstances owned by a
VirtualMachineInstanceReplicaSet will result in the
VirtualMachineInstanceReplicaSet scheduling replacements for the evicted
VirtualMachineInstances on other nodes in the cluster.

VirtualMachineInstance Eviction Behavior
----------------------------------------

VirtualMachineInstances not backed by either a
VirtualMachineInstanceReplicaSet or an VirtualMachine object will not be
re-scheduled after eviction.
