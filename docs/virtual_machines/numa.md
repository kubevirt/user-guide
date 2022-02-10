# NUMA

**FEATURE STATE:** KubeVirt v0.43

NUMA support in KubeVirt is at this stage limited to a small set of special
use-cases and will improve over time together with improvements made to
Kubernetes.

In general, the goal is to map the host NUMA topology as efficiently as possible
to the Virtual Machine topology to improve the performance.

The following NUMA mapping strategies can be used:

- [**GuestMappingPassthrough**](#guestmappingpassthrough)

## Preconditions

In order to use current NUMA support, the following preconditions must be met:

* [Dedicated CPU Resources](dedicated_cpu_resources.md) must be configured.
* [Hugepages](virtual_hardware.md#hugepages) need to be allocatable on target
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


## Running real-time workloads

### Overview

It is possible to deploy Virtual Machines that run a real-time kernel and make use of [libvirtd's guest cpu and memory optimizations](https://www.libvirt.org/kbase/kvm-realtime.html) that improve the overall latency. These changes leverage mostly on already available settings in KubeVirt, as we will see shortly, but the VMI manifest now exposes two new settings that instruct KubeVirt to configure the generated libvirt XML with the recommended tuning settings for running real-time workloads.

To make use of the optimized settings, two new settings have been added to the VMI schema:

- `spec.domain.cpu.realtime`: When defined, it instructs KubeVirt to configure the linux scheduler for the VCPUS to run processes in FIFO scheduling policy (SCHED_FIFO) with priority 1. This setting guarantees that all processes running in the host will be executed with real-time priority.

- `spec.domain.cpu.realtime.mask`: It defines which VCPUs assigned to the VM are used for real-time. If not defined, libvirt will define all VCPUS assigned to run processes in FIFO scheduling and in the highest priority (1).

### Preconditions

A prerequisite to running real-time workloads include locking resources in the cluster to allow the real-time VM exclusive usage. This translates into nodes, or node, that have been configured with a [dedicated set of CPUs](https://github.com/kubevirt/user-guide/blob/main/docs/virtual_machines/dedicated_cpu_resources.md) and also provides support for [NUMA](https://github.com/kubevirt/user-guide/blob/main/docs/virtual_machines/numa.md) with a free number of hugepages of 2Mi or 1Gi size (depending on the configuration in the VMI). Additionally, the node must be configured to allow the scheduler to run processes with real-time policy.

### Nodes capable of running real-time workloads

When the KubeVirt pods are deployed in a node, it will check if it is capable of running processes in real-time scheduling policy and label the node as real-time capable (kubevirt.io/realtime). If, on the other hand, the node is not able to deliver such capability, the label is not applied. To check which nodes are able to host real-time VM workloads run this command:

```bash
$>kubectl get nodes -l kubevirt.io/realtime
NAME         STATUS   ROLES              AGE    VERSION
worker-0-0   Ready    worker             12d    v1.20.0+df9c838
```

Internally, the KubeVirt pod running in each node checks if the kernel setting `kernel.sched_rt_runtime_us` equals to -1, which grants processes to run in real-time scheduling policy for an unlimited amount of time.

### Configuring a VM Manifest

Here is an example of a VM manifest that runs a custom fedora container disk configured to run with a real-time kernel. The settings have been configured for optimal efficiency.


```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: fedora-realtime
  name: fedora-realtime
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: fedora-realtime
    spec:
      domain:
        devices:
          autoattachSerialConsole: true
          autoattachMemBalloon: false
          autoattachGraphicsDevice: false
          disks:
          - disk:
              bus: virtio
            name: containerdisk 
          - disk:
              bus: virtio
            name: cloudinitdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 1Gi
            cpu: 2
          limits:
            memory: 1Gi
            cpu: 2
        cpu:
          model: host-passthrough
          dedicatedCpuPlacement: true
          isolateEmulatorThread: true
          ioThreadsPolicy: auto
          features:
            - name: tsc-deadline
              policy: require
          numa:
            guestMappingPassthrough: {}
          realtime: {}
        memory:
          hugepages:
            pageSize: 1Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-realtime-container-disk:v20211008-22109a3
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
            bootcmd:
              - tuned-adm profile realtime
        name: cloudinitdisk
```

Breaking down the tuned sections, we have the following configuration:

[Devices](https://libvirt.org/kbase/kvm-realtime.html#device-configuration): 
- Disable the guest's memory balloon capability
- Avoid attaching a graphics device, to reduce the number of interrupts to the kernel.

```yaml
    spec:
      domain:
        devices:
          autoattachSerialConsole: true
          autoattachMemBalloon: false
          autoattachGraphicsDevice: false
```


[CPU](https://libvirt.org/kbase/kvm-realtime.html#cpu-configuration):
- model: `host-passthrough` to allow the guest to see host CPU without masking any capability.
- dedicated CPU Placement: The VM needs to have dedicated CPUs assigned to it. The Kubernetes CPU Manager takes care of this aspect.
- isolatedEmulatorThread: to request an additional CPU to run the emulator on it, thus avoid using CPU cycles from the workload CPUs.
- ioThreadsPolicy: Set to auto to let the dedicated IO thread to run in the same CPU as the emulator thread.
- NUMA: defining `guestMappingPassthrough` enables NUMA support for this VM.
- realtime: instructs the virt-handler to configure this VM for real-time workloads, such as configuring the VCPUS to use FIFO scheduler policy and set priority to 1.
cpu:
```yaml
        cpu:
          model: host-passthrough
          dedicatedCpuPlacement: true
          isolateEmulatorThread: true
          ioThreadsPolicy: auto
          features:
            - name: tsc-deadline
              policy: require
          numa:
            guestMappingPassthrough: {}
          realtime: {}
```

[Memory](https://libvirt.org/kbase/kvm-realtime.html#memory-configuration)
- pageSize: allocate the pod's memory in hugepages of the given size, in this case of 1Gi.
```yaml
        memory:
          hugepages:
            pageSize: 1Gi
```

### How to dedicate VCPUS for real-time only

It is possible to pass a regular expression of the VCPUs to isolate to use real-time scheduling policy, by using the `realtime.mask` setting.

```yaml
        cpu:
          numa:
            guestMappingPassthrough: {}
          realtime:
            mask: "0"
```

When applied this configuration, KubeVirt will only set the first VCPU for real-time scheduler policy, leaving the remaining VCPUS to use the default scheduler policy. Other examples of valid masks are:
- `0-3`: Use cores 0 to 3 for real-time scheduling, assuming that the VM has requested at least 3 cores.
- `0-3,^1`: Use cores 0, 2 and 3 for real-time scheduling only, assuming that the VM has requested at least 3 cores.
