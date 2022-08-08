# Export API

## Prerequesites
None

### Export Feature Gate

VMExport support must be enabled in the feature gates to be supported. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `VMExport` to it.

### Export token

In order to securely export a Virtual Machine Disk, you must create a token that is used to authorize users accessing the export endpoint. This token must be in a secret that is stored in the namespace the Virtual Machine resides in. The contents of the secret can be passed as a token header or parameter to the export URL. The name of the header or argument is `x-kubevirt-export-token` with a value that matches the content of the secret. The secret can be named any valid secret in the namespace. We recommend you generate an alpha numeric token of at least 12 characters. The data key should be `token`. For example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: example-token
data:
  token: MTIzNDU2Nzg5MGFi
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

All other volume types are not exported. The export will only be available when the VM is not running, this is to prevent corrupt data from being exported. If you want to export data from a running VM, the VM will have to use storage that can be snapshotted, and you can create a Virtual Machine Snapshot and export that while the VM stays running. If an export is active and the VM is started the export will detect this state and terminate the export server.

If the VM contains multiple volumes that can be exported, each volume will get its own URL links. If the VM contains no volumes that can be exported, the VMExport will go into a `Skipped` phase, and no export server is started.

### Export Virtual Machine Snapshot volumes

After you have created the token you can now create a VMExport CR that identifies the Virtual Machine Snapshot you want to export. You can create a VMExport that looks like this:

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

After you have created the token you can now create a VMExport CR that identifies the Persistent Volume Claim (PVC) you want to export. You can create a VMExport that looks like this:

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

In this example the PVC name is `example-pvc`. Note the PVC doesn't need to contain a Virtual Machine Disk, it can contain any content, but the main use case is exporting Virtual Machine Disks. After you post this yaml to the cluster, a new export server is created in the same namespace as the PVC. If the source PVC is in use by another pod (such as the virt-launcher pod) then the export will remain pending until the PVC is no longer in use. If the exporter server is active and another pod starts using the PVC, the exporter server will be terminated until the PVC is not in use anymore.


### Export status links

The VirtualMachineExport CR will contain a status with internal and external links to the export service. The internal links are only valid inside the cluster, and the external links are valid for external access through an Ingress or Route. The `cert` field will contain the CA that signed the certificate of the export server for internal links, or the CA that signed the Route or Ingress.

#### KubeVirt content-type
Example of exporting a PVC that contains a KubeVirt disk image. The controller determines if the PVC contains a kubevirt disk by checking if there is a special annotation on the PVC, or if there is a DataVolume ownerReference on the PVC, or if the PVC has a volumeMode of block.

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
The external link certificates as associated with the Ingress/Route that points to the service created by the KubeVirt operator. The CA that signed the Ingress/Route will part of the certificates. 

### virtctl integration
__TODO__
