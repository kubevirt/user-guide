# Instancetypes and preferences

**FEATURE STATE:** 

* `v1alpha1` (Experimental) as of the [`v0.56.0`](https://github.com/kubevirt/kubevirt/releases/tag/v0.56.0) release

## Introduction

KubeVirt's [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) API contains many advanced options for tuning the performance of a VM that goes beyond what typical users need to be aware of. Users have previously been unable to simply define the storage/network they want assigned to their VM and then declare in broad terms what quality of resources and kind of performance characteristics they need for their VM.

Instancetypes and preferences provide a way to define a set of resource, performance and other runtime characteristics, allowing users to reuse these definitions across multiple [`VirtualMachines`](https://kubevirt.io/api-reference/master/definitions.html#_v1_virtualmachine).

## VirtualMachineInstancetype

```yaml
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachineInstancetype
metadata:
  name: example-instancetype
spec:
  cpu:
    guest: 1
  memory:
    guest: 128Mi
```

KubeVirt provides two Instancetype based [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), a cluster wide [`VirtualMachineClusterInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineclusterinstancetype) and a namespaced [`VirtualMachineInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineinstancetype). These [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) encapsulate the following resource related characteristics of a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) through a shared [`VirtualMachineInstancetypeSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineinstancetypespec):

* [CPU](https://kubevirt.io/api-reference/main/definitions.html#_v1_cpuinstancetype) : Required number of vCPUs presented to the guest
* [Memory](https://kubevirt.io/api-reference/main/definitions.html#_v1_memoryinstancetype) : Required amount of memory presented to the guest
* [GPUs](https://kubevirt.io/api-reference/main/definitions.html#_v1_gpu) : Optional list of vGPUs to passthrough
* [HostDevices](https://kubevirt.io/api-reference/main/definitions.html#_v1_hostdevice) : Optional list of HostDevices to passthrough
* IOThreadsPolicy : Optional IOThreadsPolicy to be used
* [LaunchSecurity](https://kubevirt.io/api-reference/main/definitions.html#_v1_launchsecurity): Optional LaunchSecurity to be used

Anything provided within an instancetype cannot be overridden within the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine). For example as `CPU` and `Memory` are both required attributes of an instancetype if a user makes any requests for `CPU` or `Memory` resources within the underlying [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) the instancetype will conflict and the request will be rejected during creation.

## VirtualMachinePreference

```yaml
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachinePreference
metadata:
  name: example-preference
spec:
  devices:
    preferredDiskBus: virtio
    preferredInterfaceModel: virtio
```

KubeVirt also provides two further preference based [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), again a cluster wide [`VirtualMachineClusterPreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineclusterpreference) and namespaced [`VirtualMachinePreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachinepreference). These [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) encapsulate the preferred value of any remaining attributes of a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) required to run a given workload, again this is through a shared [`VirtualMachinePreferenceSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachinepreferencespec).

Unlike instancetypes preferences only represent the preferred values and as such can be overridden by values in the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) provided by the user.

