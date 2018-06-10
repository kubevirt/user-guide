# OfflineVirtualMachine

An _OfflineVirtualMachine_  provides additional management capabilities to a
VirtualMachine inside the cluster. That includes:

 * ABI stability
 * Start/stop/restart capabilities on the controller level
 * Offline configuration change with propagation on VirtualMachine recreation
 * Ensure that the VirtualMachine is running if it should be running

It focuses on a 1:1 relationship between the controller instance and a virtual
machine instance. In many ways it is very similar to a
[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
with `spec.replica` set to `1`.

## How to use an OfflineVirtualMachine

An OfflineVirtualMachine will make sure that a VirtualMachine object with an
identical name will be present in the cluster, if `spec.running` is set to
`true`. Further it will make sure that a VirtualMachine will be removed from
the cluster if `spec.running` is set to `false`.

### Starting and stopping

After creating an OfflineVirtualMachine it can be switched on or off like this:

```bash
# Start the virtual machine:
virtctl start myvm

# Stop the virtual machine:
virtctl stop myvm
```

`kubectl` can be used too:

```bash
# Start the virtual machine:
kubectl patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

# Stop the virtual machine:
kubectl patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'
```

### Controller status

Once a VirtualMachine is created, its state will be tracked via
`status.created` and `status.ready`. If a VirtualMachine exists in the cluster,
`status.created` will equal to `true`. If the VirtualMachine is also ready,
`status.ready` will equal `true` too.

If a VirtualMachine reaches a final state but the `spec.running` equals `true`,
the OfflineVirtualMachine controller will set `status.ready` to `false` and
re-create the VirtualMachine.

### Restarting

A VirtualMachine restart can be triggered by deleting the VirtualMachine. This
will also propagate configuration changes from the template in the
OfflineVirtualMachine:

```bash
# Restart the offline virtual machine (you delete the vm!):
kubectl delete virtualmachine myvm
```

### Fencing considerations

An OfflineVirtualMachine will never restart or re-create a VirtualMachine until
the current instance of the VirtualMachine is deleted from the cluster.

### Exposing as a Service
An OfflineVirtualMachine could be exposed as a service. The actual service will be available once the VirtualMachine starts without additional interaction.

For example, exposing SSH port (22) as a `ClusterIP` service using `virtctl` after the OfflineVirtualMAchine was created, but before it started:

```bash
$ virtctl expose offlinevirtualmachine vm-ephemeral --name vmservice --port 27017 --target-port 22
```

All service exposure options that apply to a VirtualMachine apply to an OfflineVirtualMachine. See [Exposing VirtualMachine](http://www.kubevirt.io/user-guide/#/workloads/virtual-machines/expose-service) for more details.

## When to use an OfflineVirtualMachine

### When ABI stability is required between restarts

An _OfflineVirtualMachine_ makes sure that VirtualMachine ABI configurations
are consistent between restarts. A classical example are licenses which are
bound to the firmware UUID of a virtual machine. The _OfflineVirtualMachine_
makes sure that the UUID will always stay the same without the user having to
take care of it.

One of the main benefits is that a user can still make use of defaulting logic,
although a stable ABI is needed.

### When config updates should be picked up on the next restart

If the VirtualMachine configuration should be modifyable inside the cluster and
these changes should be picked up on the next VirtualMachine restart. This
means that no hotplug is involved.

### When you want to let the cluster manage your individual VirtualMachine

Kubernetes as a declarative system can help you to manage the VirtualMachine.

You tell it that you want this VirtualMachine with your application running,
the OfflineVirtualMachine will try to make sure it stays running.

> **Note**: The current believe is that if it is defined that the
> VirtualMachine should be running, it should be running. This is different to
> many classical virtualization platforms, where VMs stay down if they were
> switched off. Restart policies may be added if needed. Please provide your
> use-case if you need this!

## Example

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: OfflineVirtualMachine
metadata:
  creationTimestamp: null
  labels:
    kubevirt.io/ovm: ovm-cirros
  name: ovm-cirros
spec:
  running: false
  template:
    metadata:
      creationTimestamp: null
      labels:
        kubevirt.io/ovm: ovm-cirros
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: registrydisk
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
        registryDisk:
          image: kubevirt/cirros-registry-disk-demo:latest
      - cloudInitNoCloud:
          userDataBase64: IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        name: cloudinitvolume
```

Saving this manifest into `ovm.yaml` and submitting it to Kubernetes will
create the controller instance:

```bash
$ kubectl create -f ovm.yaml 
offlinevirtualmachine "ovm-cirros" created
```

Since `spec.running` is set to `false`, no vm will be created:

```bash
$ kubectl get vms
No resources found.
```

Let's start the OfflineVirtualMachine:

```bash
$ virtctl start omv ovm-cirros
```

As expected, a VirtualMachine called `ovm-cirros` got created:

```yaml
$ kubectl describe ovm ovm-cirros
Name:         ovm-cirros
Namespace:    default
Labels:       kubevirt.io/ovm=ovm-cirros
Annotations:  <none>
API Version:  kubevirt.io/v1alpha1
Kind:         OfflineVirtualMachine
Metadata:
  Cluster Name:        
  Creation Timestamp:  2018-04-30T09:25:08Z
  Generation:          0
  Resource Version:    6418
  Self Link:           /apis/kubevirt.io/v1alpha1/namespaces/default/offlinevirtualmachines/ovm-cirros
  UID:                 60043358-4c58-11e8-8653-525500d15501
Spec:
  Running:  true
  Template:
    Metadata:
      Creation Timestamp:  <nil>
      Labels:
        Kubevirt . Io / Ovm:  ovm-cirros
    Spec:
      Domain:
        Devices:
          Disks:
            Disk:
              Bus:        virtio
            Name:         registrydisk
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
  Normal  SuccessfulCreate  15s   offlinevirtualmachine-controller  Created virtual machine: ovm-cirros
```

### kubectl commandline interactions

Whenever you want to manipulate the OfflineVirtualMachine through the
commandline you can use the kubectl command. The following are examples
demonstrating how to do it.

```bash
# Define an offline virtual machine:
kubectl create -f myofflinevm.yaml

# Start the virtual machine:
kubectl patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

# Look at offline virtual machine status and associated events:
kubectl describe offlinevirtualmachine myvm

# Look at the now created virtual machine status and associated events:
kubectl describe virtualmachine myvm

# Stop the virtual machine:
kubectl patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'

# Restart the offline virtual machine (you delete the vm!):
kubectl delete virtualmachine myvm

# Implicit cascade delete (first deletes the virtual machine and then the offline virtual machine)
kubectl delete offlinevirtualmachine myvm

# Explicit cascade delete (first deletes the virtual machine and then the offline virtual machine)
kubectl delete offlinevirtualmachine myvm --cascade=true

# Orphan delete (The running virtual machine is only detached, not deleted)
# Recreating the offline virtual machine would lead to the adoption of the virtual machine
kubectl delete offlinevirtualmachine myvm --cascade=false
```
