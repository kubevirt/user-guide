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

## Define a HTTP Liveness Probe

The following VirtualMachineInstance configures a HTTP Liveness Probe
via `spec.livenessProbe.httpGet`, which will query port 1500 of the
VirtualMachineInstance, after an initial delay of 120 seconds. The
VirtualMachineInstance itself installs and runs a minimal HTTP server on
port 1500 via cloud-init.

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      labels:
        special: vmi-fedora
      name: vmi-fedora
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
        resources:
          requests:
            memory: 1024M
      livenessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        httpGet:
          port: 1500
        timeoutSeconds: 10
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        registryDisk:
          image: registry:5000/kubevirt/fedora-cloud-registry-disk-demo:devel
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
            bootcmd:
              - setenforce 0
              - dnf install -y nmap-ncat
              - systemd-run --unit=httpserver nc -klp 1500 -e '/usr/bin/echo -e HTTP/1.1 200 OK\\nContent-Length: 12\\n\\nHello World!'
        name: cloudinitdisk

## Define a TCP Liveness Probe

The following VirtualMachineInstance configures a TCP Liveness Probe via
`spec.livenessProbe.tcpSocket`, which will query port 1500 of the
VirtualMachineInstance, after an initial delay of 120 seconds. The
VirtualMachineInstance itself installs and runs a minimal HTTP server on
port 1500 via cloud-init.

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      labels:
        special: vmi-fedora
      name: vmi-fedora
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
        resources:
          requests:
            memory: 1024M
      livenessProbe:
        initialDelaySeconds: 120
        periodSeconds: 20
        tcpSocket:
          port: 1500
        timeoutSeconds: 10
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        registryDisk:
          image: registry:5000/kubevirt/fedora-cloud-registry-disk-demo:devel
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
            bootcmd:
              - setenforce 0
              - dnf install -y nmap-ncat
              - systemd-run --unit=httpserver nc -klp 1500 -e '/usr/bin/echo -e HTTP/1.1 200 OK\\nContent-Length: 12\\n\\nHello World!'
        name: cloudinitdisk

## Define Readiness Probes

Readiness Probes are configured in a similar way like liveness probes.
Instead of `spec.livenessProbe`, `spec.readinessProbe` needs to be
filled:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      labels:
        special: vmi-fedora
      name: vmi-fedora
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
        resources:
          requests:
            memory: 1024M
      readinessProbe:
        httpGet:
          port: 1500
        initialDelaySeconds: 120
        periodSeconds: 20
        timeoutSeconds: 10
        failureThreshold: 3
        successThreshold: 3
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        registryDisk:
          image: registry:5000/kubevirt/fedora-cloud-registry-disk-demo:devel
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
            bootcmd:
              - setenforce 0
              - dnf install -y nmap-ncat
              - systemd-run --unit=httpserver nc -klp 1500 -e '/usr/bin/echo -e HTTP/1.1 200 OK\\n\\nHello World!'
        name: cloudinitdisk

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
---
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-with-watchdog
  name: vmi-with-watchdog
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
    machine:
      type: ""
    resources:
      requests:
        memory: 512M
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: quay.io/kubevirt/alpine-container-disk-demo
    name: containerdisk
```

The example above configures it with the `poweroff` action. It defines what will
happen if the OS can't respond anymore. Other possible actions are `reset`
and `shutdown`. The Alpine VM in this example will have the device exposed
as `/dev/watchdog`. This device can then be used by the `watchdog`
binary. For example, if root executes this command inside the VM:

```bash
watchdog -t 2000ms -T 4000ms /dev/watchdog
```

the watchdog will send a heartbeat every two seconds to `/dev/watchdog` and
after four seconds without a heartbeat the defined action will be executed. In
this case a hard `poweroff`.
