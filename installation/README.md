# Installation

KubeVirt is a virtualization add-on to Kubernetes and this guide assumes that a Kubernetes cluster is already installed.

## Requirements

A few requirements need to be met before you can begin:

* [Kubernetes](https://kubernetes.io) cluster \([OpenShift](https://github.com/openshift/origin), Tectonic\)
* `kubectl` client utility
* `git`

### Minimum Cluster Requirements

Kubernetes 1.10 or later is required to run KubeVirt.

In addition it can be that feature gates need to be opened.

#### Runtime

KubeVirt is currently support on the following container runtimes:

- docker
- crio (with runv)

### Virtualization support

There are several distributions of Kubernetes, you need to decide on one and deploy it.

Hardware with virtualization support is recommended. You can use virt-host-validate to ensure that your hosts are capable of running virtualization workloads:

```bash
$ virt-host-validate qemu
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
...
```

#### Software emulation

If hardware virtualization is not available, then a [software emulation fallback](https://github.com/kubevirt/kubevirt/blob/master/docs/software-emulation.md) can be enabled using:

```
$ kubectl create configmap -n kube-system kubevirt-config \
    --from-literal debug.useEmulation=true
```

This ConfigMap needs to be created before deployment or the virt-controller deployment has to be restarted.

### Hugepages support

For hugepages support you need at least Kubernetes version `1.9`.

#### Enable feature-gate

To enable hugepages on Kubernetes, check the [official documentation](https://v1-9.docs.kubernetes.io/docs/tasks/manage-hugepages/scheduling-hugepages/#before-you-begin).

To enable hugepages on OpenShift, check the [official documentation](https://docs.openshift.org/3.9/scaling_performance/managing_hugepages.html#huge-pages-prerequisites).

#### Pre-allocate hugepages on a node

To pre-allocate hugepages on boot time, you will need to specify hugepages under kernel boot parameters `hugepagesz=2M hugepages=64` and restart your machine.

You can find more about hugepages under [official documentation](https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt).

## Cluster side add-on deployment

### Core components

Once Kubernetes is deployed, you will need to deploy the KubeVirt add-on. The add-on is deployed to a cluster using the `kubectl` tool and manifest file:

```bash
$ RELEASE=v0.10.0
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```

This command will deploy the most recent stable version of KubeVirt to your cluster. The new components will be deployed in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system
NAME                                           READY     STATUS        RESTARTS   AGE
libvirt-9zmtl                                  2/2       Running       0          28m
virt-controller-5d9fc8cf8b-n5trt               0/1       Running       0          27m
virt-handler-vwdjx                             1/1       Running       0          28m
```

## Client side `virtctl` deployment

Basic VirtualMachineInstance operations can be performed with the stock `kubectl` utility. However, the `virtctl` binary utility is required to use advanced features such as:

* Serial and graphical console access

It also provides convenience commands for:

* Starting and stopping VirtualMachineInstances
* Live migrating VirtualMachineInstances

The most recent version of the tool can be retrieved from the [official release page](https://github.com/kubevirt/kubevirt/releases).

## Deploying on OpenShift

There are three ways to deploy KubeVirt on OpenShift.

### Using command line interface

The following [SCCs](https://docs.openshift.com/container-platform/3.7/admin_guide/manage_scc.html) need to be added prior `kubevirt.yaml` deployment:

```bash
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-privileged
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-controller
oc adm policy add-scc-to-user privileged -n kube-system -z kubevirt-apiserver
```

Once privileges are granted, the `kubevirt.yaml` can be deployed:

```bash
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```

### From Service Catalog as an APB

You can find KubeVirt in the OpenShift Service Catalog and install it from there. In order to do that please follow the documentation in the [KubeVirt APB repository](https://github.com/ansibleplaybookbundle/kubevirt-apb).

### Using Ansible playbooks

The [kubevirt-ansible](https://github.com/kubevirt/kubevirt-ansible) project provides a collection of playbooks that installs KubeVirt and it's related components on top of OpenShift or Kubernetes clusters.

## Deploying from Source

See the [Developer Getting Started Guide](https://github.com/kubevirt/kubevirt/blob/master/docs/getting-started.md) to understand how to build and deploy KubeVirt from source.

## Installing network plugins (optional)

KubeVirt alone does not bring any additional network plugins, it just allows
user to utilize them. If you want to attach your VMs to multiple networks
(Multus CNI) or have full control over L2 (OVS CNI), you need to deploy
respective network plugins. For more information, refer to [OVS CNI installation
guide](https://github.com/kubevirt/ovs-cni/blob/master/docs/deployment-on-arbitrary-cluster.md).

> Note: KubeVirt Ansible [network playbook](https://github.com/kubevirt/kubevirt-ansible/tree/master/playbooks#network) installs these plugins by default.

## Update

> Note: Updates are not yet supported.

Usually it is sufficient to re-apply the manifests for performing a rolling update:

```bash
$ RELEASE=v0.4.0
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```

