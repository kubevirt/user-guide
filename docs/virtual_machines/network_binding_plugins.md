# Network Binding Plugins
[v1.1.0, Alpha feature]

A modular plugin which integrates with Kubevirt to implement a
network binding.

## Overview

### Network Connectivity
In order for a VM to have access to external network(s), several layers
need to be defined and configured, depending on the connectivity characteristics
needs.

These layers include:

- Host connectivity: Network provider.
- Host to Pod connectivity: CNI.
- Pod to domain connectivity: Network Binding.

This guide focuses on the Network Binding portion.

### Network Binding
The network binding defines how the domain (VM) network interface is wired
in the VM pod through the domain to the guest.

The network binding includes:

- Domain vNIC configuration.
- Pod network configuration (optional).
- Services to deliver network details to the guest (optional).
  E.g. DHCP server to pass the IP configuration to the guest.

### Plugins
The network bindings have been part of Kubevirt core API and codebase.
With the increase of the number of network bindings added and
frequent requests to tweak and change the existing network bindings,
a decision has been made to create a network binding plugin infrastructure.

The plugin infrastructure provides means to compose a network binding plugin
and integrate it into Kubevirt in a modular manner.

Kubevirt is providing several network binding plugins as references.
The following plugins are available:

- [passt](net_binding_plugins/passt.md) [v1.1.0]
- [macvtap](net_binding_plugins/macvtap.md) [v1.1.1]
- [slirp](net_binding_plugins/slirp.md) [v1.1.0]

## Definition & Flow
A network binding plugin configuration consist of the following steps:

- Deploy network binding optional components:

  - Binding CNI plugin.
  - Binding NetworkAttachmentDefinition manifest.
  - Access to the sidecar image.
  - Enable `NetworkBindingPlugins` Feature Gate (FG).

- Register network binding.
- Assign VM network interface binding.

### Deployment
Depending on the plugin, some components need to be deployed in the cluster.
Not all network binding plugins require all these components, therefore
these steps are optional.

- Binding CNI plugin: When it is required to change the pod network stack
  (and a core domain-attachment is not a fit), a custom CNI plugin is
  composed to serve the network binding plugin.

  This binary needs to be deployed on each node of the cluster, like any
  other CNI plugin.

  The binary can be built from source or consumed from an existing artifact.

> **Note**: The location of the CNI plugins binaries depends on the platform
> used and its configuration. A frequently used path for such binaries is
> `/opt/cni/bin/`.

- Binding NetworkAttachmentDefinition: It references the binding CNI plugin,
  with optional configuration settings.
  The manifest needs to be deployed on the cluster at a namespace which
  is accessible by the VM and its pod.

Example:
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: netbindingpasst
spec:
  config: '{
            "cniVersion": "1.0.0",
            "name": "netbindingpasst",
            "plugins": [
              {
                "type": "cni-passt-binding-plugin"
              }
            ]
  }'
```

> **Note**: It is possible to deploy the NetworkAttachmentDefinition
> on the `default` namespace, where all other namespaces can access it.
> Nevertheless, it is recommended (for security reasons) to define the
> NetworkAttachmentDefinition in the same namespace the VM resides.

- [Multus](https://github.com/k8snetworkplumbingwg/multus-cni): In order
  for the network binding CNI and the NetworkAttachmentDefinition to operate,
  there is a need to have Multus deployed on the cluster.
  For more information, check the
  [Quickstart Intallation Guide](https://github.com/k8snetworkplumbingwg/multus-cni#quickstart-installation-guide).

- Sidecar image: When a core domain-attachment is not a fit, a sidecar is
  used to configure the vNIC domain configuration.
  In a more complex scenarios, the sidecar also runs services like DHCP to
  deliver IP information to the guest.

  The sidecar image is built and usually pushed to an image registry for
  consumption. Therefore, the cluster needs to have access to the image.
  
  The image can be built from source and pushed to an accessible registry
  or used from a given registry that already contains it.

- Feature Gate
  The network binding plugin is currently (v1.1.0) in Alpha stage, protected
  by a feature gate (FG) named `NetworkBindingPlugins`.

  It is therefore necessary to set the FG in the Kubevirt CR.

  Example (valid when the FG subtree is already defined):
```
kubectl patch kubevirts -n kubevirt kubevirt --type=json -p='[{"op": "add", "path": "/spec/configuration/developerConfiguration/featureGates/-",   "value": "NetworkBindingPlugins"}]'
```

### Register
In order to use a network binding plugin, the cluster admin needs to register
the binding.
Registration includes the addition of the binding name with all its parameters
to the Kubevirt CR.

The following (optional) parameters are currently supported:

- [networkAttachmentDefinition](#networkattachmentdefinition)
- [sidecarImage](#sidecarimage)
- [domainAttachmentType](#domainattachmenttype)
- [migration](#migration)

#### networkAttachmentDefinition
From: v1.1.0

Use the <namespace/object-name> format to specify
the [NetworkAttachementDefinition](https://github.com/k8snetworkplumbingwg/multi-net-spec/blob/master/v1.0/%5Bv1%5D%20Kubernetes%20Network%20Custom%20Resource%20Definition%20De-facto%20Standard.md)
that defines the CNI plugin and the configuration the binding plugin uses.
Used when the binding plugin needs to change the pod network namespace.

#### sidecarImage
From: v1.1.0

Specify a container image in a registry.
Used when the binding plugin needs to modify the domain vNIC configuration
or when a service needs to be executed (e.g. DHCP server). 

#### domainAttachmentType
From: v1.1.1

The Domain Attachment type is a pre-defined core kubevirt method to attach
an interface to the domain.

Specify the name of a core domain attachment type.
A possible alternative to a sidecar, to configure the domain vNIC.

Supported types:

- `tap` (from v1.1.1): The domain configuration is set to use an existing
  tap device. It also supports existing `macvtap` devices.

When both the `domainAttachmentType` and `sidecarImage` are specified,
the domain will first be configured according to the `domainAttachmentType`
and then the `sidecarImage` may modify it.

#### migration
From: v1.2.0

Specify whether the network binding plugin supports migration.
It is possible to specify a migration method.
Supported migration method types:
- `link-refresh` (from v1.2.0): after migration, the guest nic will be deactivated and then activated again.
   It can be useful to renew the DHCP lease.

> **Note**: In some deployments the Kubevirt CR is controlled by an external
> controller (e.g. [HCO](https://github.com/kubevirt/hyperconverged-cluster-operator)).
> In such cases, make sure to configure the wrapper operator/controller so the
> changes will get preserved.

Example (the `passt` binding):
```
kubectl patch kubevirts -n kubevirt kubevirt --type=json -p='[{"op": "add", "path": "/spec/configuration/network",   "value": {
            "binding": {
                "passt": {
                    "networkAttachmentDefinition": "default/netbindingpasst",
                    "sidecarImage": "quay.io/kubevirt/network-passt-binding:20231205_29a16d5c9"
                    "migration": {
                        "method": "link-refresh"
                    }
                }
            }
        }}]'
```

### VM Network Interface
When configuring the VM/VMI network interface, the binding plugin name
can be specified. If it exists in the Kubevirt CR, it will be used
to setup the network interface.

Example (`passt` binding):
```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-net-binding-passt
  name: vm-net-binding-passt
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-net-binding-passt
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
          - name: passtnet
            binding:
              name: passt
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: passtnet
        pod: {}
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