For example as shown below, if a user has provided a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) with a disk bus already defined within a [DiskTarget](https://kubevirt.io/api-reference/main/definitions.html#_v1_disktarget) *and* has also selected a set of preferences with [DevicePreference](https://kubevirt.io/api-reference/main/definitions.html#_v1_devicepreferences) and `preferredDiskBus` defined the users original choice within the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) and [DiskTarget](https://kubevirt.io/api-reference/main/definitions.html#_v1_disktarget) are used:

```yaml
$ cat << EOF | kubectl apply -f - 
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachinePreference
metadata:
  name: example-preference-disk-virtio
spec:
  devices:
    preferredDiskBus: virtio
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-preference-user-override
spec:
  preference:
    kind: VirtualMachinePreference
    name: example-preference-disk-virtio
  running: false
  template:
    spec:
      domain:
        memory:
          guest: 128Mi
        devices:
          disks:
          - disk:
              bus: sata
            name: containerdisk
          - disk: {}
            name: cloudinitdisk
        resources: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: registry:5000/kubevirt/cirros-container-disk-demo:devel
        name: containerdisk
      - cloudInitNoCloud:
          userData: |
            #!/bin/sh

            echo 'printed from cloud-init userdata'
        name: cloudinitdisk
EOF
virtualmachinepreference.instancetype.kubevirt.io/example-preference-disk-virtio created
virtualmachine.kubevirt.io/example-preference-user-override configured


$ virtctl start example-preference-user-override
VM example-preference-user-override was scheduled to start

# We can see the original request from the user within the VirtualMachine lists `containerdisk` with a `SATA` bus
$ kubectl get vms/example-preference-user-override -o json | jq .spec.template.spec.domain.devices.disks
[
  {
    "disk": {
      "bus": "sata"
    },
    "name": "containerdisk"
  },
  {
    "disk": {},
    "name": "cloudinitdisk"
  }
]

# This is still the case in the VirtualMachineInstance with the remaining disk using the `preferredDiskBus` from the preference of `virtio`
$ kubectl get vmis/example-preference-user-override -o json | jq .spec.domain.devices.disks
[
  {
    "disk": {
      "bus": "sata"
    },
    "name": "containerdisk"
  },
  {
    "disk": {
      "bus": "virtio"
    },
    "name": "cloudinitdisk"
  }
]


```

## VirtualMachine

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-vm
spec:
  instancetype:
    kind: VirtualMachineInstancetype
    name: example-instancetype
  preference:
    kind: VirtualMachinePreference
    name: example-preference
```

The previous instancetype and preference CRDs are matched to a given [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) through the use of a matcher. Each matcher consists of the following:

* Name (string): Name of the resource being referenced
* Kind (string):  Optional, defaults to the cluster wide CRD kinds of `VirtualMachineClusterInstancetype` or `VirtualMachineClusterPreference` if not provided
* RevisionName (string) : Optional, name of a [ControllerRevision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) containing a copy of the [`VirtualMachineInstancetypeSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineinstancetypespec) or [`VirtualMachinePreferenceSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachinepreferencespec) taken when the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) is first started. See the [Versioning](#versioning) section below for more details on how and why this is captured.

## Versioning

Versioning of these resources is required to ensure the eventual `VirtualMachineInstance` created when starting a `VirtualMachine` does not change between restarts if any referenced instancetype or set of preferences are updated during the lifetime of the `VirtualMachine`.

This is currently achieved by using [ControllerRevision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) to retain a copy of the [`VirtualMachineInstancetypeSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachineinstancetypespec) or [`VirtualMachinePreferenceSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachinepreferencespec) at the time the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) is first started. A reference to these [ControllerRevisions](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) are then retained in the VirtualMachineInstancetypeMatcher and VirtualMachinePreferenceMatcher within the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) for future use.


```yaml
$ kubectl.sh apply -f examples/csmall.yaml -f examples/vm-cirros-csmall.yaml
virtualmachineinstancetype.instancetype.kubevirt.io/csmall created
virtualmachine.kubevirt.io/vm-cirros-csmall created

$ kubectl get vm/vm-cirros-csmall -o json | jq .spec.instancetype
{
  "kind": "VirtualMachineInstancetype",
  "name": "csmall",
}

$ virtctl start vm-cirros-csmall
VM vm-cirros-csmall was scheduled to start

$ kubectl get vm/vm-cirros-csmall -o json | jq .spec.instancetype
{
  "kind": "VirtualMachineInstancetype",
  "name": "csmall",
  "revisionName": "vm-cirros-csmall-csmall-6709b990-f717-44fe-a8ff-cb441d20b904-1"
}

$ kubectl get controllerrevision/vm-cirros-csmall-csmall-6709b990-f717-44fe-a8ff-cb441d20b904-1 -o json | jq .
{
  "apiVersion": "apps/v1",
  "data": {
    "apiVersion": "",
    "spec": "eyJjcHUiOnsiZ3Vlc3QiOjF9LCJtZW1vcnkiOnsiZ3Vlc3QiOiIxMjhNaSJ9fQ=="
  },
  "kind": "ControllerRevision",
  "metadata": {
    "creationTimestamp": "2022-08-02T11:56:29Z",
    "name": "vm-cirros-csmall-csmall-6709b990-f717-44fe-a8ff-cb441d20b904-1",
    "namespace": "default",
    "ownerReferences": [
      {
        "apiVersion": "kubevirt.io/v1",
        "blockOwnerDeletion": true,
        "controller": true,
        "kind": "VirtualMachine",
        "name": "vm-cirros-csmall",
        "uid": "7ad77f47-ee51-4024-8d5b-4141aec7b04c"
      }
    ],
    "resourceVersion": "7819",
    "uid": "df3767bc-9413-4881-a961-2254f985dfd2"
  },
  "revision": 0
}

$ kubectl delete vm/vm-cirros-csmall
virtualmachine.kubevirt.io "vm-cirros-csmall" deleted

$ kubectl get controllerrevision/vm-cirros-csmall-csmall-6709b990-f717-44fe-a8ff-cb441d20b904-1 
Error from server (NotFound): controllerrevisions.apps "vm-cirros-csmall-csmall-6709b990-f717-44fe-a8ff-cb441d20b904-1" not found


```

## Examples

Various examples are available within the [`kubevirt`](https://github.com/kubevirt/kubevirt) repo under [`/examples`](https://github.com/kubevirt/kubevirt/tree/main/examples). The following uses an example `VirtualMachine` provided by the [`containerdisk/fedora` repo](https://quay.io/repository/containerdisks/fedora) and replaces much of the `DomainSpec` with the equivalent instancetype and preferences:

```yaml
cat << EOF | kubectl apply -f - 
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachineInstancetype
metadata:
  name: cmedium
spec:
  cpu:
    guest: 1
  memory:
    guest: 1Gi
---
apiVersion: instancetype.kubevirt.io/v1alpha1
kind: VirtualMachinePreference
metadata:
  name: fedora
spec:
  devices:
    preferredDiskBus: virtio
    preferredInterfaceModel: virtio
    preferredRng: {}
  features:
    preferredAcpi: {}
    preferredSmm: {}
  firmware:
    preferredUseEfi: true
    preferredUseSecureBoot: true    
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  creationTimestamp: null
  name: fedora
spec:
  instancetype:
    name: cmedium
    kind: virtualMachineInstancetype
  preference:
    name: fedora
    kind: virtualMachinePreference
  runStrategy: Always
  template:
    metadata:
      creationTimestamp: null
    spec:
      domain:
        devices: {}
      volumes:
      - containerDisk:
          image: quay.io/containerdisks/fedora:latest
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            users:
              - name: admin
                sudo: ALL=(ALL) NOPASSWD:ALL
                ssh_authorized_keys:
                  - ssh-rsa AAAA...
        name: cloudinit
EOF
```