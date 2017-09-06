## Installation

KubeVirt is a virtualization add-on to Kubernetes. This implies that KubeVirt requires a Kubernetes cluster to be already installed.

### Requirements

A few requirements need to be met before you can begin:

* [Kubernets](https://kubernetes.io) cluster \([OpenShift](https://github.com/openshift/origin), Tectonic\)
* kubectl client utility
* git

#### Minimum Requirements

| Component | Minimum Version |
| --- | --- |
| Kubernetes | 1.7 |
| KubeVirt | 0.0.3 |

#### Virtualization support

There are several distributions of Kubernetes, you need to decide on one and get it deployed.

Hardware with virtualization support is recommended. You can use virt-host-validate to ensure that your hosts are capable of running virtualization workloads:

```
$ virt-host-validate qemu
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller mount-point                  : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpu' controller mount-point                     : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuacct' controller mount-point                 : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'cpuset' controller mount-point                  : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : PASS
  QEMU: Checking for cgroup 'devices' controller mount-point                 : PASS
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for cgroup 'blkio' controller mount-point                   : PASS
  QEMU: Checking for device assignment IOMMU support                         : PASS
  QEMU: Checking if IOMMU is enabled by kernel                               : PASS
```

### Cluster side add-on deployment

Once Kubernetes is deployed, you will need to deploy the KubeVirt add-on. The add-on is getting deployed to a cluster using the `kubectl` tool and manifest file.

> Note: So far we can only provide deployment files for minikube. Additional manifests will follow.

```bash
$ kubectl create -f FIXME
```

This command will deploy the most recent stable version of KubeVirt to your cluster.

See the [developer getting started guide](https://github.com/kubevirt/kubevirt/blob/master/docs/getting-started.md) to understand how to build and deploy Kubevirt from sources.

### Client side `virtctl` deployment

Basic VM operations can be peformed with the stock `kubectl` utility. However, the `virtctl` binary is required to use advanced features, i.e.:

* Serial and graphical console access
* Actions for starting and stopping
* Action for live-migration

The most recent version of the tool can be retrieved from the [official release page](https://github.com/kubevirt/kubevirt/releases).

