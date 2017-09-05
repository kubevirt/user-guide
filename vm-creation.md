## Creation

With the installation of KubeVirt, new resource kinds are added to the Kubernetes API to managed Virtual Machines. These new kinds allow you to create new objects of that kind.

Virtual Machines are represented by objects of the `VM` kind. Because the kinds are added to the Kubernete API, the stock Kubernetes client tools \(`kubectl`\) can be used to create, modify, and delete VM objects.

### VM API

> Note: Currently there isno offline documentation of the VM API.

A VM object is also called the _VM API_, as the object is used to define a virtual machine.

Here is an example of a VM object:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VM
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



