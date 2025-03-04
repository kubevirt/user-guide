# VM Rollout Strategies

In KubeVirt, the VM rollout strategy defines how changes to a VM object affect a running guest.  
In other words, it defines when and how changes to a VM object get propagated to its corresponding VMI object.

There are currently 2 rollout strategies: `LiveUpdate` and `Stage`.
Only 1 can be specified and the default is `Stage`.

## LiveUpdate

The `LiveUpdate` VM rollout strategy tries to propagate VM object changes to running VMIs as soon as possible.  
For example, changing the number of CPU sockets will trigger a [CPU hotplug](../compute/cpu_hotplug.md).

Enable the `LiveUpdate` VM rollout strategy in the KubeVirt CR:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    vmRolloutStrategy: "LiveUpdate"
```

## Stage

The `Stage` VM rollout strategy stages every change made to the VM object until its next reboot.  

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    vmRolloutStrategy: "Stage"
```

## RestartRequired condition

Any change made to a VM object when the rollout strategy is `Stage` will trigger the `RestartRequired` VM condition.  
When the rollout strategy is `LiveUpdate`, only non-propagatable changes will trigger the condition.

Once the `RestartRequired` condition is set on a VM object, no further changes can be propagated, even if the strategy is set to `LiveUpdate`.  
Changes will become effective on next reboot, and the condition will be removed.

## Limitations

The current implementation has the following limitations:

- Once the `RestartRequired` condition is set, the only way to get rid of it is to restart the VM. In the future, we plan on implementing a way to get rid of it by reverting the VM template spec to its last non-RestartRequired state.
- Cluster defaults are excluded from this logic. It means that changing a cluster-wide setting that impacts VM specs will not be live-updated, regardless of the rollout strategy.
- The `RestartRequired` condition comes with a message stating what kind of change triggered the condition (CPU/memory/other). That message pertains only to the first change that triggered the condition. Additional changes that would usually trigger the condition will just get staged and no additional `RestartRequired` condition will be added.
