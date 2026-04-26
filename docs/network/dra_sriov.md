# DRA-based SR-IOV for Virtual Machines

[v1.9] - Alpha

This guide shows how to connect a VM to an SR-IOV network using Kubernetes DRA (Dynamic Resource Allocation).
In this model, SR-IOV devices are requested through `ResourceClaim` APIs and attached through KubeVirt `resourceClaim` networks.

## Before you begin

- Enable and configure an external SR-IOV DRA driver in the cluster.
- Ensure a matching `DeviceClass` exists for SR-IOV devices.
- Enable the `NetworkDevicesWithDRA` KubeVirt feature gate.
- Use Kubernetes v1.36 or newer (required for DRA device metadata file support).

!!! warning
    In Alpha, DRA-based SR-IOV and legacy device-plugin SR-IOV are mutually exclusive at cluster level.
    Use a single SR-IOV mode per cluster.

## 1) Enable the KubeVirt feature gate

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
      - NetworkDevicesWithDRA
```

For more details, see [Activating and deactivating feature gates](../cluster_admin/activating_feature_gates.md).

## 2) Create network and claim objects

Create a `NetworkAttachmentDefinition` used by SR-IOV CNI:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: sriov-nad
spec:
  config: |
    {
      "cniVersion": "0.4.0",
      "name": "sriov-nad",
      "type": "sriov",
      "ipam": { "type": "host-local", "ranges": [[{"subnet":"10.0.1.0/24"}]] }
    }
```

Create a `ResourceClaimTemplate` that requests an SR-IOV VF from DRA:

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaimTemplate
metadata:
  name: sriov-claim-template
spec:
  spec:
    devices:
      requests:
      - name: vf
        exactly:
          deviceClassName: sriovnetwork.k8snetworkplumbingwg.io
      config:
      - requests: ["vf"]
        opaque:
          driver: sriovnetwork.k8snetworkplumbingwg.io
          parameters:
            apiVersion: sriovnetwork.k8snetworkplumbingwg.io/v1alpha1
            kind: VfConfig
            netAttachDefName: sriov-nad
            driver: vfio-pci
            addVhostMount: true
```

## 3) Attach the DRA SR-IOV network to a VMI

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: vmi-sriov-dra
spec:
  domain:
    devices:
      interfaces:
      - name: sriov-net
        sriov: {}
  networks:
  - name: sriov-net
    resourceClaim:
      claimName: sriov-network-claim
      requestName: vf
  resourceClaims:
  - name: sriov-network-claim
    resourceClaimTemplateName: sriov-claim-template
```

The `networks[].resourceClaim.claimName` must match `spec.resourceClaims[].name`, and `requestName` must match the request in the claim (`vf` in this example).
