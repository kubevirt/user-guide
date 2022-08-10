# Export API
It can be desireable to export a Virtual Machine and its related disks out of a cluster so you can import that Virtual Machine into another system or cluster. The Virtual Machine disks are the most prominent things you will want to export. The export API makes it possible to declaratively export Virtual Machine disks. It is also possible to export individual PVCs and their contents, for instance when you have created a memory dump from a VM or are using virtio-fs to have a Virtual Machine populate a PVC.

In order not to overload the kubernetes API server the data is transferred through a dedicated export proxy server. The proxy server can then be exposed to the outside world through a service associated with an Ingress/Route or NodePort.

### Export Feature Gate

VMExport support must be enabled in the feature gates to be available. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `VMExport` to it.

### Export token

In order to securely export a Virtual Machine Disk, you must create a token that is used to authorize users accessing the export endpoint. This token must be in the same namespace as the Virtual Machine. The contents of the secret can be passed as a token header or parameter to the export URL. The name of the header or argument is `x-kubevirt-export-token` with a value that matches the content of the secret. The secret can be named any valid secret in the namespace. We recommend you generate an alpha numeric token of at least 12 characters. The data key should be `token`. For example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: example-token
stringData:
  token: 1234567890ab
```
### Export Virtual Machine volumes
After you have created the token you can now create a VMExport CR that identifies the Virtual Machine you want to export. You can create a VMExport that looks like this:

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
spec:
  tokenSecretRef: example-token
  source:
    apiGroup: "kubevirt.io"
    kind: VirtualMachine
    name: example-vm
```

The following volumes present in the VM will be exported:

* PersistentVolumeClaims
* DataVolumes
* MemoryDump

All other volume types are not exported. To avoid the export of inconsistent data, a Virtual Machine can only be exported while it is powered off. Any active VM exports will be terminated if the Virtual Machine is started. To export data from a running Virtual Machine you must first create a Virtual Machine Snapshot (see below).

If the VM contains multiple volumes that can be exported, each volume will get its own URL links. If the VM contains no volumes that can be exported, the VMExport will go into a `Skipped` phase, and no export server is started.

### Export Virtual Machine Snapshot volumes

You can create a VMExport CR that identifies the Virtual Machine Snapshot you want to export. You can create a VMExport that looks like this:

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
spec:
  tokenSecretRef: example-token
  source:
    apiGroup: "snapshot.kubevirt.io"
    kind: VirtualMachineSnapshot
    name: example-vmsnapshot
```

When you create a VMExport based on a Virtual Machine Snapshot, the controller will attempt to create PVCs from the volume snapshots contained in Virtual Machine Snapshot. Once all the PVCs are ready, the export server will start and you can begin the export. If the Virtual Machine Snapshot contains multiple volumes that can be exported, each volume will get its own URL links. If the Virtual Machine snapshot contains no volumes that can be exported, the VMExport will go into a `skipped` phase, and no export server is started.

### Export Persistent Volume Claim

You can create a VMExport CR that identifies the Persistent Volume Claim (PVC) you want to export. You can create a VMExport that looks like this:

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
spec:
  tokenSecretRef: example-token
  source:
    apiGroup: ""
    kind: PersistentVolumeClaim
    name: example-pvc
```

In this example the PVC name is `example-pvc`. Note the PVC doesn't need to contain a Virtual Machine Disk, it can contain any content, but the main use case is exporting Virtual Machine Disks. After you post this yaml to the cluster, a new export server is created in the same namespace as the PVC. If the source PVC is *in use by another pod* (such as the virt-launcher pod) then the export will remain pending until the PVC is no longer in use. If the exporter server is active and another pod starts using the PVC, the exporter server will be terminated until the PVC is not in use anymore.


### Export status links

The VirtualMachineExport CR will contain a status with internal and external links to the export service. The internal links are only valid inside the cluster, and the external links are valid for external access through an Ingress or Route. The `cert` field will contain the CA that signed the certificate of the export server for internal links, or the CA that signed the Route or Ingress.

