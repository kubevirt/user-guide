# Virtual network interfaces and Networks

In order to provide network connectivity to a guest OS, users must specify an `interface`. Every interface has to specify the `network` it should be connected, from the list of networks set in the spec, referenced by `name`.

```yaml
kind: VM
spec:
  devices:
    interfaces:
      - name: red
        bridge: ##
          delegateIp: true # offers the ip in case that the source has an ip
  networks:
  - name: red
    pod: {} # Stock pod network
```

- Networks
A list of networks that represent a physical device that can be attached to the Virtual Machine network interface.

- Interfaces
A list of Virtual interfaces that can be created for the virtual machine. The interface also provides a mechanism that will be used to connect to the physical device specified by the network.

**Currently, only a single interface, connected to a pod network is supported.**

**Note:** By not specifying any interfaces and networks, pod network interface will be bridged and it's MAC and IP will be delegated to the VM.
