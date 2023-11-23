# VirtualMachinePool

A *VirtualMachinePool* tries to ensure that a specified
number of VirtualMachine replicas and their respective
VirtualMachineInstances are in the ready state at any time.
In other words, a *VirtualMachinePool* makes sure that a
VirtualMachine or a set of VirtualMachines is always up
and ready. 

No state is kept and no guarantees are made about the maximum number
of VirtualMachineInstance replicas running at any time.
For example, the *VirtualMachinePool* may decide to create
new replicas if possibly still running VMs are entering an
unknown state.


## Using VirtualMachinePool

The *VirtualMachinePool* allows us to specify a *VirtualMachineTemplate*
in `spec.virtualMachineTemplate`. It consists of `ObjectMetadata` in
`spec.virtualMachineTemplate.metadata`, and a `VirtualMachineSpec` in
`spec.virtualMachineTemplate.spec`. The specification of the virtual machine
is equal to the specification of the virtual machine in the
`VirtualMachine` workload.

`spec.replicas` can be used to specify how many replicas are wanted. If
unspecified, the default value is 1. This value can be updated anytime.
The controller will react to the changes.

`spec.selector` is used by the controller to keep track of managed
virtual machines. The selector specified there must be able to match the
virtual machine labels as specified in `spec.virtualMachineTemplate.metadata.labels`.
If the selector does not match these labels, or they are empty, the
controller will simply do nothing except log an error. The user
is responsible for avoiding the creation of other virtual machines or
*VirtualMachinePools* which may conflict with the selector and
the template labels.

### Creating a VirtualMachinePool

VirtualMachinePool is part of the Kubevirt API `pool.kubevirt.io/v1alpha1`.

The example below shows how to create a simple `VirtualMachinePool`:

#### Example

```yaml
    apiVersion: pool.kubevirt.io/v1alpha1
    kind: VirtualMachinePool
    metadata:
      name: vm-pool-cirros
    spec:
      replicas: 3
      selector:
        matchLabels:
          kubevirt.io/vmpool: vm-pool-cirros
      virtualMachineTemplate:
        metadata:
          creationTimestamp: null
          labels:
            kubevirt.io/vmpool: vm-pool-cirros
        spec:
          running: true
          template:
            metadata:
              creationTimestamp: null
              labels:
                kubevirt.io/vmpool: vm-pool-cirros
            spec:
              domain:
                devices:
                  disks:
                  - disk:
                      bus: virtio
                    name: containerdisk
                resources:
                  requests:
                    memory: 128Mi
              terminationGracePeriodSeconds: 0
              volumes:
              - containerDisk:
                  image: kubevirt/cirros-container-disk-demo:latest
                name: containerdisk 
```

Saving this manifest into `vm-pool-cirros.yaml` and submitting it to
Kubernetes will create three virtual machines based on the template.

    $ kubectl create -f vm-pool-cirros.yaml
    virtualmachinepool.pool.kubevirt.io/vm-pool-cirros created
    $ kubectl describe vmpool vm-pool-cirros
    Name:         vm-pool-cirros
    Namespace:    default
    Labels:       <none>
    Annotations:  <none>
    API Version:  pool.kubevirt.io/v1alpha1
    Kind:         VirtualMachinePool
    Metadata:
      Creation Timestamp:  2023-02-09T18:30:08Z
      Generation:          1
        Manager:      kubectl-create
        Operation:    Update
        Time:         2023-02-09T18:30:08Z
        API Version:  pool.kubevirt.io/v1alpha1
        Fields Type:  FieldsV1
        fieldsV1:
          f:status:
            .:
            f:labelSelector:
            f:readyReplicas:
            f:replicas:
        Manager:         virt-controller
        Operation:       Update
        Subresource:     status
        Time:            2023-02-09T18:30:44Z
      Resource Version:  6606
      UID:               ba51daf4-f99f-433c-89e5-93f39bc9989d
    Spec:
      Replicas:  3
      Selector:
        Match Labels:
          kubevirt.io/vmpool:  vm-pool-cirros
      Virtual Machine Template:
        Metadata:
          Creation Timestamp:  <nil>
          Labels:
            kubevirt.io/vmpool:  vm-pool-cirros
        Spec:
          Running:  true
          Template:
            Metadata:
              Creation Timestamp:  <nil>
              Labels:
                kubevirt.io/vmpool:  vm-pool-cirros
            Spec:
              Domain:
                Devices:
                  Disks:
                    Disk:
                      Bus:  virtio
                    Name:   containerdisk
                Resources:
                  Requests:
                    Memory:                      128Mi
              Termination Grace Period Seconds:  0
              Volumes:
                Container Disk:
                  Image:  kubevirt/cirros-container-disk-demo:latest
                Name:     containerdisk
    Status:
      Label Selector:  kubevirt.io/vmpool=vm-pool-cirros
      Ready Replicas:  2
      Replicas:        3
    Events:
      Type    Reason            Age   From                           Message
      ----    ------            ----  ----                           -------
      Normal  SuccessfulCreate  17s   virtualmachinepool-controller  Created VM default/vm-pool-cirros-0
      Normal  SuccessfulCreate  17s   virtualmachinepool-controller  Created VM default/vm-pool-cirros-2
      Normal  SuccessfulCreate  17s   virtualmachinepool-controller  Created VM default/vm-pool-cirros-1

