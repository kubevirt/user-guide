# Updating KubeVirt

Zero downtime rolling updates are supported starting with release
`v0.17.0` onward. Updating from any release prior to the KubeVirt
`v0.17.0` release is not supported.

> Note: Updating is only supported from N-1 to N release.

Updates are triggered one of two ways.

1.  By changing the imageTag value in the KubeVirt CR’s spec.

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
in the cluster doesn’t have these RBAC rules itself. In this case, you
need to update the `virt-operator` first, and then proceed to update
kubevirt. See [this issue for more
details](https://github.com/kubevirt/kubevirt/issues/2533).

# Deleting KubeVirt

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


