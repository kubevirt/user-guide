# Passt binding

## Overview

[Plug A Simple Socket Transport](https://passt.top/passt/about/) is an enhanced
alternative to [SLIRP](https://en.wikipedia.org/wiki/Slirp), providing user-space
network connectivity.

`passt` is a universal tool which implements a translation layer between
a Layer-2 network interface and native Layer -4 sockets (TCP, UDP, ICMP/ICMPv6 echo)
on a host.

Its main benefits are:

- Doesn't require extra network capabilities as CAP_NET_RAW and CAP_NET_ADMIN.
- Allows integration with service meshes (which expect applications to run locally) out of the box.
- Supports IPv6 out of the box (in contrast to the existing bindings which require configuring IPv6
  manually).

### Functionality support
| Functionality                                  | Support |
|------------------------------------------------|---------|
| Migration support                              | Yes     |
| Service Mesh support                           | Yes     |
| Pod IP in guest                                | Yes     |
| Custom CIDR in guest                           | No      |
| Require extra capabilities (on pod) to operate | No      |
| Primary network (pod network)                  | Yes     |
| Secondary network                              | No      |


> **NOTE**: To achieve optimal memory consumption with Passt binding,
> specify ports required for your workload.
> When no ports are explicitly specified, all ports are forwarded,
> leading to memory overhead of up to 250 Mi.

## Passt network binding plugin
[v1.1.0]

The binding plugin replaces the experimental core passt binding implementation
(including its API).

> **Note**: The network binding plugin infrastructure and the passt plugin
> specifically are in Alpha stage. Please use them with care, preferably
> on a non-production deployment.

The passt binding plugin consists of the following components:

- Passt CNI plugin.
- Sidecar image.

As described in the [definition & flow](../../network/network_binding_plugins.md#definition--flow) section,
the passt plugin needs to:

- Deploy the CNI plugin binary on the nodes.
- Define a NetworkAttachmentDefinition that points to the CNI plugin.
- Assure access to the sidecar image.
- Register the binding plugin on the Kubevirt CR.
- Reference the network binding by name from the VM spec interface.

And in detail:

### Passt CNI deployment on nodes

#### v1.6.0 and above
Kubevirt releases a container image `quay.io/kubevirt/network-passt-binding-cni:v1.6.0`,
which can be used via daemonSet to copy the CNI binary to the nodes.

Create the following DaemonSet:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: passt-binding-cni
  namespace: kubevirt
  labels:
    tier: node
    app: passt-binding-cni
spec:
  selector:
    matchLabels:
      name: passt-binding-cni
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 10%
  template:
    metadata:
      labels:
        name: passt-binding-cni
        tier: node
        app: passt-binding-cni
      annotations:
        description: passt-binding-cni installs 'passt binding' CNI on cluster nodes
    spec:
      priorityClassName: system-cluster-critical
      containers:
      - name: installer
        image: quay.io/kubevirt/network-passt-binding-cni:v1.6.0
        command: [ "/bin/sh", "-ce" ]
        args:
        - |
          ls -la "/cni/kubevirt-passt-binding"
          cp -f "/cni/kubevirt-passt-binding" "/opt/cni/bin"
          echo "passt binding CNI plugin installation complete..sleep infinity"
          sleep 2147483647
        resources:
          requests:
            cpu: "10m"
            memory: "15Mi"
        securityContext:
          privileged: true
        volumeMounts:
        - name: cnibin
          mountPath: /opt/cni/bin
      volumes:
      - name: cnibin
        hostPath:
          path: /opt/cni/bin
```

#### prior to v1.6.0
The CNI binary can be retrieved directly from the kubevirt release assets (on GitHub) or to be built from its
[sources](https://github.com/kubevirt/kubevirt/tree/release-1.1/cmd/cniplugins/passt-binding).

> **Note**: The kubevirt project uses Bazel to build the binaries and container images.
> For more information in how to build the whole project, visit the developer
> [getting started guide](https://github.com/kubevirt/kubevirt/blob/release-1.1/docs/getting-started.md).

Once the binary is ready, you may rename it to a meaningful name (e.g. `kubevirt-passt-binding`).
This name is used in the NetworkAttachmentDefinition configuration.

Copy the binary to each node in your cluster.
The location of the CNI plugins may vary between platforms and versions.
One common path is `/opt/cni/bin/`.

### Passt NetworkAttachmentDefinition
The configuration needed for passt is minimalistic:

```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: netbindingpasst
spec:
  config: '{
            "cniVersion": "1.0.0",
            "name": "netbindingpasst",
            "plugins": [
              {
                "type": "kubevirt-passt-binding"
              }
            ]
  }'
```

The object should be created in a "default" namespace where all other namespaces
can access, or, in the same namespace the VMs reside in.

### Passt sidecar image
Passt sidecar image is built and pushed to
[kubevirt quay repository](https://quay.io/repository/kubevirt/network-passt-binding).

The sidecar sources can be found
[here](https://github.com/kubevirt/kubevirt/tree/release-1.1/cmd/sidecars/network-passt-binding).

The relevant sidecar image needs to be accessible by the cluster and
specified in the Kubevirt CR when registering the network binding plugin.


### Passt Registration
As described in the [registration section](../../network/network_binding_plugins.md#register), passt binding plugin
configuration needs to be added to the kubevirt CR.

To register the passt binding, patch the kubevirt CR as follows:
```yaml
kubectl patch kubevirts -n kubevirt kubevirt --type=json -p='[{"op": "add", "path": "/spec/configuration/network",   "value": {
            "binding": {
                "passt": {
                    "networkAttachmentDefinition": "default/netbindingpasst",
                    "sidecarImage": "quay.io/kubevirt/network-passt-binding:v1.6.0",
                    "migration": {},
                    "computeResourceOverhead": {
                      "requests": {
                        "memory": "250Mi",
                      }
                    }
                }
            }
        }}]'
```

The NetworkAttachmentDefinition and sidecarImage values should correspond with the
names used in the previous sections, [here](#passt-networkattachmentdefinition)
and [here](#passt-sidecar-image).

When using the plugin, additional memory overhead of `250Mi` will be requested for the compute container in the virt-launcher pod.

When the VM boots for the first time, Passt's internal DHCP server assigns an IP address to the guest with an "infinite" lease duration.

**Note**:
> During a live migration:
> - The target pod is assigned a new IP address from the pod network, which is reflected in the VMI interfaces status.
> - The guest OS retains the original IP address until it explicitly requests an address from Passt's internal DHCP server.
> 
> Connectivity Considerations
> Passt automatically applies Network Address Translation (NAT) when passing traffic to/from the guest.
> This enables the following behavior:
> - The pod's new IP address is used for connectivity
> - Despite the discrepancy between the pod IP and the guest IP, connectivity to/from the guest remains unaffected. 
> 
> It is possible to synchronize the guest and pod's IP addresses by initiating a DHCP request from the guest OS.

### VM Passt Network Interface
Set the VM network interface binding name to reference the one defined in the
kubevirt CR.

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-net-binding-passt
  name: vm-net-binding-passt
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-net-binding-passt
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
          interfaces:
          - name: passtnet
            binding:
              name: passt
            ports:
            - name: http
              port: 80
              protocol: TCP
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: passtnet
        pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.6.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            version: 2
            ethernets:
              eth0:
                dhcp4: true
        name: cloudinitdisk
```
