# VirtualMachine

An _VirtualMachine_  provides additional management capabilities to a
VirtualMachineInstance inside the cluster. That includes:

 * ABI stability
 * Start/stop/restart capabilities on the controller level
 * Offline configuration change with propagation on VirtualMachineInstance recreation
 * Ensure that the VirtualMachineInstance is running if it should be running

It focuses on a 1:1 relationship between the controller instance and a virtual
machine instance. In many ways it is very similar to a
[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
with `spec.replica` set to `1`.

## How to use a VirtualMachine

A VirtualMachine will make sure that a VirtualMachineInstance object with an
identical name will be present in the cluster, if `spec.running` is set to
`true`. Further it will make sure that a VirtualMachineInstance will be removed from
the cluster if `spec.running` is set to `false`.

### Starting and stopping

After creating a VirtualMachine it can be switched on or off like this:

```bash
# Start the virtual machine:
virtctl start myvm

# Stop the virtual machine:
virtctl stop myvm
```

`kubectl` can be used too:

```bash
# Start the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

# Stop the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'
```

### Controller status

Once a VirtualMachineInstance is created, its state will be tracked via
`status.created` and `status.ready`. If a VirtualMachineInstance exists in the cluster,
`status.created` will equal to `true`. If the VirtualMachineInstance is also ready,
`status.ready` will equal `true` too.

If a VirtualMachineInstance reaches a final state but the `spec.running` equals `true`,
the VirtualMachine controller will set `status.ready` to `false` and
re-create the VirtualMachineInstance.

### Restarting

A VirtualMachineInstance restart can be triggered by deleting the VirtualMachineInstance. This
will also propagate configuration changes from the template in the
VirtualMachine:

```bash
# Restart the virtual machine (you delete the instance!):
kubectl delete virtualmachineinstance myvm
```

### Fencing considerations

A VirtualMachine will never restart or re-create a VirtualMachineInstance until
the current instance of the VirtualMachineInstance is deleted from the cluster.

### Exposing as a Service
A VirtualMachine can be exposed as a service. The actual service will be available once the VirtualMachineInstance starts without additional interaction.

For example, exposing SSH port (22) as a `ClusterIP` service using `virtctl` after the OfflineVirtualMAchine was created, but before it started:

```bash
$ virtctl expose virtualmachine vmi-ephemeral --name vmiservice --port 27017 --target-port 22
```

All service exposure options that apply to a VirtualMachineInstance apply to a VirtualMachine. See [Exposing VirtualMachineInstance](http://www.kubevirt.io/user-guide/#/workloads/virtual-machines/expose-service) for more details.

## When to use a VirtualMachine

### When ABI stability is required between restarts

A _VirtualMachine_ makes sure that VirtualMachineInstance ABI configurations
are consistent between restarts. A classical example are licenses which are
bound to the firmware UUID of a virtual machine. The _VirtualMachine_
makes sure that the UUID will always stay the same without the user having to
take care of it.

One of the main benefits is that a user can still make use of defaulting logic,
although a stable ABI is needed.

### When config updates should be picked up on the next restart

If the VirtualMachineInstance configuration should be modifyable inside the cluster and
these changes should be picked up on the next VirtualMachineInstance restart. This
means that no hotplug is involved.

### When you want to let the cluster manage your individual VirtualMachineInstance

Kubernetes as a declarative system can help you to manage the VirtualMachineInstance.

You tell it that you want this VirtualMachineInstance with your application running,
the VirtualMachine will try to make sure it stays running.

> **Note**: The current believe is that if it is defined that the
> VirtualMachineInstance should be running, it should be running. This is different to
> many classical virtualization platforms, where VMs stay down if they were
> switched off. Restart policies may be added if needed. Please provide your
> use-case if you need this!

## Example

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachine
metadata:
  creationTimestamp: null
  labels:
    kubevirt.io/vm: vm-cirros
  name: vm-cirros
spec:
  running: false
  template:
    metadata:
      creationTimestamp: null
      labels:
        kubevirt.io/vm: vm-cirros
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
            volumeName: registryvolume
          - disk:
              bus: virtio
            name: cloudinitdisk
            volumeName: cloudinitvolume
        machine:
          type: ""
        resources:
          requests:
            memory: 64M
      terminationGracePeriodSeconds: 0
      volumes:
      - name: registryvolume
        containerDisk:
          image: kubevirt/cirros-container-disk-demo:latest
      - cloudInitNoCloud:
          userDataBase64: IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        name: cloudinitvolume
```

Saving this manifest into `vm.yaml` and submitting it to Kubernetes will
create the controller instance:

```bash
$ kubectl create -f vm.yaml 
virtualmachine "vm-cirros" created
```

Since `spec.running` is set to `false`, no vmi will be created:

```bash
$ kubectl get vmis
No resources found.
```

Let's start the VirtualMachine:

```bash
$ virtctl start omv vm-cirros
```

As expected, a VirtualMachineInstance called `vm-cirros` got created:

```yaml
$ kubectl describe vm vm-cirros
Name:         vm-cirros
Namespace:    default
Labels:       kubevirt.io/vm=vm-cirros
Annotations:  <none>
API Version:  kubevirt.io/v1alpha2
Kind:         VirtualMachine
Metadata:
  Cluster Name:        
  Creation Timestamp:  2018-04-30T09:25:08Z
  Generation:          0
  Resource Version:    6418
  Self Link:           /apis/kubevirt.io/v1alpha2/namespaces/default/virtualmachines/vm-cirros
  UID:                 60043358-4c58-11e8-8653-525500d15501
Spec:
  Running:  true
  Template:
    Metadata:
      Creation Timestamp:  <nil>
      Labels:
        Kubevirt . Io / Ovmi:  vm-cirros
    Spec:
      Domain:
        Devices:
          Disks:
            Disk:
              Bus:        virtio
            Name:         containerdisk
            Volume Name:  registryvolume
            Disk:
              Bus:        virtio
            Name:         cloudinitdisk
            Volume Name:  cloudinitvolume
        Machine:
          Type:  
        Resources:
          Requests:
            Memory:                      64M
      Termination Grace Period Seconds:  0
      Volumes:
        Name:  registryvolume
        Registry Disk:
          Image:  kubevirt/cirros-registry-disk-demo:latest
        Cloud Init No Cloud:
          User Data Base 64:  IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        Name:                 cloudinitvolume
Status:
  Created:  true
  Ready:    true
Events:
  Type    Reason            Age   From                              Message
  ----    ------            ----  ----                              -------
  Normal  SuccessfulCreate  15s   virtualmachine-controller  Created virtual machine: vm-cirros
```

### kubectl commandline interactions

Whenever you want to manipulate the VirtualMachine through the
commandline you can use the kubectl command. The following are examples
demonstrating how to do it.

```bash
# Define a virtual machine:
kubectl create -f myvm.yaml

# Start the virtual machine:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

# Look at virtual machine status and associated events:
kubectl describe virtualmachine myvm

# Look at the now created virtual machine instance status and associated events:
kubectl describe virtualmachineinstance myvm

# Stop the virtual machine instance:
kubectl patch virtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'

# Restart the virtual machine (you delete the instance!):
kubectl delete virtualmachineinstance myvm

# Implicit cascade delete (first deletes the virtual machine and then the virtual machine)
kubectl delete virtualmachine myvm

# Explicit cascade delete (first deletes the virtual machine and then the virtual machine)
kubectl delete virtualmachine myvm --cascade=true

# Orphan delete (The running virtual machine is only detached, not deleted)
# Recreating the virtual machine would lead to the adoption of the virtual machine instance
kubectl delete virtualmachine myvm --cascade=false
```
