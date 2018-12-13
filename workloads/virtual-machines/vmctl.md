# VMCTL

## Background

One remarkable difference between KubeVirt and other solutions that run Virtual
Machine workloads in a container is the toplevel API. KubeVirt treats
VirtualMachineInstances as a first class citizen by designating custom
resources to map/track VirtualMachine settings and attributes. This has
considerable advantages, but there's a trade-off: native Kubernetes
higher-level workload controllers such as Deployments, ReplicaSets, DaemonSets,
StatefulSets are designed to work directly with Pods. Because VirtualMachine
and VirtualMachineInstance resources are simply defined outside the scope of
Kubernetes responsibility, it will always be up to the KubeVirt project to
create analogues of those controllers. This is possible, and is in fact
something that exists for some entities, e.g.
VirtualMachineInstanceReplicaSet, but the KubeVirt project will always be one
step behind. Any significant changes upstream would need to be implemented
manually in KubeVirt.

## Overview

Vmctl is designed to address this delta by managing VirtualMachines from within
a Pod. Vmctl will take an upstream VirtualMachine to act as a prototype and
derive and spawn a new VirtualMachine based on it. This derived VM will be
running alongside the vmctl pod. Thus for every vmctl pod in the cluster, there
should be a VM running alongside of it. To be clear, vmctl is not a VM instead
it is controlling a VM close by. The derived VM will be similar to the
prototype, but a few fields will be modified:

* Name
* NodeSelector
* Running

### Name

The new VirtualMachine's `Name` attribute will be a concatenation of the
prototype VM's name and the Pod's name. This will be a unique resource name
because both the prototype VM name and the vmctl Pod name are unique.

### NodeSelector

The new VirtualMachine will have a selector with node affinity matching the
running vmctl Pod's node, thus the VirtualMachine and the vmctl Pod will run on
the same node. This is because a `DaemonSet` maps one pod to each node in a
cluster. By tracking which Node a vmctl Pod is running on, KubeVirt ensures the
same behavior for VirtualMachines.

### Running

The new VirtualMachine will be set to the running state regardless of the
prototype VM's state.

## Implementation

Vmctl is implemented as a go binary, deployed in a container, that takes the
following parameters:

* `namespace`: The namespace to create the derived VirtualMachine in. The
   default namespace is `default`.
* `proto-namespace`: The namespace the prototype VM is in. This defaults to
   the value used for `namespace` if omitted.
* `hostname-override`: Mainly for testing--in order to make it possible to run
   vmctl outside of a pod.

vmctl has a single positional argument:

* prototype VM name

When the vmctl container is deployed, it will locate the requested prototype
VM, clone it, and watch wait. When the vmctl pod is deleted, vmctl will clean
up the derived VirtualMachine. Consequently it is inadvisable to use a 0 length
grace period for shutting down the pod.

## Services

One note worth stressing is that from Kubernete's perspective the vmctl Pod is
entirely distinct from the VM it spawns. It is especially important to be
mindful of this when creating services. From an end user's perspective, there's
nothing useful running on the vmctl Pod itself. The recommended method of
exposing services on a VM is to use Labels and Selectors. Applying a label to
the prototype VM, and using that `matchLabel` on a service is sufficient to
expose the service on all derived VM's.

## PersistentVolumeClaims

Another thing to consider with vmctl is the use of shared volumes. By nature
vmctl is designed to spawn an arbitrary number of VirtualMachines on demand,
all of which will define the same Disk and Volume stanzas. Because of this,
using shared volumes in read-write mode should be avoided, or the PVC's could
be corrupted. To avoid this issue, ephemeral disks or ContainerDisks could be
used.

# Examples

The following PodPreset applies to all examples below. This is done to remove
lines that are related to the Kubernetes DownwardAPI in order to make the
examples more clear.

```yaml
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: have-podinfo
  selector:
    matchLabels:
      app: vmctl
spec:
  volumeMounts:
    - name: podinfo
      mountPath: /etc/podinfo
  volumes:
    - name: podinfo
      downwardAPI:
        items:
        - path: "name"
          fieldRef:
            fieldPath: metadata.name
```

## Deployment

This is an example of using vmctl as a Deployment (Note: this example uses the
`have-podinfo` PodPreset above):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vmctl
  labels:
    app: vmctl
spec:
  replicas: 3
  selector:
    matchLabels:
      app: vmctl
  template:
    metadata:
      labels:
        app: vmctl
    spec:
      containers:
      - name: vmctl
        image: quay.io/fabiand/vmctl
        imagePullPolicy: IfNotPresent
        args:
        - "testvm"
        serviceAccountName: default
```

This example would look for a VirtualMachine in the `default` namespace named
`testvm`, and instantiate 3 replicas of it.


## Daemonset

This is an example of using vmctl as a Daemonset (Note: this example uses the
`have-podinfo` PodPreset above):

```yaml
apiVersion: apps/v1
kind: Daemonset
metadata:
  name: vmctl
  labels:
    app: vmctl
spec:
  selector:
    matchLabels:
      app: vmctl
  template:
    metadata:
      labels:
        app: vmctl
    spec:
      containers:
      - name: vmctl
        image: quay.io/fabiand/vmctl
        imagePullPolicy: IfNotPresent
        args:
        - "testvm"
        serviceAccountName: default
```

This example would look for a VirtualMachine in the `default` namespace named
`testvm`, and instantiate a VirtualMachine on every node in the Kubernetes
cluster.

## Service

Assuming a controller similar to the examples above, where a label `app: vmctl`
is used, a service to expose the VM's could look like this:

```yaml
kind: Service
apiVersion: v1
metadata:
  name: my-service
spec:
  selector:
    app: vmctl
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

In this case a clusterIP would be created that maps port 80 to each VM. See
[Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
for more information.
