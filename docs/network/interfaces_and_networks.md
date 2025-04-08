# Interfaces and Networks

Connecting a virtual machine to a network consists of two parts. First,
networks are specified in `spec.networks`. Then, interfaces backed by
the networks are added to the VM by specifying them in
`spec.domain.devices.interfaces`.

Each interface must have a corresponding network with the same name.

An `interface` defines a virtual network interface of a virtual machine. A `network` specifies the backend of an
`interface` and declares which logical or physical device it is
connected to.

There are multiple ways of configuring an `interface` as well as a
`network`.

All possible configuration options are available in the [Interface API
Reference](https://kubevirt.io/api-reference/master/definitions.html#_v1_interface)
and [Network API
Reference](https://kubevirt.io/api-reference/master/definitions.html#_v1_network).

## Networks

Networks are configured in VMs `spec.template.spec.networks`. A network must have
a unique name. 

Each network should declare its type by defining one of the following
fields:

| Type     | Description                                                                                  |
|----------|----------------------------------------------------------------------------------------------|
| `pod`    | Default Kubernetes network                                                                   |
| `multus` | Secondary network provided using Multus or Primary network when Multus is defined as default |

### pod

Represents the default (aka primary) pod interface (typically `eth0`) configured
by cluster network solution that is present in each pod.
The main advantage of this network type is that it is native to Kubernetes, 
allowing VMs to benefit from all network services provided by Kubernetes.

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              masquerade: {}
      networks:
      - name: default
        pod: {} # Stock pod network
```

### multus
Secondary networks in Kubernetes allow pods to connect to additional networks beyond the default network, 
enabling more complex network topologies. These secondary networks are supported by meta-plugins like 
[Multus](https://github.com/k8snetworkplumbingwg/multus-cni), which let each pod attach to multiple network interfaces.
Kubevirt support the connection of VMs to secondary networks using Multus.
This assumes that multus is installed across your cluster and a corresponding
`NetworkAttachmentDefinition` CRD was created.

The following example defines a secondary network which uses the [bridge CNI
plugin](https://www.cni.dev/plugins/current/main/bridge/), which will connect the VM
to Linux bridge `br10`. Other CNI plugins such as
ptp, bridge-cni or sriov-cni might be used as well. For their
installation and usage refer to the respective project documentation.

First the `NetworkAttachmentDefinition` needs to be created. That is
usually done by an administrator. Users can then reference the
definition.

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: linux-bridge-net-ipam
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "mynet",
      "plugins": [
        {
          "type": "bridge",
          "bridge": "br10",
          "disableContainerInterface": true,
          "macspoofchk": true
        }
      ]
    }'
```

With following definition, the VM will be connected to the default pod
network and to the secondary bridge network, referencing the `NetworkAttachmentDefinition` 
shown above(in the same namespace)

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
       domain:
         devices:
           interfaces:
           - name: default
             masquerade: {}
           - name: bridge-net
             bridge: {}
       networks:
       - name: default
         pod: {} # Stock pod network
       - name: bridge-net
         multus: # Secondary multus network
           networkName: linux-bridge-net-ipam #ref to NAD name
```
#### Multus as primary network provider
It is also possible to define a multus network as the default pod
network by indicating the VM's `spec.template.spec.networks.multus.default=true`.
See [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) documentation for further information
>**Note:** that a multus `default` network and a `pod` network type are mutually exclusive

>The multus delegate chosen as default **must** return at least one IP address.


Example: a `NetworkAttachmentDefinition` with IPAM.

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: bridge-test
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "bridge-test",
      "type": "bridge",
      "bridge": "br1",
      "ipam": {
        "type": "host-local",
        "subnet": "10.250.250.0/24"
      }
    }'
```

Define a VM with a `multus` network as the default.

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: test1
              bridge: {}
      networks:
      - name: test1
        multus: # Multus network as default
          default: true
          networkName: bridge-test
```


## Interfaces

Network interfaces are configured in `spec.domain.devices.interfaces`.
They describe properties of virtual interfaces as "seen" inside guest
instances. The same `network` may be connected to a virtual
machine in multiple different ways, each with their own connectivity
guarantees and characteristics.
> **Note** networks and interfaces must have a one-to-one relationship   

The mandatory interface configuration includes:
- A `name`, which references a network name 
- The name of supported network core binding from the table below, or a reference to a [network binding plugin](https://kubevirt.io/user-guide/network/network_binding_plugins/).

| Type         | Description                                                               |
|--------------|---------------------------------------------------------------------------|
| `bridge`     | Connect using a linux bridge                                              |
| `sriov`      | Connect using a passthrough SR-IOV VF via vfio                            |
| `masquerade` | Connect using `nftables` rules to NAT the traffic both egress and ingress |

Each interface may also have additional configuration fields that modify
properties "seen" inside guest instances, as listed below:

| Name       | Format                                                             | Default value          | Description                                                                                |
|------------|--------------------------------------------------------------------|------------------------|--------------------------------------------------------------------------------------------|
| model      | One of: `e1000`, `e1000e`, `ne2k_pci`, `pcnet`, `rtl8139`, `virtio`| `virtio`               | NIC type. **Note:** Use `e1000` model if your guest image doesn't ship with virtio drivers |
| macAddress | `ff:ff:ff:ff:ff:ff` or `FF-FF-FF-FF-FF-FF`                         |                        | MAC address as seen inside the guest system, for example: `de:ad:00:00:be:af`              |
| ports      |                                                                    | empty (i.e. all ports) | A list of ports to forward to the VM guest.                                                |
| pciAddress | `0000:81:00.1`                                                     |                        | Set network interface PCI address, for example: `0000:81:00.1`                             |


```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              model: e1000 # expose e1000 NIC to the guest
              masquerade: {} # connect through a masquerade
              ports:
               - name: http
                 port: 80 # forward only http traffic
      networks:
      - name: default
        pod: {}
```

> **Note:** For secondary interfaces, when a MAC address is specified for a
> virtual machine interface, it is passed to the underlying CNI plugin which is,
> in turn, expected to configure the network provider to allow for this particular MAC.
> Not every plugin has native support for custom MAC addresses.

> **Note:** For some CNI plugins without native support for custom MAC
> addresses, there is a workaround, which is to use the `tuning` CNI
> plugin to adjust pod interface MAC address. This can be used as
> follows:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ptp-mac
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "ptp-mac",
      "plugins": [
        {
          "type": "ptp",
          "ipam": {
            "type": "host-local",
            "subnet": "10.1.1.0/24"
          }
        },
        {
          "type": "tuning"
        }
      ]
    }'
```

> This approach may not work for all plugins. For example, OKD SDN is
> not compatible with `tuning` plugin.
>
> -   Plugins that handle custom MAC addresses natively: `ovs`, `bridge`.
>
> -   Plugins that are compatible with `tuning` plugin: `flannel`, `ptp`.
>
> -   Plugins that don't need special MAC address treatment: `sriov` (in
>     `vfio` mode).
>
### Ports

Declare ports to forward to the virtual machine guest.

| Name       | 	Format   | 	Required | Description         |
|------------|-----------|-----------|---------------------|
| `name`     |           | no        | Name                |
| `port`     | 1 - 65535 | yes       | Port to expose      |
| `protocol` | TCP,UDP   | no        | Connection protocol |

> **Note:**  
> The `ports` attribute is only evaluated by specific network bindings, namely the masquerade core network binding.  
> In the bridge network binding, it has no effect. For network binding plugins, its behavior depends on the plugin implementation.  
> See the network binding plugin [documentation](https://kubevirt.io/user-guide/network/network_binding_plugins/) for details.

If `spec.domain.devices.interfaces` is omitted, the virtual machine is
connected using the default pod network interface of `bridge` type. If
you'd like to have a virtual machine instance without any network
connectivity, you can use the `autoattachPodInterface` field as follows:

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          autoattachPodInterface: false
```


### bridge

In `bridge` mode, virtual machines are connected to the network backend
through a linux "bridge". The pod network IPv4 address (if exists) is delegated to
the virtual machine via DHCPv4. The virtual machine should be configured
to use DHCP to acquire IPv4 addresses.

> **Note:** If a specific MAC address is not configured in the virtual
> machine interface spec the MAC address from the relevant pod interface
> is delegated to the virtual machine.

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: red
              bridge: {} # connect through a bridge
      networks:
      - name: red
        multus:
          networkName: red
```

At this time, `bridge` mode doesn't support additional configuration
fields.

> **Note:** due to IPv4 address delegation, in `bridge` mode the pod
> doesn't have an IP address configured, which may introduce issues with
> third-party solutions that may rely on it. For example, Istio may not
> work in this mode.

> **Note:** admin can forbid using `bridge` interface type for pod
> networks via a designated configuration flag. To achieve it, the admin
> should set the following option to `false`:

```yaml
apiVersion: kubevirt.io/v1
kind: Kubevirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    network:
      permitBridgeInterfaceOnPodNetwork: false
```

> **Note:** binding the pod network using `bridge` interface type may
> cause issues. Other than the third-party issue mentioned in the above
> note, live migration is not allowed with a pod network binding of
> `bridge` interface type, and also some CNI plugins might not allow to
> use a custom MAC address for your VM instances. If you think you may
> be affected by any of issues mentioned above, consider changing the
> default interface type to `masquerade`, and disabling the `bridge`
> type for pod network, as shown in the example above.


### masquerade

In `masquerade` mode, KubeVirt allocates internal IP addresses to
virtual machines and hides them behind NAT. All the traffic exiting
virtual machines is "source NAT'ed" using pod IP addresses; thus, cluster
workloads should use the pod's IP address to contact the VM over this interface.
This IP address is reported in the VMI's `status.interfaces`. A guest
operating system should be configured to use DHCP to acquire IPv4 addresses.

To allow the VM to live-migrate or hard restart (both cause the VM to run on a
different pod, with a different IP address) and still be reachable, it should be
exposed by a Kubernetes [service](../network/service_objects.md#service-objects).

To allow traffic of specific ports into virtual machines, the template `ports` section of
the interface should be configured as follows. If the `ports` section is missing,
all ports forwarded into the VM.

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: red
              masquerade: {} # connect using masquerade mode
              ports:
                - port: 80 # forward traffic on port 80 to the virtual machine guest
      networks:
      - name: red
        pod: {}
```

> **Note:** Masquerade is only allowed to connect to the pod network.

> **Note:** The network CIDR can be configured in the pod network
> section using the `vmNetworkCIDR` attribute.

#### masquerade - IPv4 and IPv6 dual-stack support

`masquerade` mode can be used in IPv4 and IPv6 dual-stack clusters to provide
a VM with an IP connectivity over both protocols.

As with the IPv4 `masquerade` mode, the VM can be contacted using the pod's IP
address - which will be in this case two IP addresses, one IPv4 and one
IPv6. Outgoing traffic is also "NAT'ed" to the pod's respective IP address
from the given family.

Unlike in IPv4, the configuration of the IPv6 address and the default route is
not automatic; it should be configured via cloud init, as shown below:

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: red
              masquerade: {} # connect using masquerade mode
              ports:
                - port: 80 # allow incoming traffic on port 80 to get into the virtual machine
      networks:
      - name: red
        pod: {}
```

> **Note:** The IPv6 address for the VM and default gateway **must** be the ones
> shown above.

#### masquerade - IPv6 single-stack support

`masquerade` mode can be used in IPv6 single stack clusters to provide a VM
with an IPv6 only connectivity.

As with the IPv4 `masquerade` mode, the VM can be contacted using the pod's IP
address - which will be in this case the IPv6 one.
Outgoing traffic is also "NAT'ed" to the pod's respective IPv6 address.

As with the dual-stack cluster, the configuration of the IPv6 address and the default route is
not automatic; it should be configured via cloud init, as shown in the [dual-stack section](#masquerade-ipv4-and-ipv6-dual-stack-support).

Unlike the dual-stack cluster, which has a DHCP server for IPv4, the IPv6 single stack cluster
has no DHCP server at all. Therefore, the VM won't have the search domains information and
reaching a destination using its FQDN is not possible.
Tracking issue - https://github.com/kubevirt/kubevirt/issues/7184

### sriov

In `sriov` core network binding, SR-IOV Virtual Functions' PCI devices are directly exposed to virtual machines.
[SR-IOV device
plugin](https://github.com/k8snetworkplumbingwg/sriov-network-device-plugin) and [CNI](https://github.com/k8snetworkplumbingwg/sriov-cni) can be used to manage SR-IOV devices in kubernetes, making them available for kubevirt to consume.
The device is passed through into the guest operating system as a [host
device](https://libvirt.org/drvnodedev.html), using the
[vfio](https://www.kernel.org/doc/Documentation/vfio.txt) userspace
interface, to maintain high networking performance.

#### How to expose SR-IOV VFs to KubeVirt
To simplify procedure, use the [SR-IOV network operator](https://github.com/k8snetworkplumbingwg/sriov-network-operator/blob/v1.4.0/doc/quickstart.md) to deploy
and configure SR-IOV components in your cluster. On how to use the
operator, please refer to [their respective
documentation](https://github.com/k8snetworkplumbingwg/sriov-network-operator/blob/master/doc/quickstart.md).

> **Note:** KubeVirt relies on VFIO userspace driver to pass PCI devices
> into VM guest. Because of that, when configuring SR-IOV operator
> policies, make sure you define a pool of VF resources that uses
> `deviceType: vfio-pci`.


#### Start an SR-IOV VM

Assuming that  `sriov-device-plugin`and `sriov-cni` are deployed on the cluster nodes,
create a network-attachment-definition CR [as shown here](https://github.com/k8snetworkplumbingwg/sriov-cni?tab=readme-ov-file#usage).
The name of the CR should correspond with the reference in the VM networks spec (see example below)

Finally, to create a VM that will attach to the aforementioned Network, refer
to the following VM spec:

```yaml
---
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: sriov-net
            sriov: {}
      networks:
      - name: default
        pod: {}
      - multus:
          networkName: default/sriov-net
        name: sriov-net
```

> **Note:** for some NICs (e.g. Mellanox), the kernel module needs to be
> installed in the guest VM.

> **Note:** Placement on dedicated CPUs can only be achieved if the Kubernetes CPU manager is running on the SR-IOV capable workers.
> For further details please refer to the [dedicated cpu resources documentation](../compute/dedicated-cpu_resources.md/).

### Link State Management

From KubeVirt v1.5.0, you can set the desired interface's link state using the interface's `state` field.
The allowed values are: 

- `up` - Equivalent to an active network connection. This is the default if no value is specified.
- `down` - Equivalent to having the network cable disconnected from the vNIC.
- `absent` - Only relevant for NIC hotunplug.

> **Note:** The desired link state can be specified for network interfaces using all bindings other than `sriov`, as the virtualization
> stack used by KubeVirt does not allow setting it for SR-IOV devices.

Example of specifying an interface in the `down` state:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: my-vm
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              state: down
              masquerade: { }
      networks:
        - name: default
          pod: { }
```

The desired link state specification can be specified:

1. On VM creation.
2. When the VM is running.
3. When the VM is not running.
4. When a new network interface is hotplugged.

> **WARNING:** When [HTTP / TCP readiness and/or liveness probes](../user_workloads/liveness_and_readiness_probes.md) are specified 
> on the VM, setting the primary interface's link state to `down` will cause the VM:
> 
> 1. To be marked as not ready (readiness probe)
> 2. To be restarted, as the kubelet will kill the virt-launcher pod (liveness probe)

### Current Link State Status

The current link state of network interfaces is reported in the VirtualMachineInstance status section:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: my-vm
spec:
  domain:
    devices:
      interfaces:
      - name: default
        state: down
        masquerade: { }
  networks:
  - name: default
    pod: { }
status:
  interfaces:
    - name: default
      linkState: down
```

> **Note:** KubeVirt does not report the current link state of SR-IOV devices, as it cannot track external changes made
> to them.

## Security

### MAC spoof check

MAC spoofing refers to the ability to generate traffic with an arbitrary source
MAC address.
An attacker may use this option to generate attacks on the network.

In order to protect against such scenarios, it is possible to enable the
mac-spoof-check support in CNI plugins that support it.

The pod primary network which is served by the cluster network provider
is not covered by this documentation. Please refer to the relevant provider to
check how to enable spoofing check.
The following text refers to the secondary networks, served using multus.

There are two known CNI plugins that support mac-spoof-check:

- [sriov-cni](https://github.com/openshift/sriov-cni):
  Through the `spoofchk` parameter .
- [bridge-cni](https://www.cni.dev/plugins/current/main/bridge/):
  Through the `macspoofchk` parameter.

The configuration is to be done on the  NetworkAttachmentDefinition by the
operator and any interface that refers to it, will have this feature enabled.

Below is an example of using the `bridge` CNI with `macspoofchk` enabled:
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: br-spoof-check
spec:
  config: '{
            "cniVersion": "0.3.1",
            "name": "br-spoof-check",
            "type": "bridge",
            "bridge": "br10",
            "disableContainerInterface": true,
            "macspoofchk": true
        }'
```

On the VM, the network section should point to this
NetworkAttachmentDefinition by name:
```yaml
networks:
- name: default
  pod: {}
- multus:
    networkName: br-spoof-check
  name: br10
```

## Limitations and known issues
### Invalid CNIs for secondary networks
The following list of CNIs is known **not** to work for bridge interfaces -
which are most common for secondary interfaces.

- [macvlan](https://www.cni.dev/plugins/current/main/macvlan/)

- [ipvlan](https://www.cni.dev/plugins/current/main/ipvlan/)

The reason is similar: the bridge interface type moves the pod interface MAC
address to the VM, leaving the pod interface with a different address. The
aforementioned CNIs require the pod interface to have the original MAC address.

These issues are tracked individually:

- [macvlan](https://github.com/kubevirt/kubevirt/issues/5483)

- [ipvlan](https://github.com/kubevirt/kubevirt/issues/7001)

Feel free to discuss and / or propose fixes for them; we'd like to have
these plugins as valid options on our ecosystem.

- The `bridge` CNI supports mac-spoof-check through nftables, therefore
the node must support nftables and have the `nft` binary deployed.



## Additional Notes
### MTU
There are two methods for the MTU to be propagated to the guest interface.

* Libvirt - for this the guest machine needs new enough virtio network driver that understands
  the data passed into the guest via a PCI config register in the emulated device.
* DHCP - for this the guest DHCP client should be able to read the MTU from the DHCP server response.

On **Windows** guest non virtio interfaces, MTU has to be set manually using `netsh` or other tool
since the Windows DHCP client doesn't request/read the MTU.

The table below is summarizing the MTU propagation to the guest.

|            | masquerade     | bridge with CNI IP | bridge with no CNI IP | Windows |
|------------|----------------|--------------------|-----------------------|---------|
| virtio     | DHCP & libvirt | DHCP & libvirt     | libvirt               | libvirt |
| non-virtio | DHCP           | DHCP               | X                     | X       |

* bridge with CNI IP - means the CNI gives IP to the pod interface and bridge binding is used
  to bind the pod interface to the guest.

### virtio-net multiqueue

Setting the `networkInterfaceMultiqueue` to `true` will enable the
multi-queue functionality, increasing the number of vhost queue, for
interfaces configured with a `virtio` model.

```yaml
# partial example - kept short for brevity 
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          networkInterfaceMultiqueue: true
```

Users of a Virtual Machine with multiple vCPUs may benefit of increased
network throughput and performance.

Currently, the number of queues is being determined by the number of
vCPUs of a VM. This is because multi-queue support optimizes RX
interrupt affinity and TX queue selection in order to make a specific
queue private to a specific vCPU.

Without enabling the feature, network performance does not scale as the
number of vCPUs increases. Guests cannot transmit or retrieve packets in
parallel, as virtio-net has only one TX and RX queue.

Virtio interfaces advertise on their status.interfaces.interface entry a field named queueCount.  
The queueCount field indicates how many queues were assigned to the interface.  
Queue count value is derived from the domain XML.  
In case the number of queues can't be determined (i.e interface that is reported by quest-agent only),
it will be omitted.


>*NOTE*: Although the virtio-net multiqueue feature provides a
performance benefit, it has some limitations and therefore should not be
unconditionally enabled

#### Some known limitations

-   Guest OS is limited to ~200 MSI vectors. Each NIC queue requires a
    MSI vector, as well as any virtio device or assigned PCI device.
    Defining an instance with multiple virtio NICs and vCPUs might lead
    to a possibility of hitting the guest MSI limit.

-   virtio-net multiqueue works well for incoming traffic, but can
    occasionally cause a performance degradation, for outgoing traffic.
    Specifically, this may occur when sending packets under 1,500 bytes
    over the Transmission Control Protocol (TCP) stream.

-   Enabling virtio-net multiqueue increases the total network
    throughput, but in parallel it also increases the CPU consumption.

-   Enabling virtio-net multiqueue in the host QEMU config, does not
    enable the functionality in the guest OS. The guest OS administrator
    needs to manually turn it on for each guest NIC that requires this
    feature, using ethtool.

-   MSI vectors would still be consumed (wasted), if multiqueue was
    enabled in the host, but has not been enabled in the guest OS by the
    administrator.

-   In case the number of vNICs in a guest instance is proportional to
    the number of vCPUs, enabling the multiqueue feature is less
    important.

-   Each virtio-net queue consumes 64 KiB of kernel memory for the vhost
    driver.

>*NOTE*: Virtio-net multiqueue should be enabled in the guest OS
manually, using ethtool. For example:
`ethtool -L <NIC> combined #num_of_queues`

More information please refer to [KVM/QEMU
MultiQueue](http://www.linux-kvm.org/page/Multiqueue).