#### KubeVirt content-type
The following is an example of exporting a PVC that contains a KubeVirt disk image. The controller determines if the PVC contains a kubevirt disk by checking if there is a special annotation on the PVC, or if there is a DataVolume ownerReference on the PVC, or if the PVC has a volumeMode of block.

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
  namespace: example
spec:
  source:
    apiGroup: ""
    kind: PersistentVolumeClaim
    name: example-pvc
  tokenSecretRef: example-token
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-06-21T14:10:09Z"
    reason: podReady
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-06-21T14:09:02Z"
    reason: pvcBound
    status: "True"
    type: PVCReady
  links:
    external:
      cert: |-
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      volumes:
      - formats:
        - format: raw
          url: https://vmexport-proxy.test.net/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example-disk/disk.img
        - format: gzip
          url: https://vmexport-proxy.test.net/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example-disk/disk.img.gz
        name: example-disk
    internal:
      cert: |-
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      volumes:
      - formats:
        - format: raw
          url: https://virt-export-example-export.example.svc/volumes/example-disk/disk.img
        - format: gzip
          url: https://virt-export-example-export.example.svc/volumes/example-disk/disk.img.gz
        name: example-disk
  phase: Ready
  serviceName: virt-export-example-export
```
#### Archive content-type
Archive content-type is automatically selected if we are unable to determine the PVC contains a KubeVirt disk. The archive will contain all the files that are in the PVC.

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
  namespace: example
spec:
  source:
    apiGroup: ""
    kind: PersistentVolumeClaim
    name: example-pvc
  tokenSecretRef: example-token
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-06-21T14:10:09Z"
    reason: podReady
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-06-21T14:09:02Z"
    reason: pvcBound
    status: "True"
    type: PVCReady
  links:
    external:
      cert: |-
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      volumes:
      - formats:
        - format: dir
          url: https://vmexport-proxy.test.net/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example/dir
        - format: tar.gz
          url: https://vmexport-proxy.test.net/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example/disk.tar.gz
        name: example-disk
    internal:
      cert: |-
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      volumes:
      - formats:
        - format: dir
          url: https://virt-export-example-export.example.svc/volumes/example/dir
        - format: tar.gz
          url: https://virt-export-example-export.example.svc/volumes/example/disk.tar.gz
        name: example-disk
  phase: Ready
  serviceName: virt-export-example-export
```
#### Format types
There are 4 format types that are possible:

* Raw. The unaltered raw KubeVirt disk image.
* Gzip. The raw KubeVirt disk image but gzipped to help with transferring efficiency.
* Dir. A directory listing, allowing you to find the files contained in the PVC.
* Tar.gz The contents of the PVC tarred and gzipped in a single file.

Raw and Gzip will be selected if the PVC is determined to be a KubeVirt disk. KubeVirt disks contain a single disk.img file (or are a block device). Dir will return a list of the files in the PVC, to download a specific file you can replace `/dir` in the URL with the path and file name. For instance if the PVC contains the file `/example/data.txt` you can replace `/dir` with `/example/data.txt` to download just data.txt file. Or you can use the tar.gz URL to get all the contents of the PVC in a tar file.


#### Internal link certificates
The export server certificate is valid for 7 days after which it is rotated by deleting the export server pod and associated secret and generating a new one. If for whatever reason the export server pod dies, the associated secret is also automatically deleted and a new pod and secret are generated. The VirtualMachineExport object status will be automatically updated to reflect the new certificate.

#### External link certificates
The external link certificates are associated with the Ingress/Route that points to the service created by the KubeVirt operator. The CA that signed the Ingress/Route will part of the certificates. 

### virtctl integration
__TODO__

### Use cases

#### Clone VM from one cluster to another cluster

