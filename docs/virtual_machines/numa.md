# NUMA

**FEATURE STATE:** KubeVirt v0.43

## Predonditions

In order to use current NUMA support, three preconditions must be met:
[Dedicated CPU Resources](dedicated_cpu_resources.md) must be
configured, [Hugepages](virtual_hardware.md#Hugepages) need to be allocatable on
target nodes and the `NUMA`
[feature gate](../operations/activating_feature_gates.md#how-to-activate-a-feature-gate)
must be enabled.

## GuestMappingPassthrough

GuestMappingPassthrough will pass through the node numa topology to the guest.
The topology is based on the dedicated CPUs which the VMI got assigned from the
kubelet via the CPU Manager. It can be requested by
setting `spec.domain.cpu.guesstMappingPassthrough`.

Since KubeVirt does not know upfront which exclusive CPUs the VMI will get from
the kubelet, guests may see different NUMA topologies when being rescheduled.
Further the resulting NUMA topology may be asymmetrical. Finally the VMI may
fail to start on the node if not enough hugepages are available on the assigned
NUMA nodes.

While the NUMA modelling strategy has its limitations, for high-performance
applications aligning the guest NUMA architecture with the node can be critical.

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
        guestMappingPassthrough : {}
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