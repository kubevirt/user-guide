# Liveness and Readiness Probes

It is possible to configure Liveness and Readiness Probes in a similar
fashion like it is possible to configure [Liveness and Readiness Probes
on
Containers](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).

Liveness Probes will effectively stop the VirtualMachineInstance if they
fail, which will allow higher level controllers, like VirtualMachine or
VirtualMachineInstanceReplicaSet to spawn new instances, which will
hopefully be responsive again.

Readiness Probes are an indicator for Services and Endpoints if the
VirtualMachineInstance is ready to receive traffic from Services. If
Readiness Probes fail, the VirtualMachineInstance will be removed from
the Endpoints which back services until the probe recovers.

Watchdogs focus on ensuring that an Operating System is still responsive. They
complement the probes which are more workload centric. Watchdogs require kernel
support from the guest and additional tooling like the commonly used `watchdog`
binary.

Exec probes are Liveness or Readiness probes specifically intended for VMs.
These probes run a command inside the VM and determine the VM ready/live state based
on its success.
For running commands inside the VMs, the qemu-guest-agent package is used.
A command supplied to an exec probe will be wrapped by `virt-probe` in the 
operator and forwarded to the guest.

## Define a HTTP Liveness Probe

The following VirtualMachine configures a HTTP Liveness Probe
via `spec.template.spec.livenessProbe.httpGet`, which will query port 1500 of the
VirtualMachine, after an initial delay of 120 seconds. The
VirtualMachine itself installs and runs a minimal HTTP server on
port 1500 via cloud-init.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-http-liveness-probe
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinit
          rng: {}
        resources:
          requests:
            memory: 1Gi
      livenessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        httpGet:
          port: 1500
        timeoutSeconds: 10
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/centos-stream:9
      - name: cloudinit
        cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: centos
            user: centos
            chpasswd: { expire: False }
            bootcmd:
              - ["sudo", "dnf", "install", "-y", "nmap-ncat"]
              - ["sudo", "systemd-run", "--unit=httpserver", "nc", "-klp", "1500", "-e", '/usr/bin/echo -e HTTP/1.1 200 OK\\nContent-Length: 12\\n\\nHello World!']
```

## Define a TCP Liveness Probe

The following VirtualMachine configures a TCP Liveness Probe via
`spec.template.spec.livenessProbe.tcpSocket`, which will query port 1500 of the
VirtualMachine, after an initial delay of 120 seconds. The
VirtualMachine itself installs and runs a minimal HTTP server on
port 1500 via cloud-init.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-tcp-liveness-probe
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinit
          rng: {}
        resources:
          requests:
            memory: 1Gi
      livenessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        tcpSocket:
          port: 1501
        timeoutSeconds: 10
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/centos-stream:9
      - name: cloudinit
        cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: centos
            user: centos
            chpasswd: { expire: False }
            bootcmd:
              - ["sudo", "dnf", "install", "-y", "nmap-ncat"]
              - ["sudo", "systemd-run", "--unit=httpserver", "nc", "-klp", "1500", "-e", '/usr/bin/echo -e HTTP/1.1 200 OK\\nContent-Length: 12\\n\\nHello World!']
```

## Define Readiness Probes

Readiness Probes are configured in a similar way like liveness probes.
Instead of `spec.template.spec.livenessProbe`, `spec.template.spec.readinessProbe` 
needs to be filled:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-readiness-probe
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinit
          rng: {}
        resources:
          requests:
            memory: 1Gi
      readinessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        timeoutSeconds: 10
        failureThreshold: 3
        successThreshold: 3
        httpGet:
          port: 1500
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/centos-stream:9
      - name: cloudinit
        cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: centos
            user: centos
            chpasswd: { expire: False }
            bootcmd:
              - ["sudo", "dnf", "install", "-y", "nmap-ncat"]
              - ["sudo", "systemd-run", "--unit=httpserver", "nc", "-klp", "1500", "-e", '/usr/bin/echo -e HTTP/1.1 200 OK\\nContent-Length: 12\\n\\nHello World!']
