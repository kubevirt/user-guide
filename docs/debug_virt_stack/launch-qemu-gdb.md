# Launch QEMU with gdb and connect locally with gdb client

This guide is for cases where QEMU counters very early failures and it is hard to synchronize it in a later point in time.

## Image creation and PVC population

This scenario is a slight variation of the [guide about starting strace](../debug_virt_stack/launch-qemu-strace.md), hence some of the details on the image build and the PVC population are simply skipped and explained in the other section.

In this example, QEMU will be launched with [`gdbserver`](https://man7.org/linux/man-pages/man1/gdbserver.1.html) and later we will connect to it using a local `gdb` client.

The wrapping script looks like:
```bash
#!/bin/bash

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/var/run/debug/usr/lib64 /var/run/debug/usr/bin/gdbserver \
	localhost:1234 \
	/usr/libexec/qemu-kvm $@ &
printf "%d" $(pgrep gdbserver) > /run/libvirt/qemu/run/default_vmi-debug-tools.pid

```

First, we need to build and push the image with the wrapping script and the gdbserver:
```dockerfile
FROM quay.io/centos/centos:stream9 as build

ENV DIR /debug-tools
ENV DEBUGINFOD_URLS https://debuginfod.centos.org/
RUN mkdir -p ${DIR}/logs

RUN yum  install --installroot=${DIR} -y gdb-gdbserver && yum clean all

COPY ./wrap_qemu_gdb.sh $DIR/wrap_qemu_gdb.sh
RUN chmod 0755 ${DIR}/wrap_qemu_gdb.sh
RUN chown 107:107 ${DIR}/wrap_qemu_gdb.sh
RUN chown 107:107 ${DIR}/logs
```

Then, we can create and populate the `debug-tools` PVC as with did in the [strace example](../debug_virt_stack/launch-qemu-strace.md):
```console
$ k apply -f debug-tools-pvc.yaml
persistentvolumeclaim/debug-tools created
$ kubectl  apply -f populate-job-pvc.yaml
job.batch/populate-pvc created
$ $ kubectl  get jobs
NAME           COMPLETIONS   DURATION   AGE
populate-pvc   1/1           7s         2m12s
```

Configmap:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config-map
data:
  my_script.sh: |
    #!/bin/sh
    tempFile=`mktemp --dry-run`
    echo $4 > $tempFile
    sed -i "s|<emulator>/usr/libexec/qemu-kvm</emulator>|<emulator>/var/run/debug/wrap_qemu_gdb.sh</emulator>|" $tempFile
    cat $tempFile
```

As last step, we need to create the configmaps to modify the VM XML:
```console
$ kubectl apply -f configmap.yaml
configmap/my-config-map created
```

### Build client image

In this scenario, we use an additional container image containing `gdb` and the same qemu binary as the target process to debug. This image will be run locally with `podman`.

In order to build this image, we need to identify the image of the `virt-launcher` container we want to debug. Based on the KubeVirt installation, the namespace and the name of the KubeVirt CR could vary. In this example, we'll assume that KubeVirt CR is called `kubevirt` and installed in the `kubevirt` namespace.

You can easily find out the right names in your cluster by searching with:
```console
$ kubectl get kubevirt -A
NAMESPACE   NAME       AGE     PHASE
kubevirt    kubevirt   3h11m   Deployed
```

The steps to build the image are:

1. Get the registry of the images of the KubeVirt installation:
```console
$ export registry=$(kubectl get kubevirt kubevirt -n kubevirt  -o jsonpath='{.status.observedDeploymentConfig}' |jq '.registry'|tr -d "\"")
$ echo $registry
"registry:5000/kubevirt"
```

2. Get the shasum of the virt-launcher image:
```console
$ export tag=$(kubectl get kubevirt kubevirt -n kubevirt  -o jsonpath='{.status.observedDeploymentConfig}' |jq '.virtLauncherSha'|tr -d "\"")
$ echo $tag
"sha256:6c8b85eed8e83a4c70779836b246c057d3e882eb513f3ded0a02e0a4c4bda837"
```

Example of Dockerfile:
```dockerfile
ARG registry
ARG tag
FROM ${registry}/kubevirt/virt-launcher${tag} AS launcher
FROM quay.io/centos/centos:stream9 as build

RUN yum  install -y gdb && yum clean all

COPY --from=launcher /usr/libexec/qemu-kvm /usr/libexec/qemu-kvm
```

3. Build the image by using the `registry` and the `tag` retrieved in the previous steps:
```console
$ podman build \
    -t gdb-client \
    --build-arg registry=$registry  \
    --build-arg tag=@$tag \
    -f Dockerfile.client .
```

Podman will replace the registry and tag arguments provided on the command line. In this way, we can specify the image registry and shasum for the KubeVirt version to debug.

## Run the VM to troubleshoot

For this example, we add an annotation to keep the virt-launcher pod running even if any errors occur:
```yaml
metadata:
  annotations:
    kubevirt.io/keep-launcher-alive-after-failure: "true"
```

Then, we can launch the VM:
```console
$ kubectl apply -f debug-vmi.yaml
virtualmachineinstance.kubevirt.io/vmi-debug-tools created
$ kubectl  get vmi
NAME              AGE   PHASE       IP    NODENAME   READY
vmi-debug-tools   28s   Scheduled         node01     False
$ kubectl  get po
NAME                                  READY   STATUS      RESTARTS   AGE
populate-pvc-dnxld                    0/1     Completed   0          4m17s
virt-launcher-vmi-debug-tools-tfh28   4/4     Running     0          25s
```


The wrapping script starts the `gdbserver` and expose in the port `1234` inside the container. In order to be able to connect remotely to the gdbserver, we can use the command `kubectl port-forward` to expose the gdb port on our machine.

```console
$ kubectl  port-forward virt-launcher-vmi-debug-tools-tfh28 1234
Forwarding from 127.0.0.1:1234 -> 1234
Forwarding from [::1]:1234 -> 1234

```

Finally, we can start the gbd client in the container:
```console
$ podman run -ti --network host gdb-client:latest
$ gdb /usr/libexec/qemu-kvm -ex 'target remote localhost:1234'
GNU gdb (GDB) Red Hat Enterprise Linux 10.2-12.el9
Copyright (C) 2021 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-redhat-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
--Type <RET> for more, q to quit, c to continue without paging--
Type "apropos word" to search for commands related to "word"...
Reading symbols from /usr/libexec/qemu-kvm...

Reading symbols from /root/.cache/debuginfod_client/26221a84fabd219a68445ad0cc87283e881fda15/debuginfo...
Remote debugging using localhost:1234
Reading /lib64/ld-linux-x86-64.so.2 from remote target...
warning: File transfers from remote targets can be slow. Use "set sysroot" to access files locally instead.
Reading /lib64/ld-linux-x86-64.so.2 from remote target...
Reading symbols from target:/lib64/ld-linux-x86-64.so.2...
Downloading separate debug info for /system-supplied DSO at 0x7ffc10eff000...
0x00007f1a70225e70 in _start () from target:/lib64/ld-linux-x86-64.so.2
```

For simplicity, we started podman with the option `--network host` in this way, the container is able to access any port mapped on the host.
