## Creation

### API Overview

With the installation of KubeVirt, new types are added to the Kubernetes API to managed Virtual Machines.

You can interact with the new resources \(via `kubectl`\) as you would with any other API resource.

### VirtualMachine API

> Note: Currently there is no offline documentation of the VirtualMachine API.

A VirtualMachine API is also called a VirtualMachine object, because the object is used to define a virtual machine.

Here is an example of a VirtualMachine object:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  domain:
    devices:
      graphics:
      - type: spice
      video:
      - type: qxl
      disks:
      - type: network
        device: disk
        driver:
          name: qemu
          type: raw
          cache: none
        source:
          host:
            name: iscsi-demo-target.default
          protocol: iscsi
          name: iqn.2017-01.io.kubevirt:sn.42/2
      consoles:
      - type: pty
    memory:
      unit: MB
      value: 64
    os:
      type:
        os: hvm
    type: qemu
```



