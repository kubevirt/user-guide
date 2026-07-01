# Assigning GPUs with Dynamic Resource Allocation (DRA)

**FEATURE STATE:** v1.9.0: Beta

KubeVirt can attach GPUs to virtual machines through Kubernetes [Dynamic Resource Allocation (DRA)](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/).
With DRA, a GPU is requested through the Kubernetes `ResourceClaim` API, allocated by an external GPU DRA driver, and attached to the VM through `spec.resourceClaims` and `spec.domain.devices.gpus`.

This is an alternative to the device-plugin flow documented in [Host Devices Assignment](host-devices.md).
With DRA, you do not need to allowlist GPUs in `permittedHostDevices`.
Instead, the DRA driver publishes `ResourceSlice` objects and KubeVirt reads device metadata from files mounted into virt-launcher.

!!! Note
    Throughout this guide, **Container Device Interface (CDI)** refers to the Kubernetes mechanism that DRA drivers use to inject device nodes into virt-launcher pods — not [Containerized Data Importer](../storage/containerized_data_importer.md), which KubeVirt uses for disk import workflows.

`GPUsWithDRA` feature gate is in Beta and is enabled by default starting in v1.9.0.
The only earlier release that supports it is v1.8.x, where you must enable it manually.

See [Activating feature gates](../cluster_admin/activating_feature_gates.md) to enable it on earlier releases or to disable it.

## Prerequisites

- **GPU DRA driver.** Install a compatible external GPU DRA driver in the cluster.

    This guide documents the [NVIDIA k8s-dra-driver-gpu](https://github.com/kubernetes-sigs/dra-driver-nvidia-gpu) for production clusters.

    The driver must publish [DRA device metadata (KEP-5304)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/5304-dra-attributes-downward-api) — device attributes such as `resource.kubernetes.io/pciBusID` — in JSON files mounted into virt-launcher.
    KubeVirt reads these files to build the libvirt domain XML for the GPU.
    This is separate from the VFIO device nodes that CDI mounts at runtime: CDI delivers the `/dev/vfio/*` device nodes; the metadata file identifies which PCI device to attach.
    Driver authors can find details on publishing these attributes in [Access DRA device metadata](https://kubernetes.io/docs/tasks/configure-pod-container/assign-resources/access-dra-device-metadata/).

- **Host preparation for passthrough GPUs.** For passthrough allocations, GPU nodes must meet the usual PCI passthrough requirements (IOMMU enabled, `vfio-pci` available).
    See [Host Devices Assignment](host-devices.md#host-preparation-for-pci-passthrough).

## Overview

The high-level workflow is:

1. Install a GPU DRA driver on the cluster.
2. Create a `ResourceClaimTemplate` that requests a GPU from the driver.
3. Create a VMI that references the claim and maps it to `spec.domain.devices.gpus`.

##  Installing the DRA GPU driver

### DRA driver for NVIDIA GPUs

Install the [dra-driver-nvidia-gpu](https://github.com/kubernetes-sigs/dra-driver-nvidia-gpu).

For installation details, see the [installation guide](https://dra-driver-nvidia-gpu.sigs.k8s.io/docs/install/).

For enabling GPU passthrough support in the DRA driver, see the [KubeVirt VFIO GPU passthrough guide](https://dra-driver-nvidia-gpu.sigs.k8s.io/docs/guides/kubevirt-vfio-gpu-passthrough/).

## Creating a ResourceClaimTemplate

Create a `ResourceClaimTemplate` that requests a GPU from the DRA driver.
Replace `vfio.gpu.nvidia.com` with the `DeviceClass` name published by your driver.

When using the DRA driver for NVIDIA GPUs for KubeVirt passthrough, include the opaque `VfioDeviceConfig` block below.
The NVIDIA driver does not inject the VFIO API device by default.
See the [VfioDeviceConfig](https://dra-driver-nvidia-gpu.sigs.k8s.io/docs/guides/kubevirt-vfio-gpu-passthrough/#vfiodeviceconfig-parameters) parameters in the driver guide for more details.

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaimTemplate
metadata:
  name: dra-gpu-claim-template
spec:
  spec:
    devices:
      config:
        - requests:
            - dra-gpu
          opaque:
            driver: gpu.nvidia.com
            parameters:
              apiVersion: resource.nvidia.com/v1beta1
              kind: VfioDeviceConfig
              iommu:
                backendPolicy: LegacyOnly
                enableAPIDevice: true
      requests:
        - name: dra-gpu
          exactly:
            allocationMode: ExactCount
            count: 1
            deviceClassName: vfio.gpu.nvidia.com
```

## Creating a VMI with a DRA GPU

Reference the claim template in `spec.resourceClaims`, then map the allocated GPU to `spec.domain.devices.gpus` using `claimName` and `requestName`.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: vm-dra-gpu
  labels:
    app: vm-dra-gpu-test
spec:
  resourceClaims:
    - name: dra-gpu-claim
      resourceClaimTemplateName: dra-gpu-claim-template
  domain:
    resources:
      requests:
        memory: 128Mi
    cpu:
      cores: 1
    devices:
      disks:
        - name: containerdisk
          disk:
            bus: virtio
      interfaces:
        - name: default
          masquerade: {}
      gpus:
        - name: gpu0
          claimName: dra-gpu-claim
          requestName: dra-gpu
  networks:
    - name: default
      pod: {}
  volumes:
    - name: containerdisk
      containerDisk:
        image: quay.io/kubevirt/cirros-container-disk-demo:latest
```

!!! warning "Important"
    **These fields must reference each other:**

    - `spec.resourceClaims[].resourceClaimTemplateName` must match the `metadata.name` of the `ResourceClaimTemplate` created in step 2 (`dra-gpu-claim-template` in this example).
    - `spec.domain.devices.gpus[].claimName` must match `spec.resourceClaims[].name` for the claim that backs the device   (`dra-gpu-claim` in this example).
    - `spec.domain.devices.gpus[].requestName` must match the request `name` defined in the `ResourceClaimTemplate` (`dra-gpu` in this example).

When the VMI starts, virt-launcher uses the metadata file for attributes such as `resource.kubernetes.io/pciBusID` and the CDI-mounted `/dev/vfio/*` device nodes to configure GPU passthrough in the libvirt domain XML.
