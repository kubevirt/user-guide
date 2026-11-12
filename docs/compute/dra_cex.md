# Assigning Crypto Express devices with Dynamic Resource Allocation (DRA)

**FEATURE STATE:** v1.9.0: Beta

KubeVirt can attach IBM Crypto Express (CEX) Adjunct Processor (AP) queues to virtual machines on s390x through Kubernetes [Dynamic Resource Allocation (DRA)](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/).
With DRA, a queue is requested through the Kubernetes `ResourceClaim` API, allocated by the [CEX DRA driver](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver), and attached to the VM through `spec.resourceClaims` and `spec.domain.devices.hostDevices`.

On s390x, KubeVirt passes the allocated queues through as one `vfio-ap` mediated device.
This is an alternative to the device-plugin flow documented in [Host Devices Assignment](host-devices.md).

!!! Note
    Throughout this guide, **Container Device Interface (CDI)** refers to the Kubernetes mechanism that DRA drivers use to inject device nodes into virt-launcher pods — not [Containerized Data Importer](../storage/containerized_data_importer.md), which KubeVirt uses for disk import workflows.

`HostDevicesWithDRA` is in Beta and is enabled by default starting in v1.9.0.
A CEX queue is still declared under `spec.domain.devices.hostDevices`, so the Alpha `HostDevices` feature gate has to be enabled as well.
`HostDevices` stays off until you add it.

See [Activating feature gates](../cluster_admin/activating_feature_gates.md).

## Prerequisites

- **s390x nodes with Crypto Express cards.** The driver runs on IBM Z and LinuxONE.
    Kubernetes 1.34 or later is required, and KubeVirt 1.9.0 or later.
    Node and cluster requirements, including the AP-bus kernel feature the driver probes, are in the driver [prerequisites](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver/blob/main/docs/installation/prerequisites.md).

