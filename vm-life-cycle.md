## Life-cycle

The `VM` kind represents a running virtual machine _instance_.
To start a VM, you just need to create a `VM` object using `kubectl`.
To stop the VM, you just need to delete the corresponding `VM` object using `kubectl`.

This behaviour is equivalent to managing `Pod`s.

### Launching a virtual machine

```
kubectl create -f vm.yaml
```

### Listing virtual machines





```

### Stopping a virtual machine

```yaml