# Slirp

## Overview

[SLIRP](https://en.wikipedia.org/wiki/Slirp) provides user-space
network connectivity.

> **Note:** in `slirp` mode, the only supported protocols are TCP and
> UDP. ICMP is *not* supported.

## Slirp network binding plugin
[v1.1.0]

The binding plugin replaces the [core `slirp` binding](../../network/interfaces_and_networks.md#slirp)
API.

> **Note**: The network binding plugin infrastructure is in Alpha stage.
> Please use them with care.

The slirp binding plugin consists of the following components:

- Sidecar image.

As described in the [definition & flow](../../network/network_binding_plugins.md#definition--flow) section,
the slirp plugin needs to:

- Assure access to the sidecar image.
- Register the binding plugin on the Kubevirt CR.
- Reference the network binding by name from the VM spec interface.

> **Note**: In order for the core slirp binding to use the network binding plugin
> the registered name for this binding should be `slirp`.


### Slirp Registration
As described in the [registration section](../../network/network_binding_plugins.md#register), slirp binding plugin
configuration needs to be added to the kubevirt CR.

To register the slirp binding, patch the kubevirt CR as follows:
```yaml
kubectl patch kubevirts -n kubevirt kubevirt --type=json -p='[{"op": "add", "path": "/spec/configuration/network",   "value": {
            "binding": {
                "slirp": {
                    "sidecarImage": "quay.io/kubevirt/network-slirp-binding:v1.1.0"
                }
            }
        }}]'
```

### VM Slirp Network Interface
Set the VM network interface binding name to reference the one defined in the
kubevirt CR.

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-net-binding-slirp
  name: vm-net-binding-passt
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-net-binding-slirp
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
          - name: slirpnet
            binding:
              name: slirp
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: slirpnet
        pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:v1.1.0
        name: containerdisk
      - cloudInitNoCloud:
          networkData: |
            version: 2
            ethernets:
              eth0:
                dhcp4: true
        name: cloudinitdisk
```
