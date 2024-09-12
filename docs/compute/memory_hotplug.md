# Memory Hotplug

Memory hotplug was introduced in KubeVirt version 1.1, enabling the dynamic resizing of the amount of memory available to a running VM.

## Limitations
* Memory hotplug is currently only supported on the x86_64,arm64 architectures.
* Linux guests running at least Linux v5.8 are fully supported.
* Windows guests support has been added to virtio-win, but it should be considered unstable.
* Current hotplug implementation involves live-migration of the VM workload.
* VirtualMachines must have at least 1GiB of memory to support memory-hotplug.


# Configuration

### Enable feature-gate

To use memory hotplug we need to add the `VMLiveUpdateFeatures` feature gate in the KubeVirt CR:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - VMLiveUpdateFeatures
```

### Configure the Workload Update Strategy

Configure `LiveMigrate` as `workloadUpdateStrategy` in the KubeVirt CR, since the current implementation of the hotplug process requires the VM to live-migrate.

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  workloadUpdateStrategy:
    workloadUpdateMethods:
    - LiveMigrate
```

### Configure the VM rollout strategy

Finally, set the VM rollout strategy to `LiveUpdate`, so that the changes made to the VM object propagate to the VMI without a restart.  
This is also done in the KubeVirt CR configuration:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    vmRolloutStrategy: "LiveUpdate"
```

**NOTE:** If memory hotplug is enabled/disabled on an already running VM, a reboot is necessary for the changes to take effect.

More information can be found on the [VM Rollout Strategies](../user_workloads/vm_rollout_strategies.md) page.

### [OPTIONAL] Set a cluster-wide maximum amount of memory

You can set the maximum amount of memory for the guest using a cluster level setting in the KubeVirt CR.

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    liveUpdateConfiguration:
      maxGuest: 8Gi
```

The VM-level configuration will take precedence over the cluster-wide one.

## Memory Hotplug in Action

First we enable the `VMLiveUpdateFeatures` feature gate, set the rollout strategy to `LiveUpdate` and set `LiveMigrate` as `workloadUpdateStrategy` in the KubeVirt CR.

```sh
$ kubectl --namespace kubevirt patch kv kubevirt -p='[{"op": "add", "path": "/spec/configuration/developerConfiguration/featureGates", "value": ["VMLiveUpdateFeatures"]}]' --type='json'
$ kubectl --namespace kubevirt patch kv kubevirt -p='[{"op": "add", "path": "/spec/configuration/vmRolloutStrategy", "value": "LiveUpdate"}]' --type='json'
$ kubectl --namespace kubevirt patch kv kubevirt -p='[{"op": "add", "path": "/spec/workloadUpdateStrategy/workloadUpdateMethods", "value": ["LiveMigrate"]}]' --type='json'
```

Now we create a VM with memory hotplug enabled.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-alpine
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        memory:
          guest: 1Gi
        devices:
          interfaces:
            - masquerade: {}
              model: virtio
              name: default
          disks:
          - disk:
              bus: virtio
            name: containerdisk
      networks:
        - name: default
          pod: {}
      volumes:
      - containerDisk:
          image: registry:5000/kubevirt/alpine-container-disk-demo:devel
        name: containerdisk
```

The Virtual Machine will automatically start and once booted it will report the currently available memory to the guest in the `status.memory` field inside the VMI.

```sh
$ kubectl get vmi vm-cirros -o json | jq .status.memory
```
```json
{
  "guestAtBoot": "1Gi",
  "guestCurrent": "1Gi",
  "guestRequested": "1Gi"
}
```

Since the Virtual Machine is now running we can patch the VM object to double the available guest memory so that we'll go from 1Gi to 2Gi.

```sh
$ kubectl patch vm vm-cirros -p='[{"op": "replace", "path": "/spec/template/spec/domain/memory/guest", "value": "2Gi"}]' --type='json'
```

After the hotplug request is processed and the Virtual Machine is live migrated, the new amount of memory should be available to the guest
and visible in the VMI object.

```sh
$ kubectl get vmi vm-cirros -o json | jq .status.memory
```
```json
{
  "guestAtBoot": "1Gi",
  "guestCurrent": "2Gi",
  "guestRequested": "2Gi"
}
```
