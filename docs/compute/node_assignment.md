# Node assignment

You can constrain the VM to only run on specific nodes or to prefer
running on specific nodes:

-   **nodeSelector**
-   **Affinity and anti-affinity**
-   **Taints and Tolerations**


## nodeSelector

Setting `spec.nodeSelector` requirements, constrains the scheduler to
only schedule VMs on nodes, which contain the specified labels. In the
following example the vmi contains the labels `cpu: slow` and
`storage: fast`:

```yaml
metadata:
  name: testvmi-ephemeral
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  nodeSelector:
    cpu: slow
    storage: fast
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        lun: {}
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

Thus the scheduler will only schedule the vmi to nodes which contain
these labels in their metadata. It works exactly like the Pods
`nodeSelector`. See the [Pod nodeSelector
Documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
for more examples.


## Affinity and anti-affinity

The `spec.affinity` field allows specifying hard- and soft-affinity for
VMs. It is possible to write matching rules against workloads (VMs and
Pods) and Nodes. Since VMs are a workload type based on Pods,
Pod-affinity affects VMs as well.

An example for `podAffinity` and `podAntiAffinity` may look like this:

```yaml
metadata:
  name: testvmi-ephemeral
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  nodeSelector:
    cpu: slow
    storage: fast
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        lun: {}
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: failure-domain.beta.kubernetes.io/zone
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: kubernetes.io/hostname
  volumes:
    - name: mypvcdisk
      persistentVolumeClaim:
        claimName: mypvc
```

Affinity and anti-affinity works exactly like the Pods `affinity`. This
includes `podAffinity`, `podAntiAffinity`, `nodeAffinity` and
`nodeAntiAffinity`. See the [Pod affinity and anti-affinity
Documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)
for more examples and details.


## Taints and Tolerations

Affinity as described above, is a property of VMs that attracts them to
a set of nodes (either as a preference or a hard requirement). Taints
are the opposite - they allow a node to repel a set of VMs.

Taints and tolerations work together to ensure that VMs are not
scheduled onto inappropriate nodes. One or more taints are applied to a
node; this marks that the node should not accept any VMs that do not
tolerate the taints. Tolerations are applied to VMs, and allow (but do
not require) the VMs to schedule onto nodes with matching taints.

You add a taint to a node using kubectl taint. For example,

    kubectl taint nodes node1 key=value:NoSchedule

An example for `tolerations` may look like this:

```yaml
metadata:
  name: testvmi-ephemeral
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
spec:
  nodeSelector:
    cpu: slow
    storage: fast
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        lun: {}
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```
## Node balancing with Descheduler

In some cases we might need to rebalance the cluster on current scheduling policy
and load conditions. [Descheduler](https://github.com/kubernetes-sigs/descheduler)
can find pods, which violates e.g. scheduling decisions and evict them based on descheduler
policies. Kubevirt VMs are handled as pods with local storage, so by default,
descheduler will not evict them. But it can be easily overridden by adding special
annotation to the VMI template in the VM:

```console
spec:
  template:
    metadata:
      annotations:
        descheduler.alpha.kubernetes.io/evict: true
```

This annotation will cause, that the descheduler will be able to evict the VM's pod which can then be
scheduled by scheduler on different nodes. A VirtualMachine will never restart or re-create a
VirtualMachineInstance until the current instance of the VirtualMachineInstance is deleted from the cluster.

## Live update


When the [VM rollout strategy](../user_workloads/vm_rollout_strategies.md) is set to `LiveUpdate`, changes to a VM's node selector, affinities, and tolerations will dynamically propagate to the VMI (unless the `RestartRequired` condition is set).

**Current behavior:**
- Changes to tolerations are now supported for live update and will be applied to the running VMI without requiring a restart, as long as the `RestartRequired` condition is not set.

Modifications of the node selector / affinities / tolerations will only take effect on next [migration](live_migration.md); the change alone will not trigger one.

Modifications of the node selector / affinities will only take effect on next [migration](live_migration.md), the change
alone will not trigger one.