```

Note that in the case of Readiness Probes, it is also possible to set a
`failureThreshold` and a `successThreashold` to only flip between ready
and non-ready state if the probe succeeded or failed multiple times.

## Dual-stack considerations

Some context is needed to understand the limitations imposed by a dual-stack
network configuration on readiness - or liveness - probes. Users must be
fully aware that a dual-stack configuration is currently only available when
using a masquerade binding type. Furthermore, it must be recalled that
accessing a VM using masquerade binding type is performed via the pod IP
address; in dual-stack mode, both IPv4 and IPv6 addresses can be used to reach
the VM.

Dual-stack networking configurations have a limitation when using HTTP / TCP
probes - you **cannot probe the VMI by its IPv6 address**. The reason for this
is the `host` field for both the
[HTTP](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#httpgetaction-v1-core)
and
[TCP](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#tcpsocketaction-v1-core)
probe actions default to the pod's IP address, which is currently always the
IPv4 address.

Since the pod's IP address is not known before creating the VMI, it is not
possible to pre-provision the probe's host field.

## Defining a Watchdog

A watchdog is a more VM centric approach where the responsiveness of the
Operating System is focused on. One can configure the `i6300esb` watchdog
device:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-watchdog
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          watchdog:
            name: mywatchdog
            i6300esb:
              action: "poweroff"
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinit
          rng: {}
        resources:
          requests:
            memory: 1Gi
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/fedora:latest
      - name: cloudinit
        cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            user: fedora
            chpasswd: { expire: False }
            packages:
                busybox
```

The example above configures it with the `poweroff` action. It defines what will
happen if the OS can't respond anymore. Other possible actions are `reset`
and `shutdown`. The VM in this example will have the device exposed
as `/dev/watchdog`. This device can then be used by the `watchdog`
binary. For example, if root executes this command inside the VM:

```bash
sudo busybox watchdog -t 2000ms -T 4000ms /dev/watchdog
```

The watchdog will send a heartbeat every two seconds to `/dev/watchdog` and
after four seconds without a heartbeat the defined action will be executed. In
this case a hard `poweroff`.

## Defining Guest-Agent Ping Probes

Guest-Agent probes are based on qemu-guest-agent `guest-ping`.  This will ping
the guest and return an error if the guest is not up and running.  To easily
define this on VM spec, specify `guestAgentPing: {}` in VM's 
`spec.template.spec.readinessProbe`.  `virt-controller` will translate this 
into a corresponding command wrapped by `virt-probe`.

> Note: You can only define one of the type of probe, i.e. guest-agent exec 
> or ping probes.


**Important:** If the qemu-guest-agent is not installed **and** enabled inside
the VM, the probe will fail.  Many images don't enable the agent by default so
make sure you either run one that does or enable it. 

Make sure to provide enough delay and failureThreshold for the VM and the agent
to be online.

In the following example the Fedora image does have qemu-guest-agent available
by default. Nevertheless, in case qemu-guest-agent is not installed, it will be
installed and enabled via cloud-init as shown in the example below.  Also,
cloud-init assigns the proper SELinux context, i.e. virt_qemu_ga_exec_t, to the
`/tmp/healthy.txt` file.  Otherwise, SELinux will deny the attempts to open the
`/tmp/healthy.txt` file causing the probe to fail.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-agent-readiness-probe
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          rng: {}
        resources:
          requests:
            memory: 1Gi
      readinessProbe:
        exec:
          command: ["cat", "/tmp/healthy.txt"]
        failureThreshold: 10
        initialDelaySeconds: 120
        periodSeconds: 10
        timeoutSeconds: 5
      terminationGracePeriodSeconds: 180
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/fedora
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
              chpasswd:
                expire: false
              password: password
              user: fedora
              packages:
                qemu-guest-agent
              runcmd:
                - ["touch", "/tmp/healthy.txt"]
                - ["sudo", "chcon", "--type", "virt_qemu_ga_exec_t", "/tmp/healthy.txt"]
                - ["sudo", "systemctl", "enable", "--now", "qemu-guest-agent"]
```

Note that, in the above example if SELinux is not installed in your container
disk image, the command `chcon` should be removed from the VM manifest shown. 
Otherwise, the `chcon`  command will fail.

The `.status.ready` field will switch to `true` indicating that probes are
returning successfully:

```sh
kubectl wait vmis/vmi-guest-probe --for=condition=Ready --timeout=5m
```

Additionally, the following command can be used inside the VM to watch the
incoming qemu-ga commands:

```sh
journalctl _COMM=qemu-ga --follow
```
