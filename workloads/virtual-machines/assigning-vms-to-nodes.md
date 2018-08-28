# Assigning VMs to Nodes

You can constrain the VM to only run on specific nodes or to prefer running on specific nodes:

* **nodeSelector**
* **Affinity and anti-affinity**
* **Taints and Tolerations**

## nodeSelector

Setting `spec.nodeSelector` requirements, constrains the scheduler to only schedule VMs on nodes, which contain the specified labels. In the following example the vmi contains the labels `cpu: slow` and `storage: fast`:

```yaml
metadata:
  name: testvmi-ephemeral
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
spec:
  nodeSelector:
    cpu: slow
    storage: fast
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        lun: {}
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

Thus the scheduler will only schedule the vmi to nodes which contain these labels in their metadata. It works exactly like the Pods `nodeSelector`. See the [Pod nodeSelector Documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) for more examples.

## Affinity and anti-affinity

The `spec.affinity` field allows specifying hard- and soft-affinity for VMs. It is possible to write matching rules agains workloads \(VMs and Pods\) and Nodes. Since VMs are a workload type based on Pods, Pod-affinity affects VMs as well.

An example for `podAffinity` and `podAntiAffinity` may look like this:

```yaml
metadata:
  name: testvmi-ephemeral
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
spec:
  nodeSelector:
    cpu: slow
    storage: fast
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        lun: {}
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: failure-domain.beta.kubernetes.io/zone
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: kubernetes.io/hostname
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
```

Affinity and anti-affinity works exactly like the Pods `affinity`. This includes `podAffinity`, `podAntiAffinity`, `nodeAffinity` and `nodeAntiAffinity`. See the [Pod affinity and anti-affinity Documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) for more examples and details.

## Taints and Tolerations

Affinity as described above, is a property of VMs that attracts them to a set of nodes (either as a preference or a hard requirement). Taints are the opposite – they allow a node to repel a set of VMs.

Taints and tolerations work together to ensure that VMs are not scheduled onto inappropriate nodes. One or more taints are applied to a node; this marks that the node should not accept any VMs that do not tolerate the taints. Tolerations are applied to VMs, and allow (but do not require) the VMs to schedule onto nodes with matching taints.

You add a taint to a node using kubectl taint. For example,

```bash
kubectl taint nodes node1 key=value:NoSchedule
```

An example for `tolerations` may look like this:

```yaml
metadata:
  name: testvmi-ephemeral
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
spec:
  nodeSelector:
    cpu: slow
    storage: fast
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mypvcdisk
        volumeName: mypvc
        lun: {}
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```
