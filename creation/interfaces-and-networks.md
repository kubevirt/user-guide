Interfaces and Networks
=======================

Connecting a virtual machine to a network consists of two parts. First,
networks are specified in `spec.networks`. Then, interfaces backed by
the networks are added to the VM by specifying them in
`spec.domain.devices.interfaces`.

Each interface must have a corresponding network with the same name.

An `interface` defines a virtual network interface of a virtual machine
(also called a frontend). A `network` specifies the backend of an
`interface` and declares which logical or physical device it is
connected to (also called as backend).

There are multiple ways of configuring an `interface` as well as a
`network`.

All possible configuration options are available in the [Interface API
Reference](https://kubevirt.io/api-reference/master/definitions.html#_v1_interface)
and [Network API
Reference](https://kubevirt.io/api-reference/master/definitions.html#_v1_network).

Backend
-------

Network backends are configured in `spec.networks`. A network must have
a unique name. Additional fields declare which logical or physical
device the network relates to.

Each network should declare its type by defining one of the following
fields:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th>Type</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><code>pod</code></p></td>
<td><p>Default Kubernetes network</p></td>
</tr>
<tr class="even">
<td><p><code>multus</code></p></td>
<td><p>Secondary network provided using Multus</p></td>
</tr>
<tr class="odd">
<td><p><code>genie</code></p></td>
<td><p>Secondary network provided using Genie</p></td>
</tr>
</tbody>
</table>

### pod

A `pod` network represents the default pod `eth0` interface configured
by cluster network solution that is present in each pod.

    kind: VM
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              masquerade: {}
      networks:
      - name: default
        pod: {} # Stock pod network

### multus

It is also possible to connect VMIs to secondary networks using
[Multus](https://github.com/intel/multus-cni). This assumes that multus
is installed across your cluster and a corresponding
`NetworkAttachmentDefinition` CRD was created.

The following example defines a network which uses the [ovs-cni
plugin](https://github.com/kubevirt/ovs-cni), which will connect the VMI
to Open vSwitch’s bridge `br1` and VLAN 100. Other CNI plugins such as
ptp, bridge, macvlan or Flannel might be used as well. For their
installation and usage refer to the respective project documentation.

First the `NetworkAttachmentDefinition` needs to be created. That is
usually done by an administrator. Users can then reference the
definition.

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

With following definition, the VMI will be connected to the default pod
network and to the secondary Open vSwitch network.

    kind: VM
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              masquerade: {}
              bootFileName: default_image.bin
              tftpServerName: tftp.example.com
              bootOrder: 1   # attempt to boot from an external tftp server
            - name: ovs-net
              bridge: {}
              bootOrder: 2   # if first attempt failed, try to PXE-boot from this L2 networks
      networks:
      - name: default
        pod: {} # Stock pod network
      - name: ovs-net
        multus: # Secondary multus network
          networkName: ovs-vlan-100

It is also possible to define a multus network as the default pod
network with [Multus](https://github.com/intel/multus-cni). A version of
multus after this [Pull
Request](https://github.com/intel/multus-cni/pull/174) is required
(currently master).

**Note the following:**

-   A multus default network and a pod network type are mutually
    exclusive.

-   The virt-launcher pod that starts the VMI will **not** have the pod
    network configured.

-   The multus delegate chosen as default **must** return at least one
    IP address.

Create a `NetworkAttachmentDefinition` with IPAM.

    apiVersion: "k8s.cni.cncf.io/v1"
    kind: NetworkAttachmentDefinition
    metadata:
      name: macvlan-test
    spec:
      config: '{
          "type": "macvlan",
          "master": "eth0",
          "mode": "bridge",
          "ipam": {
            "type": "host-local",
                  "subnet": "10.250.250.0/24"
          }
        }'

Define a VMI with a [Multus](https://github.com/intel/multus-cni)
network as the default.

    kind: VM
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
          networkName: macvlan-test

### genie

It is also possible to connect VMIs to multiple networks using
[Genie](https://github.com/Huawei-PaaS/CNI-Genie). This assumes that
genie is installed across your cluster.

The following example defines a network which uses
[Flannel](https://github.com/coreos/flannel-cni) as the main network
provider and as the [ovs-cni
plugin](https://github.com/kubevirt/ovs-cni) as the secondary one. The
OVS CNI will connect the VMI to Open vSwitch’s bridge `br1` and VLAN
100.

Other CNI plugins such as ptp, bridge, macvlan might be used as well.
For their installation and usage refer to the respective project
documentation.

Genie does not use the `NetworkAttachmentDefinition` CRD. Instead it
uses the name of the underlying CNI in order to find the required
configuration. It does that by looking into the configuration files
under `/etc/cni/net.d/` and finding the file that has that network name
as the CNI type. Therefore, for the case described above, the following
configuration file should exist, for example,
`/etc/cni/net.d/99-ovs-cni.conf` file would be:

    {
      "cniVersion": "0.3.1",
      "type": "ovs",
      "bridge": "br1",
      "vlan": 100
    }

Similarly to Multus, Genie’s configuration file must be the first one in
the `/etc/cni/net.d/` directory. This also means that Genie cannot be
used together with Multus on the same cluster.

With following definition, the VMI will be connected to the default pod
network and to the secondary Open vSwitch network.

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

Frontend
--------

Network interfaces are configured in `spec.domain.devices.interfaces`.
They describe properties of virtual interfaces as “seen” inside guest
instances. The same network backend may be connected to a virtual
machine in multiple different ways, each with their own connectivity
guarantees and characteristics.

Each interface should declare its type by defining on of the following
fields:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr class="header">
<th>Type</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><code>bridge</code></p></td>
<td><p>Connect using a linux bridge</p></td>
</tr>
<tr class="even">
<td><p><code>slirp</code></p></td>
<td><p>Connect using QEMU user networking mode</p></td>
</tr>
<tr class="odd">
<td><p><code>sriov</code></p></td>
<td><p>Pass through a SR-IOV PCI device via <code>vfio</code></p></td>
</tr>
<tr class="even">
<td><p><code>masquerade</code></p></td>
<td><p>Connect using Iptables rules to nat the traffic</p></td>
</tr>
</tbody>
</table>

Each interface may also have additional configuration fields that modify
properties “seen” inside guest instances, as listed below:

<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead>
<tr class="header">
<th>Name</th>
<th>Format</th>
<th>Default value</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><code>model</code></p></td>
<td><p>One of: <code>e1000</code>, <code>e1000e</code>, <code>ne2k_pci</code>, <code>pcnet</code>, <code>rtl8139</code>, <code>virtio</code></p></td>
<td><p><code>virtio</code></p></td>
<td><p>NIC type</p></td>
</tr>
<tr class="even">
<td><p>macAddress</p></td>
<td><p><code>ff:ff:ff:ff:ff:ff</code> or <code>FF-FF-FF-FF-FF-FF</code></p></td>
<td></td>
<td><p>MAC address as seen inside the guest system, for example: <code>de:ad:00:00:be:af</code></p></td>
</tr>
<tr class="odd">
<td><p>ports</p></td>
<td></td>
<td><p>empty</p></td>
<td><p>List of ports to be forwarded to the virtual machine.</p></td>
</tr>
<tr class="even">
<td><p>pciAddress</p></td>
<td><p><code>0000:81:00.1</code></p></td>
<td></td>
<td><p>Set network interface PCI address, for example: <code>0000:81:00.1</code></p></td>
</tr>
</tbody>
</table>

    kind: VM
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              model: e1000 # expose e1000 NIC to the guest
              masquerade: {} # connect through a masquerade
              ports:
               - name: http
                 port: 80
      networks:
      - name: default
        pod: {}

> **Note:** If a specific MAC address is configured for a virtual
> machine interface, it’s passed to the underlying CNI plugin that is
> expected to configure the backend to allow for this particular MAC
> address. Not every plugin has native support for custom MAC addresses.

> **Note:** For some CNI plugins without native support for custom MAC
> addresses, there is a workaround, which is to use the `tuning` CNI
> plugin to adjust pod interface MAC address. This can be used as
> follows:
>
>     apiVersion: "k8s.cni.cncf.io/v1"
>     kind: NetworkAttachmentDefinition
>     metadata:
>       name: ptp-mac
>     spec:
>       config: '{
>           "cniVersion": "0.3.1",
>           "name": "ptp-mac",
>           "plugins": [
>             {
>               "type": "ptp",
>               "ipam": {
>                 "type": "host-local",
>                 "subnet": "10.1.1.0/24"
>               }
>             },
>             {
>               "type": "tuning"
>             }
>           ]
>         }'
>
> This approach may not work for all plugins. For example, OKD SDN is
> not compatible with `tuning` plugin.
>
> -   Plugins that handle custom MAC addresses natively: `ovs`.
>
> -   Plugins that are compatible with `tuning` plugin: `flannel`,
>     `ptp`, `bridge`.
>
> -   Plugins that don’t need special MAC address treatment: `sriov` (in
>     `vfio` mode).
>
### Ports

Declare ports listen by the virtual machine

> **Note:** When using the slirp interface only the configured ports
> will be forwarded to the virtual machine.

<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead>
<tr class="header">
<th>Name</th>
<th>Format</th>
<th>Required</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><code>name</code></p></td>
<td></td>
<td><p>no</p></td>
<td><p>Name</p></td>
</tr>
<tr class="even">
<td><p><code>port</code></p></td>
<td><p>1 - 65535</p></td>
<td><p>yes</p></td>
<td><p>Port to expose</p></td>
</tr>
<tr class="odd">
<td><p><code>protocol</code></p></td>
<td><p>TCP,UDP</p></td>
<td><p>no</p></td>
<td><p>Connection protocol</p></td>
</tr>
</tbody>
</table>

> **Tip:** Use `e1000` model if your guest image doesn’t ship with
> virtio drivers.

> **Note:** Windows machines need the latest virtio network driver to
> configure the correct MTU on the interface.

If `spec.domain.devices.interfaces` is omitted, the virtual machine is
connected using the default pod network interface of `bridge` type. If
you’d like to have a virtual machine instance without any network
connectivity, you can use the `autoattachPodInterface` field as follows:

    kind: VM
    spec:
      domain:
        devices:
          autoattachPodInterface: false

### bridge

In `bridge` mode, virtual machines are connected to the network backend
through a linux “bridge”. The pod network IPv4 address is delegated to
the virtual machine via DHCPv4. The virtual machine should be configured
to use DHCP to acquire IPv4 addresses.

> **Note:** If a specific MAC address is not configured in the virtual
> machine interface spec the MAC address from the relevant pod interface
> is delegated to the virtual machine.

    kind: VM
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

At this time, `bridge` mode doesn’t support additional configuration
fields.

> **Note:** due to IPv4 address delegation, in `bridge` mode the pod
> doesn’t have an IP address configured, which may introduce issues with
> third-party solutions that may rely on it. For example, Istio may not
> work in this mode.

> **Note:** admin can forbid using `bridge` interface type for pod
> networks via a designated configuration flag. To achieve it, the admin
> should set the following option to `false`:

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      permitBridgeInterfaceOnPodNetwork: "false"

> **Note:** binding the pod network using `bridge` interface type may
> cause issues. Other than the third-party issue mentioned in the above
> note, live migration is not allowed with a pod network binding of
> `bridge` interface type, and also some CNI plugins might not allow to
> use a custom MAC address for your VM instances. If you think you may
> be affected by any of issues mentioned above, consider changing the
> default interface type to `masquerade`, and disabling the `bridge`
> type for pod network, as shown in the example above.

### slirp

In `slirp` mode, virtual machines are connected to the network backend
using QEMU user networking mode. In this mode, QEMU allocates internal
IP addresses to virtual machines and hides them behind NAT.

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

At this time, `slirp` mode doesn’t support additional configuration
fields.

> **Note:** in `slirp` mode, the only supported protocols are TCP and
> UDP. ICMP is *not* supported.

More information about SLIRP mode can be found in [QEMU
Wiki](https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29).

### masquerade

In `masquerade` mode, KubeVirt allocates internal IP addresses to
virtual machines and hides them behind NAT. All the traffic exiting
virtual machines is "NAT’ed" using pod IP addresses. A virtual machine
should be configured to use DHCP to acquire IPv4 addresses.

To allow traffic into virtual machines, the template `ports` section of
the interface should be configured as follows.

    kind: VM
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

> **Note:** Masquerade is only allowed to connect to the pod network.

> **Note:** The network CIDR can be configured in the pod network
> section using the `vmNetworkCIDR` attribute.

### virtio-net multiqueue

Setting the `networkInterfaceMultiqueue` to `true` will enable the
multi-queue functionality, increasing the number of vhost queue, for
interfaces configured with a `virtio` model.

    kind: VM
    spec:
      domain:
        devices:
          networkInterfaceMultiqueue: true

Users of a Virtual Machine with multiple vCPUs may benefit of increased
network throughput and performance.

Currently, the number of queues is being determined by the number of
vCPUs of a VM. This is because multi-queue support optimizes RX
interrupt affinity and TX queue selection in order to make a specific
queue private to a specific vCPU.

Without enabling the feature, network performance does not scale as the
number of vCPUs increases. Guests cannot transmit or retrieve packets in
parallel, as virtio-net has only one TX and RX queue.

*NOTE*: Although the virtio-net multiqueue feature provides a
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

-   Each virtio-net queue consumes 64 KB of kernel memory for the vhost
    driver.

*NOTE*: Virtio-net multiqueue should be enabled in the guest OS
manually, using ethtool. For example:
`ethtool -L <NIC> combined #num_of_queues`

More information please refer to [KVM/QEMU
MultiQueue](http://www.linux-kvm.org/page/Multiqueue).

### sriov

In `sriov` mode, virtual machines are directly exposed to an SR-IOV PCI
device, usually allocated by [Intel SR-IOV device
plugin](https://github.com/intel/sriov-network-device-plugin). The
device is passed through into the guest operating system as a host
device, using the
[vfio](https://www.kernel.org/doc/Documentation/vfio.txt) userspace
interface, to maintain high networking performance.

    kind: VM
    spec:
      domain:
        devices:
          interfaces:
            - name: sriov-net
              sriov: {}
      networks:
      - name: sriov-net
        multus:
          networkName: sriov-net-crd

To simplify procedure, please use [OpenShift SR-IOV
operator](https://github.com/openshift/sriov-network-operator) to deploy
and configure SR-IOV components in your cluster. On how to use the
operator, please refer to [their respective
documentation](https://github.com/openshift/sriov-network-operator/blob/master/doc/quickstart.md).

> **Note:** KubeVirt relies on VFIO userspace driver to pass PCI devices
> into VMI guest. Because of that, when configuring SR-IOV operator
> policies, make sure you define a pool of VF resources that uses
> `driver: vfio`.