`Replicas` is `3` and `Ready Replicas` is `2`. This means that at the
moment when showing the status, three Virtual Machines were already
created, but only two are running and ready.

### Scaling via the Scale Subresource

> **Note:** This requires KubeVirt 0.59 or newer.

The `VirtualMachinePool` supports the `scale` subresource.
As a consequence it is possible to scale it via `kubectl`:

    $ kubectl scale vmpool vm-pool-cirros --replicas 5


### Removing a VirtualMachine from VirtualMachinePool

It is also possible to remove a `VirtualMachine` from its `VirtualMachinePool`.

In this scenario, the `ownerReferences` needs to be removed from the `VirtualMachine`.
This can be achieved either by using `kubectl edit` or `kubectl patch`.
Using `kubectl patch` it would look like:

    kubectl patch vm vm-pool-cirros-0 --type merge --patch '{"metadata":{"ownerReferences":null}}' 

> **Note:** You may want to update your VirtualMachine labels as well to avoid impact on selectors.


### Using the Horizontal Pod Autoscaler

> **Note:** This requires KubeVirt 0.59 or newer.

The
[HorizontalPodAutoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
(HPA) can be used with a `VirtualMachinePool`. Simply
reference it in the spec of the autoscaler:

```yaml
    apiVersion: autoscaling/v1
    kind: HorizontalPodAutoscaler
    metadata:
      creationTimestamp: null
      name: vm-pool-cirros
    spec:
      maxReplicas: 10
      minReplicas: 3
      scaleTargetRef:
        apiVersion: pool.kubevirt.io/v1alpha1
        kind: VirtualMachinePool
        name: vm-pool-cirros
      targetCPUUtilizationPercentage: 50
```


or use `kubectl autoscale` to define the HPA via the commandline:

    $ kubectl autoscale vmpool vm-pool-cirros --min=3 --max=10 --cpu-percent=50

## Exposing a VirtualMachinePool as a Service

A VirtualMachinePool may be exposed as a service. When
this is done, one of the VirtualMachine replicas will be picked
for the actual delivery of the service.

For example, exposing SSH port (22) as a ClusterIP service:

```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: vm-pool-cirros-ssh
    spec:
      type: ClusterIP
      selector:
        kubevirt.io/vmpool: vm-pool-cirros
      ports:
        - protocol: TCP
          port: 2222
          targetPort: 22
```
Saving this manifest into `vm-pool-cirros-ssh.yaml` and submitting it to
Kubernetes will create the `ClusterIP` service listening on port 2222 and
forwarding to port 22.

See [Service
Objects](http://kubevirt.io/user-guide/virtual_machines/service_objects/)
for more details.


## Using Persistent Storage

> **Note:** DataVolumes are part of [CDI](https://kubevirt.io/user-guide/operations/containerized_data_importer/)

Usage of a `DataVolumeTemplates` within a `spec.virtualMachineTemplate.spec` will result in the creation
of unique persistent storage for each VM within a VMPool. The `DataVolumeTemplate`
name will have the VM's sequential postfix appended to it when the VM is created from the
`spec.virtualMachineTemplate.spec.dataVolumeTemplates`. This makes each VM a completely unique stateful workload.


## Using Unique CloudInit and ConfigMap Volumes with VirtualMachinePools

By default, any secrets or configMaps references in a `spec.virtualMachineTemplate.spec.template`
Volume section will be used directly as is, without any modification to the naming. This
means if you specify a secret in a `CloudInitNoCloud` volume, that every VM instance spawned
from the VirtualMachinePool with this volume will get the exact same secret used for their cloud-init
user data.

This default behavior can be modified by setting the `AppendPostfixToSecretReferences` and
`AppendPostfixToConfigMapReferences` booleans to true on the VMPool spec. When these booleans
are enabled, references to secret and configMap names will have the VM's sequential postfix
appended to the secret and configmap name. This allows someone to pre-generate unique per VM
`secret` and `configMap` data for a VirtualMachinePool ahead of time in a way that will be predictably
assigned to VMs within the VirtualMachinePool.

