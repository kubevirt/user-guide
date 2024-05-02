# Export API
It can be desirable to export a Virtual Machine and its related disks out of a cluster so you can import that Virtual Machine into another system or cluster. The Virtual Machine disks are the most prominent things you will want to export. The export API makes it possible to declaratively export Virtual Machine disks. It is also possible to export individual PVCs and their contents, for instance when you have created a memory dump from a VM or are using virtio-fs to have a Virtual Machine populate a PVC.

In order not to overload the kubernetes API server the data is transferred through a dedicated export proxy server. The proxy server can then be exposed to the outside world through a service associated with an Ingress/Route or NodePort. As an alternative, the `port-forward` flag can be used with the virtctl integration to bypass the need of an Ingress/Route.

### Export Feature Gate

VMExport support must be enabled in the feature gates to be available. The
[feature gates](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate)
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

#### Manifests
The VirtualMachine manifests can be retrieved by accessing the `manifests` in the VirtualMachineExport status. The `all` type will return the VirtualMachine manifest, any DataVolumes, and a configMap that contains the public CA certificate of the Ingress/Route of the external URL, or the CA of the export server of the internal URL. The `auth-header-secret` will be a secret that contains a Containerized Data Importer (CDI) compatible header. This header contains a text version of the export token.

Both internal and external links will contain a `manifests` field. If there are no external links, then there will not be any external manifests either. The virtualMachine `manifests` field is only available if the source is a `VirtualMachine` or `VirtualMachineSnapshot`. Exporting a `PersistentVolumeClaim` will not generate a Virtual Machine manifest.

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
      ...
      manifests:
      - type: all
        url: https://vmexport-proxy.test.net/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/external/manifests/all
      - type: auth-header-secret
        url: https://vmexport-proxy.test.net/api/export.kubevirt.io/v1alpha1/namespaces/example/virtualmachineexports/example-export/external/manifests/secret
    internal:
      ...
      manifests:
      - type: all
        url: https://virt-export-export-pvc.default.svc/internal/manifests/all
      - type: auth-header-secret
        url: https://virt-export-export-pvc.default.svc/internal/manifests/secret
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

