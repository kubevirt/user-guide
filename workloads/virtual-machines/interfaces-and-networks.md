# Interfaces and Networks

An `interface` defines a virtual network interface of a virtual machine.

A `network` specifies the backend of an `interface` and controls to which logical or physical device it is connected to.

Often there is more than one way to connect an `interface` to a `network`. A user can control this connection by choosing between different options.
However, at time of writing this document there is only a single way to connect interfaces and pods, and this method is `delegateIp`.

## Default network connectivity of a virtual machine

> **Note:** Currently, only a single interface is supported, and this must be connected to the pod network.

By default - thus if nothing else is specified - a virtual machine will get a single network interface connected to the pod network.

## Customizing network interfaces and networks

In order customize the network connectivity of a virtual machine, users must provide

- a list of interfaces and
- a list of networks each of the interfaces is connected to

The `name` property of an interface and network items defines which interface is connected to which network.
This means that if an interface is named `red`, then it will be connected to a network which is also named `red`:

```yaml
kind: VM
spec:
  devices:
    interfaces:
      - name: red
        bridge: ## Define how the interface is connected to a network
          delegateIp: true # offers the ip in case that the source has an ip
  networks:
  - name: red
    pod: {} # Stock pod network
```

## Backend connection support matrix

||||
|--:|:--:|:--:|
| Backend / Connection | `bridge` | `bridge.delegateIp` |
|`pod` | Ethernet | IP |

## Available backends

| Backend | Description |
|--|--|
| `pod` | This represents the default interface present in each Kubernetes pod |

### `pod` backend

|Feature||
|--|--|
| Supported protocols | TCP, UDP |
| Eventually supported protocols | IP |

This backend type is used if an interface should be connected to the regular pod network interface.

In some cases the underlying network plugin (flannel, weave, OpenShift SDN) acts as an Ethernet bridge or switch, in those cases the `pod` backend can also be used to provide an IP level connectivity to an interface (see backend `bridge.delegateIP`).

## Interface

Interfaces are the glue which is connecting a backend to the frontend.

|Options||
|--|--|
| `name` | Logical name of the interface as well as a reference to the associated networks. Must match the Name of a Network. |
| `model` | Interface model. |
| connection method | specifies the method which will be used to connect the interface to the guest. |
| `ports` | List of ports to be forwarded to the virtual machine. |


## Available connections methods

| Connection method | Description |
|--|--|
| `bridge` | Bridge the interface to the network |
| `slirp` | Use qemu user interface |

### `bridge` connection

This connection will create an Ethernet bridge between the interface and the network.

If the `delegateIp` option is used, then - if available - an IP address assigned to the network device representing the network, will be offered to the virtual machine via DHCP and be removed from the interface itself. The effect is that the IP endpoint is "moved" form the network interface to the virtual machine.

|Feature||
|--|--|
| Supported protocols | Ethernet, IP |

|Options||
|--|--|
| `delegateIp` | `pod` backend only: The IP assigned to the pod will be delegated to the VM using DHCP |

### `slirp` connection

This connection will use the qemu user interface.

Let the VM be exposed like a process which would be running inside a container. The requirement is that a process will bind to a port.

 <span style="color:red">Note:</span> SLIRP is not recommended for production use.

All the egress connection will originate from the qemu process, and all the ingress connection will go through the qemu process.

|Feature||
|--|--|
| Supported protocols | TCP/UDP only |

#### Example

This configuration will deploy a virtual machine. Then it will install an nginx server with the cloud-init script and expose port 80 from the VM to the pod.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
  labels:
    special: vmi-slirp
  name: vmi-slirp
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
      interfaces:
      - name: testSlirp
        slirp: {}
        ports:
        - name: http
          port: 80
          protocol: TCP
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  networks:
  - name: testSlirp
    pod: {}
  terminationGracePeriodSeconds: 0
  volumes:
  - name: registryvolume
    registryDisk:
      image: registry:5000/kubevirt/fedora-cloud-registry-disk-demo:devel
  - cloudInitNoCloud:
      userData: |-
        #!/bin/bash
        echo "fedora" |passwd fedora --stdin
        yum install -y nginx
        systemctl enable nginx
        systemctl start nginx
    name: cloudinitvolume
status: {}
```

## Ports

| Options ||
|--|--|
| `name` | Name |
| `port` | Port to expose (mandatory)|
| `protocol` | Connection protocol (TCP, UDP)|