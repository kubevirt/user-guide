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

## Backend

Network backends are configured in `spec.networks`. A network must have a
unique name. Additional fields declare which logical or physical device the
network relates to.

Each network should declare its type by defining one of the following fields:

| Type | Description |
|--|--|
| `pod` | Default Kubernetes network |
| `multus` | Secondary network provided using Multus |
| `genie` | Secondary network provided using Genie |

### pod

A `pod` network represents the default pod `eth0` interface configured by
cluster network solution that is present in each pod.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: default
          bridge: {}
  networks:
  - name: default
    pod: {} # Stock pod network
```

### multus

It is also possible to connect VMIs to secondary networks using
[Multus](https://github.com/intel/multus-cni). This assumes that multus is
installed across your cluster and a corresponding
`NetworkAttachmentDefinition` CRD was created.

The following example defines a network which uses the [ovs-cni
plugin](https://github.com/kubevirt/ovs-cni), which will connect the VMI to Open
vSwitch's bridge `br1` and VLAN 100. Other CNI plugins such as ptp, bridge,
macvlan or Flannel might be used as well. For their installation and usage refer
to the respective project documentation.

First the `NetworkAttachmentDefinition` needs to be created. That is usually
done by an administrator. Users can then reference the definition.

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: ovs-vlan-100
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "ovs",
      "bridge": "br1",
      "vlan": 100
    }'
```

With following definition, the VMI will be connected to the default pod network
and to the secondary Open vSwitch network.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: default
          bridge: {}
        - name: ovs-net
          bridge: {}
  networks:
  - name: default
    pod: {} # Stock pod network
  - name: ovs-net
    multus: # Secondary multus network
      networkName: ovs-vlan-100
```

### genie

It is also possible to connect VMIs to multiple networks using
[Genie](https://github.com/Huawei-PaaS/CNI-Genie). This assumes that genie is
installed across your cluster.

The following example defines a network which uses [Flannel](https://github.com/coreos/flannel-cni) as the main network provider and as the [ovs-cni
plugin](https://github.com/kubevirt/ovs-cni) as the secondary one. The OVS CNI will connect the VMI to Open
vSwitch's bridge `br1` and VLAN 100.

Other CNI plugins such as ptp, bridge,
macvlan might be used as well. For their installation and usage refer
to the respective project documentation.

Genie does not use the `NetworkAttachmentDefinition` CRD. Instead it uses the name of the
underlying CNI in order to find the required configuration. It does that by looking into the configuration
files under ```/etc/cni/net.d/``` and finding the file that has that network name as the CNI type.
Therefore, for the case described above, the following configuration file should exist, for example,
```/etc/cni/net.d/99-ovs-cni.conf``` file would be:
```json
{
  "cniVersion": "0.3.1",
  "type": "ovs",
  "bridge": "br1",
  "vlan": 100
}
```
Similarly to Multus, Genie's configuration file must be the first one in the ```/etc/cni/net.d/``` directory. This also
means that Genie cannot be used together with Multus on the same cluster.

With following definition, the VMI will be connected to the default pod network
and to the secondary Open vSwitch network.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: default
          bridge: {}
        - name: ovs-net
          bridge: {}
  networks:
  - name: default
    genie: # Stock pod network
      networkName: flannel
  - name: ovs-net
    genie: # Secondary genie network
      networkName: ovs
```

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
| `sriov` | Pass through a SR-IOV PCI device via `vfio` |

Each interface may also have additional configuration fields that modify
properties "seen" inside guest instances, as listed below:

| Name | Format | Default value | Description |
|--|--|--|--|
| `model` | One of: `e1000`, `e1000e`, `ne2k_pci`, `pcnet`, `rtl8139`, `virtio` | `virtio` | NIC type |
| macAddress | `ff:ff:ff:ff:ff:ff` or `FF-FF-FF-FF-FF-FF` | | MAC address as seen inside the guest system, for example: `de:ad:00:00:be:af` |
| ports ||empty| List of ports to be forwarded to the virtual machine. |
| pciAddress | `0000:81:00.1` | | Set network interface PCI address, for example: `0000:81:00.1` |

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: default
          model: e1000 # expose e1000 NIC to the guest
          bridge: {} # connect through a bridge
          ports:
           - name: http
             port: 80
  networks:
  - name: default
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

