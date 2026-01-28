# KubeVirt Migration Controller

The [KubeVirt Migration Controller](https://github.com/kubevirt/kubevirt-migration-controller) project provides a set of APIs facilitating bulk storage live migration operations.

## Prerequisites
As the project operates on kubevirt VMs with persistent disks, it naturally requires:
- [CDI](/docs/storage/containerized_data_importer.md)
- [KubeVirt](/docs/cluster_admin/installation.md)

## Installation

Install the latest release using the operator

    for YAML in $(curl -s https://api.github.com/repos/kubevirt/kubevirt-migration-operator/releases/latest | grep browser_download_url | grep -oE 'https://[^"]+\.yaml'); do kubectl create -f $YAML; done


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

One can also issue a single plan/migration against multiple namespaces via the following resources

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
