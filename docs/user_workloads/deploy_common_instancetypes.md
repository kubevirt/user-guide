# Deploy common-instancetypes

The [`kubevirt/common-instancetypes`](https://github.com/kubevirt/common-instancetypes) provide a set of [instancetypes and preferences](../user_workloads/instancetypes.md) to help create KubeVirt [`VirtualMachines`](http://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine).

Beginning with the 1.1 release of KubeVirt, cluster wide resources can be deployed directly through KubeVirt, without another operator.
This allows deployment of a set of default instancetypes and preferences along side KubeVirt.

With the [`v1.4.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.4.0) release of KubeVirt, common-instancetypes are now deployed by default.

## **FEATURE STATE:** 

* Alpha - [`v1.1.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.1.0)
* Beta - [`v1.2.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.2.0)
* GA - [`v1.4.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.4.0) (Enabled by default)

## Control deployment of common-instancetypes

To explictly enable or disable the deployment of cluster-wide common-instancetypes through the KubeVirt `virt-operator` use the `spec.configuration.commonInstancetypesDeployment.enable` configurable.

```shell
$ kubectl patch -n kubevirt kv/kubevirt --type merge -p '{"spec":{"configuration":{"commonInstancetypesDeployment":{"enable": false}}}}'
```

## Deploy common-instancetypes manually

For customization purposes or to install namespaced resources, common-instancetypes can also be deployed by hand.

To install all resources provided by the [`kubevirt/common-instancetypes`](https://github.com/kubevirt/common-instancetypes) project without further customizations, simply apply with [`kustomize`](https://kustomize.io/) enabled (-k flag):

```yaml
$ kubectl apply -k https://github.com/kubevirt/common-instancetypes.git
```

Alternatively, targets for each of the available custom resource types (e.g. namespaced instancetypes) are available.

For example, to deploy `VirtualMachineInstancetypes` run the following command:

```yaml
$ kubectl apply -k https://github.com/kubevirt/common-instancetypes.git/VirtualMachineInstancetypes
```
