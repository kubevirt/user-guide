Virtual Machines
================

The `VirtualMachineInstance` type conceptionally has two parts:

-   Information for making scheduling decisions

-   Information about the virtual machine ABI

Every `VirtualMachineInstance` object represents a single running
virtual machine instance.

Creation
========

API Overview
------------

With the installation of KubeVirt, new types are added to the Kubernetes
API to manage Virtual Machines.

You can interact with the new resources (via `kubectl`) as you would
with any other API resource.

VirtualMachineInstance API
--------------------------

> Note: A full API reference is available at
> <https://kubevirt.io/api-reference/>.

Here is an example of a VirtualMachineInstance object:

    apiVersion: kubevirt.io/v1alpha3
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
            disk:
              bus: virtio
          - name: emptydisk
            disk:
              bus: virtio
          - disk:
              bus: virtio
            name: cloudinitdisk
      volumes:
      - name: containerdisk
        containerDisk:
          image: kubevirt/fedora-cloud-container-disk-demo:latest
      - name: emptydisk
        emptyDisk:
          capacity: "2Gi"
      - name: cloudinitdisk
        cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }

This example uses a fedora cloud image in combination with cloud-init
and an ephemeral empty disk with a capacity of `2Gi`. For the sake of
simplicity, the volume sources in this example are ephemeral and don’t
require a provisioner in your cluster.

What’s next
===========

-   More information about persistent and ephemeral volumes:
    [Disks and Volumes](creation/disks-and-volumes.md)

-   How to access a VirtualMachineInstance via `console` or `vnc`:
    [Console Access](usage/graphical-and-console-access.md)

-   How to customize VirtualMachineInstances with `cloud-init`:
    [Cloud Init] (creation/cloud-init.md)
