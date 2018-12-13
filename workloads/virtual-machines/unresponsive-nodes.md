# Detecting and resolving Node issues

KubeVirt has its own node daemon, called virt-handler. In addition to the usual
k8s methods of detecting issues on nodes, the virt-handler daemon has its own
heartbeat mechanism. This allows for fine-tuned error handling of
VirtualMachineInstances.

## Heartbeat of virt-handler

`virt-handler` periodically tries to update the `kubevirt.io/schedulable` label
and the `kubevirt.io/heartbeat` annotation on the node it is running on:

```bash
$ kubectl get nodes -o yaml
apiVersion: v1
items:
- apiVersion: v1
  kind: Node
  metadata:
    annotations:
      kubevirt.io/heartbeat: 2018-11-05T09:42:25Z
    creationTimestamp: 2018-11-05T08:55:53Z
    labels:
      beta.kubernetes.io/arch: amd64
      beta.kubernetes.io/os: linux
      cpumanager: "false"
      kubernetes.io/hostname: node01
      kubevirt.io/schedulable: "true"
      node-role.kubernetes.io/master: ""
```

If a `VirtualMachineInstance` gets scheduled, the scheduler is only considering
nodes where `kubevirt.io/schedulable` is `true`. This can be seen when looking
on the corresponding pod of a `VirtualMachineInstance`:

```bash
$ kubectl get pods  virt-launcher-vmi-nocloud-ct6mr -o yaml
apiVersion: v1
kind: Pod
metadata:
  [...]
spec:
  [...]
  nodeName: node01
  nodeSelector:
    kubevirt.io/schedulable: "true"
  [...]
```

In case there is a communication issue or the host goes down, `virt-handler`
can't update its labels and annotations any-more. Once the last
`kubevirt.io/heartbeat` timestamp is older than five minutes, the KubeVirt
node-controller kicks in and sets the `kubevirt.io/schedulable` label to
`false`. As a consequence no more VMIs will be schedule to this node until
virt-handler is connected again.

## Deleting stuck VMIs when virt-handler is unresponsive

In cases where `virt-handler` has some issues but the node is in general fine,
a `VirtualMachineInstance` can be deleted as usual via `kubectl delete vmi
<myvm>`. Pods of a `VirtualMachineInstance` will be told by the
cluster-controllers they should shut down. As soon as the Pod is gone, the
`VirtualMachineInstance` will be moved to `Failed` state, if `virt-handler` did
not manage to update it's heartbeat in the meantime. If `virt-handler` could
recover in the meantime,  `virt-handler` will move the `VirtualMachineInstance`
to failed state instead of the cluster-controllers.

## Deleting stuck VMIs when the whole node is unresponsive

If the whole node is unresponsive, deleting a `VirtualMachineInstance` via
`kubectl delete vmi <myvmi>` alone will never remove the
`VirtualMachineInstance`. In this case all pods on the unresponsive node need
to be force-deleted: First make sure that the node is really dead. Then delete
all pods on the node via a force-delete: `kubectl delete pod --force
--grace-period=0 <mypod>`.

As soon as the pod disappears and the heartbeat from virt-handler timed out,
the VMIs will be moved to `Failed` state. If they were already marked for
deletion they will simply disappear. If not, they can be deleted and will
disappear almost immediately.

## Timing considerations

It takes up to five minutes until the KubeVirt cluster components can detect
that virt-handler is unhealthy. During that time-frame it is possible that new
VMIs are scheduled to the affected node. If virt-handler is not capable of connecting
to these pods on the node, the pods will sooner or later go to failed state. As
soon as the cluster finally detects the issue, the VMIs will be set to failed
by the cluster.
