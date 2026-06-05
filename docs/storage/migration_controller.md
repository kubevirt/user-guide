# KubeVirt Migration Controller

The [KubeVirt Migration Controller](https://github.com/kubevirt/kubevirt-migration-controller) project provides a set of APIs that facilitate bulk storage live migration operations. This enables you to live migrate multiple virtual machine disks to a common destination storage class.

## Prerequisites 
Your KubeVirt environment must have the [Containerized Data Importer (CDI)](../storage/containerized_data_importer.md) installed to use persistent disks.

## Installation

Install the latest release using the operator

```shell
for YAML in $(curl -s https://api.github.com/repos/kubevirt/kubevirt-migration-operator/releases/latest | grep browser_download_url | grep -oE 'https://[^"]+\.yaml'); do kubectl create -f $YAML; done
```


## Create a VirtualMachine with disk on storage A

Execute the following, to create a VirtualMachine and DataVolume pair:

```shell
cat <<EOF | kubectl apply -f -
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: simple-dv
spec:
  source:
      registry:
        url: docker://quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.7.0
  storage:
    storageClassName: storageclass-a
    resources:
      requests:
        storage: "10Gi"
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: simple-vm
spec:
  runStrategy: Always
  template:
    metadata:
      labels: {kubevirt.io/domain: simple-vm,
        kubevirt.io/vm: simple-vm}
    spec:
      domain:
        devices:
          disks:
          - disk: {bus: virtio}
            name: dv-disk
          - disk: {bus: virtio}
            name: cloudinitdisk
        resources:
          requests: {memory: 2048M}
      volumes:
      - dataVolume: {name: simple-dv}
        name: dv-disk
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
        name: cloudinitdisk
EOF
```

## Create a migration plan

```shell
cat <<EOF | kubectl apply -f -
apiVersion: migrations.kubevirt.io/v1alpha1
kind: VirtualMachineStorageMigrationPlan
metadata:
  name: test-plan
spec:
  virtualMachines:
  - name: simple-vm
    targetMigrationPVCs:
    - volumeName: dv-disk
      destinationPVC:
        name: test-pvc
        storageClassName: storageclass-b
EOF
```

## Start the migration

```shell
cat <<EOF | kubectl apply -f -
apiVersion: migrations.kubevirt.io/v1alpha1
kind: VirtualMachineStorageMigration
metadata:
  name: test-migration
spec:
  virtualMachineStorageMigrationPlanRef:
    name: test-plan
EOF
```

Observe completion
```shell
$ kubectl get virtualmachinestoragemigration
NAME             PLAN        PHASE       AGE
test-migration   test-plan   Completed   50s
```

## Multi namespace

One can also issue a single plan/migration against multiple namespaces using `MultiNamespaceVirtualMachineStorageMigrationPlan/MultiNamespaceVirtualMachineStorageMigration`.  
The former embeds single namespaced spec, and creates it in the specified namespace.  
An example can be found here:

```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MultiNamespaceVirtualMachineStorageMigrationPlan
metadata:
  name: multi-ns-storage-migration-plan
spec:
  namespaces:
    - name: production
      virtualMachines:
        - name: prod-vm-1
          targetMigrationPVCs:
            - volumeName: rootdisk
              destinationPVC:
                storageClassName: fast-ssd
    - name: development
      virtualMachines:
        - name: dev-vm-1
          targetMigrationPVCs:
            - volumeName: rootdisk
              destinationPVC:
                storageClassName: standard
```

And similarly, to start it

```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MultiNamespaceVirtualMachineStorageMigration
metadata:
  name: multi-ns-storage-migration
spec:
  multiNamespaceVirtualMachineStorageMigrationPlanRef:
    name: multi-ns-storage-migration-plan
```

## Canceling a migration

To cancel an in-progress migration, delete the `VirtualMachineStorageMigration` resource:

```shell
kubectl delete virtualmachinestoragemigration test-migration
```

The controller will transition the migration through the `Canceling` phase, automatically revert the VM volumes back to their original source PVCs, and clean up any target DataVolumes that were created during the migration. Once complete, the migration reaches the `Canceled` phase and the resource is removed.

```shell
$ kubectl get virtualmachinestoragemigration
NAME             PLAN        PHASE      AGE
test-migration   test-plan   Canceled   30s
```

For multi-namespace migrations, delete the `MultiNamespaceVirtualMachineStorageMigration` resource — each child migration will be cancelled in the same way.

> **Note:** This differs from KubeVirt's built-in [volume migration](volume_migration.md#volume-migration-cancellation), where cancellation requires applying the old VM spec to revert the volume set. With the migration controller, deleting the migration CR is sufficient — the controller handles the revert automatically.
