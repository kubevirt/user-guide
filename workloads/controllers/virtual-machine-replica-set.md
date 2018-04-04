# Virtual Machine Replica Set

\#\# Virtual Machine Replica Set

A _VirtualMachineReplicaSet_ tries to ensures that a specified number of Virtual Machine replicas are running at any time. In other words, a _VirtualMachineReplicaSet_ makes sure that a Virtual Machine or a homogeneous set of Virtual Machines is always up and ready. It is very similar to a [Kubernetes Replica Set](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/).

No state is kept and no guarantees about the maximum number of Virtual Machine Replicas which are up are given. For example, the _VirtualMachineReplicaSet_ may decide to create new Replicas if possibly still running Virtual Machines are entering an unknown state.

## How to use a VirtualMachineReplicaSet

The _VirtualMachineReplicaSet_ allows to specify a _VirtualMachineTemplate_ in `spec.template`. It consists of `ObjectMetadata` in `spec.template.metadata`, and a `VirtualMachineSpec` in `spec.template.spec`. The specification of the virtual machine is equal to the specification of the virtual machine in the `VirtualMachine` workload.

`spec.replicas` can be used to specify how many replicas are wanted. If not specified, the default value is 1. This value can be updated anytime. The controller will react to the changes.

`spec.selector` is used by the controller to keep track of managed virtual machines. The selector specified there must be able to match the virtual machine labels as specified in `spec.template.metadata.labels`. If the selector does not match these labels, or they are empty, the controller will simply do nothing except from logging an error. The user is responsible for not creating other virtual machines or _VirtualMachineReplicaSets_ which conflict with the selector and the template labels.

## When to use a VirtualMachineReplicaSet

Whenever one wants many identical Virtual Machines and does not care about maintaining any disk state after they were terminated, the VirtualMachineReplicaSet is the right choice.

### Fast starting ephemeral Virtual Machines

This use-case involves small fast booting Virtual Machines with little provisioning performed during initialization.

Migrations are not important. Redistributing Virtual Machine workloads between nodes can be achieved simply by deleting managed VirtualMachines which are running on an overloaded Node. The `eviction` of such a VirtualMachine can happen by directly deleting the VirtualMachine instance \(KubeVirt aware workload redistribution\) or by deleting the corresponding Pod where the Virtual Machine runs in \(Only Kubernetes aware workload redistribution\).

### Slow starting ephemeral Virtual Machines

In this use-case one has big, slow booting Virtual Machines, and complex or resource intensive provisioning is done during the boot. With other words, the timespan between the creation of a new Virtual Machine and entering the ready state of a VirtualMachine is long.

One still does not care about the state, but since re-provisioning VirtualMachines is expensive, Migrations are important. Workload redistribution between nodes can be achieved by migrating VirtualMachines to different nodes. A workload redistributor needs to be aware of KubeVirt and create Migrations, instead of `evicting` VirtualMachines by deletion.

> **Note:** The simplest form of having a migratable ephemeral VirtualMachine, will be to use local storage based on `RegistryDisks` in combination with a file based backing store. However, migratable backing store support did not yet land in KubeVirt.

## Example

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: testvm-ephemeral
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          dev: vda
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
```

Saving this manifest into `testreplicaset.yaml` and submitting it to Kubernetes will create three virtual machines based on the template.

```bash
$ kubectl create -f testreplicaset.yaml
virtualmachinereplicaset "testreplicaset" created
$ kubectl describe vmrs testreplicaset
Name:         testreplicaset
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  kubevirt.io/v1alpha1
Kind:         VirtualMachineReplicaSet
Metadata:
  Cluster Name:        
  Creation Timestamp:  2018-01-03T12:42:30Z
  Generation:          0
  Resource Version:    6380
  Self Link:           /apis/kubevirt.io/v1alpha1/namespaces/default/virtualmachinereplicasets/testreplicaset
  UID:                 903a9ea0-f083-11e7-9094-525400ee45b0
Spec:
  Replicas:  3
  Selector:
    Match Labels:
      Myvm:  myvm
  Template:
    Metadata:
      Creation Timestamp:  <nil>
      Labels:
        Myvm:  myvm
      Name:    test
    Spec:
      Domain:
        Devices:
          Disks:
            Disk:
              Dev:        vda
            Name:         registrydisk
            Volume Name:  registryvolume
        Resources:
          Requests:
            Memory:  64M
      Volumes:
        Name:  registryvolume
        Registry Disk:
          Image:  kubevirt/cirros-registry-disk-demo:latest
Status:
  Conditions:      <nil>
  Ready Replicas:  2
  Replicas:        3
Events:
  Type    Reason            Age   From                                 Message
  ----    ------            ----  ----                                 -------
  Normal  SuccessfulCreate  13s   virtualmachinereplicaset-controller  Created virtual machine: testh8998
  Normal  SuccessfulCreate  13s   virtualmachinereplicaset-controller  Created virtual machine: testf474w
  Normal  SuccessfulCreate  13s   virtualmachinereplicaset-controller  Created virtual machine: test5lvkd
```

`Replicas` is `3` and `Ready Replicas` is `2`. This means that at the moment when showing the status, three Virtual Machines were already created, but only two are yet running and ready.

