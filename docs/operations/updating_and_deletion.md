# Updating and deletion

## Updating KubeVirt Control Plane

Zero downtime rolling updates are supported starting with release
`v0.17.0` onward. Updating from any release prior to the KubeVirt
`v0.17.0` release is not supported.

> Note: Updating is only supported from N-1 to N release.

Updates are triggered one of two ways.

1.  By changing the imageTag value in the KubeVirt CR's spec.

For example, updating from `v0.17.0-alpha.1` to `v0.17.0` is as simple
as patching the KubeVirt CR with the `imageTag: v0.17.0` value. From
there the KubeVirt operator will begin the process of rolling out the
new version of KubeVirt. Existing VM/VMIs will remain uninterrupted both
during and after the update succeeds.

    $ kubectl patch kv kubevirt -n kubevirt --type=json -p '[{ "op": "add", "path": "/spec/imageTag", "value": "v0.17.0" }]'

2.  Or, by updating the kubevirt operator if no imageTag value is set.

When no imageTag value is set in the kubevirt CR, the system assumes
that the version of KubeVirt is locked to the version of the operator.
This means that updating the operator will result in the underlying
KubeVirt installation being updated as well.

    $ export RELEASE=v0.26.0
    $ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml

The first way provides a fine granular approach where you have full
control over what version of KubeVirt is installed independently of what
version of the KubeVirt operator you might be running. The second
approach allows you to lock both the operator and operand to the same
version.

Newer KubeVirt may require additional or extended RBAC rules. In this
case, the #1 update method may fail, because the virt-operator present
in the cluster doesn't have these RBAC rules itself. In this case, you
need to update the `virt-operator` first, and then proceed to update
kubevirt. See [this issue for more
details](https://github.com/kubevirt/kubevirt/issues/2533).

## Updating KubeVirt Workloads

Workload updates are supported as an opt in feature starting with `v0.39.0`

By default, when KubeVirt is updated this only involves the control plane
components. Any existing VirtualMachineInstance (VMI) workloads that are
running before an update occurs remain 100% untouched. The workloads
continue to run and are not interrupted as part of the default update process.

It's important to note that these VMI workloads do involve components such as
libvirt, qemu, and virt-launcher, which can optionally be updated during the
KubeVirt update process as well. However that requires opting in to having
virt-operator perform automated actions on workloads.

Opting in to VMI updates involves configuring the `workloadUpdateStrategy`
field on the KubeVirt CR. This field controls the methods virt-operator will
use to when updating the VMI workload pods.

There are two methods supported.

**LiveMigrate:** Which results in VMIs being updated by live migrating the
virtual machine guest into a new pod with all the updated components enabled.

**Evict: ** Which results in the VMI's pod being shutdown. If the VMI is
controlled by a higher level VirtualMachine object with `runStrategy: always`,
then a new VMI will spin up in a new pod with updated components.

The least disruptive way to update VMI workloads is to use LiveMigrate. Any
VMI workload that is not live migratable will be left untouched. If live
migration is not enabled in the cluster, then the only option available for
virt-operator managed VMI updates is the Evict method.


**Example: Enabling VMI workload updates via LiveMigration**

```console
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  imagePullPolicy: IfNotPresent
  workloadUpdateStrategy:
    workloadUpdateMethods:
      - LiveMigrate
```

**Example: Enabling VMI workload updates via Evict with batch tunings**

The batch tunings allow configuring how quickly VMI's are evicted. In large
clusters, it's desirable to ensure that VMI's are evicted in batches in order
to distribute load.

```console
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  imagePullPolicy: IfNotPresent
  workloadUpdateStrategy:
    workloadUpdateMethods:
      - Evict
    batchEvictionSize: 10
    batchEvictionInterval: "1m"
```


**Example: Enabling VMI workload updates with both LiveMigrate and Evict**

When both LiveMigrate and Evict are specified, then any workloads which are
live migratable will be guaranteed to be live migrated. Only workloads which
are not live migratable will be evicted.


```console
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  imagePullPolicy: IfNotPresent
  workloadUpdateStrategy:
    workloadUpdateMethods:
      - LiveMigrate
      - Evict
    batchEvictionSize: 10
    batchEvictionInterval: "1m"
```

## Deleting KubeVirt

To delete the KubeVirt you should first to delete `KubeVirt` custom
resource and then delete the KubeVirt operator.

    $ export RELEASE=v0.17.0
    $ kubectl delete -n kubevirt kubevirt kubevirt --wait=true # --wait=true should anyway be default
    $ kubectl delete apiservices v1alpha3.subresources.kubevirt.io # this needs to be deleted to avoid stuck terminating namespaces
    $ kubectl delete mutatingwebhookconfigurations virt-api-mutator # not blocking but would be left over
    $ kubectl delete validatingwebhookconfigurations virt-api-validator # not blocking but would be left over
    $ kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml --wait=false

> Note: If by mistake you deleted the operator first, the KV custom
> resource will get stuck in the `Terminating` state, to fix it, delete
> manually finalizer from the resource.
>
> Note: The `apiservice` and the `webhookconfigurations` need to be
> deleted manually due to a bug.
>
>     $ kubectl -n kubevirt patch kv kubevirt --type=json -p '[{ "op": "remove", "path": "/metadata/finalizers" }]'
