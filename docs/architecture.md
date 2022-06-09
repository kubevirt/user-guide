# Architecture

KubeVirt is built using a service oriented architecture and a choreography
pattern.

## Stack


      +---------------------+
      | KubeVirt            |
    ~~+---------------------+~~
      | Orchestration (K8s) |
      +---------------------+
      | Scheduling (K8s)    |
      +---------------------+
      | Container Runtime   |
    ~~+---------------------+~~
      | Operating System    |
      +---------------------+
      | Virtual(kvm)        |
    ~~+---------------------+~~
      | Physical            |
      +---------------------+

Users requiring virtualization services are speaking to the Virtualization API
(see below) which in turn is speaking to the Kubernetes cluster to schedule
requested Virtual Machine Instances (VMIs). Scheduling, networking, and storage 
are all delegated to Kubernetes, while KubeVirt provides the virtualization functionality.


## Additional Services

KubeVirt provides additional functionality to your Kubernetes cluster,
to perform virtual machine management

If we recall how Kubernetes is handling Pods, then we remember that Pods are
created by posting a Pod specification to the Kubernetes API Server.
This specification is then transformed into an object inside the API Server,
this object is of a specific type or _kind_ - that is how it's called in the
specification.
A Pod is of the type `Pod`. Controllers within Kubernetes know how to handle
these Pod objects. Thus once a new Pod object is seen, those controllers
perform the necessary actions to bring the Pod alive, and to match the
required state.

This same mechanism is used by KubeVirt. Thus KubeVirt delivers three things
to provide the new functionality:

