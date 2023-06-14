# KSM Management

Kernel Samepage Merging ([KSM](http://www.linux-kvm.org/page/KSM))
allows de-duplication of memory. KSM tries to find identical Memory Pages and merge
those to free memory.
>Further Information:  
>- [KSM (Kernel Samepage Merging) feature](https://www.thomas-krenn.com/en/wiki/KSM_(Kernel_Samepage_Merging)_feature)  
>- [Kernel Same-page Merging (KSM)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_tuning_and_optimization_guide/chap-ksm)

## Enabling KSM through KubeVirt CR
KSM can be enabled on nodes by `spec.configuration.ksmConfiguration` in the KubeVirt CR.  
`ksmConfiguration` instructs on which nodes KSM will be enabled, exposing a `nodeLabelSelector`.  
`nodeLabelSelector` is a [LabelSelector](https://github.com/kubernetes/apimachinery/blob/60180f072f73eafec72ef9f2c418a6bb1357d434/pkg/apis/meta/v1/types.go#L1195)
and defines the filter, based on the node labels. If a node's labels match the label selector term,
then on that node, KSM will be enabled.  
>**NOTE**  
>If `nodeLabelSelector` is nil KSM will not be enabled on any nodes.  
>Empty `nodeLabelSelector` will enable KSM on every node.  

#### Examples:

- Enabling KSM on nodes in which the hostname is `node01` or `node03`:
```yaml
spec:
  configuration:
    ksmConfiguration:
      nodeLabelSelector:
        matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
              - node01
              - node03
```

- Enabling KSM on nodes with labels `kubevirt.io/first-label: true`, `kubevirt.io/second-label: true`:
```yaml
spec:
  configuration:
    ksmConfiguration:
      nodeLabelSelector:
        matchLabels:
          kubevirt.io/first-label: "true"
          kubevirt.io/second-label: "true"
```

- Enabling KSM on every node:
```yaml
spec:
  configuration:
    ksmConfiguration:
      nodeLabelSelector: {}
```


## Annotation and restore mechanism
 
On those nodes where KubeVirt enables the KSM via configuration, an annotation will be
added (`kubevirt.io/ksm-handler-managed`).  
This annotation is an internal record to keep track of which nodes are currently 
managed by virt-handler, so that it is possible to distinguish which nodes should be restored
in case of future ksmConfiguration changes.

Let's imagine this scenario:

1. There are 3 nodes in the cluster and one of them(`node01`) has KSM externally enabled.
2. An admin patches the KubeVirt CR adding a ksmConfiguration which enables ksm for `node02` and `node03`.
3. After a while, an admin patches again the KubeVirt CR deleting the ksmConfiguration.

Thanks to the annotation, the virt-handler is able to disable ksm on only those nodes where it
itself had enabled it(`node02` `node03`), leaving the others unchanged (`node01`).

## Node labelling

KubeVirt can discover on which nodes KSM is enabled and will mark them
with a special label (`kubevirt.io/ksm-enabled`) with value `true`.
This label can be used to schedule the vms in nodes with KSM enabled or not.
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: testvm
    spec:
      nodeSelector:
        kubevirt.io/ksm-enabled: "true"
      [...]
```
