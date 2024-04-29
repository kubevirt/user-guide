# Resources requests and limits

In this document, we are talking about the resources values set on the virt-launcher compute container, referred to as "the container" below for simplicity.

## CPU

Note: dedicated CPUs (and isolated emulator thread) are ignored here as they have a [dedicated page](./dedicated_cpu_resources.md).

### CPU requests on the container
- By default, the container requests (1/cpuAllocationRatio) CPU per vCPU. The number of vCPUs is sockets*cores*threads, defaults to 1.
- cpuAllocationRatio defaults to 10 but can be changed in the CR.
- If a CPU limit is manually set on the VM(I) and no CPU request is, the CPU requests on the container will match the CPU limits
- Manually setting CPU requests on the VM(I) will override all of the above and be the CPU requests for the container

### CPU limits on the container
- By default, no CPU limit is set on the container
- If auto CPU limits is enabled (see next section), then the container will have a CPU limit of 1 per vCPU
- Manually setting CPU limits on the VM(I) will override all of the above and be the CPU limits for the container

### Auto CPU limits
KubeVirt provides two ways to automatically set CPU limits on VM(I)s:

- Enable the `AutoResourceLimitsGate` feature gate.
- Add the namespaceLabelSelector in the KubeVirt CR.

In both cases, the VM(I) created will have a CPU limit of 1 per vCPU.

#### AutoResourceLimitsGate feature gate
By enabling this feature gate, cpu limits will be added to the vmi if all the following conditions are true:

- The namespace where the VMI will be created has a ResourceQuota containing cpu limits.
- The VMI has no manually set cpu limits.
- The VMI is not requesting dedicated CPU.

#### autoCPULimitNamespaceLabelSelector configuration
Cluster admins can define a label selector in the KubeVirt CR.  
Once that label selector is defined, if the creation namespace matches the selector, all VM(I)s created in it will have a CPU limits set.

Example:

- CR:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    autoCPULimitNamespaceLabelSelector:
      matchLabels:
        autoCpuLimit: "true"
```

- Namespace:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    autoCpuLimit: "true"
    kubernetes.io/metadata.name: default
  name: default
```

## Memory
### Memory requests on the container
- VM(I)s must specify a desired amount of memory, in either spec.domain.memory.guest or spec.domain.resources.requests.memory (ignoring hugepages, see the [dedicated page](hugepages.md)). If both are set, the memory requests take precedence. A calculated amount of overhead will be added to it, forming the memory request value for the container.

### Memory limits on the container
- By default, no memory limit is set on the container
- If auto memory limits is enabled (see next section), then the container will have a limit of 2x the requested memory.
- Manually setting a memory limit on the VM(I) will set the same value on the container

#### Warnings
- Memory limits have to be more than memory requests + overhead, otherwise the container will have memory requests > limits and be rejected by Kubernetes.
- Memory usage bursts could lead to VM crashes when memory limits are set


### Auto memory limits
KubeVirt provides a feature gate(`AutoResourceLimitsGate`) to automatically set memory limits on VM(I)s.
By enabling this feature gate, memory limits will be added to the vmi if all the following conditions are true:

- The namespace where the VMI will be created has a ResourceQuota containing memory limits.
- The VMI has no manually set memory limits.
- The VMI is not requesting dedicated CPU.

If all the previous conditions are true, the memory limits will be set to a value (`2x`) of the memory requests.
This ratio can be adjusted, per namespace, by adding the annotation `alpha.kubevirt.io/auto-memory-limits-ratio`,
with the desired custom value.
For example, with `alpha.kubevirt.io/auto-memory-limits-ratio: 1.2`, the memory limits set will be equal to (`1.2x`) of the memory requests.
