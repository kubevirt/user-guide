# Evaluating KubeVirt

## What is KubeVirt?

KubeVirt is a Kubernetes add-on that enables virtual machine workloads to run natively on Kubernetes clusters. Virtual machines (VMs) are represented as Kubernetes custom resources, `VirtualMachine` and `VirtualMachineInstance`, so they can be managed with the same tools, APIs, and RBAC policies as any other workload.

## Why KubeVirt?

- **Lift and shift VM workloads** onto Kubernetes without rewriting applications as containers
- **Mix VMs and containers** in a single platform, sharing networking, storage, and scheduling infrastructure
- **Unify operations**: one control plane, one set of policies, one monitoring stack
- **No separate hypervisor platform**: KubeVirt runs as a Kubernetes operator inside your existing cluster

## How does it work?

KubeVirt deploys a lightweight operator that extends the Kubernetes API with new custom resource definitions (CRDs). When you create a `VirtualMachine` object, KubeVirt schedules a pod that runs the VM using libvirt and QEMU/KVM on a node with hardware virtualization support. The VM's full lifecycle, including start, stop, live migrate, and snapshot, is managed through the Kubernetes API.

See the [Architecture](../architecture.md) page for a deeper technical overview, including diagrams of KubeVirt's components and how they integrate with Kubernetes.

## Key concepts

| Concept | Description |
|---------|-------------|
| `VirtualMachine` (VM) | A persistent VM definition, similar to a Deployment for pods |
| `VirtualMachineInstance` (VMI) | A running VM instance, similar to a Pod |
| Instance types | Predefined CPU/memory/resource bundles for consistent VM sizing across environments |
| `virtctl` | CLI tool that extends `kubectl` with VM-specific commands (console access, SSH, live migration) |
| Container disks | VM disk images packaged as OCI container images for easy distribution via registries |

## Try it without installing

Explore KubeVirt interactively in your browser at [Killercoda](https://killercoda.com/kubevirt). No installation or Kubernetes cluster required: the environment is provisioned for you.

## Next steps

- [First steps guide](running_kubevirt_first_time.md): install KubeVirt on a local or cloud cluster and run your first VM
- [Cluster Administration: Installation](../cluster_admin/installation.md): production installation requirements and configuration options
- [Architecture](../architecture.md): technical deep-dive into KubeVirt's components and integration with Kubernetes