- **CEX DRA driver.** Install [k8s-cex-dra-driver](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver).
    The current release, `v1.0.0-alpha.0`, is a technical preview.
    A default install publishes the DeviceClass `ap-queue.virtual-machine.ibm.com` for virtual machines.

    The driver publishes [DRA device metadata (KEP-5304)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/5304-dra-attributes-downward-api) in JSON files mounted into virt-launcher.
    For a virtual-machine claim the file carries `mdevUUID`, the UUID of the vfio-ap mediated device that covers every queue in the claim.
    KubeVirt reads `mdevUUID` to build the libvirt domain XML and selects the `vfio-ap` model on s390x.
    CDI delivers the `/dev/vfio/*` device nodes; the metadata file identifies which mediated device to attach.
    Driver authors can find details on publishing these attributes in [Access DRA device metadata](https://kubernetes.io/docs/tasks/configure-pod-container/assign-resources/access-dra-device-metadata/).

## Overview

The high-level workflow is:

1. Install the CEX DRA driver on the cluster.
2. Configure the KubeVirt CR so virt-handler leaves vfio-ap mediated devices to the driver.
3. Create a `ResourceClaimTemplate` that requests a CEX queue from the driver.
4. Create a VMI that references the claim and maps it to `spec.domain.devices.hostDevices`.

## Installing the CEX DRA driver

Install [k8s-cex-dra-driver](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver).

The release publishes source only.
Build the image and apply the Kustomize overlay as described in the driver [installation guide](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver/blob/main/docs/installation/driver.md).

The overlay creates the `cex-dra-driver` namespace, the DaemonSet, and the `ap-queue.virtual-machine.ibm.com` DeviceClass used below.
After the plugin pods are ready, each node publishes its AP queues as `ResourceSlice` objects.
The driver name on those slices is `cex-driver.ibm.com`.

An end-to-end walkthrough, from the image build through a guest check with `lszcrypt`, is in the driver [quickstart](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver/blob/main/docs/quickstart.md).

## Configuring KubeVirt

Merge the following into the existing KubeVirt CR.
`HostDevices` enables `spec.domain.devices.hostDevices`.
`HostDevicesWithDRA` is already on by default in v1.9.0; add it here only when it has been disabled.

```yaml
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - HostDevices
    mediatedDevicesConfiguration:
      mediatedDeviceTypes: []
    permittedHostDevices:
      mediatedDevices:
        - mdevNameSelector: "VFIO AP Passthrough Device"
          resourceName: "ibm.com/crypto-express"
          externalResourceProvider: true
```

Two settings keep virt-handler from owning the vfio-ap devices:

- An empty `mediatedDeviceTypes` list stops virt-handler from creating AP mediated devices.
    The CEX DRA driver creates the vfio-ap device when a claim is prepared.
- The `permittedHostDevices` entry keep-lists that device type.
    `mdevNameSelector` must be `VFIO AP Passthrough Device`, the mediated-device type name the driver creates.
    `externalResourceProvider: true` tells virt-handler that an external component provides the device, so virt-handler does not register its own device plugin for `ibm.com/crypto-express` and does not remove mediated devices of this type.
    virt-handler sweeps `/sys/bus/mdev/devices`.
    Without this entry it can remove the driver's vfio-ap device while the VMI stays Ready, and the guest AP bus goes empty.

`ibm.com/crypto-express` is the allowlist resource name.
The VMI refers to the claim with `claimName` and `requestName`, as shown below.

## Creating a ResourceClaimTemplate

Create a `ResourceClaimTemplate` that requests one queue from `ap-queue.virtual-machine.ibm.com`.
Select the card mode the guest needs with a CEL selector on `cex.ibm.com/type`.
The value is `cca`, `ep11`, or `accel`.

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaimTemplate
metadata:
  name: single-cca-ap-queue-vm
spec:
  spec:
    devices:
      requests:
        - name: cca-ap-queue
          exactly:
            deviceClassName: ap-queue.virtual-machine.ibm.com
            allocationMode: ExactCount
            count: 1
            selectors:
              - cel:
                  expression: device.attributes["cex.ibm.com"].type == "cca"
```

Further selectors (card generation, master-key verification pattern), co-location constraints, and the optional `CryptoConfig` block are documented in [Requesting queues](https://github.com/ibm-s390-cloud/k8s-cex-dra-driver/blob/main/docs/usage/usage.md).

A single request may ask for more than one queue.
The driver still prepares one vfio-ap mediated device for the claim and publishes one `mdevUUID` for that request, which is what KubeVirt consumes.

## Creating a VMI with a CEX queue

Reference the claim template in `spec.resourceClaims`, then map it to `spec.domain.devices.hostDevices` using `claimName` and `requestName`.
The same fields sit under `spec.template.spec` on a `VirtualMachine`.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: vmi-cex
spec:
  resourceClaims:
    - name: claim0
      resourceClaimTemplateName: single-cca-ap-queue-vm
  domain:
    resources:
      requests:
        memory: 1Gi
      limits:
        memory: 1Gi
    devices:
      disks:
        - name: containerdisk
          disk:
            bus: virtio
        - name: cloudinit
          disk:
            bus: virtio
      hostDevices:
        - name: cex-cca
          claimName: claim0
          requestName: cca-ap-queue
      rng: {}
  volumes:
    - name: containerdisk
      containerDisk:
        image: quay.io/containerdisks/fedora:latest
    - name: cloudinit
      cloudInitNoCloud:
        userData: |-
          #cloud-config
          user: fedora
          ssh_authorized_keys:
            - ssh-ed25519 AAAA... you@example.com
          packages:
            - s390utils-base
```

Replace the `ssh_authorized_keys` entry with your own public key.
`s390utils-base` provides `lszcrypt`, which the stock container disk does not include.
The guest needs a route to the Fedora mirrors on first boot so cloud-init can install that package.

!!! warning "Important"
    **These fields must reference each other:**

    - `spec.resourceClaims[].resourceClaimTemplateName` must match the `metadata.name` of the `ResourceClaimTemplate` (`single-cca-ap-queue-vm` in this example).
    - `spec.domain.devices.hostDevices[].claimName` must match `spec.resourceClaims[].name` for the claim that backs the device (`claim0` in this example).
    - `spec.domain.devices.hostDevices[].requestName` must match the request `name` defined in the `ResourceClaimTemplate` (`cca-ap-queue` in this example).

When the VMI starts, virt-launcher uses `mdevUUID` from the metadata file and the CDI-mounted `/dev/vfio/*` device nodes to attach the vfio-ap mediated device in the libvirt domain XML.

Confirm the claim is allocated and the queue is visible in the guest:

```bash
kubectl get resourceclaims
kubectl get vmi vmi-cex
virtctl ssh fedora@vmi/vmi-cex -c 'lszcrypt'
```

`lszcrypt` lists one CEX device whose adapter and domain match the `apid` and `apqi` attributes of the allocated ResourceSlice device.

## One vfio-ap device per guest

Libvirt accepts one `vfio-ap` host device per guest.
The driver prepares one mediated device per claim, and that device already carries every queue allocated to the claim, including queues from several requests.

List one `hostDevices` entry per claim.
Point `requestName` at any request name in that claim.
The guest sees every queue on the claim.
One `hostDevices` entry per request fails admission into the domain: the VMI stays in `Scheduled` and `SyncFailed` events report `Only one hostdev of model vfio-ap is supported`.