### TTL (Time to live) for an Export
For various reasons (security being one), users should be able to specify a TTL for the VMExport objects that limits the lifetime of an export.  
This is done via the `ttlDuration` field which accepts a k8s [duration](https://godoc.org/k8s.io/apimachinery/pkg/apis/meta/v1#Duration),  
which defaults to 2 hours when not specified.
```yaml
apiVersion: export.kubevirt.io/v1alpha1
kind: VirtualMachineExport
metadata:
    name: example-export
spec:
    source:
        apiGroup: "kubevirt.io"
        kind: VirtualMachine
        name: example-vm
    tokenSecretRef: example-token
    ttlDuration: 1h
```

### virtctl integration: vmexport
The virtctl `vmexport` command allows users to interact with the export API in an easy-to-use way.

`vmexport` uses two mandatory arguments:

* The vmexport **functions** (create|delete|download).
* The VirtualMachineExport **name**.

These three **functions** are:

#### Create
```sh
# Creates a VMExport object according to the specified flag.

# The flag should either be:

# --pvc, to specify the name of the pvc to export.
# --snapshot, to specify the name of the VM snapshot to export.
# --vm, to specify the name of the Virtual Machine to export.

$ virtctl vmexport create name [flags]
```

#### Delete
```sh
# Deletes the specified VMExport object.

$ virtctl vmexport delete name
```
#### Download
```sh
# Downloads a volume from the defined VMExport object.

# The main available flags are:

# --output, mandatory flag to specify the output file.
# --volume, optional flag to specify the name of the downloadable volume.
# --vm|--snapshot|--pvc, if specified, are used to create the VMExport object assuming it doesn't exist. The name of the object to export has to be specified.
# --format, optional flag to specify wether to download the file in compressed (default) or raw format.
# --port-forward, optional flag to easily download the volume without the need of an ingress or route. Also, the local port can be optionally specified with the --local-port flag.

$ virtctl vmexport download name [flags]
```

By default, the volume will be downloaded in compressed format. Users can specify the desired format (gzip or raw) by using the `format` flag, as shown below:

```sh
# Downloads a volume from the defined VMExport object and, if necessary, decompresses it.
$ virtctl vmexport download name --format=raw [flags]
```

#### TTL (Time to live)
TTL can also be added when creating a VMExport via virtctl
```sh
$ virtctl vmexport create name --ttl=1h
```

For more information about usage and examples:

```
$ virtctl vmexport --help

Export a VM volume.

Usage:
  virtctl vmexport [flags]

Examples:
  # Create a VirtualMachineExport to export a volume from a virtual machine:
	virtctl vmexport create vm1-export --vm=vm1

	# Create a VirtualMachineExport to export a volume from a virtual machine snapshot
	virtctl vmexport create snap1-export --snapshot=snap1

	# Create a VirtualMachineExport to export a volume from a PVC
	virtctl vmexport create pvc1-export --pvc=pvc1

	# Delete a VirtualMachineExport resource
	virtctl vmexport delete snap1-export

	# Download a volume from an already existing VirtualMachineExport (--volume is optional when only one volume is available)
	virtctl vmexport download vm1-export --volume=volume1 --output=disk.img.gz

	# Create a VirtualMachineExport and download the requested volume from it
	virtctl vmexport download vm1-export --vm=vm1 --volume=volume1 --output=disk.img.gz

Flags:
  -h, --help              help for vmexport
      --insecure          When used with the 'download' option, specifies that the http request should be insecure.
      --keep-vme          When used with the 'download' option, specifies that the vmexport object should not be deleted after the download finishes.
      --output string     Specifies the output path of the volume to be downloaded.
      --pvc string        Sets PersistentVolumeClaim as vmexport kind and specifies the PVC name.
      --snapshot string   Sets VirtualMachineSnapshot as vmexport kind and specifies the snapshot name.
      --vm string         Sets VirtualMachine as vmexport kind and specifies the vm name.
      --volume string     Specifies the volume to be downloaded.

Use "virtctl options" for a list of global command-line options (applies to all commands).
```


### Use cases

#### Clone VM from one cluster to another cluster

If you want to transfer KubeVirt disk images from a source cluster to another target cluster, you can use the VMExport in the source to expose the disks and use Containerized Data Importer (CDI) in the target cluster to import the image into the target cluster. Let's assume we have an Ingress or Route in the source cluster that exposes the export proxy with the following example domain `virt-exportproxy-example.example.com` and we have a Virtual Machine in the source cluster with one disk, which looks like this:

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

This is a VM that has a DataVolume (DV) `example-dv` that is populated from a container disk and we want to export that disk to the target cluster. To export this VM we have to create a token that we can use in the target cluster to get access to the export, or we can let the export controller generate one for us. For example

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
  tokenSecretRef: example-token #optional, if omitted the export controller will generate a token
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

Now we are ready to import this disk into the target cluster. In order for CDI to import, we will need to provide appropriate yaml that contains the following:
- CA cert (as config map)
- The token needed to access the disk images in a CDI compatible format
- The VM yaml
- DataVolume yaml (optional if not part of the VM definition)

virtctl provides an additional argument to the download command called `--manifest` that will retrieve the appropriate information from the export server, and either save it to a file with the `--output` argument or write to standard out. By default this output will not contain the header secret as it contains the token in plaintext. To get the header secret you specify the `--include-secret` argument. The default output format is `yaml` but it is possible to get `json` output as well.

Assuming there is a running VirtualMachineExport called `example-export` and the same namespace exists in the target cluster. The name of the kubeconfig of the target cluster is named `kubeconfig-target`, to clone the vm into the target cluster run the following commands:

```bash
$ virtctl vmexport download example-export --manifest --include-secret --output=import.yaml
$ kubectl apply -f import.yaml --kubeconfig=kubeconfig-target
```

The first command generates the yaml and writes it to `import.yaml`. The second command applies the generated yaml to the target cluster. It is possible to combine the two commands writing to standard `out` with the first command, and piping it into the second command. Use this option if the export token should not be written to a file anywhere. This will create the VM in the target cluster, and provides CDI in the target cluster with everything required to import the disk images.

After the import completes you should be able to start the VM in the target cluster.

#### Download a VM volume locally using virtctl vmexport

Several steps from the previous section can be simplified considerably by using the `vmexport` command.

Again, let's assume we have an Ingress or Route in our cluster that exposes the export proxy, and that we have a Virtual Machine in the cluster with one disk like this:

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

Once we meet these requirements, the process of downloading the volume locally can be accomplished by different means:

##### Performing each step separately

We can download the volume by performing every single step in a different command. We start by creating the export object:

```bash
# We use an arbitrary name for the VMExport object, but specify our VM name in the flag.

$ virtctl vmexport create vmexportname --vm=example-vm
```

Then, we download the volume in the specified output:

```bash
# Since our virtual machine only has one volume, there's no need to specify the volume name with the --volume flag.

# After the download, the VMExport object is deleted by default, so we are using the optional --keep-vme flag to delete it manually.

$ virtctl vmexport download vmexportname --output=/tmp/disk.img --keep-vme
```

Lastly, we delete the VMExport object:

```bash
$ virtctl vmexport delete vmexportname
```

##### Performing one single step

All the previous steps can be simplified in one, single command:

```bash
# Since we are using a create flag (--vm) with download, the command creates the object assuming the VMExport doesn't exist.

# Also, since we are not using --keep-vme, the VMExport object is deleted after the download.

$ virtctl vmexport download vmexportname --vm=example-vm --output=/tmp/disk.img
```

After the download finishes, we can find our disk in `/tmp/disk.img`.
