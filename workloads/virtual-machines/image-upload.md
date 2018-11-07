# Creating Virtual Machines from local images with CDI and virtctl

The [Containerized Data Importer](https://github.com/kubevirt/containerized-data-importer) (CDI) project provides facilities for enabling [Persistent Volume Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVCs) to be used as disks for KubeVirt VMs.  The three main CDI use cases are:

- Import a disk image from a URL to a PVC (HTTP/S3)
- Clone an an existing PVC
- Upload a local disk image to a PVC

This document deals with the third use case.  So you should have CDI installed in your cluster, a VM disk that you'd like to upload, and virtctl in your path.

## Install CDI

Install the latest CDI release [here](https://github.com/kubevirt/containerized-data-importer/releases) (currently v1.3.0)

```bash
VERSION=v1.3.0
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-controller.yaml

```

### Expose cdi-uploadproxy service

The `cdi-uploadproxy` service must be accessible from outside the cluster.  Here are some ways to do that:

- [NodePort Service](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Route](https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html)
- [kubectl port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) (not recommended for production clusters)

Look [here](https://github.com/kubevirt/containerized-data-importer/blob/master/doc/upload.md) for example manifests.

## Supported image formats

- `.img`
- `.iso`
- `.qcow2`

\* compressed `.tar`, `.gz`, and `.xz` versions of above supported as well

Example in this doc uses [this](http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img) [CirrOS](https://launchpad.net/cirros) image

## virtctl image-upload

virtctl has an image-upload command with the following options:

```bash
virtctl image-upload --help
Upload a VM image to a PersistentVolumeClaim.

Usage:
  virtctl image-upload [flags]

Examples:
  # Upload a local disk image to a newly created PersistentVolumeClaim:
	virtctl image-upload --upload-proxy-url=https://cdi-uploadproxy.mycluster.com --pvc-name=upload-pvc --pvc-size=10Gi --image-path=/images/fedora28.qcow2

Flags:
      --access-mode string       The access mode for the PVC. (default "ReadWriteOnce")
  -h, --help                     help for image-upload
      --image-path string        Path to the local VM image.
      --insecure                 Allow insecure server connections when using HTTPS.
      --no-create                Don't attempt to create a new PVC.
      --pvc-name string          The destination PVC.
      --pvc-size string          The size of the PVC to create (ex. 10Gi, 500Mi).
      --storage-class string     The storage class for the PVC.
      --uploadproxy-url string   The URL of the cdi-upload proxy service.
      --wait-secs uint           Seconds to wait for upload pod to start. (default 60)

Use "virtctl options" for a list of global command-line options (applies to all commands).

```

"virtctl image-upload" works by creating a PVC of the requested size, sending an `UploadTokenRequest` to the `cdi-apiserver`, and uploading the file to the `cdi-uploadproxy`.

```bash
virtctl image-upload --pvc-name=cirros-vm-disk --pvc-size=500Mi --image-path=/home/mhenriks/images/cirros-0.4.0-x86_64-disk.img --uploadproxy-url=<url to upload proxy service>
```

## Create a VirtualMachineInstance

To create a `VirtualMachinInstance` from a PVC, you can execute the following:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  creationTimestamp: null
  name: cirros-vm
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: pvcdisk
        volumeName: pvcvolume
    machine:
      type: ""
    resources:
      requests:
        memory: 64M
  terminationGracePeriodSeconds: 0
  volumes:
  - name: pvcvolume
    persistentVolumeClaim:
      claimName: cirros-vm-disk
status: {}
EOF
```

## Connect to VirtualMachineInstance console

Use `virtctl` to connect to the newly create `VirtualMachinInstance`.

```bash
virtctl console cirros-vm
```
