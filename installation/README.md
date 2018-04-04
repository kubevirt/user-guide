# Installation

KubeVirt is a virtualization add-on to Kubernetes and this guide assumes that a Kubernetes cluster is already installed.

## Requirements

A few requirements need to be met before you can begin:

* [Kubernets](https://kubernetes.io) cluster \([OpenShift](https://github.com/openshift/origin), Tectonic\)
* `kubectl` client utility
* `git`

### Minimum Requirements

| Component | Minimum Version |
| --- | --- |
| Kubernetes | 1.7 |
| KubeVirt | [v0.1.0](https://github.com/kubevirt/kubevirt/releases/v0.1.0) |

### Virtualization support

There are several distributions of Kubernetes, you need to decide on one and get it deployed.

Hardware with virtualization support is recommended. You can use virt-host-validate to ensure that your hosts are capable of running virtualization workloads:

```text
$ virt-host-validate qemu
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
...
```

## Cluster side add-on deployment

### Core components

Once Kubernetes is deployed, you will need to deploy the KubeVirt add-on. The add-on is deployed to a cluster using the `kubectl` tool and manifest file:

```bash
$ RELEASE=v0.2.0
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

Basic VirtualMachine operations can be peformed with the stock `kubectl` utility. However, the `virtctl` binary utility is required to use advanced features such as:

* Serial and graphical console access

Or to have convenience commands for:

* Starting and stopping VirtualMachines
* Live migrating VirtualMachines

The most recent version of the tool can be retrieved from the [official release page](https://github.com/kubevirt/kubevirt/releases).

## Deploying on OpenShift

There exist three ways on how to deploy KubeVirt on OpenShift.

### Using command line interface

Following [SCCs](https://docs.openshift.com/container-platform/3.7/admin_guide/manage_scc.html) need to be added prior `kubevirt.yaml` deployment:

```text
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-privileged
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-controller
```

**NOTE:** For Kubevirt **0.2.0**, following is required in addition to the SCCs above:

```text
oc adm policy add-scc-to-user privileged system:serviceaccount:kube-system:kubevirt-infra
```

Once privileges are granted, the `kubevirt.yaml` can be deployed:

```text
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```

### From Service Catalog as an APB

You can find KubeVirt in OpenShift Service Catalog and install it from there. In order to do that please follow the documentation of [KubeVirt APB repository](https://github.com/ansibleplaybookbundle/kubevirt-apb).

### Using Ansible playbooks

There is project [kubevirt-ansible](https://github.com/kubevirt/kubevirt-ansible) which provides a collection of playbooks to install KubeVirt and it's related components on top of OpenShift or Kubernetes clusters.

## Deploying from Source

See the [Developer Getting Started Guide](https://github.com/kubevirt/kubevirt/blob/master/docs/getting-started.md) to understand how to build and deploy Kubevirt from sources.

## Update

> Note: Updates are not yet supported.

Usually it is sufficient to re-apply the manifests for performing a roling update:

```bash
$ RELEASE=v0.1.0
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```

