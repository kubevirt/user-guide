# Creation

## API Overview

With the installation of KubeVirt, new types are added to the Kubernetes API to manage Virtual Machines.

You can interact with the new resources \(via `kubectl`\) as you would with any other API resource.

## VirtualMachineInstance API

> Note: A full API reference is available at [https://kubevirt.io/api-reference/](https://kubevirt.io/api-reference/).

Here is an example of a VirtualMachineInstance object:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: testvmi-nocloud
spec:
  terminationGracePeriodSeconds: 30
  domain:
    resources:
      requests:
        memory: 1024M
    devices:
      disks:
      - name: containerdisk
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
    containerDisk:
      image: kubevirt/fedora-cloud-container-disk-demo:latest
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
 * How to access a VirtualMachineInstance via `console` or `vnc`: [Graphical and Serial Console Access](workloads/virtual-machines/graphical-and-console-access.md)
 * How to customize VirtualMachineInstances with `cloud-init`: [Startup Scripts](workloads/virtual-machines/startup-scripts.md)
