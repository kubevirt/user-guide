# Interfaces and Networks

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

## Backend

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
</tbody>
</table>

### pod

A `pod` network represents the default pod `eth0` interface configured
by cluster network solution that is present in each pod.

```yaml
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
```

### multus

It is also possible to connect VMIs to secondary networks using
[Multus](https://github.com/intel/multus-cni). This assumes that multus
is installed across your cluster and a corresponding
`NetworkAttachmentDefinition` CRD was created.

The following example defines a network which uses the [ovs-cni
plugin](https://github.com/kubevirt/ovs-cni), which will connect the VMI
to Open vSwitch's bridge `br1` and VLAN 100. Other CNI plugins such as
ptp, bridge, macvlan or Flannel might be used as well. For their
installation and usage refer to the respective project documentation.

First the `NetworkAttachmentDefinition` needs to be created. That is
usually done by an administrator. Users can then reference the
definition.

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

With following definition, the VMI will be connected to the default pod
network and to the secondary Open vSwitch network.

```yaml
kind: VM
spec:
  domain:
    devices:
      interfaces:
        - name: default
          masquerade: {}
          bootOrder: 1   # attempt to boot from an external tftp server
          dhcpOptions:
            bootFileName: default_image.bin
            tftpServerName: tftp.example.com
        - name: ovs-net
          bridge: {}
          bootOrder: 2   # if first attempt failed, try to PXE-boot from this L2 networks
  networks:
  - name: default
    pod: {} # Stock pod network
  - name: ovs-net
    multus: # Secondary multus network
      networkName: ovs-vlan-100
```

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

```yaml
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
```

Define a VMI with a [Multus](https://github.com/intel/multus-cni)
network as the default.

```yaml
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
```

#### Invalid CNIs for secondary networks
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

## Frontend

Network interfaces are configured in `spec.domain.devices.interfaces`.
They describe properties of virtual interfaces as "seen" inside guest
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
properties "seen" inside guest instances, as listed below:

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

```yaml
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
```

> **Note:** For secondary interfaces, when a MAC address is specified for a
> virtual machine interface, it is passed to the underlying CNI plugin which is,
> in turn, expected to configure the backend to allow for this particular MAC.
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

> **Tip:** Use `e1000` model if your guest image doesn't ship with
> virtio drivers.

> **Note:** Windows machines need the latest virtio network driver to
> configure the correct MTU on the interface.

If `spec.domain.devices.interfaces` is omitted, the virtual machine is
connected using the default pod network interface of `bridge` type. If
you'd like to have a virtual machine instance without any network
connectivity, you can use the `autoattachPodInterface` field as follows:

```yaml
kind: VM
spec:
  domain:
    devices:
      autoattachPodInterface: false
```

### bridge

In `bridge` mode, virtual machines are connected to the network backend
through a linux "bridge". The pod network IPv4 address is delegated to
the virtual machine via DHCPv4. The virtual machine should be configured
to use DHCP to acquire IPv4 addresses.

> **Note:** If a specific MAC address is not configured in the virtual
> machine interface spec the MAC address from the relevant pod interface
> is delegated to the virtual machine.

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
apiVersion: kubevirt.io/v1alpha3
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

### slirp

In `slirp` mode, virtual machines are connected to the network backend
using QEMU user networking mode. In this mode, QEMU allocates internal
IP addresses to virtual machines and hides them behind NAT.

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

At this time, `slirp` mode doesn't support additional configuration
fields.

> **Note:** in `slirp` mode, the only supported protocols are TCP and
> UDP. ICMP is *not* supported.

More information about SLIRP mode can be found in [QEMU
Wiki](https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29).

### masquerade

In `masquerade` mode, KubeVirt allocates internal IP addresses to
virtual machines and hides them behind NAT. All the traffic exiting
virtual machines is "NAT'ed" using pod IP addresses. A guest operating system
should be configured to use DHCP to acquire IPv4 addresses.

To allow traffic of specific ports into virtual machines, the template `ports` section of
the interface should be configured as follows. If the `ports` section is missing,
all ports forwarded into the VM.

```yaml
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
kind: VM
spec:
  domain:
    devices:
      disks:
        - disk:
          bus: virtio
          name: cloudinitdisk
      interfaces:
        - name: red
          masquerade: {} # connect using masquerade mode
          ports:
            - port: 80 # allow incoming traffic on port 80 to get into the virtual machine
  networks:
  - name: red
    pod: {}
  volumes:
  - cloudInitNoCloud:
      networkData: |
        version: 2
        ethernets:
          eth0:
            dhcp4: true
            addresses: [ fd10:0:2::2/120 ]
            gateway6: fd10:0:2::1
      userData: |-
        #!/bin/bash
        echo "fedora" |passwd fedora --stdin
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

### virtio-net multiqueue

Setting the `networkInterfaceMultiqueue` to `true` will enable the
multi-queue functionality, increasing the number of vhost queue, for
interfaces configured with a `virtio` model.

```yaml
kind: VM
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

-   Each virtio-net queue consumes 64 KiB of kernel memory for the vhost
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

#### How to expose SR-IOV VFs to KubeVirt
To simplify procedure, please use [OpenShift SR-IOV
operator](https://github.com/openshift/sriov-network-operator) to deploy
and configure SR-IOV components in your cluster. On how to use the
operator, please refer to [their respective
documentation](https://github.com/openshift/sriov-network-operator/blob/master/doc/quickstart.md).

> **Note:** KubeVirt relies on VFIO userspace driver to pass PCI devices
> into VMI guest. Because of that, when configuring SR-IOV operator
> policies, make sure you define a pool of VF resources that uses
> `driver: vfio`.

Once the operator is deployed, an [SriovNetworkNodePolicy
](https://github.com/openshift/sriov-network-operator#sriovnetworknodeconfigpolicy)
must be provisioned, in which the list of SR-IOV devices to expose (with
respective configurations) is defined.

Please refer to the following `SriovNetworkNodePolicy` for an example:

```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: policy-1
  namespace: sriov-network-operator
spec:
  deviceType: vfio-pci
  mtu: 9000
  nicSelector:
    pfNames:
    - ens1f0
  nodeSelector:
    sriov: "true"
  numVfs: 8
  priority: 90
  resourceName: sriov-nic
```

The policy above will configure the `SR-IOV` device plugin, allowing the
PF named `ens1f0` to be exposed in the SRIOV capable nodes as a resource named
`sriov-nic`.

#### Start an SR-IOV VM

Once all the SR-IOV components are deployed, it is needed to indicate how to
configure the SR-IOV network. Refer to the following
`SriovNetwork` for an example:

```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-net
  namespace: sriov-network-operator
spec:
  ipam: |
    {}
  networkNamespace: default
  resourceName: sriov-nic
  spoofChk: "off"
```

Finally, to create a VM that will attach to the aforementioned Network, refer
to the following VMI spec:

```yaml
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-perf
  name: vmi-perf
spec:
  domain:
    cpu:
      sockets: 2
      cores: 1
      threads: 1
      dedicatedCpuPlacement: true
    resources:
      requests:
        memory: "4Gi"
      limits:
        memory: "4Gi"
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      interfaces:
      - masquerade: {}
        name: default
      - name: sriov-net
        sriov: {}
      rng: {}
    machine:
      type: ""
  networks:
  - name: default
    pod: {}
  - multus:
      networkName: default/sriov-net
    name: sriov-net
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: docker.io/kubevirt/fedora-cloud-container-disk-demo:latest
    name: containerdisk
  - cloudInitNoCloud:
      userData: |
        #!/bin/bash
        echo "centos" |passwd centos --stdin
        dhclient eth1
    name: cloudinitdisk
```

> **Note:** for some NICs (e.g. Mellanox), the kernel module needs to be
> installed in the guest VM.

> **Note:** Placement on dedicated CPUs can only be achieved if the Kubernetes CPU manager is running on the SR-IOV capable workers.
> For further details please refer to the [dedicated cpu resources documentation](https://kubevirt.io/user-guide/#/creation/dedicated-cpu).

### Macvtap

In `macvtap` mode, virtual machines are directly exposed to the Kubernetes
nodes L2 network. This is achieved by 'extending' an existing network interface
with a virtual device that has its own MAC address.

Macvtap interfaces are feature gated; to enable the feature, follow
[these](../operations/activating_feature_gates.md#how-to-activate-a-feature-gate)
instructions, in order to activate the `Macvtap` feature gate (case sensitive).

#### Limitations

- Live migration is not seamless, see [issue #5912](https://github.com/kubevirt/kubevirt/issues/5912#issuecomment-888938920)

#### How to expose host interface to the macvtap device plugin
To simplify the procedure, please use the
[Cluster Network Addons Operator](https://github.com/kubevirt/cluster-network-addons-operator)
to deploy and configure the macvtap components in your cluster.

The aforementioned operator effectively deploys the
[macvtap-cni](https://github.com/kubevirt/macvtap-cni) cni / device plugin
combo.

There are two different alternatives to configure which host interfaces get
exposed to the user, enabling them to create macvtap interfaces on top of:

- select the host interfaces: indicates which host interfaces are exposed.
- expose all interfaces: all interfaces of all hosts are exposed.

Both options are configured via the `macvtap-deviceplugin-config` ConfigMap,
and more information on how to configure it can be found in the
[macvtap-cni](https://github.com/kubevirt/macvtap-cni#deployment) repo.

You can find a minimal example, in which the `eth0` interface of the Kubernetes
nodes is exposed, via the `master` attribute.
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: macvtap-deviceplugin-config
data:
  DP_MACVTAP_CONF: |
    [
        {
            "name"     : "dataplane",
            "master"   : "eth0",
            "mode"     : "bridge",
            "capacity" : 50
        },
    ]
```

This step can be omitted, since the default configuration of the aforementioned
`ConfigMap` is to expose all host interfaces (which is represented by the
following configuration):
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: macvtap-deviceplugin-config
data:
  DP_MACVTAP_CONF: '[]'
```

#### Start a VM with macvtap interfaces

Once the macvtap components are deployed, it is needed to indicate how to
configure the macvtap network. Refer to the following
`NetworkAttachmentDefinition` for a simple example:

```yaml
---
kind: NetworkAttachmentDefinition
apiVersion: k8s.cni.cncf.io/v1
metadata:
  name: macvtapnetwork
  annotations:
    k8s.v1.cni.cncf.io/resourceName: macvtap.network.kubevirt.io/eth0
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "macvtapnetwork",
      "type": "macvtap"
      "mtu": 1500
    }'
```
The requested `k8s.v1.cni.cncf.io/resourceName` annotation must point to an
exposed host interface (via the `master` attribute, on the
`macvtap-deviceplugin-config` `ConfigMap`).

Finally, to create a VM that will attach to the aforementioned Network, refer
to the following VMI spec:

```yaml
---
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-host-network
  name: vmi-host-network
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      interfaces:
      - macvtap: {}
        name: hostnetwork
      rng: {}
    machine:
      type: ""
    resources:
      requests:
        memory: 1024M
  networks:
  - multus:
      networkName: macvtapnetwork
    name: hostnetwork
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: docker.io/kubevirt/fedora-cloud-container-disk-demo:devel
    name: containerdisk
  - cloudInitNoCloud:
      userData: |-
        #!/bin/bash
        echo "fedora" |passwd fedora --stdin
    name: cloudinitdisk
```
The requested `multus` `networkName` - i.e. `macvtapnetwork` - must match the
name of the provisioned `NetworkAttachmentDefinition`.

> **Note:** VMIs with macvtap interfaces can be migrated, but their MAC
> addresses **must** be statically set.

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
- cnv-bridge: Through the `macspoofchk`.

> **Note:** `cnv-bridge` is provided by
  [CNAO](https://github.com/kubevirt/cluster-network-addons-operator).
  The [bridge-cni](https://github.com/containernetworking/plugins) is planned
  to support the `macspoofchk` options as well.

The configuration is to be done on the  NetworkAttachmentDefinition by the
operator and any interface that refers to it, will have this feature enabled.

Below is an example of using the `cnv-bridge` CNI with `macspoofchk` enabled:
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: br-spoof-check
spec:
  config: '{
            "cniVersion": "0.3.1",
            "name": "br-spoof-check",
            "type": "cnv-bridge",
            "bridge": "br10",
            "macspoofchk": true
        }'
```

On the VMI, the network section should point to this
NetworkAttachmentDefinition by name:
```yaml
  networks:
  - name: default
    pod: {}
  - multus:
      networkName: br-spoof-check
    name: br10
```

#### Limitations

- The `cnv-bridge` CNI supports mac-spoof-check through nftables, therefore
the node must support nftables and have the `nft` binary deployed.
