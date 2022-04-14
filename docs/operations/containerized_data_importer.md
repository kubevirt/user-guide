# Containerized Data Importer

The [Containerized Data
Importer](https://github.com/kubevirt/containerized-data-importer) (CDI)
project provides facilities for enabling [Persistent Volume
Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
(PVCs) to be used as disks for KubeVirt VMs by way of
[DataVolumes](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/datavolumes.md).
The three main CDI use cases are:

-   Import a disk image from a web server or container registry to a DataVolume
-   Clone an existing PVC to a DataVolume
-   Upload a local disk image to a DataVolume

This document deals with the third use case. So you should have CDI
installed in your cluster, a VM disk that you'd like to upload, and
virtctl in your path.

## Install CDI

Install the latest CDI release
[here](https://github.com/kubevirt/containerized-data-importer/releases)

    VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
    kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
    kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml

## Expose cdi-uploadproxy service

The `cdi-uploadproxy` service must be accessible from outside the
cluster. Here are some ways to do that:

-   [NodePort
    Service](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)

-   [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

-   [Route](https://docs.openshift.com/container-platform/4.10/networking/routes/route-configuration.html)

-   [kubectl
    port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)
    (not recommended for production clusters)

Look
[here](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/upload.md)
for example manifests.

## Supported image formats

CDI supports the `raw` and `qcow2` image formats which are supported by qemu.
See the [qemu documentation](https://www.qemu.org/docs/master/system/images.html#disk-image-file-formats) for more details.  Bootable ISO images can also be
used and are treated like `raw` images.  Images may be compressed with either
the `gz` or `xz` format.

The example in this document uses
[this](http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img)
[CirrOS](https://launchpad.net/cirros) image

## virtctl image-upload

virtctl has an image-upload command with the following options:

    virtctl image-upload --help
    Upload a VM image to a DataVolume/PersistentVolumeClaim.

    Usage:
      virtctl image-upload [flags]

    Examples:
      # Upload a local disk image to a newly created DataVolume:
      virtctl image-upload dv dv-name --size=10Gi --image-path=/images/fedora30.qcow2

      # Upload a local disk image to an existing DataVolume
      virtctl image-upload dv dv-name --no-create --image-path=/images/fedora30.qcow2

      # Upload a local disk image to an existing PersistentVolumeClaim
      virtctl image-upload pvc pvc-name --image-path=/images/fedora30.qcow2

      # Upload to a DataVolume with explicit URL to CDI Upload Proxy
      virtctl image-upload dv dv-name --uploadproxy-url=https://cdi-uploadproxy.mycluster.com --image-path=/images/fedora30.qcow2

    Flags:
          --access-mode string       The access mode for the PVC. (default "ReadWriteOnce")
          --block-volume             Create a PVC with VolumeMode=Block (default Filesystem).
      -h, --help                     help for image-upload
          --image-path string        Path to the local VM image.
          --insecure                 Allow insecure server connections when using HTTPS.
          --no-create                Don't attempt to create a new DataVolume/PVC.
          --pvc-name string          DEPRECATED - The destination DataVolume/PVC name.
          --pvc-size string          DEPRECATED - The size of the PVC to create (ex. 10Gi, 500Mi).
          --size string              The size of the DataVolume to create (ex. 10Gi, 500Mi).
          --storage-class string     The storage class for the PVC.
          --uploadproxy-url string   The URL of the cdi-upload proxy service.
          --wait-secs uint           Seconds to wait for upload pod to start. (default 60)

    Use "virtctl options" for a list of global command-line options (applies to all commands).

`virtctl image-upload` works by creating a DataVolume of the requested
size, sending an `UploadTokenRequest` to the `cdi-apiserver`, and
uploading the file to the `cdi-uploadproxy`.

    virtctl image-upload dv cirros-vm-disk --size=500Mi --image-path=/home/mhenriks/images/cirros-0.4.0-x86_64-disk.img --uploadproxy-url=<url to upload proxy service>

## Addressing Certificate Issues when Uploading Images

Issues with the certificates can be circumvented by using the `--insecure` flag to prevent the virtctl command from verifying the remote host.
It is better to resolve certificate issues that prevent uploading images using the `virtctl image-upload` command and not use the `--insecure` flag.

The following are some common issues with certificates and some easy ways to fix them.

### Does not contain any IP SANs

This issue happens when trying to upload images using an IP address instead of a resolvable name.
For example, trying to upload to the IP address 192.168.39.32 at port 31001 would produce the following error.

    virtctl image-upload dv f33 \
      --size 5Gi \
      --image-path Fedora-Cloud-Base-33-1.2.x86_64.raw.xz \
      --uploadproxy-url https://192.168.39.32:31001

    PVC default/f33 not found 
    DataVolume default/f33 created
    Waiting for PVC f33 upload pod to be ready...
    Pod now ready
    Uploading data to https://192.168.39.32:31001

     0 B / 193.89 MiB [-------------------------------------------------------]   0.00% 0s

    Post https://192.168.39.32:31001/v1alpha1/upload: x509: cannot validate certificate for 192.168.39.32 because it doesn't contain any IP SANs


It is easily fixed by adding an entry it your local name resolution service.
This could be a DNS server or the local hosts file.
The URL used to upload the proxy should be changed to reflect the resolvable name.

The `Subject` and the `Subject Alternative Name` in the certificate contain valid names that can be used for resolution.
Only one of these names needs to be resolvable.
Use the `openssl` command to view the names of the cdi-uploadproxy service.

    echo | openssl s_client -showcerts -connect 192.168.39.32:31001 2>/dev/null \
         | openssl x509 -inform pem -noout -text \
         | sed -n -e '/Subject.*CN/p' -e '/Subject Alternative/{N;p}'

        Subject: CN = cdi-uploadproxy
            X509v3 Subject Alternative Name: 
                DNS:cdi-uploadproxy, DNS:cdi-uploadproxy.cdi, DNS:cdi-uploadproxy.cdi.svc

Adding the following entry to the /etc/hosts file, if it provides name resolution, should fix this issue.
Any service that provides name resolution for the system could be used.

    echo "192.168.39.32  cdi-uploadproxy" >> /etc/hosts

The upload should now work.

    virtctl image-upload dv f33 \
      --size 5Gi \
      --image-path Fedora-Cloud-Base-33-1.2.x86_64.raw.xz \
      --uploadproxy-url https://cdi-uploadproxy:31001

    PVC default/f33 not found 
    DataVolume default/f33 created
    Waiting for PVC f33 upload pod to be ready...
    Pod now ready
    Uploading data to https://cdi-uploadproxy:31001

     193.89 MiB / 193.89 MiB [=============================================] 100.00% 1m38s

    Uploading data completed successfully, waiting for processing to complete, you can hit ctrl-c without interrupting the progress
    Processing completed successfully
    Uploading Fedora-Cloud-Base-33-1.2.x86_64.raw.xz completed successfully



### Certificate Signed by Unknown Authority
This happens because the cdi-uploadproxy certificate is self signed and the system does not trust the cdi-uploadproxy as a Certificate Authority.

    virtctl image-upload dv f33 \
      --size 5Gi \
      --image-path Fedora-Cloud-Base-33-1.2.x86_64.raw.xz \
      --uploadproxy-url https://cdi-uploadproxy:31001

    PVC default/f33 not found 
    DataVolume default/f33 created
    Waiting for PVC f33 upload pod to be ready...
    Pod now ready
    Uploading data to https://cdi-uploadproxy:31001

     0 B / 193.89 MiB [-------------------------------------------------------]   0.00% 0s

    Post https://cdi-uploadproxy:31001/v1alpha1/upload: x509: certificate signed by unknown authority

This can be fixed by adding the certificate to the systems trust store.
Download the cdi-uploadproxy-server-cert.

    kubectl get secret -n cdi cdi-uploadproxy-server-cert \
      -o jsonpath="{.data['tls\.crt']}" \
      | base64 -d > cdi-uploadproxy-server-cert.crt

Add this certificate to the systems trust store. On Fedora, this can be done as follows.

    sudo cp cdi-uploadproxy-server-cert.crt /etc/pki/ca-trust/source/anchors

    sudo update-ca-trust

The upload should now work.

    virtctl image-upload dv f33 \
      --size 5Gi \
      --image-path Fedora-Cloud-Base-33-1.2.x86_64.raw.xz \
      --uploadproxy-url https://cdi-uploadproxy:31001

    PVC default/f33 not found 
    DataVolume default/f33 created
    Waiting for PVC f33 upload pod to be ready...
    Pod now ready
    Uploading data to https://cdi-uploadproxy:31001

     193.89 MiB / 193.89 MiB [=============================================] 100.00% 1m36s

    Uploading data completed successfully, waiting for processing to complete, you can hit ctrl-c without interrupting the progress
    Processing completed successfully
    Uploading Fedora-Cloud-Base-33-1.2.x86_64.raw.xz completed successfully



## Setting the URL of the cdi-upload Proxy Service
Setting the URL for the cdi-upload proxy service allows the `virtctl image-upload` command to upload the images without specifying the `--uploadproxy-url` flag.
Permanently setting the URL is done by patching the CDI configuration.

The following will set the default upload proxy to use port 31001 of cdi-uploadproxy.
An IP address could also be used instead of the dns name.

See the section Addressing Certificate Issues when Uploading for why cdi-uploadproxy was chosen and issues that can be encountered when using an IP address.

    kubectl patch cdi cdi \
      --type merge \
      --patch '{"spec":{"config":{"uploadProxyURLOverride":"https://cdi-uploadproxy:31001"}}}'


## Create a VirtualMachineInstance

To create a `VirtualMachineInstance` from a DataVolume, you can execute the
following:

    cat <<EOF | kubectl apply -f -
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: cirros-vm
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: dvdisk
        machine:
          type: ""
        resources:
          requests:
            memory: 64M
      terminationGracePeriodSeconds: 0
      volumes:
      - name: dvdisk
        dataVolume:
          name: cirros-vm-disk
    status: {}
    EOF

## Connect to VirtualMachineInstance console

Use `virtctl` to connect to the newly create `VirtualMachineInstance`.

    virtctl console cirros-vm
