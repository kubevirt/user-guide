# Privileged debugging on the node

This article describes the scenarios in which you can create privileged pods and have root access to the cluster nodes.

With privileged pods, you may access devices in `/dev`, utilize host namespaces and ptrace processes that are running on the node, and use the `hostPath` volume to mount node directories in the container.

A quick way to verify if you are allowed to create privileged pods is to create a sample pod with the `--dry-run=server` option, like:

```console
$ kubectl apply -f debug-pod.ymal --dry-run=server
```

# Build the container image

KubeVirt uses [distroless containers](https://github.com/GoogleContainerTools/distroless) and those images don't have a package manager, for this reason it isn't possible to use the image as parent for installing additional packages.

In certain debugging scenarios, the tools require to have exactly the same binary available. However, if the debug tools are operating in a different container, this can be especially difficult as the filesystems of the containers are isolated.

This section will cover how to build a container image with
the debug tools plus binaries of the KubeVirt version you want to debug.

Based on your installation the namespace and the name of the KubeVirt CR could
vary. In this example, we'll assume that KubeVirt CR is called `kubevirt` and
installed in the `kubevirt` namespace. You can easily find out how it is called
in your cluster by searching with `kubectl get kubevirt -A`.
This is necessary as we need to retrieve the original `virt-launcher` image to have exactly the same QEMU binary we want to debug.

Get the registry of the images of the KubeVirt installation:
```console
$ export registry=$(kubectl get kubevirt kubevirt -n kubevirt  -o jsonpath='{.status.observedDeploymentConfig}' |jq '.registry'|tr -d "\"")
$ echo $registry
"registry:5000/kubevirt"
```

Get the shasum of the virt-launcher image:
```console
$ export tag=$(kubectl get kubevirt kubevirt -n kubevirt  -o jsonpath='{.status.observedDeploymentConfig}' |jq '.virtLauncherSha'|tr -d "\"")
$ echo $tag
"sha256:6c8b85eed8e83a4c70779836b246c057d3e882eb513f3ded0a02e0a4c4bda837"
```

Dockerfile:
```dockerfile
ARG registry
ARG tag
FROM ${registry}/kubevirt/virt-launcher${tag} AS launcher

FROM quay.io/centos/centos:stream9

RUN yum install -y \
        gdb \
        kernel-devel \
        qemu-kvm-tools \
        strace \
        systemtap-client \
        systemtap-devel \
    && yum clean all
COPY --from=launcher / /
```

Then, we can build the image by using the `registry` and the `tag` retrieved in the previous steps:
```console
$ podman build \
    -t debug-tools \
    --build-arg registry=$registry  \
    --build-arg tag=@$tag \
    -f Dockerfile .
```

## Deploy the privileged debug pod

This is an example that gives you a couple of suggestions how you can define your debugging pod:

```yaml
kind: Pod
metadata:
  name: node01-debug
spec:
  containers:
  - command:
    - /bin/sh
    image: registry:5000/debug-tools:latest
    imagePullPolicy: Always
    name: debug
    securityContext:
      privileged: true
      runAsUser: 0
    stdin: true
    stdinOnce: true
    tty: true
    volumeMounts:
    - mountPath: /host
      name: host
    - mountPath: /usr/lib/modules
      name: modules
    - mountPath: /sys/kernel
      name: sys-kernel
  hostNetwork: true
  hostPID: true
  nodeName: node01
  restartPolicy: Never
  volumes:
  - hostPath:
      path: /
      type: Directory
    name: host
  - hostPath:
      path: /usr/lib/modules
      type: Directory
    name: modules
  - hostPath:
      path: /sys/kernel
      type: Directory
    name: sys-kernel
```

The `privileged` option is required to have access to mostly all the resources
on the node.

The `nodeName` ensures that the debugging pod will be scheduled on the desired node. In order to select the right now, you can use the `-owide` option with `kubectl get po` and this will report the nodes where the pod is running.

Example:
```console
 k get pods -owide
NAME                                READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
local-volume-provisioner-4jtkb      1/1     Running   0          152m    10.244.196.129   node01   <none>           <none>
node01-debug                        1/1     Running   0          44m     192.168.66.101   node01   <none>           <none>
virt-launcher-vmi-ephemeral-xg98p   3/3     Running   0          2m54s   10.244.196.148   node01   <none>           1/1
```

In the `volumes` section, you can specify the directories you want to be directly mounted in the debugging container. For example, `/usr/lib/modules` is particularly useful if you need to load some kernel modules.

Sharing the host pid namespace with the option `hostPID` allows you to see all the processes on the node and attach to it with tools like `gdb` and `strace`.

`exec`-ing into the pod gives you a shell with  privileged access to the node plus the tooling you installed into the image:

```console
$ kubectl exec -ti debug -- bash
```

The following examples assume you have already execed into the `node01-debug` pod.

### Validating the host for virtualization

The tool [`vist-host-validate`](https://libvirt.org/manpages/virt-host-validate.html) is utility to validate the host to run libvirt hypervisor. This, for example, can be used to check if a particular node is kvm capable.

Example:
```console
$  virt-host-validate
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : PASS
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : PASS
  QEMU: Checking if IOMMU is enabled by kernel                               : PASS
  QEMU: Checking for secure guest support                                    : WARN (Unknown if this platform has Secure
```

### Run a command directly on the node

The debug container has in the volume section the host filesystem mounted under `/host`. This can be particularly useful if you want to access the node filesystem or execute a command directly on the host. However, the tool needs already to be present on the node.

```console
# chroot /host
sh-5.1# cat /etc/os-release
NAME="CentOS Stream"
VERSION="9"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="9"
PLATFORM_ID="platform:el9"
PRETTY_NAME="CentOS Stream 9"
ANSI_COLOR="0;31"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:centos:centos:9"
HOME_URL="https://centos.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_SUPPORT_PRODUCT="Red Hat Enterprise Linux 9"
REDHAT_SUPPORT_PRODUCT_VERSION="CentOS Stream"
```

### Attach to a running process (e.g strace or gdb)

This requires the field `hostPID: true` in this way you are able to list all the
processes running on the node.

```console
$ ps -ef |grep qemu-kvm
qemu       50122   49850  0 12:34 ?        00:00:25 /usr/libexec/qemu-kvm -name guest=default_vmi-ephemeral,debug-threads=on -S -object {"qom-type":"secret","id":"masterKey0","format":"raw","file":"/var/run/kubevirt-private/libvirt/qemu/lib/domain-1-default_vmi-ephemera/master-key.aes"} -machine pc-q35-rhel9.2.0,usb=off,dump-guest-core=off,memory-backend=pc.ram,acpi=on -accel kvm -cpu Skylake-Client-IBRS,ss=on,vmx=on,pdcm=on,hypervisor=on,tsc-adjust=on,clflushopt=on,umip=on,md-clear=on,stibp=on,flush-l1d=on,arch-capabilities=on,ssbd=on,xsaves=on,pdpe1gb=on,ibpb=on,ibrs=on,amd-stibp=on,amd-ssbd=on,rdctl-no=on,ibrs-all=on,skip-l1dfl-vmentry=on,mds-no=on,pschange-mc-no=on,tsx-ctrl=on,fb-clear=on,hle=off,rtm=off -m size=131072k -object {"qom-type":"memory-backend-ram","id":"pc.ram","size":134217728} -overcommit mem-lock=off -smp 1,sockets=1,dies=1,cores=1,threads=1 -object {"qom-type":"iothread","id":"iothread1"} -uuid b56f06f0-07e9-4fe5-8913-18a14e83a4d1 -smbios type=1,manufacturer=KubeVirt,product=None,uuid=b56f06f0-07e9-4fe5-8913-18a14e83a4d1,family=KubeVirt -no-user-config -nodefaults -chardev socket,id=charmonitor,fd=21,server=on,wait=off -mon chardev=charmonitor,id=monitor,mode=control -rtc base=utc -no-shutdown -boot strict=on -device {"driver":"pcie-root-port","port":16,"chassis":1,"id":"pci.1","bus":"pcie.0","multifunction":true,"addr":"0x2"} -device {"driver":"pcie-root-port","port":17,"chassis":2,"id":"pci.2","bus":"pcie.0","addr":"0x2.0x1"} -device {"driver":"pcie-root-port","port":18,"chassis":3,"id":"pci.3","bus":"pcie.0","addr":"0x2.0x2"} -device {"driver":"pcie-root-port","port":19,"chassis":4,"id":"pci.4","bus":"pcie.0","addr":"0x2.0x3"} -device {"driver":"pcie-root-port","port":20,"chassis":5,"id":"pci.5","bus":"pcie.0","addr":"0x2.0x4"} -device {"driver":"pcie-root-port","port":21,"chassis":6,"id":"pci.6","bus":"pcie.0","addr":"0x2.0x5"} -device {"driver":"pcie-root-port","port":22,"chassis":7,"id":"pci.7","bus":"pcie.0","addr":"0x2.0x6"} -device {"driver":"pcie-root-port","port":23,"chassis":8,"id":"pci.8","bus":"pcie.0","addr":"0x2.0x7"} -device {"driver":"pcie-root-port","port":24,"chassis":9,"id":"pci.9","bus":"pcie.0","addr":"0x3"} -device {"driver":"virtio-scsi-pci-non-transitional","id":"scsi0","bus":"pci.5","addr":"0x0"} -device {"driver":"virtio-serial-pci-non-transitional","id":"virtio-serial0","bus":"pci.6","addr":"0x0"} -blockdev {"driver":"file","filename":"/var/run/kubevirt/container-disks/disk_0.img","node-name":"libvirt-2-storage","cache":{"direct":true,"no-flush":false},"auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-2-format","read-only":true,"discard":"unmap","cache":{"direct":true,"no-flush":false},"driver":"qcow2","file":"libvirt-2-storage"} -blockdev {"driver":"file","filename":"/var/run/kubevirt-ephemeral-disks/disk-data/containerdisk/disk.qcow2","node-name":"libvirt-1-storage","cache":{"direct":true,"no-flush":false},"auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-1-format","read-only":false,"discard":"unmap","cache":{"direct":true,"no-flush":false},"driver":"qcow2","file":"libvirt-1-storage","backing":"libvirt-2-format"} -device {"driver":"virtio-blk-pci-non-transitional","bus":"pci.7","addr":"0x0","drive":"libvirt-1-format","id":"ua-containerdisk","bootindex":1,"write-cache":"on","werror":"stop","rerror":"stop"} -netdev {"type":"tap","fd":"22","vhost":true,"vhostfd":"24","id":"hostua-default"} -device {"driver":"virtio-net-pci-non-transitional","host_mtu":1480,"netdev":"hostua-default","id":"ua-default","mac":"7e:cb:ba:c3:71:88","bus":"pci.1","addr":"0x0","romfile":""} -add-fd set=0,fd=20,opaque=serial0-log -chardev socket,id=charserial0,fd=18,server=on,wait=off,logfile=/dev/fdset/0,logappend=on -device {"driver":"isa-serial","chardev":"charserial0","id":"serial0","index":0} -chardev socket,id=charchannel0,fd=19,server=on,wait=off -device {"driver":"virtserialport","bus":"virtio-serial0.0","nr":1,"chardev":"charchannel0","id":"channel0","name":"org.qemu.guest_agent.0"} -audiodev {"id":"audio1","driver":"none"} -vnc vnc=unix:/var/run/kubevirt-private/3a8f7774-7ec7-4cfb-97ce-581db52ee053/virt-vnc,audiodev=audio1 -device {"driver":"VGA","id":"video0","vgamem_mb":16,"bus":"pcie.0","addr":"0x1"} -global ICH9-LPC.noreboot=off -watchdog-action reset -device {"driver":"virtio-balloon-pci-non-transitional","id":"balloon0","free-page-reporting":true,"bus":"pci.8","addr":"0x0"} -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny -msg timestamp=on
$ gdb -p 50122 /usr/libexec/qemu-kvm
```

### Debugging using `crictl`

[`Crictl`](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md) is a cli for CRI runtimes and can be particularly useful to troubleshoot container failures (for a more detailed guide, please refer to this [Kubernetes article](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)).

In this example, we'll concentrate to find where libvirt creates the files
and directory in the `compute` container of the virt-launcher pod.

```console
$ crictl ps |grep compute
67bc7be3222da       5ef5ba25a087a80e204f28be6c9250bbf378fd87fa927085abd516188993d695                                                       25 minutes ago      Running             compute                   0                   7b045ea9f485f       virt-launcher-vmi-ephemeral-xg98p
$ crictl inspect 67bc7be3222da
[..]
    "mounts": [
      {
      {
        "containerPath": "/var/run/libvirt",
        "hostPath": "/var/lib/kubelet/pods/2ccc3e93-d1c3-4f22-bb31-321bfa74edf6/volumes/kubernetes.io~empty-dir/libvirt-runtime",
        "propagation": "PROPAGATION_PRIVATE",
        "readonly": false,
        "selinuxRelabel": true
      },
[..]
$ ls /var/lib/kubelet/pods/2ccc3e93-d1c3-4f22-bb31-321bfa74edf6/volumes/kubernetes.io~empty-dir/libvirt-runtime/
common	    qemu		 virtlogd-sock	virtqemud-admin-sock  virtqemud.conf
hostdevmgr  virtlogd-admin-sock  virtlogd.pid	virtqemud-sock	      virtqemud.pid
```
