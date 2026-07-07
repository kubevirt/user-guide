# Node maintenance

Before removing a kubernetes node from the cluster, users will want to
ensure that VirtualMachineInstances have been gracefully terminated
before powering down the node. Since all VirtualMachineInstances are
backed by a Pod, the recommended method of evicting
VirtualMachineInstances is to use the **kubectl drain** command, or in
the case of OKD the **oc adm drain** command.

## Evict all VMs from a Node

Select the node you'd like to evict VirtualMachineInstances from by
identifying the node from the list of cluster nodes.

`kubectl get nodes`

The following command will gracefully terminate all VMs on a specific
node. Replace `<node-name>` with the name of the node where the eviction should occur.

`kubectl drain <node-name> --delete-local-data --ignore-daemonsets=true --force --pod-selector=kubevirt.io=virt-launcher`

Below is a break down of why each argument passed to the drain command
is required.

-   `kubectl drain <node-name>` is selecting a specific node as a target
    for the eviction

-   `--delete-local-data` is a required flag that is necessary for
    removing any pod that utilizes an emptyDir volume. The
    VirtualMachineInstance Pod does use emptyDir volumes, however the
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
    kubectl can't guarantee that the pods being terminated on the target
    node will get re-scheduled replacements placed else where in the
    cluster after the pods are evicted. KubeVirt has its own controllers
    which manage the underlying VirtualMachineInstance pods. Each
    controller behaves differently to a VirtualMachineInstance being
    evicted. That behavior is outlined further down in this document.

-   `--pod-selector=kubevirt.io=virt-launcher` means only
    VirtualMachineInstance pods managed by KubeVirt will be removed from
    the node.

## Evict all VMs and Pods from a Node

By removing the `-pod-selector` argument from the previous command, we
can issue the eviction of all Pods on a node. This command ensures Pods
associated with VMs as well as all other Pods are evicted from the
target node.

`kubectl drain <node name> --delete-local-data --ignore-daemonsets=true --force`

## Evacuate VMIs via Live Migration from a Node

If the `LiveMigration`
[feature gate](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate)
is enabled, it is possible to
specify an `evictionStrategy` on VMIs which will react with live-migrations on
specific taints on nodes. The following snippet on a VMI or the VMI templates in
a VM ensures that the VMI is migrated during node eviction:

    spec:
      evictionStrategy: LiveMigrate

Here a full VMI:

```yaml
apiVersion: kubevirt.io/v1
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
```
Behind the scenes a **PodDisruptionBudget** is created for each VMI
which has an **evictionStrategy** defined. This ensures that evictions
are be blocked on these VMIs and that we can guarantee that a VMI will
be migrated instead of shut off.

**Note** Prior to v0.34 the drain process with live migrations was detached from
the `kubectl drain` itself and required in addition specifying a special taint
on the nodes: `kubectl taint nodes foo kubevirt.io/drain=draining:NoSchedule`.
This is no longer needed. The taint will still be respected if provided but is
**obsolete**.

## Re-enabling a Node after Eviction

The **kubectl drain** will result in the target node being marked as
unschedulable. This means the node will not be eligible for running new
VirtualMachineInstances or Pods.

If it is decided that the target node should become schedulable again,
the following command must be run.

`kubectl uncordon <node name>`

or in the case of OKD.

`oc adm uncordon <node name>`

## Shutting down a Node after Eviction

From KubeVirt's perspective, a node is safe to shutdown once all
VirtualMachineInstances have been evicted from the node. In a multi-use
cluster where VirtualMachineInstances are being scheduled alongside
other containerized workloads, it is up to the cluster admin to ensure
all other pods have been safely evicted before powering down the node.

## VirtualMachine Evictions

The eviction of any VirtualMachineInstance that is owned by a
VirtualMachine set to **running=true** will result in the
VirtualMachineInstance being re-scheduled to another node.

The VirtualMachineInstance in this case will be forced to power down and
restart on another node. In the future once KubeVirt introduces live
migration support, the VM will be able to seamlessly migrate to another
node during eviction.

### VirtualMachineInstanceReplicaSet Eviction Behavior

