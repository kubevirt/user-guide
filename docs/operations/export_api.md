# Export API

## Prerequesites
None

### Export Feature Gate

VMExport support must be enabled in the feature gates to be supported. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `VMExport` to it.

### Export token

In order to securely export a Virtual Machine Disk, you must create a token that is used to authorize users accessing the export endpoint. This token must be in a secret that is stored in the namespace the Virtual Machine resides in. The contents of the secret can be passed as a token header or parameter to the export URL. The name of the header or argument is `x-kubevirt-export-token` with a value that matches the content of the secret. The secret can be named any valid secret in the namespace. We recommend you use best security practices when generating this token. 

### Export Virtual Machine disk

After you have created the token you can now create a VMExport CR that identifies the disk of the VM you want to export. In KubeVirt in the end all persisted Virtual Machine disks are stored in a Persistent Volume Claim (PVC) in the namespace the Virtual Machine resides in. Once you have identified the PVC you can create a VMExport that looks like this:

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
    name: vm-disk
```

In this example the PVC name is vm-disk, but it will be different for your Virtual Machine Disk. Note the PVC doesn't need to contain a Virtual Machine Disk, it can contain any content, but the main use case is exporting Virtual Machine Disks. After you post this yaml to the cluster, and the PVC is not in use by another pod, a new export server is created in the same namespace as the PVC. The VirtualMachineExport CR will contain a status with internal and external links to the export service. The internal links are only valid inside the cluster, and the external links are valid for external access. The `cert` field will contain the CA that signed the certificate of the export server for internal links, or the CA that signed the Route or Ingress.

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
    name: example-disk
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

If the source PVC is in use by another pod (such as the virt-launcher pod) then the export will remain pending until the PVC is no longer in use.

### Internal link certificates
The export server certificate is valid for 7 days after which it is rotated by deleting the export server pod and associated secret and generating a new one. If for whatever reason the export server pod dies, the associated secret is also automatically deleted and a new pod and secret are generated. The VirtualMachineExport object status will be automatically updated to reflect the new certificate.

### Source Types
Currently the only valid source type is a PersistentVolumeClaim.