### virtio-net multiqueue

Setting the `networkInterfaceMultiqueue` to `true` will enable the multi-queue functionality,
increasing the number of vhost queue, for interfaces configured with a `virtio` model.

```yaml
kind: VM
spec:
  domain:
    devices:
      networkInterfaceMultiqueue: true
```

Users of a Virtual Machine with multiple vCPUs may benefit of increased network throughput and performance.

Currently, the number of queues is being determined by the number of vCPUs of a VM.
This is because multi-queue support optimizes RX interrupt affinity and TX queue
selection in order to make a specific queue private to a specific vCPU.

Without enabling the feature, network performance does not scale as the number of vCPUs increases.
Guests cannot transmit or retrieve packets in parallel, as virtio-net has only one TX and RX queue.

*NOTE*: Although the virtio-net multiqueue feature provides a performance benefit,
it has some limitations and therefore should not be unconditionally enabled

#### Some known limitations

* Guest OS is limited to ~200 MSI vectors. Each NIC queue requires a MSI vector,
as well as any virtio device or assigned PCI device. Defining an instance with
multiple virtio NICs and vCPUs might lead to a possibility of hitting the guest MSI limit.
* virtio-net multiqueue works well for incoming traffic, but can occasionally cause
a performance degradation, for outgoing traffic. Specifically, this may occur when
sending packets under 1,500 bytes over the Transmission Control Protocol (TCP) stream.
* Enabling virtio-net multiqueue increases the total network throughput, but in parallel
it also increases the CPU consumption.
* Enabling virtio-net multiqueue in the host QEMU config, does not enable the functionality
in the guest OS. The guest OS administrator needs to manually turn it on for each guest
NIC that requires this feature, using ethtool.
* MSI vectors would still be consumed (wasted), if multiqueue was enabled in the
host, but has not been enabled in the guest OS by the administrator.
* In case the number of vNICs in a guest instance is proportional to the number of vCPUs,
enabling the multiqueue feature is less important.
* Each virtio-net queue consumes 64 KB of kernel memory for the vhost driver.

*NOTE*: Virtio-net multiqueue should be enabled in the guest OS manually, using ethtool.
For example:
`ethtool -L <NIC> combined #num_of_queues`

More information please refer to [KVM/QEMU MultiQueue](http://www.linux-kvm.org/page/Multiqueue).

### sriov

In `sriov` mode, virtual machines are directly exposed to an SR-IOV PCI device,
usually allocated by [Intel SR-IOV device
plugin](https://github.com/intel/sriov-network-device-plugin). The device is
passed through into the guest operating system as a host device, using the
[vfio](https://www.kernel.org/doc/Documentation/vfio.txt) userspace interface,
to maintain high networking performance.

> **Note:** you need to enable the SRIOV feature gate to use the feature. For
> example:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kube-system
  labels:
    kubevirt.io: ""
data:
  feature-gates: "SRIOV"
```

Information on how to set up Intel SR-IOV device plugin can be found
[in their respective documentation](https://github.com/intel/sriov-network-device-plugin/blob/master/README.md).

> **Note:** while the `sriov` mode is validated and tested using the Intel
> SR-IOV device plugin, other plugins may add support for the same by setting
> the `PCIDEVICE_<resourceName>` environment variables inside pods to a list of
> allocated PCI device IDs, as in:
> PCIDEVICE_VENDOR_COM_RESOURCE_NAME=0000:81:11.1,0000:81:11.2[,...]

> **Note:** as of the time of writing, in addition to attaching a VM to a
> SR-IOV network, you have to also request corresponding devices from the
> device plugin, by adding appropriate `resources.limits` and
> `resources.requests` entries.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: sriov-net
          sriov: {}
    resources:
      limits:
        intel.com/sriov: "1"
      requests:
        intel.com/sriov: "1"
  networks:
  - name: sriov-net
    multus:
      networkName: sriov-net-crd
```
