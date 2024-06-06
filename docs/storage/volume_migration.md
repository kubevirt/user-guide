# Migration update volume strategy and volume migration

Storage migration is possible while the VM is running by using the update volume strategy. Storage migration can be useful in the cases where the users need to change the underlying storage, for example, if the storage class has been deprecated, or there is a new more performant driver available.

This feature doesn't handle the volume creation or cover migration between storage classes, but rather implements a basic API which can be used by overlaying tools to perform more advanced migration planning.

If `Migration` is specified as `updateVolumesStrategy`, KubeVirt will try to migrate the storage from the old volume set to the new one when the VirtualMachine spec is updated. The migration considers the changed volumes present into a single update. A single update may contain modifications to more than one volume, but sequential changes to the volume set will be handled as separate migrations.

Updates are declarative and [GitOps](https://kubevirt.io/user-guide/cluster_admin/gitops/) compatible. For example, a new version of the VM specification with the new volume set and the migration volume update strategy can be directly applied using `kubectl apply` or interactively editing the VM with `kubectl edit`

Example:
Original VM with a datavolume and datavolume template:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-dv
  name: vm-dv
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: src-dv
    spec:
      storage:
        accessModes:
        - ReadWriteOnce
        volumeMode: Filesystem
        resources:
          requests:
            storage: 2Gi
        storageClassName: local
      source:
        registry:
          url: docker://registry:5000/kubevirt/alpine-container-disk-demo:devel
  runStrategy: "Always"
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-dv
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
          interfaces:
          - masquerade: {}
            name: default
        resources:
          requests:
            memory: 128Mi
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: src-dv
        name: datavolumedisk1
      networks:
      - name: default
        pod: {}
```

The datavolume `src-dv` is migrated to the pvc `dest-pvc`:
```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: dst-dv
spec:
  source:
      blank: {}
  storage:
    accessModes:
      - ReadWriteMany
    volumeMode: Block
    resources:
      requests:
        storage: 5Gi
    storageClassName: rook-ceph
```

by updating the VM:
```diff
 apiVersion: kubevirt.io/v1
 kind: VirtualMachine
     kubevirt.io/vm: vm-dv
   name: vm-dv
 spec:
+  updateVolumesStrategy: Migration
   dataVolumeTemplates:
   - metadata:
-      name: src-pvc
+      name: dst-dv

       volumes:
       - dataVolume:
-          name: src-pvc
+          name: dst-dv
         name: datavolumedisk1
```

The destination volume may be of a different type or size than the source. It is possible to migrate from and to a block volume as well as a filesystem volume.
The destination volume should be equal to or larger than the source volume. However, the additional difference in the size of the destination volume is not instantly visible within the VM and must be manually resized because the guest is unaware of the migration.

The volume migration depends on the `VolumeMigration` and `VolumesUpdateStrategy` feature gates and the `LiveMigrate` workloadUpdateStrategy. To fully enable the feature, add the following to the KubeVirt CR:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - VMLiveUpdateFeatures
        - VolumesUpdateStrategy
        - VolumeMigration
    vmRolloutStrategy: LiveUpdate
  workloadUpdateStrategy:
    workloadUpdateMethods:
    - LiveMigrate
```

The volume migration progress can be monitored by watching the corresponding VirtualMachineInstanceMigration object using the label `kubevirt.io/volume-update-in-progress: <vm-name>`. Example:
```bash
$ kubectl get virtualmachineinstancemigrations -l kubevirt.io/volume-update-in-progress: vmi` --watch=true
NAME                           PHASE       VMI
kubevirt-workload-update-abcd  Running     vmi
```

## Datavolume template

Updating a datavolume that is referenced by a datavolume template requires special caution. The volumes section must include a reference to the name of the datavolume template. This means that the datavolume templates must either be entirely deleted or updated as well.

Example of updating the datavolume for the original VM in the first example:
```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: dst-dv
spec:
  source:
      blank: {}
  storage:
    accessModes:
      - ReadWriteMany
    volumeMode: Block
    resources:
      requests:
        storage: 10Gi
    storageClassName: rook-ceph-block
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-dv
  name: vm-dv
spec:
  updateVolumesStrategy: Migration
  dataVolumeTemplates:
  - metadata:
      name: dst-dv
    spec:
      storage:
        accessModes:
        - ReadWriteOnce
        volumeMode: Filesystem
        resources:
          requests:
            storage: 2Gi
        storageClassName: local
      source:
        registry:
          url: docker://registry:5000/kubevirt/alpine-container-disk-demo:devel
  runStrategy: "Always"
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-dv
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
          interfaces:
          - masquerade: {}
            name: default
        resources:
          requests:
            memory: 128Mi
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: dst-dv
        name: datavolumedisk1
      networks:
      - name: default
        pod: {}
```

## Limitations

Only certain types of disks and volumes are supported to be migrated. For an invalid type of volume the RestartRequired condition is set and volumes will be replaced upon VM restart.
Currently, the volume migration is supported between PersistentVolumeClaims and Datavolumes.
Additionally, volume migration is forbidden if the disk is:
* shareable, since it cannot guarantee the data consistency with multiple writers
* hotpluggable, this case isn't currently supported
* filesystem, since virtiofs doesn't currently support live-migration
* lun, originally the disk might support SCSI protocol but the destination PVC class does not. This case isn't currently supported.

Currently, KubeVirt only enables live migration between separate nodes. Volume migration relies on live migration; hence, live migrating storage on the same node is also not possible. Volume migration is possible between local storage, like between 2 PVCs with RWO access mode, but they need to be located on two different host.
