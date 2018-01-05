# The Offline Virtual Machine user guide

If you require to get hold of non-running virtual machines, you will need to work
with the OfflineVirtualMachine object. The OfflineVirtualMachine holds the
template for a running VirtualMachine and holds additional metadata used
for tracking in the KubeVirt ecosystem.

The OfflineVirtualMachine work with the VirtualMachine, which is a running
VirtualMachine, that is created upon user request for virtual machine to start.

## When to use it

Whenever you need to manipulate stopped virtual machine (changing/displaying
configuration).

## How to use it

The OfflineVirtualMachine is designed as a [Kubernetes CRD](https://kubernetes.io/docs/concepts/api-extension/custom-resources/).
CRD implies that you can use the OfflineVirtualMachine as you would use any
other Kubernetes object.

### Commandline

Whenever you want to manipulate the OfflineVirtualMachine through the commandline
you can use the kubectl command. The following are examples demonstrating how
to do it.

```bash
# Define an OfflineVirtualMachine:
kubectl create -f myofflinevm.yaml

# Start an OfflineVirtualMachine:
kubectl patch offlinevirtualmachine myvm -p \
    '{"spec":{"running" :"true"}}'

# Look at OfflineVirtualMachine status and associated events:
kubectl describe offlinevirtualmachine myvm

# Look at the now created VirtualMachine status and associated events:
kubectl describe virtualmachine myvm

# Stop an OfflineVirtualMachine:
kubectl patch offlinevirtualmachine myvm -p \
    '{"spec":{"running":"false"}}'

# Implicit cascade delete (first deletes the vm and then the ovm)
kubectl delete offlinevirtualmachine myvm

# Explicit cascade delete (first deletes the vm and then the ovm)
kubectl delete offlinevirtualmachine myvm --cascade=true

# Orphan delete (The running vm is only detached, not deleted)
# Recreating the ovm would lead to the adoption of the vm
kubectl delete offlinevirtualmachine myvm --cascade=false
```

### REST API

Third party apps can utilize the Kubernetes REST API to manipulate the
OfflineVirtualMachine.

The REST API copies the structure of the Kubernetes, so it can be accessed as

```text
POST /apis/kubevirt.io/v1alpha1/namespaces/{namespace}/offlinevirtualmachine
GET /apis/kubevirt.io/v1alpha1/namespaces/{namespace}/offlinevirtualmachine
GET /apis/kubevirt.io/v1alpha1/namespaces/{namespace}/offlinevirtualmachine/{name}
DELETE /apis/kubevirt.io/v1alpha1/namespaces/{namespace}/offlinevirtualmachine/{name}
PUT /apis/kubevirt.io/v1alpha1/namespaces/{namespace}/offlinevirtualmachine/{name}
PATCH /apis/kubevirt.io/v1alpha1/namespaces/{namespace}/offlinevirtualmachine/{name}
```

### The deletion of objects
WIP
