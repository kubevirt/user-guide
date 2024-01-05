# VSOCK

VM Sockets (vsock) is a fast and efficient guest-host communication mechanism.

## Background

Right now KubeVirt uses virtio-serial for local guest-host communication. Currently it used in KubeVirt by libvirt and qemu to communicate with the qemu-guest-agent. Virtio-serial can also be used by other agents, but it is a little bit cumbersome due to:

- A small set of ports on the virtio-serial device
- Low bandwidth
- No socket based communication possible, which requires every agent to establish their own protocols, or work with translation layers like SLIP to be able to use protocols like gRPC for reliable communication.
- No easy and supportable way to get a virtio-serial socket assigned and being able to access it without entering the virt-launcher pod.
- Due to the point above, privileges are required for services.

With [virtio-vsock](https://man7.org/linux/man-pages/man7/vsock.7.html) we get support for easy guest-host communication which solves the above issues from a user/admin perspective.

## Usage

### Feature Gate

To enable VSOCK in KubeVirt cluster, the user may expand the `featureGates`
field in the KubeVirt CR by adding the `VSOCK` to it.

```yaml
apiVersion: kubevirt.io/v1
kind: Kubevirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  ...
  configuration:
    developerConfiguration:
      featureGates:
        - "VSOCK"
```

Alternatively, users can edit an existing kubevirt CR:

`kubectl edit kubevirt kubevirt -n kubevirt`

```yaml
...
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - "VSOCK"
```      

### Virtual Machine Instance

To attach VSOCK device to a Virtual Machine, the user has to add `autoattachVSOCK: true` in a `devices` section of Virtual Machine Instance specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  name: testvmi-vsock
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      autoattachVSOCK: true
```

This will expose VSOCK device to the VM. The `CID` will be assigned randomly by `virt-controller`, and exposed to the Virtual Machine Instance status:

```yaml
status:
  VSOCKCID: 123
```

## Security

> **_NOTE:_**  The `/dev/vhost-vsock` device is *NOT NEEDED* to connect or bind to a VSOCK socket.

To make VSOCK feature secure, following measures are put in place:

- The whole VSOCK features will live behind a feature gate.
- By default the first 1024 ports of a vsock device are privileged. Services trying to bind to those require `CAP_NET_BIND_SERVICE` capability.
-  `AF_VSOCK` socket syscall gets blocked in containerd 1.7+ (containerd/containerd#7442). It is right now the responsibility of the vendor to ensure that the used CRI selects a default seccomp policy which blocks VSOCK socket calls in a similar way like it was done for containerd.
- CIDs are assigned by `virt-controller` and are unique per Virtual Machine Instance to ensure that `virt-handler` has an easy way of tracking the identity without races. While this still allows `virt-launcher` to fake-use an assigned CID, it eliminates possible assignment races which attackers could make use-of to redirect VSOCK calls.
