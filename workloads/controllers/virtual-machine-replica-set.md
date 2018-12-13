# VirtualMachineInstanceReplicaSet

## VirtualMachineInstanceReplicaSet

A _VirtualMachineInstanceReplicaSet_ tries to ensures that a specified number of VirtualMachineInstance replicas are running at any time. In other words, a _VirtualMachineInstanceReplicaSet_ makes sure that a VirtualMachineInstance or a homogeneous set of VirtualMachineInstances is always up and ready. It is very similar to a [Kubernetes ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/).

No state is kept and no guarantees about the maximum number of VirtualMachineInstance replicas which are up are given. For example, the _VirtualMachineInstanceReplicaSet_ may decide to create new replicas if possibly still running VMs are entering an unknown state.

## How to use a VirtualMachineInstanceReplicaSet

The _VirtualMachineInstanceReplicaSet_ allows us to specify a _VirtualMachineInstanceTemplate_ in `spec.template`. It consists of `ObjectMetadata` in `spec.template.metadata`, and a `VirtualMachineInstanceSpec` in `spec.template.spec`. The specification of the virtual machine is equal to the specification of the virtual machine in the `VirtualMachineInstance` workload.

`spec.replicas` can be used to specify how many replicas are wanted. If unspecified, the default value is 1. This value can be updated anytime. The controller will react to the changes.

`spec.selector` is used by the controller to keep track of managed virtual machines. The selector specified there must be able to match the virtual machine labels as specified in `spec.template.metadata.labels`. If the selector does not match these labels, or they are empty, the controller will simply do nothing except from logging an error. The user is responsible for not creating other virtual machines or _VirtualMachineInstanceReplicaSets_ which conflict with the selector and the template labels.

## Exposing a VirtualMachineInstanceReplicaSet as a Service

A VirtualMachineInstanceReplicaSet could be exposed as a service. When this is done, one of the VirtualMachineInstances replicas will be picked for the actual delivery of the service.

For example, exposing SSH port (22) as a ClusterIP service using virtctl on a VirtualMachineInstanceReplicaSet:

```bash
$ virtctl expose vmirs vmi-ephemeral --name vmiservice --port 27017 --target-port 22
```

All service exposure options that apply to a VirtualMachineInstance apply to a VirtualMachineInstanceReplicaSet. See [Exposing VirtualMachineInstance](http://www.kubevirt.io/user-guide/#/workloads/virtual-machines/expose-service) for more details.

## When to use a VirtualMachineInstanceReplicaSet

> **Note:** The base assumption is that referenced disks are read-only or that
> the VMIs are writing internally to a tmpfs. The most obvious volume sources
> for VirtualMachineInstanceReplicaSets which KubeVirt supports are referenced
> below. If other types are used **data corruption** is possible.

Using VirtualMachineInstanceReplicaSet is the right choice when one wants many
identical VMs and does not care about maintaining any disk state after the VMs
are terminated.

 [Volume types](workloads/virtual-machines/disks-and-volumes.md) which
 work well in combination with a VirtualMachineInstanceReplicaSet are:

* **cloudInitNoCloud**
* **ephemeral**
* **containerDisk**
* **emptyDisk**
* **configMap**
* **secret**
* any other type, if the VMI writes internally to a tmpfs

### Fast starting ephemeral Virtual Machines

This use-case involves small and fast booting VMs with little provisioning
performed during initialization.

In this scenario, migrations are not important. Redistributing VM workloads
between Nodes can be achieved simply by deleting managed
VirtualMachineInstances which are running on an overloaded Node. The `eviction`
of such a VirtualMachineInstance can happen by directly deleting the
VirtualMachineInstance instance \(KubeVirt aware workload redistribution\) or
by deleting the corresponding Pod where the Virtual Machine runs in \(Only
Kubernetes aware workload redistribution\).

### Slow starting ephemeral Virtual Machines

In this use-case one has big and slow booting VMs, and complex or resource
intensive provisioning is done during boot. More specifically, the timespan
between the creation of a new VM and it entering the ready state is long.

In this scenario, one still does not care about the state, but since
re-provisioning VMs is expensive, migrations are important. Workload
redistribution between Nodes can be achieved by migrating
VirtualMachineInstances to different Nodes. A workload redistributor needs to
be aware of KubeVirt and create migrations, instead of `evicting`
VirtualMachineInstances by deletion.

> **Note:** The simplest form of having a migratable ephemeral
> VirtualMachineInstance, will be to use local storage based on `ContainerDisks`
> in combination with a file based backing store. However, migratable backing
> store support has not officially landed yet in KubeVirt and is untested.

## Example

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstanceReplicaSet
metadata:
  name: testreplicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      myvmi: myvmi
  template:
    metadata:
      name: test
      labels:
        myvmi: myvmi
    spec:
      domain:
        devices:
          disks:
          - disk:
            name: containerdisk
            volumeName: registryvolume
        resources:
          requests:
            memory: 64M
      volumes:
      - name: registryvolume
        containerDisk:
          image: kubevirt/cirros-container-disk-demo:latest
```

Saving this manifest into `testreplicaset.yaml` and submitting it to Kubernetes will create three virtual machines based on the template.

```bash
$ kubectl create -f testreplicaset.yaml
virtualmachineinstancereplicaset "testreplicaset" created
$ kubectl describe vmirs testreplicaset
Name:         testreplicaset
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  kubevirt.io/v1alpha2
Kind:         VirtualMachineInstanceReplicaSet
Metadata:
  Cluster Name:        
  Creation Timestamp:  2018-01-03T12:42:30Z
  Generation:          0
  Resource Version:    6380
  Self Link:           /apis/kubevirt.io/v1alpha2/namespaces/default/virtualmachineinstancereplicasets/testreplicaset
  UID:                 903a9ea0-f083-11e7-9094-525400ee45b0
Spec:
  Replicas:  3
  Selector:
    Match Labels:
      Myvmi:  myvmi
  Template:
    Metadata:
      Creation Timestamp:  <nil>
      Labels:
        Myvmi:  myvmi
      Name:    test
    Spec:
      Domain:
        Devices:
          Disks:
            Disk:
            Name:         containerdisk
            Volume Name:  registryvolume
        Resources:
          Requests:
            Memory:  64M
      Volumes:
        Name:  registryvolume
        Container Disk:
          Image:  kubevirt/cirros-container-disk-demo:latest
Status:
  Conditions:      <nil>
  Ready Replicas:  2
  Replicas:        3
Events:
  Type    Reason            Age   From                                 Message
  ----    ------            ----  ----                                 -------
  Normal  SuccessfulCreate  13s   virtualmachineinstancereplicaset-controller  Created virtual machine: testh8998
  Normal  SuccessfulCreate  13s   virtualmachineinstancereplicaset-controller  Created virtual machine: testf474w
  Normal  SuccessfulCreate  13s   virtualmachineinstancereplicaset-controller  Created virtual machine: test5lvkd
```

`Replicas` is `3` and `Ready Replicas` is `2`. This means that at the moment when showing the status, three Virtual Machines were already created, but only two are running and ready.

