# CPU Hotplug

The CPU hotplug feature was introduced in KubeVirt v1.0, making it possible to configure the VM workload
to allow for adding or removing virtual CPUs while the VM is running.

### Abstract
A **virtual CPU** (vCPU) is the CPU that is seen to the Guest VM OS. A VM owner can manage the amount of vCPUs from the VM spec template using the CPU topology fields (`spec.template.spec.domain.cpu`). The `cpu` object has the integers `cores,sockets,threads` so that the virtual CPU is calculated by the following formula: `cores * sockets * threads`. 

Before CPU hotplug was introduced, the VM owner could change these integers in the VM template while the VM is running, and they were staged until the next boot cycle. With CPU hotplug, it is possible to patch the `sockets` integer in the VM template and the change will take effect right away. 

Per each new socket that is hot-plugged, the amount of new vCPUs that would be seen by the guest is `cores * threads`, since the overall calculation of vCPUs is `cores * sockets * threads`. 

## Configuration

### Configure the workload update strategy
Current implementation of the hotplug process requires the VM to live-migrate.
The migration will be triggered automatically by the workload updater. The workload update strategy in the KubeVirt CR must be configured with `LiveMigrate`, as follows:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  workloadUpdateStrategy:
    workloadUpdateMethods:
    - LiveMigrate
```

### Configure the VM rollout strategy
Hotplug requires a VM rollout strategy of `LiveUpdate`, so that the changes made to the VM object propagate to the VMI without a restart.
This is also done in the KubeVirt CR configuration:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    vmRolloutStrategy: "LiveUpdate"
```

More information can be found on the [VM Rollout Strategies](../user_workloads/vm_rollout_strategies.md) page

### [OPTIONAL] Set maximum sockets or hotplug ratio
You can explicitly set the maximum amount of sockets in three ways:

1. with a value VM level
2. with a value at the cluster level
3. with a ratio at the cluster level (`maxSockets = ratio * sockets`).

Note: the third way (cluster-level ratio) will also affect other quantitative hotplug resources like memory.


<table style="width: 100% ; display: inline-table">
<tr>
<th>
<p>
VM level
</p>
</th> 
<th>
<p>
Cluster level value
</p>
</th>
<th>
<p>
Cluster level ratio
</p>
</th>
</tr>
<tr>
<td>

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        cpu:
          maxSockets: 8
```
</td>
<td>

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    liveUpdateConfiguration:
      maxCpuSockets: 8
```

</td>

<td>

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    liveUpdateConfiguration:
      maxHotplugRatio: 4
```

</td>
</tr>
</table>

The VM-level configuration will take precedence over the cluster-wide configuration.



## Hotplug process
Let's assume we have a running VM with the 4 vCPUs, which were configured with `sockets:4 cores:1 threads:1`
In the VMI status we can observe the current CPU topology the VM is running with:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
...
status:
  currentCPUTopology:
    cores: 1
    sockets: 4
    threads: 1
```
Now we want to hotplug another socket, by patching the VM object:

```
kubectl patch vm vm-cirros --type='json' \
-p='[{"op": "replace", "path": "/spec/template/spec/domain/cpu/sockets", "value": 5}]'
```
We can observe the CPU hotplug process in the VMI status:

```yaml
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: null
    status: "True"
    type: LiveMigratable
  - lastProbeTime: null
    lastTransitionTime: null
    status: "True"
    type: HotVCPUChange
  currentCPUTopology:
    cores: 1
    sockets: 4
    threads: 1
```

Please note the condition `HotVCPUChange` that indicates the hotplug process is taking place.
Also you can notice the VirtualMachineInstanceMigration object that was created for the VM in subject:

```
NAME                             PHASE     VMI
kubevirt-workload-update-kflnl   Running   vm-cirros
```
When the hotplug process has completed, the `currentCPUTopology` will be updated with the new number of sockets and the migration
is marked as successful.

```yaml
#kubectl get vmi vm-cirros -oyaml

apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: vm-cirros
spec:
  domain:
    cpu:
      cores: 1
      sockets: 5
      threads: 1
...
...
status:
  currentCPUTopology:
    cores: 1
    sockets: 5
    threads: 1


#kubectl get vmim -l kubevirt.io/vmi-name=vm-cirros
NAME                             PHASE       VMI
kubevirt-workload-update-cgdgd   Succeeded   vm-cirros
```
  
## Limitations
* VPCU hotplug is currently not supported by ARM64 architecture.
* Current hotplug implementation involves live-migration of the VM workload.

