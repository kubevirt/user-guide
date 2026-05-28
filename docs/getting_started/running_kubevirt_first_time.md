# Running KubeVirt: First Steps

This guide walks you through installing KubeVirt on a Kubernetes cluster and running your first virtual machine.

## Prerequisites

- A running Kubernetes cluster
  - Local options: see [Quickstarts](../quickstarts.md) for minikube, kind setup instructions
  - Cloud options (GKE, EKS, AKS): see [Quickstarts](../quickstarts.md)
  - OKD/OpenShift: KubeVirt extends the web console with VM management UI
- `kubectl` installed and configured to access your cluster
- Hardware virtualization support on cluster nodes
  - If unavailable (e.g., nested virtualization scenarios), software emulation can be enabled (see Step 1 note)

## Step 1: Install KubeVirt

Fetch the latest stable release version and deploy the KubeVirt operator and custom resources:

```bash
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml
kubectl -n kubevirt wait kv kubevirt --for condition=Available
```

For production clusters, nodes without hardware virtualization support, or AppArmor integration, see [Installation](../cluster_admin/installation.md) for detailed requirements and configuration options.

## Step 2: Install virtctl

`virtctl` is the KubeVirt command-line tool for VM-specific operations (console access, SSH, live migration, disk uploads). See [virtctl client tool](../user_workloads/virtctl_client_tool.md) for installation instructions.

## Step 3: Create your first virtual machine

Create a Fedora VM using a container disk (a VM disk image packaged as an OCI container):

```bash
virtctl create vm --name my-fedora-vm \
  --instancetype u1.small \
  --volume-containerdisk src:quay.io/containerdisks/fedora:latest \
  | kubectl apply -f -
```

Check the VM status:

```bash
kubectl get vm my-fedora-vm
kubectl get vmi my-fedora-vm
```

The VM is created in `Stopped` state by default. Start it:

```bash
virtctl start my-fedora-vm
```

Wait for the VMI (VirtualMachineInstance) to reach `Running` state:

```bash
kubectl get vmi my-fedora-vm -w
```

For detailed VM creation options, including cloud-init configuration, PVC-backed persistent disks, and resource specifications, see [Creating VMs](../user_workloads/creating_vms.md).

## Step 4: Access your virtual machine

Connect to the VM's serial console:

```bash
virtctl console my-fedora-vm
```

Press `Ctrl+]` to exit the console.

Or connect via SSH (requires the VM to have an SSH server running and SSH keys configured via cloud-init):

```bash
virtctl ssh fedora@my-fedora-vm
```

For graphical console access (VNC), port forwarding, and RDP configuration, see [Accessing virtual machines](../user_workloads/accessing_virtual_machines.md).

## Step 5: Next steps

Now that you have a running VM, explore these topics:

- [VM lifecycle](../user_workloads/lifecycle.md): start, stop, pause, restart, and delete VMs
- [Instance types and preferences](../user_workloads/instancetypes.md): standardize VM sizing with reusable resource profiles
- [Installation](../cluster_admin/installation.md): production installation with hardware validation, AppArmor integration, and cluster configuration
- [Disks and volumes](../storage/disks_and_volumes.md): attach persistent storage, use DataVolumes, configure boot order
- [Interfaces and networks](../network/interfaces_and_networks.md): configure VM networking, connect to pod networks, expose services