1. Additional types - so called [Custom Resource Definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (CRD) - are added to the Kubernetes API
2. Additional controllers for cluster wide logic associated with these new types
3. Additional daemons for node specific logic associated with new types

Once all three steps have been completed, you are able to

- create new objects of these new types in Kubernetes (VMIs in our
  case)
- and the new controllers take care to get the VMIs scheduled on some host,
- and a daemon - the `virt-handler` - is taking care of a host - alongside the
  `kubelet` - to launch the VMI and configure it until it matches the required
  state.

One final note; both controllers and daemons are running as Pods (or similar)
_on top of_ the Kubernetes cluster, and are not installed alongside it. The type
is - as said before - even defined inside the Kubernetes API server. This allows
users to speak to Kubernetes, but modify VMIs.

The following diagram illustrates how the additional controllers and daemons
communicate with Kubernetes and where the additional types are stored:

![Architecture diagram](./assets/architecture.png "Architecture")

And a simplified version:

![Simplified architecture diagram](./assets/architecture-simple.png "Simplified architecture")

## Application Layout

* Cluster
  * KubeVirt Components
    * virt-controller
    * virt-handler
    * libvirtd
    * …
  * KubeVirt Managed Pods
    * VMI Foo
    * VMI Bar
    * …
  * KubeVirt Custom Resources
    * VirtualMachine (VM) Foo
        -> VirtualMachineInstance (VMI) Foo
    * VirtualMachineInstanceReplicaSet (VMIRS) Bar
        -> VirtualMachineInstance (VMI) Bar

VirtualMachineInstance (VMI) is the custom resource that represents the basic ephemeral building block of an instance.
In a lot of cases this object won't be created directly by the user but by a high level resource.
High level resources for VMI can be:
* VirtualMachine (VM) - StateFul VM that can be stopped and started while keeping the VM data and state.
* VirtualMachineInstanceReplicaSet (VMIRS) - Similar to pods ReplicaSet, a group of ephemeral VMIs with similar configuration defined in a template.

## Native Workloads

KubeVirt is deployed on top of a Kubernetes cluster.
This means that you can continue to run your Kubernetes-native workloads next
to the VMIs managed through KubeVirt.

Furthermore: if you can run native workloads, and you have KubeVirt installed,
you should be able to run VM-based workloads, too.
For example, Application Operators should not require additional permissions
to use cluster features for VMs, compared to using that feature with a plain Pod.

Security-wise, installing and using KubeVirt must not grant users any permission
they do not already have regarding native workloads. For example, a non-privileged
Application Operator must never gain access to a privileged Pod by using a KubeVirt
feature.

## The Razor

We love virtual machines, think that they are very important and work hard to make
them easy to use in Kubernetes. But even more than VMs, we love good design
and modular, reusable components.
Quite frequently, we face a dilemma: should we solve a problem in KubeVirt in a
way that is best optimized for VMs, or should we take a longer path and introduce
the solution to Pod-based workloads too?

To decide these dilemmas we came up with the **KubeVirt Razor**:
"If something is useful for Pods, we should not implement it only for VMs".

For example, we debated how we should connect VMs to external network
resources. The quickest way seems to introduce KubeVirt-specific code,
attaching a VM to a host bridge.
However, we chose the longer path of integrating with [Multus](https://github.com/intel/multus-cni)
and [CNI](https://github.com/containernetworking) and improving them.

## VirtualMachine

A `VirtualMachine` provides additional management capabilities to a
VirtualMachineInstance inside the cluster. That includes:

-   API stability

-   Start/stop/restart capabilities on the controller level

-   Offline configuration change with propagation on
    VirtualMachineInstance recreation

-   Ensure that the VirtualMachineInstance is running if it should be
    running

It focuses on a 1:1 relationship between the controller instance and a
virtual machine instance. In many ways it is very similar to a
[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
with `spec.replica` set to `1`.

## How to use a VirtualMachine

A VirtualMachine will make sure that a VirtualMachineInstance object
with an identical name will be present in the cluster, if `spec.running`
is set to `true`. Further it will make sure that a
VirtualMachineInstance will be removed from the cluster if
`spec.running` is set to `false`.

There exists a field `spec.runStrategy` which can also be used to
control the state of the associated VirtualMachineInstance object. To
avoid confusing and contradictory states, these fields are mutually
exclusive.

An extended explanation of `spec.runStrategy` vs `spec.running` can be
found in [Run Strategies](./virtual_machines/run_strategies.md)

### Starting and stopping

After creating a VirtualMachine it can be switched on or off like this:

    # Start the virtual machine:
    virtctl start vm

    # Stop the virtual machine:
    virtctl stop vm

`kubectl` can be used too:

    # Start the virtual machine:
    kubectl patch virtualmachine vm --type merge -p \
        '{"spec":{"running":true}}'

    # Stop the virtual machine:
    kubectl patch virtualmachine vm --type merge -p \
        '{"spec":{"running":false}}'

### Controller status

Once a VirtualMachineInstance is created, its state will be tracked via
`status.created` and `status.ready` fields of the VirtualMachine. If a
VirtualMachineInstance exists in the cluster, `status.created` will equal
`true`. If the VirtualMachineInstance is also ready, `status.ready` will
equal `true` too.

If a VirtualMachineInstance reaches a final state but the `spec.running`
equals `true`, the VirtualMachine controller will set `status.ready` to
`false` and re-create the VirtualMachineInstance.

Additionally, the `status.printableStatus` field provides high-level summary
information about the state of the VirtualMachine. This information is also displayed
when listing VirtualMachines using the CLI:

```
$ kubectl get virtualmachines
NAME     AGE   STATUS    VOLUME
vm1      4m    Running
vm2      11s   Stopped
```

Here's the list of states currently supported and their meanings.
Note that states may be added/removed in future releases, so caution
should be used if consumed by automated programs.

 - **Stopped**: The virtual machine is currently stopped and isn't expected to start.
 - **Provisioning**: Cluster resources associated with the virtual machine (e.g., DataVolumes) are being provisioned and prepared.
 - **Starting**: The virtual machine is being prepared for running.
 - **Running**: The virtual machine is running.
 - **Paused**: The virtual machine is paused.
 - **Migrating**: The virtual machine is in the process of being migrated to another host.
 - **Stopping**: The virtual machine is in the process of being stopped.
 - **Terminating**: The virtual machine is in the process of deletion, as well as its associated resources (VirtualMachineInstance, DataVolumes, …).
 - **Unknown**: The state of the virtual machine could not be obtained, typically due to an error in communicating with the host on which it's running.


### Restarting

A VirtualMachineInstance restart can be triggered by deleting the
VirtualMachineInstance. This will also propagate configuration changes
from the template in the VirtualMachine:

    # Restart the virtual machine (you delete the instance!):
    kubectl delete virtualmachineinstance vm

To restart a VirtualMachine named vm using virtctl:

    $ virtctl restart vm

This would perform a normal restart for the VirtualMachineInstance and
would reschedule the VirtualMachineInstance on a new virt-launcher Pod

To force restart a VirtualMachine named vm using virtctl:

    $ virtctl restart vm --force --grace-period=0

This would try to perform a normal restart, and would also delete the
virt-launcher Pod of the VirtualMachineInstance with setting
GracePeriodSeconds to the seconds passed in the command.

Currently, only setting grace-period=0 is supported.

> Note: Force restart can cause data corruption, and should be used in
> cases of kernel panic or VirtualMachine being unresponsive to normal
> restarts.

### Fencing considerations

A VirtualMachine will never restart or re-create a
VirtualMachineInstance until the current instance of the
VirtualMachineInstance is deleted from the cluster.

### Exposing as a Service

A VirtualMachine can be exposed as a service. The actual service will be
available once the VirtualMachineInstance starts without additional
interaction.

For example, exposing SSH port (22) as a `ClusterIP` service using `virtctl`
after the VirtualMachine was created, but before it started:

    $ virtctl expose virtualmachine vmi-ephemeral --name vmiservice --port 27017 --target-port 22

All service exposure options that apply to a VirtualMachineInstance apply to a VirtualMachine.

See [Service Objects](./virtual_machines/service_objects.md) for more details.

## When to use a VirtualMachine

### When API stability is required between restarts

A `VirtualMachine` makes sure that VirtualMachineInstance API
configurations are consistent between restarts. A classical example are
licenses which are bound to the firmware UUID of a virtual machine. The
`VirtualMachine` makes sure that the UUID will always stay the same
without the user having to take care of it.

One of the main benefits is that a user can still make use of defaulting
logic, although a stable API is needed.

### When config updates should be picked up on the next restart

If the VirtualMachineInstance configuration should be modifiable inside
the cluster and these changes should be picked up on the next
VirtualMachineInstance restart. This means that no hotplug is involved.

### When you want to let the cluster manage your individual VirtualMachineInstance

Kubernetes as a declarative system can help you to manage the
VirtualMachineInstance. You tell it that you want this
VirtualMachineInstance with your application running, the VirtualMachine
will try to make sure it stays running.

> Note: The current belief is that if it is defined that the
> VirtualMachineInstance should be running, it should be running. This is
> different to many classical virtualization platforms, where VMs stay
> down if they were switched off. Restart policies may be added if needed.
> Please provide your use-case if you need this!

### Example

```
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-cirros
  name: vm-cirros
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-cirros
    spec:
      domain:
        devices:
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
            memory: 64M
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: kubevirt/cirros-container-disk-demo:latest
      - cloudInitNoCloud:
          userDataBase64: IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        name: cloudinitdisk
```

Saving this manifest into `vm.yaml` and submitting it to Kubernetes will
create the controller instance:

```
$ kubectl create -f vm.yaml
virtualmachine "vm-cirros" created
```

Since `spec.running` is set to `false`, no vmi will be created:

```
$ kubectl get vmis
No resources found.
```

Let's start the VirtualMachine:

```
$ virtctl start vm vm-cirros
```

As expected, a VirtualMachineInstance called `vm-cirros` got created:

```
$ kubectl describe vm vm-cirros
Name:         vm-cirros
Namespace:    default
Labels:       kubevirt.io/vm=vm-cirros
Annotations:  <none>
API Version:  kubevirt.io/v1alpha3
Kind:         VirtualMachine
Metadata:
  Cluster Name:
  Creation Timestamp:  2018-04-30T09:25:08Z
  Generation:          0
  Resource Version:    6418
  Self Link:           /apis/kubevirt.io/v1alpha3/namespaces/default/virtualmachines/vm-cirros
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
            Volume Name:  containerdisk
            Disk:
              Bus:        virtio
            Name:         cloudinitdisk
            Volume Name:  cloudinitdisk
        Machine:
          Type:
        Resources:
          Requests:
            Memory:                      64M
      Termination Grace Period Seconds:  0
      Volumes:
        Name:  containerdisk
        Registry Disk:
          Image:  kubevirt/cirros-registry-disk-demo:latest
        Cloud Init No Cloud:
          User Data Base 64:  IyEvYmluL3NoCgplY2hvICdwcmludGVkIGZyb20gY2xvdWQtaW5pdCB1c2VyZGF0YScK
        Name:                 cloudinitdisk
Status:
  Created:  true
  Ready:    true
Events:
  Type    Reason            Age   From                              Message
  ----    ------            ----  ----                              -------
  Normal  SuccessfulCreate  15s   virtualmachine-controller  Created virtual machine: vm-cirros
```

### Kubectl commandline interactions

Whenever you want to manipulate the VirtualMachine through the
commandline you can use the kubectl command. The following are examples
demonstrating how to do it.

```
    # Define a virtual machine:
    kubectl create -f vm.yaml

    # Start the virtual machine:
    kubectl patch virtualmachine vm --type merge -p \
        '{"spec":{"running":true}}'

    # Look at virtual machine status and associated events:
    kubectl describe virtualmachine vm

    # Look at the now created virtual machine instance status and associated events:
    kubectl describe virtualmachineinstance vm

    # Stop the virtual machine instance:
    kubectl patch virtualmachine vm --type merge -p \
        '{"spec":{"running":false}}'

    # Restart the virtual machine (you delete the instance!):
    kubectl delete virtualmachineinstance vm

    # Implicit cascade delete (first deletes the virtual machine and then the virtual machine instance)
    kubectl delete virtualmachine vm

    # Explicit cascade delete (first deletes the virtual machine and then the virtual machine instance)
    kubectl delete virtualmachine vm --cascade=true

    # Orphan delete (The running virtual machine is only detached, not deleted)
    # Recreating the virtual machine would lead to the adoption of the virtual machine instance
    kubectl delete virtualmachine vm --cascade=false
```
