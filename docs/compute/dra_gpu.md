# Assigning GPUs with DRA
Release:

- v1.9.0: Beta

KubeVirt can attach GPUs to virtual machines through Kubernetes [Dynamic Resource Allocation (DRA)](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/).
With DRA, a GPU is requested through the Kubernetes `ResourceClaim` API, allocated by an external GPU DRA driver, and attached to the VM through `spec.resourceClaims` and `spec.domain.devices.gpus`.

This is an alternative to the device-plugin flow documented in [Host Devices Assignment](host-devices.md).
With DRA, you do not need to allowlist GPUs in `permittedHostDevices`. Instead, the DRA driver publishes `ResourceSlice` objects and KubeVirt reads device metadata from files mounted into virt-launcher.

`GPUsWithDRA` is enabled by default starting in v1.9.0. See [Activating feature gates](../cluster_admin/activating_feature_gates.md) to enable it on earlier releases or to disable it.

## Prerequisites

- **GPU DRA driver.** Install a compatible external GPU DRA driver in the cluster.

    This guide documents the [NVIDIA k8s-dra-driver-gpu](https://github.com/kubernetes-sigs/dra-driver-nvidia-gpu) for production clusters. For development or testing without physical GPUs, see [Testing without physical GPUs](#testing-without-physical-gpus) in section 1.

    The driver must publish [DRA device metadata (KEP-5304)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/5304-dra-attributes-downward-api) — device attributes such as `resource.kubernetes.io/pciBusID` — in JSON files mounted into virt-launcher. KubeVirt reads these files to build the libvirt domain XML for the GPU. This is separate from the VFIO device nodes that CDI mounts at runtime: CDI delivers the `/dev/vfio` handles; the metadata file identifies which PCI device to attach. Enable device metadata in your driver (for NVIDIA, `featureGates.DeviceMetadata=true` in step 1).

- **Host preparation for passthrough GPUs.** For passthrough allocations, GPU nodes must meet the usual PCI passthrough requirements (IOMMU enabled, `vfio-pci` available). See [Host Devices Assignment](host-devices.md#host-preparation-for-pci-passthrough).

## Overview

The high-level workflow is:

1. Install a GPU DRA driver on the cluster.
2. Create a `ResourceClaimTemplate` that requests a GPU from the driver.
3. Create a VMI that references the claim and maps it to `spec.domain.devices.gpus`.

## 1. Install the DRA GPU driver

### DRA driver for NVIDIA GPUs

Install the [dra-driver-nvidia-gpu](https://github.com/kubernetes-sigs/dra-driver-nvidia-gpu). For installation details, see the [driver installation guide](https://dra-driver-nvidia-gpu.sigs.k8s.io/docs/install/).

```bash
helm install dra-driver-nvidia-gpu oci://registry.k8s.io/dra-driver-nvidia/charts/dra-driver-nvidia-gpu \
  --version 0.4.0 \
  --namespace dra-driver-nvidia-gpu \
  --create-namespace \
  --set gpuResourcesEnabledOverride=true \
  --set nvidiaDriverRoot=/run/nvidia/driver \
  --set resources.computeDomains.enabled=false \
  --set featureGates.PassthroughSupport=true \
  --set featureGates.DeviceMetadata=true
```

Set `nvidiaDriverRoot` based on how the NVIDIA driver is installed on your nodes:

- `/run/nvidia/driver` — GPU Operator-managed driver
- `/home/kubernetes/bin/nvidia` — GKE-managed driver
- `/` — Host-installed driver

The above helm command enables `PassthroughSupport` and `DeviceMetadata` during installation of DRA Driver for Nvidia GPUs. Other features left disabled unless your environment requires them.

#### Stop services and processes using NVIDIA GPUs

Before passthrough allocation, stop services that keep open handles on NVIDIA GPU devices (`/dev/nvidia0`, `/dev/nvidia1`, and so on).

```bash
sudo systemctl stop nvidia-dcgm dcgm nvidia-persistenced nvsm
```

Verify that no other process holds an open handle on GPU devices:

```bash
sudo lsof /dev/nvidia[^-]
```

This command should produce no output.

Common processes that block GPU passthrough include:

- **Xorg** — Identify and disable the display manager:
  ```bash
  sudo systemctl status display-manager
  sudo systemctl disable <display-manager-name>
  ```
- **vectorAdd** — A sample CUDA application; stop the process if it is running.
- **nvidia-device-plugin** — Disable or uninstall the legacy NVIDIA device plugin.
- **dcgm-exporter** — Disable or uninstall DCGM exporter.
- **NVIDIA GPU Operator** — If deployed via Helm, its pods may run `nvidia-device-plugin` and `dcgm-exporter`. Disable or uninstall the operator on GPU nodes where you use DRA passthrough.
- **nvidia-persistenced** — Disabling this service is optional. The DRA driver can handle it automatically.
- **nvidia-dcgm/dcgm** — Disabling this service is optional when running driver v4.5.0 or later.

After the driver is installed, confirm that it published `DeviceClass` and `ResourceSlice` objects for your GPUs. Use the published `deviceClassName` in step 2.

### Testing without physical GPUs

TBD. If you do not have physical GPUs available, you can try this workflow with the [dra-example-driver](https://github.com/kubernetes-sigs/dra-example-driver) `vfio-gpu` profile. This profile is separate from the driver's simulated `gpu` profile for containers and is intended for KubeVirt PCI passthrough via DRA. It discovers devices already bound to `vfio-pci` and publishes the `resource.kubernetes.io/pciBusID` device attribute that KubeVirt expects.

It is being added in [kubernetes-sigs/dra-example-driver#218](https://github.com/kubernetes-sigs/dra-example-driver/pull/218) (not yet merged).

## 2. Create a ResourceClaimTemplate

Create a `ResourceClaimTemplate` that requests a GPU from the DRA driver.
Replace `vfio.gpu.nvidia.com` with the `DeviceClass` name published by your driver.

When using the DRA driver for NVIDIA GPUs for KubeVirt passthrough, include the opaque `VfioDeviceConfig` block below. The NVIDIA driver does not inject the VFIO API device by default.

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

#### VfioDeviceConfig parameters

The opaque `VfioDeviceConfig` block tells the NVIDIA DRA driver which VFIO device nodes to mount into virt-launcher through CDI.

**`enableAPIDevice: true`** — Mounts the VFIO control device `/dev/vfio/vfio` into the virt-launcher pod. KubeVirt **requires** this device to manage VFIO PCI assignments through libvirt.

**`backendPolicy: LegacyOnly`** — Selects the legacy IOMMU VFIO backend (`/dev/vfio/<iommu-group>`). The alternative, `PreferIommuFD`, uses the IOMMUFD backend (`/dev/iommu` and `/dev/vfio/devices/vfio*`) when available on the host. KubeVirt does not support IOMMUFD yet, so use `LegacyOnly` today. When KubeVirt adds IOMMUFD support, you can switch to `PreferIommuFD`.

## 3. Create a VMI with a DRA GPU

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

!!! Note
    **These fields must reference each other:**

    - `spec.resourceClaims[].resourceClaimTemplateName` must match the `metadata.name` of the `ResourceClaimTemplate` created in step 2 (`dra-gpu-claim-template` in this example).
    - `spec.domain.devices.gpus[].claimName` must match `spec.resourceClaims[].name` for the claim that backs the device   (`dra-gpu-claim` in this example).
    - `spec.domain.devices.gpus[].requestName` must match the request `name` defined in the `ResourceClaimTemplate` (`dra-gpu` in this example).

When the VMI starts, virt-launcher uses the metadata file for attributes such as `resource.kubernetes.io/pciBusID` and the CDI-mounted `/dev/vfio` nodes to configure GPU passthrough in the libvirt domain XML.
