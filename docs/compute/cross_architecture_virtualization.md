# Cross-Architecture Virtualization

Cross-architecture virtualization allows KubeVirt to run virtual machines (VMs) whose guest architecture differs from the host node architecture (for example, running an ARM64 guest on an AMD64 node).

### **FEATURE STATE:**

* Alpha - [`v1.9.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.9.0)

## Overview

Traditionally, KubeVirt requires matching architectures between host nodes and guest virtual machines.
Cross-architecture virtualization extends KubeVirt to run multi-architecture workloads on heterogeneous or single-architecture clusters.
This allows developers to test their applications on other architectures without needing to buy nodes for that architecture.

Currently, the feature uses QEMU TCG for software emulation of the target architecture.

### Decoupling from `useEmulation`

Currently, software emulation for cross-architecture virtualization and fallback to same-architecture software emulation are separate features, controlled by different settings.

## Enabling Cross-Architecture Virtualization

To enable cross-architecture virtualization, activate the `CrossArchitectureVirtualization` feature gate in the KubeVirt Custom Resource (CR) and configure the desired `emulationPolicy`.

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
        - CrossArchitectureVirtualization
    emulationPolicy: Software
```

> **Note:** Without setting `emulationPolicy`, the default policy is `None`, which disallows cross-architecture emulation even if the feature gate is enabled. You must configure `emulationPolicy: Software` (or set `spec.emulationPolicy` on individual VMs) to allow software emulation.

## Emulation Policy

> **Note:** `emulationPolicy` is implemented starting in KubeVirt v1.10.

The `emulationPolicy` field defines the maximum permitted fallback depth for cross-architecture workloads. It can be specified at the cluster level in the KubeVirt CR (`spec.configuration.emulationPolicy`) or overridden per-VM in the VM/VMI specification (`spec.emulationPolicy`).

The permitted values, ordered from most restrictive to most permissive, are:

| Policy             | Description                                                                                               | Allowed Backends                   |
| ------------------ | --------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `None` *(Default)* | No emulation is permitted. The VM must run on a node that matches the guest architecture with native KVM. | Native KVM only                    |
| `Software`         | Permits all emulation tiers, automatically preferring native KVM over software emulation (TCG).           | Native KVM, software TCG emulation |

### Policy Precedence

The effective policy is evaluated with the following precedence:

1. **Per-VM/VMI Specification**: `spec.emulationPolicy`
2. **Cluster Configuration**: `spec.configuration.emulationPolicy` in the KubeVirt CR
3. **Default**: `None`

This hierarchy allows administrators to maintain a restrictive cluster-wide policy (such as `None`) while allowing specific development VMs to opt into `Software` emulation.

## Configuring a Cross-Architecture Virtual Machine

To run a VM on a different architecture:

1. Specify the target guest architecture in `spec.architecture` (for example, `arm64`, `amd64`, or `s390x`).
2. Provide an architecture-compatible `containerDisk` or disk image.
3. Configure `spec.emulationPolicy: Software` (if not already enabled globally).

### Example: Running an ARM64 VM on an AMD64 Node

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: arm64-fedora-vm
spec:
  runStrategy: Always
  template:
    spec:
      architecture: arm64
      emulationPolicy: Software
      domain:
        machine:
          type: virt
        resources:
          requests:
            memory: 1Gi
            cpu: 2
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/fedora:44-aarch64
```

### CPU Model Handling in Software Emulation

When software emulation (TCG) is active:

- `host-passthrough` and `host-model` CPU modes are incompatible because the host CPU instruction set differs from the guest.
- KubeVirt automatically overrides these modes to use `max` (`domain.cpu.model: max`), exposing all features supported by the QEMU TCG emulator.

### Graphics and Display Devices

Under cross-architecture software emulation:

- Video and display devices (such as `virtio-gpu` or `vga`) are disabled because minimal cross-architecture QEMU system binaries may not package display modules.
- Use the serial console (`virtctl console <vm-name>`) or network interfaces (for example, SSH) to interact with the guest operating system.

### ContainerDisk Considerations

Ensure that container disk images match the intended guest architecture (for example, `:*-aarch64` image tags for ARM64 guests).
Currently, referencing a multi-arch manifest does not work, because the image is pulled for the host architecture and therefore does not match the guest architecture.

## Pod Scheduling and Node Selection

When the `Software` policy is chosen, scheduling changes from using a hard `kubernetes.io/arch` node selector to using node affinities, which prefer the native architecture over emulation.
This ensures that even with emulation enabled, VMs are scheduled on their native architecture where possible for maximum performance.

## Monitoring and Status Conditions

`virt-handler` inspects the running domain and sets a condition on the VirtualMachineInstance (VMI) status indicating the active virtualization backend:

```yaml
status:
  conditions:
    - type: SoftwareEmulation
      status: "True"
      reason: CrossArchitectureEmulation
      message: "VM running with software emulation (host=amd64, guest=arm64)"
```

## Prerequisites and QEMU Binaries

For software emulation, the `virt-launcher` container image must contain the target architecture's QEMU system binary:

- ARM64 guests: `/usr/bin/qemu-system-aarch64`
- AMD64 guests: `/usr/bin/qemu-system-x86_64`

Because the image is based on CentOS, the emulation binaries are not bundled by default.
To use the emulation feature, you must build `virt-launcher` yourself and include the prerelease virtualization binaries.

Build and push the images with the following command:

```bash
KUBEVIRT_CROSS_ARCH_EMULATION=true make rpm-deps bazel-push-images
```

## Limitations

- **Alpha Feature**: The feature is currently under development and is expected to change.
- **Performance**: Software emulation (TCG) is roughly 10 times slower than native KVM. As such, it should not be used for production workloads.
- **Live Migration**: Live migration is currently untested and unsupported. However, it is not disabled, so proceed with caution.
- **Graphical Displays**: Graphical console/VNC is disabled under software emulation. Serial console and network access should be used instead.