If you want to transfer KubeVirt disk images from a source cluster to another target cluster, you can use the VMExport in the source to expose the disks and Containerized Data Importer (CDI) in the target cluster to import the image into the target cluster. Let's assume we have an Ingress or Route in the source cluster that exposes the export proxy with the following example domain `virt-exportproxy-example.example.com` and we have a Virtual Machine in the source cluster with one disk, which looks like this:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-example-datavolume
  name: example-vm
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: example-dv
    spec:
      storage:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 20Gi
        storageClassName: local
      source:
        registry:
          url: docker://quay.io/containerdisks/centos-stream:9
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-example-datavolume
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
        resources:
          requests:
            memory: 2Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: example-dv
        name: datavolumedisk1
```

This is a VM that has a DataVolume (DV) `example-dv` that is populated from a container disk and we want to export that disk to the target cluster. To export this VM we have to create a token that we can use in the target cluster to get access to the export. For example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: example-token
stringData:
  token: 1234567890ab
```
The value of the token is `1234567890ab` hardly a secure token, but it is an example. We can now create a VMExport that looks like this:

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
spec:
  tokenSecretRef: example-token
  source:
    apiGroup: "kubevirt.io"
    kind: VirtualMachine
    name: example-vm
```
If the VM is not running the status of the VMExport object will get updated once the export-server pod is running to look something like this:

```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
  name: example-export
  namespace: example
spec:
  tokenSecretRef: example-token
  source:
    apiGroup: "kubevirt.io"
    kind: VirtualMachine
    name: example-vm
status:
  conditions:
  - lastProbeTime: null
    reason: podReady
    status: "True"
    type: Ready
  - lastProbeTime: null
    reason: pvcBound
    status: "True"
    type: PVCReady
  links:
    external:
      cert: |-
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      volumes:
      - formats:
        - format: raw
          url: https://virt-exportproxy-example.example.com/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example-dv/disk.img
        - format: gzip
          url: https://virt-exportproxy-example.example.com/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example-dv/disk.img.gz
        name: example-disk
    internal:
      cert: |-
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      volumes:
      - formats:
        - format: raw
          url: https://virt-export-example-export.example.svc/volumes/example-dv/disk.img
        - format: gzip
          url: https://virt-export-example-export.example.svc/volumes/example-dv/disk.img.gz
        name: example-disk
  phase: Ready
  serviceName: virt-export-example-export
```
Note in this example we are in the `example` namespace in the source cluster, which is why the internal links domain ends with `.example.svc`. The external links are what will be visible to outside of the source cluster, so we can use that for when we import into the target cluster.

Now we are ready to import this disk into the target cluster. In order for CDI to import, we will need to provide it the CA certificate that signed the Ingress/Route that we will be connecting to. Luckily the `cert` field of the external links will contain the entire certificate chain. You can use the contents of the `cert` field to populate the configMap. In the target cluster create the configmap in the namespace you will import the disk into:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: router-cert
data:
  ca.pem: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
```

Next create a secret in the same namespace on the target cluster. Note: the token value will be a header that is passed to the server by CDI.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-headers
stringData:
  token: "x-kubevirt-export-token:1234567890ab"
```
Note: make sure there is no ` ` between the `:` and the actual token, otherwise the space is sent as part of the header, the authentication will fail.
Now we can go ahead and import the disk image into the target cluster using a data volume. For convenience, I put the data volume inside a data volume template section of the same VM spec as the source:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-example-datavolume
  name: example-target-vm
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: example-dv
    spec:
      source:
        http:
          url: "https://virt-exportproxy-example.example.com/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/volumes/example-dv/disk.img.gz"
          certConfigMap: router-cert
          secretExtraHeaders:
          - secret-headers
      storage:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 20Gi
        storageClassName: target-local
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-example-datavolume
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: datavolumedisk1
        resources:
          requests:
            memory: 2Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - dataVolume:
          name: example-dv
        name: datavolumedisk1
```

After the import completes you should be able to start the VM in the target cluster.
