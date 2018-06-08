# Creation

## API Overview

With the installation of KubeVirt, new types are added to the Kubernetes API to manage Virtual Machines.

You can interact with the new resources \(via `kubectl`\) as you would with any other API resource.

## VirtualMachine API

> Note: A full API reference is available at (https://kubevirt.io/api-reference/)[https://kubevirt.io/api-reference/].

A VirtualMachine API is also called a VirtualMachine object, because the object is used to define a virtual machine.

Here is an example of a VirtualMachine object:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: testvm-nocloud
spec:
  terminationGracePeriodSeconds: 30
  domain:
    resources:
      requests:
        memory: 1024M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          bus: virtio
      - name: emptydisk
        volumeName: emptydiskvolume
        disk:
          bus: virtio
      - disk:
          bus: virtio
        name: cloudinitdisk
        volumeName: cloudinitvolume
  volumes:
  - name: registryvolume
    registryDisk:
      image: kubevirt/fedora-cloud-registry-disk-demo:latest
  - name: emptydiskvolume
    emptyDisk:
      capacity: "2Gi"
  - name: cloudinitvolume
    cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
```

This example uses a fedora cloud image in combination with cloud-init and an
ephemeral empty disk with a capacity of `2Gi`. For the sake of simplicity, the
volume sources in this example are ephemeral and don't require a provisioner in
your cluster.

# What's next

 * More information about persistent and ephemeral volumes: [Disks and Volumes](workloads/virtual-machines/disks-and-volumes.md)
 * How to access a VirtualMachine via `console` or `vnc`: [Graphical and Serial Console Access](workloads/virtual-machines/graphical-and-console-access.md)
 * How to customize VirtualMachines with `cloud-init`: [Startup Scripts](workloads/virtual-machines/startup-scripts.md)
