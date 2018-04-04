## Basic Life-cycle

Every `VirtualMachine` represents a single virtual machine _instance_.  
In general, the management of VirtualMachines is kept similar to how `Pods` are managed: Every Vm that is defined in the cluster is expected to be running, just like pods.  
Deleting a VirtualMachine is equivalent to shutting it down, this is also equivalent to how pods behave.

FIXME needs to be reworked.

### Overview



### Launching a virtual machine

In order to start a VirtualMachine, you just need to create a `VirtualMachine` object using `kubectl`:

```bash
$ kubectl create -f vm.yaml
```

Alternatively, a Virtual Machine can be created and started from an OpenShift
template using `oc` client (see [OpenShift Integration guide](see
openshift-integration.md)):

```bash
$ oc process -f cluster/vm-template-fedora.yaml -p NAME=testvm CPU_CORES=2 | oc create -f -
$ oc patch offlinevirtualmachine testvm --type merge -p '{"spec":{"running":true}}'
```

The example above shows how to launch an OfflineVirtualMachine (see [Offline
Virtual Machine user guide](offline-virtual-machine.md)), from
[cluster/vm-template-fedora.yaml](kubevirt/kubevirt/blob/master/cluster/vm-template-fedora.yaml)
template, that is named `testvm` and it is restricted to 2 CPU cores.


### Listing virtual machines

VirtualMachines can be listed by querying for VirtualMachine objects:

```bash
$ kubectl get vms
```

### Retrieving a virtual machine definition

A single VirtualMachine definition can be retrieved by getting the specific VirtualMachine object:

```bash
$ kubectl get vms testvm
```

### Stopping a virtual machine

To stop the VirtualMachine, you just need to delete the corresponding `VirtualMachine` object using `kubectl`.

```bash
$ kubectl delete -f vm.yaml
# OR
$ kubectl delete vms testvm
```

> Note: Stopping a VirtualMachine implies that it will be deleted from the cluster. You will not be able to start this VirtualMachine object again.



