# CSI Overlay for VM State PVCs

The VM State PVC was originally introduced to provide persistent storage for VMs that require the use of TPM or EFI devices: 

* `spec.domain.devices.tpm.persistent: true`
* `spec.domain.devices.efi.persistent: true`

VM State PVCs currently only need to store a small amount of data, on the order of ~10MB. However, many storage providers require a minimum size requirement for PVCs varying from 1GB up to 50GB. When this requirement is applied across all VMs in the cluster, you end up with a lot of wasted storage in these VM State PVCs which can cause you to reach your storage and platform limits much faster.

The solution to this is to deploy a modified version of the Hostpath Provisioner (HPP) that will be "overlayed" atop a RWX Filesystem capable storage provider (such as NFS). 

We can achieve this overlay by leveraging HPP's [PVCTemplate storage pool](https://github.com/kubevirt/hostpath-provisioner-operator?tab=readme-ov-file#custom-resource-with-pvctemplate-storage-pool). This allows us to define a storage pool that uses a single RWX shared PVC. The underlying storage provider will create the RWX PVC at a network share location and the HPP operator will mount this volume on each node in the cluster. 
Once the storage pool is set up, any new volumes using this setup will be provisioned by HPP and the resulting PVC will be created as a directory on top of the network share allowing it to be accessed on any node.

This allows VM State PVCs to bypass the minimum PVC size requirements imposed by some storage provisioners and eliminates the need to recreate these PVCs during a VM migration.

Below are the steps to deploy and configure this CSI Overlay.

## Deploy HPP Operator

The hostpath provisioner operator requires [cert manager](https://github.com/cert-manager/cert-manager) to be installed before deploying the operator. This is because the operator has a validating webhook that verifies the contents of the CR are valid. Before deploying the operator, you need to install cert manager:

```bash
kubectl create -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Ensure cert manager is fully operational
```bash
kubectl wait --for=condition=Available -n cert-manager --timeout=120s --all deployments
```


Next, create the hostpath provisioner namespace:
```bash
kubectl create -f https://github.com/kubevirt/hostpath-provisioner-operator/releases/latest/download/namespace.yaml
```

Now deploy the webhook
```bash
kubectl create -f https://github.com/kubevirt/hostpath-provisioner-operator/releases/latest/download/webhook.yaml -n hostpath-provisioner
```

Then create the operator
```bash
kubectl create -f https://github.com/kubevirt/hostpath-provisioner-operator/releases/latest/download/operator.yaml -n hostpath-provisioner
```

Wait for operator to be ready
```bash
kubectl rollout status -n hostpath-provisioner deployment/hostpath-provisioner-operator --timeout=120s
```

## Deploy the HPP Custom Resource (CR)
Now that the operator is installed, we need to deploy the hostpath provisioner CR to indicate we want to use the provisioner as a storage overlay solution.

We can do so by configuring the `storagePool` to use a `pvcTemplate` which defines a RWX PVC.

!!! Note
    The operator will only deploy and configure the overlay resources when the `pvcTemplate.accessModes` is set to `ReadWriteMany` in the `storagePool` definition 

When the HPP Operator sees the storage pool configured this way, it will mount the RWX volume to each node in the cluster and will then create a new `StorageClass` that will provision new volumes from that storage pool. 

!!! Note 
    You can define the name of the new storage class by setting the optional `overlayClassName` field in the `storagePool` definition. If none is provided the default name will be `hpp-overlay`.

Now when any new PVCs are configured to use this new storage class, their volumes will be created as new directories within the network share. (for this example at `/nfs-vol`)



```bash
cat <<- END | kubectl apply -n hostpath-provisioner -f -
apiVersion: hostpathprovisioner.kubevirt.io/v1beta1
kind: HostPathProvisioner
metadata:
  name: hostpath-provisioner
spec:
  featureGates: 
    - "Snapshotting"
  imagePullPolicy: IfNotPresent
  storagePools:
    - name: "nfs-backend"
      path: "/nfs-vol"
      snapshotProvider: "reflink"
      overlayClassName: "hpp-overlay"
      pvcTemplate:
        accessModes:
          - ReadWriteMany
        storageClassName: "nfs-csi"
        resources:
          requests:
            storage: 10Gi
  workload:
    nodeSelector:
      kubernetes.io/os: linux
END
```

Wait for hotpath provisioner to be available
```bash
kubectl wait hostpathprovisioners.hostpathprovisioner.kubevirt.io/hostpath-provisioner --for=condition=Available --timeout=480s
```


## Modify KubeVirt CR

Once our modified HPP CR is deployed and our new overlay storage class is created, we need to set the `vmStateStorageClass` config variable within the KubeVirt CR to use this new overlay storage class. Now any new VMs that require a VM State PVC will employ this new overlay CSI technique.

```bash
kubectl edit kubevirt -n kubevirt
```

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - VMPersistentState
    vmStateStorageClass: hpp-overlay  # NOTE! this name needs to match with newly created overlay storage class .
```

## Snapshot / Restore support

In order to take snapshots of VMs that use this CSI Overlay for their VM State PVCs, you must deploy a `volumesnapshotclass` to your cluster.

!!! Note 
    The below snapshotclass is set up to point to storagepool named "nfs-backend" which is defined in the example CR above.

```bash
kubectl create -f https://github.com/kubevirt/hostpath-provisioner-operator/releases/latest/download/volumesnapshotclass.yaml
```
