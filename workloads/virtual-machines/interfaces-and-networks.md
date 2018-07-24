# Interfaces and Networks

Connecting a virtual machine to a network consists of two parts. First,
networks are specified in `spec.networks`. Then, interfaces backed by the
networks are added to the VM by specifying them in
`spec.domain.devices.interfaces`.

Each interface must have a corresponding network with the same name.

An `interface` defines a virtual network interface of a virtual machine (also
called a frontend). A `network` specifies the backend of an `interface` and
declares which logical or physical device it is connected to (also called as
backend).

There are multiple ways of configuring an `interface` as well as a `network`.

All possible configuration options are available in the
[Interface API Reference](https://kubevirt.io/api-reference/master/definitions.html#_v1_interface)
and [Network API Reference](https://kubevirt.io/api-reference/master/definitions.html#_v1_network).

> **Note:** Currently, the only supported network types are `pod` and "resource".

## Backend

Network backends are configured in `spec.networks`. A network must have a
unique name. Additional fields declare which logical or physical device the
network relates to.

### Pod

A `pod` network represents the default pod `eth0` interface configured by
cluster SDN solution that is present in each pod.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: red
          macAddress: de:ad:00:00:be:af
          model: e1000
          bridge: {}
  networks:
  - name: red
    pod: {} # Stock pod network
```

### Resource

A `resource` network represents networks exposed by using a network device plugin. The configuration of the network will include the name of the device plugin and the name of the network resource it should expose, using the following format: `<device-plugin-name>/<network-name>`. In the yaml this will look like that:

```yaml
networks:
  - name: red 
    resource:
      resourceName: bridge.network.kubevirt.io/red
```
To communicate the name of the pod interface that the device plugin creates, and what kind of networking this interface exposes to the pod, the device plugin will set a JSON encoded environment variable to the pod.

The name of this environment variable must start with: `"NETWORK_INTERFACE_RESOURCES_"`, and assumes the following JSON format for example:
```json
{
  "name": "bridge.network.kubevirt.io/red", 
  "interfaces": [{"name": "eth-red01", "protocol": "Ethernet"}, {"name": "eth-red02", "protocol": "Ethernet"}]
}
```

Other than the definition of the environment variable, no other requirements exists on the device plugin, or how the host network is managed or created.
The following [network bridge device plugin](https://github.com/kubevirt/kubernetes-device-plugins/blob/master/docs/README.bridge.md) allows exposing a bridge into the pod as an interface, and is compliant with the above environment variable based API.

> **Notes:**
> - The device plugin allows multiple pod interfaces to be exposed fro the same network (`eth-red01` and `eth-red02` in the example above), however, inside the virtual machine, we will expose only one interface
> - If multiple device plugins exposes the same network, needed by the virtual machine, only one of them will be used, and a single interface per network will be created on the virtual machine
> - In the virtual machine specification, only interface with "bridge" binding is allowed to use a network of type "resource". Any other combination is considered invalid
> - The only "protocol" currently supported is "Ethernet" - which imply "bridged" binding without delegating the IP/MAC
> - Since there is no control on the names given to the interfaces inside the guest OS, the way to match the interface to the network is by matching the MAC address given to the interface on the host, to the MAC address configured in the yaml (if a static address was configured there), or dynamically given to the pod's side of the veth, which will have the following name format: `net-<network-name>` (For example: `net-red`)

## Frontend

Network interfaces are configured in `spec.domain.devices.interfaces`. They
describe properties of virtual interfaces as "seen" inside guest instances. The
same network backend may be connected to a virtual machine in multiple
different ways, each with their own connectivity guarantees and
characteristics.

Each interface should declare its type by defining on of the following fields:

| Type | Description |
|--|--|
| `bridge` | Connect using a linux bridge |
| `slirp` | Connect using QEMU user networking mode |

Each interface may also have additional configuration fields that modify
properties "seen" inside guest instances, as listed below:

| Name | Format | Default value | Description |
|--|--|--|--|
| `model` | One of: `e1000`, `e1000e`, `ne2k_pci`, `pcnet`, `rtl8139`, `virtio` | `virtio` | NIC type |
| macAddress | `ff:ff:ff:ff:ff:ff` or `FF-FF-FF-FF-FF-FF` | | MAC address as seen inside the guest system, for example: `de:ad:00:00:be:af` |
| ports ||empty| List of ports to be forwarded to the virtual machine. |

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: red
          model: e1000 # expose e1000 NIC to the guest
          bridge: {} # connect through a bridge
          ports:
           - name: http
             port: 80
  networks:
  - name: red
    pod: {}
```

### Ports

Declare ports listen by the virtual machine

> **Note:** When using the slirp interface only the configured ports will be forwarded to the virtual machine.

| Name | Format | Required | Description|
|--|--|--|--|
| `name` | | no | Name|
| `port` | 1 - 65535| yes | Port to expose|
| `protocol` | TCP,UDP| no | Connection protocol|

> **Tip:** Use `e1000` model if your guest image doesn't ship with virtio
> drivers.

If `spec.domain.devices.interfaces` is omitted, the virtual machine is
connected using the default pod network interface of `bridge` type. If you'd
like to have a virtual machine instance without any network connectivity, you
can use the `autoattachPodInterface` field as follows:

```yaml
kind: VM
spec:
  domain:
    devices:
      autoattachPodInterface: false
```

### bridge

In `bridge` mode, virtual machines are connected to the network backend through
a linux "bridge". The pod network IPv4 address is delegated to the virtual
machine via DHCPv4. The virtual machine should be configured to use DHCP to
acquire IPv4 addresses.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: red
          bridge: {} # connect through a bridge
  networks:
  - name: red
    pod: {}
```

At this time, `bridge` mode doesn't support additional configuration
fields.

> **Note:** due to IPv4 address delagation, in `bridge` mode the pod doesn't
> have an IP address configured, which may introduce issues with third-party
> solutions that may rely on it. For example, Istio may not work in this mode.

### slirp

In `slirp` mode, virtual machines are connected to the network backend using
QEMU user networking mode. In this mode, QEMU allocates internal IP addresses
to virtual machines and hides them behind NAT.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: red
          slirp: {} # connect using SLIRP mode
  networks:
  - name: red
    pod: {}
```

At this time, `slirp` mode doesn't support additional configuration fields.

> **Note:** in `slirp` mode, the only supported protocols are TCP and UDP. ICMP
> is *not* supported.

More information about SLIRP mode can be found in
[QEMU Wiki](https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29).
