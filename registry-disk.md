## Registry Disk

The Registry Disk feature provides the ability to store and distribute Virtual
Machine disks in the container image registry. Registry Disks can be assigned
to Virtual Machines in the disks section of the Virtual Machine spec.

No network shared storage devices are utilized by Registry Disks. The disks are
pulled from the container registry and reside on the local node hosting the
Virtual Machines that consume the disks.

## When to use a Registry Disk

Registry Disks are ephemeral storage devices that can be assigned to any number
of active Virtual Machines. This makes them an ideal tool for users who want
to replicate a large number of Virtual Machine workloads that do not require
persistent data. Registry Disks are commonly used in conjunction with Virtual
Machine Replica Sets.

## When Not to use a Registry Disk

Registry Disks are not a good solution for any workload that requires persistent
disks across Virtual Machine restarts, or workloads that require Virtual
Machine live migration support. It is possible Registry Disks may gain live
migration support in the future, but at the moment live migrations are
incompatible with Registry Disks.

## Registry Disk Workflow Example

Users push Virtual Machine disks into the container registry using a KubeVirt
base designed to work with the Registry Disk feature. The latest base container
image is **kubevirt.io/registry-disk-v1alpha**.

Using this base image, users can inject a Virtual Machine disk into a container
image in a way that is consumable by the KubeVirt runtime. Disks placed into
the base container must be placed into the /disk directory. Raw and qcow2
formats are supported. Qcow2 is recommended in order to reduce the container
image's size.

Example: Inject a Virtual Machine disk into a container image.
```
cat << END > Dockerfile
FROM kubevirt.io/registry-disk-v1alpha
ADD fedora25.qcow2 /disk
END

docker build -t vmdisks/fedora25:latest .
```

Example: Upload the RegistryDisk container image to a registry.
```
docker push vmdisks/fedora25:latest
```

Example: Attach the RegistryDisk as an ephemeral disk to a virtual machine.
```
metadata:
  name: testvm-ephemeral
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
spec:
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          dev: vda
  volumes:
    - name: registryvolume
      registryDisk:
        image: vmdisks/fedora25:latest
```
