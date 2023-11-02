# Launch QEMU with strace

This guide explains how launch QEMU with a debugging tool in virt-launcher pod. This method can be useful to debug early failures or starting QEMU as a child of the debug tool relying on [ptrace](https://man7.org/linux/man-pages/man2/ptrace.2.html). The second point is particularly relevant when a process is operating in a non-privileged environment since otherwise, it would need root access to be able to ptrace the process.

[Ephemeral containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) are among the emerging techniques to overcome the lack of debugging tool inside the original image. This solution does, however, come with a number of limitations.  For example, it is possible to spawn a new container inside the same pod of the application to debug and share the same PID namespace. Though they share the same PID namespace, KubeVirt's usage of unprivileged containers makes it, for example, impossible to ptrace a running container. Therefore, this technique isn't appropriate for our needs.

Due to its security and image size reduction, KubeVirt container images are based on [distroless containers](https://github.com/GoogleContainerTools/distroless). These kinds of images are extremely beneficial for deployments, but they are challenging to troubleshoot because there is no package management, which prevents the installation of additional tools on the flight.

Wrapping the QEMU binary in a script is one practical method for debugging QEMU launched by Libvirt. This script launches the QEMU as a child of this process together with the debugging tool (such as [strace](https://man7.org/linux/man-pages/man1/strace.1.html) or [valgrind](https://valgrind.org/)).


The final part that needs to be added is the configuration for Libvirt to use the wrapped script rather than calling the QEMU program directly.

It is possible to alter the generated XML with the help of [KubeVirt sidecars](https://github.com/kubevirt/kubevirt/tree/main/cmd/sidecars). This allows us to use the wrapping script in place of the built-in emulator.

The primary concept behind this configuration is that all of the additional tools, scripts, and final output files will be stored in a [PerstistentVolumeClaim (PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) that this guide refers to as `debug-tools`. The virt-launcher pod that we wish to debug will have this PVC attached to it.


PVC:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: debug-tools
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 1Gi
```

In this guide, we'll apply the above concepts to debug QEMU inside virt-launcher using strace without the need of build a custom virt-launcher image.

You can see a full demo of this setup:
[![asciicast](https://asciinema.org/a/1Cm87DcjtUWprRrWPBzKfxVmp.svg)](https://asciinema.org/a/1Cm87DcjtUWprRrWPBzKfxVmp)

## How to bring the debug tools and wrapping script into distroless containers

This section provides an example of how to provide extra tools into the distroless container that will be supplied as a PVC using a Dockerfile.
Although there are several ways to accomplish this, this covers a relatively simple technique. Alternatively, you could run a pod and manually populate the PVC by execing into the pod.

Dockerfile:
```dockerfile
FROM quay.io/centos/centos:stream9 as build

ENV DIR /debug-tools
RUN mkdir -p ${DIR}/logs

RUN  yum install  --installroot=${DIR} -y strace && yum clean all

COPY ./wrap_qemu_strace.sh $DIR/wrap_qemu_strace.sh
RUN chmod 0755 ${DIR}/wrap_qemu_strace.sh
RUN chown 107:107 ${DIR}/wrap_qemu_strace.sh
RUN chown 107:107 ${DIR}/logs
```

The directory `debug-tools` stores the content that will be later copied inside the `debug-tools` PVC. We are essentially adding the missing utilities in the custom directory with `yum install --installroot=${DIR}}`, and the parent image matches with the parent images of virt-launcher.

The `wrap_qemu_strace.sh` is the wrapping script that will be used to launch QEMU with `strace` similarly as the example with `valgrind`.
```bash
#!/bin/bash

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/var/run/debug/usr/lib64 /var/run/debug/usr/bin/strace \
        -o /var/run/debug/logs/strace.out \
        /usr/libexec/qemu-kvm $@
```

It is important to set the dynamic library path `LD_LIBRARY_PATH` to the path where the PVC will be mounted in the virt-launcher container.

Then, you will simply need to build the image and your debug setup is ready. The Dockerfle and the script `wrap_qemu_strace.sh` need to be in the same directory where you run the command.
```console
$ podman build -t debug .
```

The second step is to populate the PVC. This can be easily achieved using a kubernetes [`Job`](https://kubernetes.io/docs/concepts/workloads/controllers/job/) like:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: populate-pvc
spec:
  template:
    spec:
      volumes:
        - name: populate
          persistentVolumeClaim:
            claimName: debug-tools
      containers:
        - name: populate
          image: registry:5000/debug:latest
          command: ["sh", "-c", "cp -r /debug-tools/* /vol"]
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: "/vol"
              name: populate
      restartPolicy: Never
  backoffLimit: 4
```

The image referenced in the `Job` is the image we built in the previous step. Once applied this and the job completed, the`debug-tools` PVC is ready to be used.

## How to start qemu launched by a debugging tool (e.g strace)

This part is achieved by using ConfigMaps and a KubeVirt sidecar (more details in the section [Using ConfigMap to run custom script](https://github.com/kubevirt/kubevirt/tree/main/cmd/sidecars#using-configmap-to-run-custom-script)).

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
    sed -i "s|<emulator>/usr/libexec/qemu-kvm</emulator>|<emulator>/var/run/debug/wrap_qemu_strace.sh</emulator>|" $tempFile
    cat $tempFile
```

The script that replaces the QEMU binary with the wrapping script in the XML is stored in the configmap `my-config-map`. This script will run as a hook, as explained in full in the documentation for the KubeVirt sidecar.

Once all the objects created, we can finally run the guest to debug.

VMI:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  annotations:
    hooks.kubevirt.io/hookSidecars: '[{"args": ["--version", "v1alpha2"],
    "image":"registry:5000/kubevirt/sidecar-shim:devel",
    "pvc": {"name": "debug-tools","volumePath": "/debug", "sharedComputePath": "/var/run/debug"},
    "configMap": {"name": "my-config-map","key": "my_script.sh", "hookPath": "/usr/bin/onDefineDomain"}}]'
  labels:
    special: vmi-debug-tools
  name: vmi-debug-tools
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      rng: {}
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: registry:5000/kubevirt/fedora-with-test-tooling-container-disk:devel
    name: containerdisk
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
    name: cloudinitdisk
```

The VMI example is a simply VM instance declaration and the interesting parts are the annotations for the hook:
* `image` refers to the sidecar-shim already built and shipped with KubeVirt
* `pvc` refers to the PVC populated with the debug setup. The `name` refers to the claim name, the `volumePath` is the path inside the sidecar container where the volume is mounted while the `sharedComputePath` is the path of the same volume inside the compute container.
* `configMap` refers to the confimap containing the script to modify the XML for the wrapping script

Once the VM is declared, the hook will modify the emulator section and Libvirt will call the wrapping script instead of QEMU directly.

## How to fetch the output

The wrapping script configures `strace` to store the output in the PVC. In this way, it is possible to retrieve the output file in a later time, for example using an additional pod like:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fetch-logs
spec:
  securityContext:
    runAsUser: 107
    fsGroup: 107
  volumes:
    - name: populate
      persistentVolumeClaim:
        claimName: debug-tools
  containers:
    - name: populate
      image: busybox:latest
      command: ["tail", "-f", "/dev/null"]
      volumeMounts:
        - mountPath: "/vol"
          name: populate
```

It is then possible to copy the file locally with:
```console
$ kubectl cp fetch-logs:/vol/logs/strace.out strace.out
```
