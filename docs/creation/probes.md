Configure Liveness and Readiness Probes
=======================================

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

Define a HTTP Liveness Probe
----------------------------

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
              - systemd-run --unit=httpserver nc -klp 1500 -e '/usr/bin/echo -e HTTP/1.1 200 OK\\n\\nHello World!'
        name: cloudinitdisk

Define a TCP Liveness Probe
---------------------------

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
              - systemd-run --unit=httpserver nc -klp 1500 -e '/usr/bin/echo -e HTTP/1.1 200 OK\\n\\nHello World!'
        name: cloudinitdisk

Define Readiness Probes
-----------------------

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
