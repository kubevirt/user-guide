---
hide:
  - navigation
  - toc
---


## Quickstart Guides

Killercoda provides an interactive environment for exploring KubeVirt scenarios:

- [KubeVirt on killercoda](https://killercoda.com/kubevirt): runs in your browser with nothing to install. A good choice for a first look at KubeVirt.

Guides for deploying KubeVirt with different Kubernetes tools:

- [KubeVirt on minikube](https://kubevirt.io/quickstart_minikube/): a local cluster on a Linux host with KVM. KubeVirt can be deployed with the minikube `kubevirt` addon, and the guide shows how to set up a multi-node cluster to try features such as live migration.

- [KubeVirt on kind](https://kubevirt.io/quickstart_kind/): a local cluster on a Linux host with KVM, whose nodes run as containers. Quick to create and delete.

- [KubeVirt on cloud providers](https://kubevirt.io/quickstart_cloud/): a cluster on a cloud provider such as AWS, Azure, GCP, or AliCloud. Use it if you don't have a Linux host with KVM, for example on macOS or Windows. Cloud resources incur costs.

## Next Steps

Once KubeVirt is running:

- [Install the `virtctl` command line tool](user_workloads/virtctl_client_tool.md) to start and stop virtual machines and access their consoles.

- [Create your first VirtualMachine](user_workloads/creating_vms.md) with `virtctl create vm`.
