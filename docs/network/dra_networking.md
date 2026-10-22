# Connecting VMs to DRA-backed Networks

**FEATURE STATE:** v1.10.0: Beta

KubeVirt can connect a virtual machine to a network backed by Kubernetes [Dynamic Resource Allocation (DRA)](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/).
A device is requested through the Kubernetes `ResourceClaim` API and allocated by the DRA driver. The VM's network declares a new `resourceClaim` source that references the claim and request (by `claimName` and `requestName`), and the VM connects to that network through an interface configured by a matching [network binding plugin](network_binding_plugins.md).

The DRA driver and the network binding plugin interoperate through a contract defined by their authors. Choose a driver and binding plugin that are compatible, and refer to their documentation for the capabilities they support together.

!!! Note
    Both the DRA driver and the network binding plugin are external, third-party components. They are outside the scope of KubeVirt and of this guide.

!!! Note
    As of KubeVirt v1.10, DRA-backed networks work only with a [network binding plugin](network_binding_plugins.md). None of the core bindings support DRA.

## Admin vs user responsibility

The DRA network flow splits across two roles, and both must be in place before a DRA backed network can be used:

- **Cluster admin** prepares the cluster: enables the `NetworkDevicesWithDRA` feature gate and deploys the third-party components. See [Prerequisites](#prerequisites) for the concrete checklist.
- **VM owner (user)** creates the `ResourceClaim`/`ResourceClaimTemplate` and the VM manifest that references it, with an interface that uses the registered binding plugin and a network with a `resourceClaim` source.

## Feature gate

The `resourceClaim` network source is controlled by the `NetworkDevicesWithDRA` feature gate. As of KubeVirt v1.10, the feature gate is in Beta and is enabled by default.

Some KubeVirt distributions may disable it. If it is disabled in your cluster, enable it on the KubeVirt CR as described in
[Activating feature gates](../cluster_admin/activating_feature_gates.md).

## Prerequisites

- **The `NetworkDevicesWithDRA` feature gate enabled.**

- **Network device DRA driver.** An external DRA driver for the target network device type must be deployed in the cluster.

- **A [DeviceClass](https://kubernetes.io/docs/reference/kubernetes-api/resource/device-class-v1/)**. A `DeviceClass` is an admin-defined category of devices. It must exist for `ResourceClaim`/`ResourceClaimTemplate` objects to reference.

- **A registered network binding plugin.** The binding plugin that configures the DRA backed interface must be registered in the KubeVirt CR. See [Network Binding Plugins](network_binding_plugins.md) for how a cluster admin registers one.

## Example: connecting a VM to a DRA-backed network

The example below requests a device through a `ResourceClaimTemplate`, then connects a VM to the DRA-backed network.
It assumes a cluster admin has already registered the binding plugin `my-binding-plugin` in the KubeVirt CR

First, create a `ResourceClaimTemplate` that requests a device from the DRA driver:

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaimTemplate
metadata:
  name: network-claim-template
spec:
  spec:
    devices:
      requests:
      - name: dev
        exactly:
          deviceClassName: my-device-class
```

!!! Note
    The device request fields are specific to your DRA driver. See the driver's documentation for how to define the `ResourceClaimTemplate` correctly.

Then create a VM that references the claim template in `spec.template.spec.resourceClaims`, declares an interface that uses the binding plugin, and adds a network with a `resourceClaim` source that points at the claim and request:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-dra-binding-plugin
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: dra-net
            binding:
              name: my-binding-plugin
      networks:
      - name: dra-net
        resourceClaim:
          claimName: network-claim
          requestName: dev
      resourceClaims:
      - name: network-claim
        resourceClaimTemplateName: network-claim-template
```

!!! warning "Important"
    **These fields must reference each other:**

    - `spec.template.spec.resourceClaims[].resourceClaimTemplateName` must match the `metadata.name` of the `ResourceClaimTemplate` (`network-claim-template` in this example).
    - `spec.template.spec.networks[].resourceClaim.claimName` must match `spec.template.spec.resourceClaims[].name` for the claim that backs the device (`network-claim` in this example).
    - `spec.template.spec.networks[].resourceClaim.requestName` must match the request `name` defined in the `ResourceClaimTemplate` (`dev` in this example).

    The interface and the network are correlated by their shared `name` (`dra-net` in this example), exactly like any other KubeVirt interface/network pair.

## Validation rules

KubeVirt validates DRA network configuration when the VM/VMI is created. Your configuration must satisfy all of the following:

- An interface mapped to a `resourceClaim` network **must** use a network binding plugin.
- Both `claimName` and `requestName` must be set (non-empty).
- The `claimName` + `requestName` tuple must be **unique** across all networks, `hostDevices`, and `gpus` — no two entries may share the same claim and request.
- `multus` and `resourceClaim` network sources **cannot** be mixed in the same VMI.

## Known limitations

- **Live migration** is supported only for `resourceClaimTemplate`backed claims, not for a direct `resourceClaim` reference.
- **One device per request.** If a request allocates more than one device (`count > 1`), only the first allocated device is used.
