Installation
============

KubeVirt is a virtualization add-on to Kubernetes and this guide assumes
that a Kubernetes cluster is already installed.

If installed on OKD, the web console is extended for management of
virtual machines.

Requirements
------------

A few requirements need to be met before you can begin:

-   [Kubernetes](https://kubernetes.io) cluster or derivative
    (such as [OpenShift](https://github.com/openshift/origin), Tectonic)
    based on Kubernetes 1.10 or greater
-   Kubernetes apiserver must have `--allow-privileged=true` in order to run KubeVirt's privileged DaemonSet.
-   `kubectl` client utility

### Container Runtime Support

KubeVirt is currently supported on the following container runtimes:

-   docker
-   crio (with runv)

Other container runtimes, which do not use virtualization features,
should work too. However, they are not tested.

### Validate Hardware Virtualization Support

Hardware with virtualization support is recommended. You can use
virt-host-validate to ensure that your hosts are capable of running
virtualization workloads:

    $ virt-host-validate qemu
      QEMU: Checking for hardware virtualization                                 : PASS
      QEMU: Checking if device /dev/kvm exists                                   : PASS
      QEMU: Checking if device /dev/kvm is accessible                            : PASS
      QEMU: Checking if device /dev/vhost-net exists                             : PASS
      QEMU: Checking if device /dev/net/tun exists                               : PASS
    ...

If hardware virtualization is not available, then a [software emulation
fallback](https://github.com/kubevirt/kubevirt/blob/master/docs/software-emulation.md)
can be enabled using:

    $ kubectl create namespace kubevirt
    $ kubectl create configmap -n kubevirt kubevirt-config \
        --from-literal debug.useEmulation=true

This ConfigMap needs to be created before deployment or the
virt-controller deployment has to be restarted.

## Installing KubeVirt on Kubernetes

KubeVirt can be installed using the KubeVirt operator, which manages the
lifecycle of all the KubeVirt core components. Below is an example of
how to install KubeVirt using an official release.

    # Pick an upstream version of KubeVirt to install
    $ export VERSION=v0.26.0
    # Deploy the KubeVirt operator
    $ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml
    # Create the KubeVirt CR (instance deployment request)
    $ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml
    # wait until all KubeVirt components is up
    $ kubectl -n kubevirt wait kv kubevirt --for condition=Available

> Note: Prior to release v0.20.0 the condition for the `kubectl wait`
> command was named "Ready" instead of "Available"

All new components will be deployed under the `kubevirt` namespace:

    kubectl get pods -n kubevirt
    NAME                                           READY     STATUS        RESTARTS   AGE
    virt-api-6d4fc3cf8a-b2ere                      1/1       Running       0          1m
    virt-controller-5d9fc8cf8b-n5trt               1/1       Running       0          1m
    virt-handler-vwdjx                             1/1       Running       0          1m
    ...

## Installing KubeVirt on OKD

The following
[SCC](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html)
needs to be added prior KubeVirt deployment:

    $ oc adm policy add-scc-to-user privileged -n kubevirt -z kubevirt-operator

Once privileges are granted, the KubeVirt can be deployed as described above.

### Web user interface on OKD

No additional steps are required to extend OKD's web console for KubeVirt.

The virtualization extension is automatically enabled when KubeVirt deployment is detected.

### From Service Catalog as an APB

You can find KubeVirt in the OKD Service Catalog and install it from
there. In order to do that please follow the documentation in the
[KubeVirt APB
repository](https://github.com/ansibleplaybookbundle/kubevirt-apb).

Deploying from Source
---------------------

See the [Developer Getting Started
Guide](https://github.com/kubevirt/kubevirt/blob/master/docs/getting-started.md)
to understand how to build and deploy KubeVirt from source.

Installing network plugins (optional)
-------------------------------------

KubeVirt alone does not bring any additional network plugins, it just
allows user to utilize them. If you want to attach your VMs to multiple
networks (Multus CNI) or have full control over L2 (OVS CNI), you need
to deploy respective network plugins. For more information, refer to
[OVS CNI installation
guide](https://github.com/kubevirt/ovs-cni/blob/master/docs/deployment-on-arbitrary-cluster.md).

> Note: KubeVirt Ansible [network
> playbook](https://github.com/kubevirt/kubevirt-ansible/tree/master/playbooks#network)
> installs these plugins by default.

# Restricting virt-handler DaemonSet

You can patch the `virt-handler` DaemonSet post-deployment to restrict
it to a specific subset of nodes with a nodeSelector. For example, to
restrict the DaemonSet to only nodes with the "region=primary" label:

    kubectl patch ds/virt-handler -n kubevirt -p '{"spec": {"template": {"spec": {"nodeSelector": {"region": "primary"}}}}}'

