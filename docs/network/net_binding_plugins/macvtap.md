# Macvtap binding

## Overview

With the `macvtap` binding plugin, virtual machines are directly exposed to the Kubernetes
nodes L2 network. This is achieved by 'extending' an existing network interface
with a virtual device that has its own MAC address.

Its main benefits are:

- Direct connection to the node nic with no intermediate bridges.

### Functionality support
| Functionality                            | Support |
|------------------------------------------|---------|
| Run without extra capabilities (on pod)  | Yes     |
| Migration support                        | No      |
| IPAM support (on pod)                    | No      |
| Primary network (pod network)            | No      |
| Secondary network                        | Yes     |

### Known Issues

- Live migration is not fully supported, see [issue #5912](https://github.com/kubevirt/kubevirt/issues/5912#issuecomment-888938920)

> **Warning**: On [KinD](https://github.com/kubernetes-sigs/kind) clusters,
> the user needs to [adjust the cluster configuration](https://github.com/kubevirt/macvtap-cni/issues/39#issuecomment-1242765996),
mounting `dev` of the running host onto the KinD nodes, because of a
[known issue](https://github.com/kubevirt/macvtap-cni/issues/39).

### Deployment

The `macvtap` solution consists of a CNI and a DP.

In order to use `macvtap`, the following points need to be covered:

- Deploy the CNI plugin binary on the nodes.
- Deploy the Device Plugin daemon on the nodes.
- Configure which node interfaces are exposed.
- Define a NetworkAttachmentDefinition that points to the CNI plugin.

#### Macvtap CNI and DP deployment on nodes

To simplify the procedure, use the
[Cluster Network Addons Operator](https://github.com/kubevirt/cluster-network-addons-operator#macvtap)
to deploy and configure the macvtap components in your cluster.

The aforementioned operator effectively deploys the
[macvtap](https://github.com/kubevirt/macvtap-cni) cni and device plugin.

#### Expose node interface to the macvtap device plugin

There are two different alternatives to configure which host interfaces get
exposed to the user, enabling them to create macvtap interfaces on top of:

- select the host interfaces: indicates which host interfaces are exposed.
- expose all interfaces: all interfaces of all hosts are exposed.

Both options are configured via the `macvtap-deviceplugin-config` ConfigMap,
and more information on how to configure it can be found in the
[macvtap-cni](https://github.com/kubevirt/macvtap-cni#deployment) repo.

This is a minimal example, in which the `eth0` interface of the Kubernetes
nodes is exposed, via the `lowerDevice` attribute.

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: macvtap-deviceplugin-config
data:
  DP_MACVTAP_CONF: |
    [
        {
            "name"        : "dataplane",
            "lowerDevice" : "eth0",
            "mode"        : "bridge",
            "capacity"    : 50
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

#### Macvtap NetworkAttachmentDefinition

The configuration needed for a macvtap network attachment can be minimalistic:

```yaml
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
      "type": "macvtap",
      "mtu": 1500
    }'
```

The object should be created in a "default" namespace where all other namespaces
can access, or, in the same namespace the VMs reside in.

The requested `k8s.v1.cni.cncf.io/resourceName` annotation must point to an
exposed host interface (via the `lowerDevice` attribute, on the
`macvtap-deviceplugin-config` `ConfigMap`).

## Macvtap network binding plugin
[v1.1.1]

The binding plugin replaces the experimental core macvtap binding implementation
(including its API).

> **Note**: The network binding plugin infrastructure and the macvtap plugin
> specifically are in Alpha stage. Please use them with care, preferably
> on a non-production deployment.

The macvtap binding plugin consists of the following components:

- [Macvtap CNI plugin](https://github.com/kubevirt/macvtap-cni).

The plugin needs to:

- Register the binding plugin on the Kubevirt CR.
- Reference the network binding by name from the VM spec interface.

And in detail:

### Macvtap Registration
The macvtap binding plugin configuration needs to be added to the kubevirt CR
in order to be used by VMs.

To register the macvtap binding, patch the kubevirt CR as follows:

```yaml
kubectl patch kubevirts -n kubevirt kubevirt --type=json -p='[{"op": "add", "path": "/spec/configuration/network",   "value": {
            "binding": {
                "macvtap": {
                    "domainAttachmentType": "tap"
                }
            }
        }}]'
```

### VM Macvtap Network Interface
Set the VM network interface binding name to reference the one defined in the
kubevirt CR.

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-net-binding-macvtap
  name: vm-net-binding-macvtap
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-net-binding-macvtap
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
          - name: podnet
            masquerade: {}
          - name: hostnetwork
            binding:
              name: macvtap
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: podnet
        pod: {}
      - name: hostnetwork
        multus:
          networkName: macvtapnetwork
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.1.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            version: 2
            ethernets:
              eth0:
                dhcp4: true
        name: cloudinitdisk
```

The multus `networkName` value should correspond with the name used in
the [network attachment definition](#macvtap-networkattachmentdefinition) section.

The `binding` value should correspond with the name used in the
[registration](#macvtap-registration).
