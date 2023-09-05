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
For namespaces that require automatic CPU limits on VM(I)s, a label selector can be defined in the KubeVirt CR.  
Once that label selector is defined, if a namespace matches the selector, all VM(I)s created in it will have a CPU limit of 1 per vCPU.

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
- VM(I)s must specify a desired amount of memory, in either spec.domain.memory.guest or spec.domain.resources.requests.memory (ignoring hugepages, see the [dedicated page](../operations/hugepages.md)). If both are set, the memory requests take precedence. A calculated amount of overhead will be added to it, forming the memory request value for the container.

### Memory limits on the container
- By default, no memory limit is set on the container
- Manually setting a memory limit on the VM(I) will set the same value on the container

#### Warnings
- Memory limits have to be more than memory requests + overhead, otherwise the container will have memory requests > limits and be rejected by Kubernetes.
- Memory usage bursts could lead to VM crashes when memory limits are set
