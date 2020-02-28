VirtualMachineInstance with dedicated CPU resources
===================================================

Certain workloads, requiring a predictable latency and enhanced
performance during its execution would benefit from obtaining dedicated
CPU resources. KubeVirt, relying on the Kubernetes CPU manager, is able
to pin guest’s vCPUs to the host’s pCPUs.

[Kubernetes CPU
manager](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/)

    Kubernetes CPU manager is a mechanism that affects the scheduling of
    workloads, placing it on a host which can allocate `Guaranteed`
    resources and pin certain POD’s containers to host pCPUs, if the
    following requirement are met:

    * https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed[POD’s
    QOS] is Guaranteed
    ** resources requests and limits are equal
    ** all containers in the POD express CPU and memory requirements
    * Requested number of CPUs is an Integer

    Additional information: *
    https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/[Enabling
    the CPU manager on Kubernetes] *
    https://docs.openshift.com/container-platform/3.10/scaling_performance/using_cpu_manager.html[Enabling
    the CPU manager on OKD] *
    https://kubernetes.io/blog/2018/07/24/feature-highlight-cpu-manager/[Kubernetes
    blog explaning the feature]

    Requesting dedicated CPU resources

Setting `spec.domain.cpu.dedicatedCpuPlacement` to `true` in a VMI spec
will indicate the desire to allocate dedicated CPU resource to the VMI

Kubevirt will verify that all the necessary conditions are met, for the
Kubernetes CPU manager to pin the virt-launcher container to dedicated
host CPUs. Once, virt-launcher is running, the VMI’s vCPUs will be
pinned to the pCPUS that has been dedicated for the virt-launcher
container.

Expressing the desired amount of VMI’s vCPUs can be done by either
setting the guest topology in `spec.domain.cpu` (`sockets`, `cores`,
`threads`) or `spec.domain.resources.[requests/limits].cpu` to a whole
number, integer (e.g. 1, 2, etc) indicating the number of vCPUs
requested for the VMI. Number of vCPUs is counted as
`sockets * cores * threads` or if `spec.domain.cpu` is empty then it
takes value from `spec.domain.resources.requests.cpu` or
`spec.domain.resources.limits.cpu`.

> **Note:** Users should not specify both `spec.domain.cpu` and
> `spec.domain.resources.[requests/limits].cpu`
>
> **Note:** `spec.domain.resources.requests.cpu` must be equal to
> `spec.domain.resources.limits.cpu`
>
> **Note:** Multiple cpu-bound microbenchmarks show a significant
> performance advantage when using `spec.domain.cpu.sockets` instead of
> `spec.domain.cpu.cores`.

All inconsistent requirements will be rejected.

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    spec:
      domain:
        cpu:
          sockets: 2
          cores: 1
          threads: 1
          dedicatedCpuPlacement: true
        resources:
          limits:
            memory: 2Gi
    [...]

OR

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    spec:
      domain:
        cpu:
          dedicatedCpuPlacement: true
        resources:
          limits:
            cpu: 2
            memory: 2Gi
    [...]

Requesting dedicated CPU for QEMU emulator
------------------------------------------

A number of QEMU threads, such as QEMU main event loop, async I/O
operation completion, etc., also execute on the same physical CPUs as
the VMI’s vCPUs. This may affect the expected latency of a vCPU. In
order to enhance the real-time support in KubeVirt and provide improved
latency, KubeVirt will allocate an additional dedicated CPU, exclusively
for the emulator thread, to which it will be pinned. This will
effectively "isolate" the emulator thread from the vCPUs of the VMI.

This functionality can be enabled by specifying
`isolateEmulatorThread: true` inside VMI spec’s `Spec.Domain.CPU`
section. Naturally, this setting has to be specified in a combination
with a `dedicatedCpuPlacement: true`.

Example:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    spec:
      domain:
        cpu:
          dedicatedCpuPlacement: true
          isolateEmulatorThread: true
        resources:
          limits:
            cpu: 2
            memory: 2Gi

Identifying nodes with a running CPU manager
--------------------------------------------

At this time, [Kubernetes doesn’t label the
nodes](https://github.com/kubernetes/kubernetes/issues/66525) that has
CPU manager running on it.

KubeVirt has a mechansim to identify which nodes has the CPU manager
running and manually add a `cpumanager=true` label. This label will be
removed when KubeVirt will identify that CPU manager is no longer
running on the node. This automatic identification should be viewed as a
temporary workaround until Kubernetes will provide the required
functionality. Therefore, this feature should be manually enabled by
adding CPUManager to the kube-config feature-gate field.

When automatic identification is disabled, cluster administrator may
manually add the above label to all the nodes when CPU Manager is
running.

-   Nodes’ labels are view-able: `kubectl describe nodes`

-   Administrators may manually label a missing node:
    `kubectl label node [node_name] cpumanager=true`

### Enabling the CPU Manager automatic identification feature gate

To enable the automatic idetification, user may expand the
`feature-gates` field in the kubevirt-config config map by adding the
`CPUManager` to it.

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      feature-gates: "CPUManager"

Alternatively, users can edit an existing kubevirt-config:

`kubectl edit configmap kubevirt-config -n kubevirt`

    ...
    data:
      feature-gates: "DataVolumes,CPUManager"

Sidecar containers and CPU allocation overhead
----------------------------------------------

**Note:** In order to run sidecar containers, KubeVirt requires the
`Sidecar` feature gate to be enabled by adding `Sidecar` to the
`kubevirt-config` ConfigMap’s `feature-gates` field.

According to the Kubernetes CPU manager model, in order the POD would
reach the required QOS level `Guaranteed`, all containers in the POD
must express CPU and memory requirements. At this time, Kubevirt often
uses a sidecar container to mount VMI’s registry disk. It also uses a
sidecar container of it’s hooking mechanism. These additional resources
can be viewed as an overhead and should be taken into account when
calculating a node capacity.

**Note:** The current defaults for sidecar’s resources: `CPU: 200m`
`Memory: 64M` As the CPU resource is not expressed as a whole number,
CPU manager will not attempt to pin the sidecar container to a host CPU.
