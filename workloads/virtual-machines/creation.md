# Creation

## API Overview

With the installation of KubeVirt, new types are added to the Kubernetes API to managed Virtual Machines.

You can interact with the new resources \(via `kubectl`\) as you would with any other API resource.

## VirtualMachine API

> Note: Currently there is no offline documentation of the VirtualMachine API.

A VirtualMachine API is also called a VirtualMachine object, because the object is used to define a virtual machine.

Here is an example of a VirtualMachine object:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  terminationGracePeriodSeconds: 0
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: mydisk
        volumeName: myvolume
        disk:
          dev: vda
  volumes:
    - name: myvolume
      iscsi:
        iqn: iqn.2017-01.io.kubevirt:sn.42
        lun: 2
        targetPortal: iscsi-demo-target.kube-system.svc.cluster.local
```

