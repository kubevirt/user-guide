# The OpenShift integration user guide

Since OpenShift extends Kubernetes functionality and it is often the preferred
container platform solution, KubeVirt provides decent level of integration with
OpenShift.  See [Installation Guide](installation.md) for more information on
how to deploy KubeVirt on OpenShift.


## OpenShift command line client

The OpenShift command line client provides secure interface to your Kubernetes
cluster.  Note that you have to be logged in.

```bash
$ oc login -u system:admin
$ oc get pods --all-namespaces
```

### Creating a VirtualMachine from OpenShift Template 

OpenShift templates provides toplevel automation of your container platform.
For example, to define an OfflineVirtualMachine from Fedora 27 image you can use
the following template
([cluster/vm-template-fedora.yaml](cluster/vm-template-fedora.yaml)):

```yaml
apiVersion: v1
kind: Template
metadata:
  name: fedora-vm-template
  annotations:
    description: "OpenShift KubeVirt Fedora VM template"
    tags: "kubevirt,openshift,template,linux"
  labels:
    kubevirt.io/os: fedora27
    miq.github.io/kubevirt-is-vm-template: "true"
objects:
- apiVersion: kubevirt.io/v1alpha1
  kind: OfflineVirtualMachine
  metadata:
    name: ${NAME}
    labels:
      kubevirt-ovm: ovm-${NAME}
  spec:
    template:
      metadata:
        labels:
          kubevirt-ovm: ovm-${NAME}
      spec:
        domain:
          cpu:
            cores: ${{CPU_CORES}}
          resources:
            requests:
              memory: ${{MEMORY}}
          devices:
            disks:
              - name: disk0
                volumeName: registryvolume
                disk:
                  bus: virtio
              - name: disk1
                volumeName: cloudinitvolume
                disk:
                  bus: virtio
        volumes:
          - name: registryvolume
            registryDisk:
              image: kubevirt/fedora-cloud-registry-disk-demo:devel
          - name: cloudinitvolume
            cloudInitNoCloud:
              userDataBase64: I2Nsb3VkLWNvbmZpZwpwYXNzd29yZDogYXRvbWljCnNzaF9wd2F1dGg6IFRydWUKY2hwYXNzd2Q6IHsgZXhwaXJlOiBGYWxzZSB9Cg==
parameters:
- name: NAME
  description: Name for the new VM
- name: MEMORY
  description: Amount of memory
  value: 4096Mi
- name: CPU_CORES
  description: Amount of cores
  value: "4"
```

You can then define template parameters using `oc process` command and pipe it
straight to `oc create` to create corresponding Kubernetes object.  Note that
the `NAME` parameter does not have defined default value, that makes it
mandatory.

```bash
$ oc process  -f cluster/vm-template-fedora.yaml -p NAME=testvm CPU_CORES=2 | oc create -f -
```

### Starting/stopping an OfflineVirtualMachine

The OfflineVirtualMachine objects are not started by default (see
[OfflineVirtualMachine user guide](offline-virtual-machine.md)).  To start or
stop your VM, you can use `oc patch` command.

```bash
$ oc patch offlinevirtualmachine testvm --type merge -p \
    '{"spec":{"running":true}}'` 

$ oc patch offlinevirtualmachine testvm --type merge -p \
   '{"spec":{"running":false}}'` 
```
