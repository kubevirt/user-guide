# NUMA

**FEATURE STATE:** KubeVirt v0.43

NUMA support in KubeVirt is at this stage limited to a small set of special
use-cases and will improve over time together with improvements made to
Kubernetes.

In general, the goal is to map the host NUMA topology as efficiently as possible
to the Virtual Machine topology to improve the performance.

The following NUMA mapping strategies can be used:

- [**GuestMappingPassthrough**](#GuestMappingPassthrough)

## Preconditions

In order to use current NUMA support, the following preconditions must be met:

* [Dedicated CPU Resources](dedicated_cpu_resources.md) must be configured.
* [Hugepages](virtual_hardware.md#Hugepages) need to be allocatable on target
  nodes.
* The `NUMA`
  [feature gate](../operations/activating_feature_gates.md#how-to-activate-a-feature-gate)
  must be enabled.

## GuestMappingPassthrough

GuestMappingPassthrough will pass through the node numa topology to the guest.
The topology is based on the dedicated CPUs which the VMI got assigned from the
kubelet via the CPU Manager. It can be requested by
setting `spec.domain.cpu.guestMappingPassthrough` on the VMI.

Since KubeVirt does not know upfront which exclusive CPUs the VMI will get from
the kubelet, there are some limitations:

* Guests may see different NUMA topologies when being rescheduled.
* The resulting NUMA topology may be asymmetrical.
* The VMI may fail to start on the node if not enough hugepages are available on
  the assigned NUMA nodes.

While this NUMA modelling strategy has its limitations, aligning the guest's
NUMA architecture with the node's can be critical for high-performance
applications.

An example VMI may look like this:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: numavm
spec:
  domain:
    cpu:
      cores: 4
      dedicatedCpuPlacement: true
      numa:
        guestMappingPassthrough: { }
    devices:
      disks:
        - disk:
            bus: virtio
          name: containerdisk
        - disk:
            bus: virtio
          name: cloudinitdisk
    resources:
      requests:
        memory: 64Mi
    memory:
      hugepages:
        pageSize: 2Mi
  volumes:
    - containerDisk:
        image: quay.io/kubevirt/cirros-container-disk-demo
      name: containerdisk
    - cloudInitNoCloud:
        userData: |
          #!/bin/sh
          echo 'printed from cloud-init userdata'
      name: cloudinitdisk
```