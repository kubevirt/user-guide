# Installation

KubeVirt is a virtualization add-on to Kubernetes and this guide assumes
that a Kubernetes cluster is already installed.

If installed on OKD, the web console is extended for management of
virtual machines.

## Requirements

A few requirements need to be met before you can begin:

-   [Kubernetes](https://kubernetes.io) cluster or derivative
    (such as [OpenShift](https://github.com/openshift/origin))
    based on a one of the latest three Kubernetes releases that are
    out at the time the KubeVirt release is made.
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

## Installing KubeVirt on Kubernetes

KubeVirt can be installed using the KubeVirt operator, which manages the
lifecycle of all the KubeVirt core components. Below is an example of
how to install KubeVirt using an official release.

    # Pick an upstream version of KubeVirt to install
    $ export RELEASE=v0.35.0
    # Deploy the KubeVirt operator
    $ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
    # Create the KubeVirt CR (instance deployment request) which triggers the actual installation
    $ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml
    # wait until all KubeVirt components are up
    $ kubectl -n kubevirt wait kv kubevirt --for condition=Available

If hardware virtualization is not available, then a
[software emulation fallback](https://github.com/kubevirt/kubevirt/blob/main/docs/software-emulation.md)
can be enabled using by setting in the KubeVirt CR `spec.configuration.developerConfiguration.useEmulation` to `true` as follows:

    $ kubectl edit -n kubevirt kubevirt kubevirt

Add the following to the `kubevirt.yaml` file

```yaml
    spec:
      ...
      configuration:
        developerConfiguration:
          useEmulation: true
```

> Note: Prior to release v0.20.0 the condition for the `kubectl wait`
> command was named "Ready" instead of "Available"

> Note: Prior to KubeVirt 0.34.2 a ConfigMap called `kubevirt-config` in the
> install-namespace was used to configure KubeVirt. Since 0.34.2 this method is
> deprecated. The configmap still has precedence over `configuration` on the
> CR exists, but it will not receive future updates and you should migrate any
> custom configurations to `spec.configuration` on the KubeVirt CR.

All new components will be deployed under the `kubevirt` namespace:

    kubectl get pods -n kubevirt
    NAME                                           READY     STATUS        RESTARTS   AGE
    virt-api-6d4fc3cf8a-b2ere                      1/1       Running       0          1m
    virt-controller-5d9fc8cf8b-n5trt               1/1       Running       0          1m
    virt-handler-vwdjx                             1/1       Running       0          1m
    ...

## Installing KubeVirt on OKD

The following
[SCC](https://docs.openshift.com/container-platform/4.10/authentication/managing-security-context-constraints.html)
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

## Installing KubeVirt on k3OS

The following
[configuration](https://github.com/rancher/k3os#configuration)
needs to be added to all nodes prior KubeVirt deployment:

```yaml
k3os:
  modules:
  - kvm
  - vhost_net
```

Once nodes are restarted with this configuration, the KubeVirt can be deployed as described above.

## Installing the Daily Developer Builds

<!-- markdown-link-check-disable -->
KubeVirt releases daily a developer build from the current main branch. One can see
when the last release happened by looking at our
[nightly-build-jobs](https://prow.apps.ovirt.org/?job=periodic-kubevirt-push-nightly-build-master).
<!-- markdown-link-check-enable -->

To install the latest developer build, run the following commands:

    $ LATEST=$(curl -L https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/latest)
    $ kubectl apply -f https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${LATEST}/kubevirt-operator.yaml
    $ kubectl apply -f https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${LATEST}/kubevirt-cr.yaml

To find out which commit this build is based on, run:

    $ LATEST=$(curl -L https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/latest)
    $ curl https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${LATEST}/commit
    d358cf085b5a86cc4fa516215f8b757a4e61def2

### Experimental ARM64 developer builds

Experimental ARM64 developer builds can be installed like this:

    $ LATEST=$(curl -L https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/latest-arm64)
    $ kubectl apply -f https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${LATEST}/kubevirt-operator-arm64.yaml
    $ kubectl apply -f https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${LATEST}/kubevirt-cr-arm64.yaml

## Deploying from Source

See the [Developer Getting Started
Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/getting-started.md)
to understand how to build and deploy KubeVirt from source.

## Installing network plugins (optional)

KubeVirt alone does not bring any additional network plugins, it just
allows user to utilize them. If you want to attach your VMs to multiple
networks (Multus CNI) or have full control over L2 (OVS CNI), you need
to deploy respective network plugins. For more information, refer to
[OVS CNI installation
guide](https://github.com/kubevirt/ovs-cni/blob/main/docs/deployment-on-arbitrary-cluster.md).

> Note: KubeVirt Ansible [network
> playbook](https://github.com/kubevirt/kubevirt-ansible/tree/master/playbooks#network)
> installs these plugins by default.

## Restricting KubeVirt components node placement

You can restrict the placement of the KubeVirt components across your 
cluster nodes by editing the KubeVirt CR:

- The placement of the KubeVirt control plane components (virt-controller, virt-api)
  is governed by the `.spec.infra.nodePlacement` field in the KubeVirt CR.
- The placement of the virt-handler DaemonSet pods (and consequently, the placement of the 
  VM workloads scheduled to the cluster) is governed by the `.spec.workloads.nodePlacement`
  field in the KubeVirt CR.
  
For each of these `.nodePlacement` objects, the `.affinity`, `.nodeSelector` and `.tolerations` sub-fields can be configured.
See the description in the [API reference](http://kubevirt.io/api-reference/master/definitions.html#_v1_componentconfig)
for further information about using these fields.

For example, to restrict the virt-controller and virt-api pods to only run on the control-plane nodes:

    kubectl patch -n kubevirt kubevirt kubevirt --type merge --patch '{"spec": {"infra": {"nodePlacement": {"nodeSelector": {"node-role.kubernetes.io/control-plane": ""}}}}}'

To restrict the virt-handler pods to only run on nodes with the "region=primary" label:

    kubectl patch -n kubevirt kubevirt kubevirt --type merge --patch '{"spec": {"workloads": {"nodePlacement": {"nodeSelector": {"region": "primary"}}}}}'

