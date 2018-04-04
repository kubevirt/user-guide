# The Offline Virtual Machine user guide

If you require to get hold of non-running virtual machines, you will need to work
with the OfflineVirtualMachine object. The OfflineVirtualMachine holds the
template for a running VirtualMachine and holds additional metadata used
for tracking in the KubeVirt ecosystem.

The OfflineVirtualMachine work with the VirtualMachine, which is a running
VirtualMachine, that is created upon user request for virtual machine to start.

## When to use it

Whenever you need to manipulate virtual machine (changing/displaying
configuration) from within the Kubernetes cluster and do not want to loose
it after it is stopped or deleted.

### Example

The OfflineVirtualMachine is defined as any other Kubernetes object. Following
is the example of OfflineVirtualMachine defined in minimal setup and
cirros disk with cirros OS prepared.

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: OfflineVirtualMachine
metadata:
  name: my-vm
spec:
  running: false
  selector:
    template:
      metadata:
        labels:
          anylabel: any_label
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
                bus: virtio
            - name: cloudinitdisk
              volumeName: cloudinitvolume
              disk:
                bus: virtio
      volumes:
        - name: registryvolume
          registryDisk:
            image: kubevirt/cirros-registry-disk-demo:devel
```

When setting the `spec.running = true` the VirtualMachine following VirtualMachine
is created:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: my-vm
  labels:
    anylabel: any_label
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
          bus: virtio
        - name: cloudinitdisk
          volumeName: cloudinitvolume
          disk:
            bus: virtio
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/cirros-registry-disk-demo:devel
```

### Commandline

Whenever you want to manipulate the OfflineVirtualMachine through the
commandline you can use the `kubectl` and `virtctl` commands. The following are
examples demonstrating how to do it.

```bash
# Define an offline virtual machine:
kubectl create -f myofflinevm.yaml

# Start the virtual machine:
virtctl start myvm

# Look at offline virtual machine status and associated events:
kubectl describe offlinevirtualmachine myvm

# Look at the now created virtual machine status and associated events:
kubectl describe virtualmachine myvm

# Stop the virtual machine:
virtctl stop myvm

# Implicit cascade delete (first deletes the virtual machine and then the
# offline virtual machine)
kubectl delete offlinevirtualmachine myvm

# Explicit cascade delete (first deletes the virtual machine and then the
# offline virtual machine)
kubectl delete offlinevirtualmachine myvm --cascade=true

# Orphan delete (The running virtual machine is only detached, not deleted)
# Recreating the offline virtual machine would lead to the adoption of the
# virtual machine
kubectl delete offlinevirtualmachine myvm --cascade=false
```

Note: `virtctl start` and `virtctl stop` are a shortcut to a more verbose
variation of the `kubectl` command:

```bash
kubectl patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

kubectl patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'
```

If you have deployed KubeVirt on top of OpenShift you would prefer to use `oc`
command instead (see [OpenShift integration user guide](openshift-integration.md))

```bash
oc patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":true}}'

oc patch offlinevirtualmachine myvm --type merge -p \
    '{"spec":{"running":false}}'
```


## How it works - Relationship between OfflineVirtualMachine and VirtualMachine

The OfflineVirtualMachine creates VirtualMachine once the `spec.running` is set
to `true`. The newly created VirtualMachine occupies the same namespace as the
mother OfflineVirtualMachine. It also has the same `metadata.name` as the
OfflineVirtualMachine.

When set `spec.running = true` the OfflineVirtualMachine will try to keep the
VirtualMachine running. This means: If the VirtualMachine is turned off from
within the guest or fails. It will recreate it and start it again. The only
way to turn the VirtualMachine off is by setting `spec.running = false`.

The OfflineVirtualMachine uses the VirtualMachine spec in `spec.spec` to
create new VirtualMachine. The principle is exactly the same as in the
[Deployment controller in Kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment).
To summarize, the spec is applied only when new VirtualMachine is created.
Also the `spec.spec` does not propagate to the already running VirtualMachine.
To apply the changes, VirtualMachine first have to be stopped and then
started again.