The eviction of VirtualMachineInstances owned by a
VirtualMachineInstanceReplicaSet will result in the
VirtualMachineInstanceReplicaSet scheduling replacements for the evicted
VirtualMachineInstances on other nodes in the cluster.

### VirtualMachineInstance Eviction Behavior

VirtualMachineInstances not backed by either a
VirtualMachineInstanceReplicaSet or an VirtualMachine object will not be
re-scheduled after eviction.

## Custom PodDisruptionBudgets for grouped VM workloads

When you define your own `PodDisruptionBudget` (PDB) to protect a group of VMs —
for example the `virt-launcher` pods backing a `VirtualMachinePool` — use
`spec.minAvailable`, not `spec.maxUnavailable`.

### Why `maxUnavailable` does not work

A `virt-launcher` pod is owned directly by a `VirtualMachineInstance` (VMI):

```
virt-launcher Pod  →  VirtualMachineInstance   (direct owner)
                   →  VirtualMachine
                   →  VirtualMachinePool
```

To honor `maxUnavailable`, the Kubernetes disruption controller must know the
expected number of pods, which it obtains by calling the `/scale` subresource on
the pod's direct owner — the `VirtualMachineInstance`. A VMI is a single,
non-replicated instance and does not implement `/scale`, so the controller cannot
compute the expected count:

```
Warning  CalculateExpectedPodCountFailed
  Failed to calculate the number of expected pods:
  virtualmachineinstances.kubevirt.io does not implement the scale subresource
```

The PDB then reports `status.expectedPods: 0`, `status.disruptionsAllowed: 0`, and
`DisruptionAllowed: False` — which blocks **every** drain or voluntary eviction, no
matter how many VMs are healthy.

Conversely, `spec.minAvailable` does not use the `/scale` subresource; it counts
the currently healthy matching pods directly and works correctly with KubeVirt
workloads.

!!! note
    This limitation is tracked in
    [kubevirt/kubevirt#18063](https://github.com/kubevirt/kubevirt/issues/18063). A
    long-term, platform-level fix is being pursued upstream in
    [kubernetes/kubernetes#139582](https://github.com/kubernetes/kubernetes/issues/139582)
    (teaching the disruption controller to traverse the owner chain to a scalable
    ancestor). Until that lands, prefer `minAvailable` as described below.

### Recommended configuration

Set `minAvailable` to the minimum number of instances your workload must keep
running during a disruption — the availability floor your application needs —
expressed as an **absolute integer**:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: vmpool-pdb
spec:
  minAvailable: 3            # keep at least 3 VMs of the pool running at all times
  selector:
    matchLabels:
      kubevirt.io/vmpool: my-pool   # match the virt-launcher pods of the pool
```

Choose the value from your application's real availability requirement, not as a
mechanical `replicas - 1`. A fixed `N-1` does not track the pool as it scales:
after an upscale it permits far more concurrent disruptions than intended, and
after a downscale it can block evictions entirely. Pick the actual minimum
capacity you need to preserve, and revisit it if you significantly resize the pool.

!!! warning
    Use an **absolute integer**, not a percentage. A percentage `minAvailable`
    (e.g. `minAvailable: 75%`) makes the disruption controller resolve the total
    replica count via the `/scale` subresource — which a `VirtualMachineInstance`
    does not implement — so it fails the same way as `maxUnavailable`. Only an
    integer `minAvailable` counts healthy pods directly and avoids the scale lookup.

Avoid `maxUnavailable` for VirtualMachineInstance-backed pods:

```yaml
spec:
  maxUnavailable: 1          # results in disruptionsAllowed: 0 (see above)
```

!!! note
    You can use `spec.maxUnavailable` on the `VirtualMachinePool` object itself as
    it is read directly by the VMPool controller. The limitation above applies only
    to a `PodDisruptionBudget`'s `maxUnavailable` field.

### Verifying

```console
$ kubectl get pdb vmpool-pdb -o wide
NAME         MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
vmpool-pdb   1               N/A               1                     2m
```

`ALLOWED DISRUPTIONS` should be `>= 1`. If you see `0` together with a
`CalculateExpectedPodCountFailed` event, the PDB is using `maxUnavailable` — switch
it to `minAvailable`.
