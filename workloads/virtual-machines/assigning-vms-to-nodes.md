# Assigning VMs to Nodes

You can constrain the VM to only run on specific nodes or to prefer running on specific nodes:

* **nodeSelector**
* **Affinity and anti-affinity**

## nodeSelector

Setting `spec.nodeSelector` requirements, constrains the scheduler to only schedule VMs on nodes, which contain the specified labels. In the following example the vm contains the labels `cpu: slow` and `storage: fast`:

```text
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
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

Thus the scheduler will only shedule the vm to nodes which contain these labels in their metadata. It works exactly like the Pods `nodeSelector`. See the [Pod nodeSelector Documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector) for more examples.

## Affinity and anti-affinity

The `spec.affinity` field allows specifying hard- and soft-affinity for VMs. It is possible to write matching rules agains workloads \(VMs and Pods\) and Nodes. Since VMs are a workload type based on Pods, Pod-affinity affects VMs as well.

An example for `podAffinity` and `podAntiAffinity` may look like this:

```text
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
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

