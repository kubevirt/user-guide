## Life-cycle

Every `VM` represents a single virtual machine _instance_.  
In general, the management of VMs is kept similar to how `Pods` are managed: Every Vm that is defined in the cluster is expected to be running, just like pods.  
Deleting a VM is equivalent to shutting it down, this is also equivalent to how pods behave.

FIXME needs to be reworked.

### Launching a virtual machine

In order to start a VM, you just need to create a `VM` object using `kubectl`:

```bash
$ kubectl create -f vm.yaml
```

### Listing virtual machines

VMs can be listed by querying for VM objects:

```bash
$ kubectl get vms
```

### Retrieving a virtual machine definition

A single VM definition can be retrieved by getting the specific VM object:

```bash
$ kubectl get vms testvm
```

### Stopping a virtual machine

To stop the VM, you just need to delete the corresponding `VM` object using `kubectl`.

```bash
$ kubectl delete -f vm.yaml
# OR
$ kubectl delete vms testvm
```



