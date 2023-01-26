# Instance types and preferences

**FEATURE STATE:** 

* `v1alpha1` (Experimental) as of the [`v0.56.0`](https://github.com/kubevirt/kubevirt/releases/tag/v0.56.0) release
* `v1alpha2` (Experimental) as of the [`v0.58.0`](https://github.com/kubevirt/kubevirt/releases/tag/v0.58.0) release
  * This version now captures complete `VirtualMachine{Instancetype,ClusterInstancetype,Preference,ClusterPreference}` objects within the created `ControllerRevisions`
  * This version is backwardly compatible with `v1alpha1`, no modifications are required to existing instancetypes, preferences or controllerrevisions.

## Introduction

KubeVirt's [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) API contains many advanced options for tuning the performance of a VM that goes beyond what typical users need to be aware of. Users have previously been unable to simply define the storage/network they want assigned to their VM and then declare in broad terms what quality of resources and kind of performance characteristics they need for their VM.

Instance types and preferences provide a way to define a set of resource, performance and other runtime characteristics, allowing users to reuse these definitions across multiple [`VirtualMachines`](https://kubevirt.io/api-reference/master/definitions.html#_v1_virtualmachine).

## VirtualMachineInstancetype

```yaml
---
apiVersion: instancetype.kubevirt.io/v1alpha2
kind: VirtualMachineInstancetype
metadata:
  name: example-instancetype
spec:
  cpu:
    guest: 1
  memory:
    guest: 128Mi
```

KubeVirt provides two Instancetype based [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), a cluster wide [`VirtualMachineClusterInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachineclusterinstancetype) and a namespaced [`VirtualMachineInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachineinstancetype). These [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) encapsulate the following resource related characteristics of a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) through a shared [`VirtualMachineInstancetypeSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachineinstancetypespec):

* [CPU](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_cpuinstancetype) : Required number of vCPUs presented to the guest
* [Memory](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_memoryinstancetype) : Required amount of memory presented to the guest
* [GPUs](https://kubevirt.io/api-reference/main/definitions.html#_v1_gpu) : Optional list of vGPUs to passthrough
* [HostDevices](https://kubevirt.io/api-reference/main/definitions.html#_v1_hostdevice) : Optional list of HostDevices to passthrough
* IOThreadsPolicy : Optional IOThreadsPolicy to be used
* [LaunchSecurity](https://kubevirt.io/api-reference/main/definitions.html#_v1_launchsecurity): Optional LaunchSecurity to be used

Anything provided within an instance type cannot be overridden within the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine). For example as `CPU` and `Memory` are both required attributes of an instance type if a user makes any requests for `CPU` or `Memory` resources within the underlying [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) the instance type will conflict and the request will be rejected during creation.

## VirtualMachinePreference

```yaml
---
apiVersion: instancetype.kubevirt.io/v1alpha2
kind: VirtualMachinePreference
metadata:
  name: example-preference
spec:
  devices:
    preferredDiskBus: virtio
    preferredInterfaceModel: virtio
```

KubeVirt also provides two further preference based [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/), again a cluster wide [`VirtualMachineClusterPreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachineclusterpreference) and namespaced [`VirtualMachinePreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachinepreference). These [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) encapsulate the preferred value of any remaining attributes of a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) required to run a given workload, again this is through a shared [`VirtualMachinePreferenceSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachinepreferencespec).

Unlike instance types preferences only represent the preferred values and as such can be overridden by values in the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) provided by the user.

For example as shown below, if a user has provided a [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) with a disk bus already defined within a [DiskTarget](https://kubevirt.io/api-reference/main/definitions.html#_v1_disktarget) *and* has also selected a set of preferences with [DevicePreference](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_devicepreferences) and `preferredDiskBus` defined the users original choice within the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) and [DiskTarget](https://kubevirt.io/api-reference/main/definitions.html#_v1_disktarget) are used:

```yaml
$ kubectl apply -f - << EOF
---
apiVersion: instancetype.kubevirt.io/v1alpha2
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

The previous instance type and preference CRDs are matched to a given [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) through the use of a matcher. Each matcher consists of the following:

* Name (string): Name of the resource being referenced
* Kind (string):  Optional, defaults to the cluster wide CRD kinds of `VirtualMachineClusterInstancetype` or `VirtualMachineClusterPreference` if not provided
* RevisionName (string) : Optional, name of a [ControllerRevision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) containing a copy of the [`VirtualMachineInstancetypeSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachineinstancetypespec) or [`VirtualMachinePreferenceSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachinepreferencespec) taken when the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#__virtualmachine) is first started. See the [Versioning](#versioning) section below for more details on how and why this is captured.
* InferFromVolume (string): Optional, see the `Inferring defaults from Volumes` section below for more details.

## Versioning

Versioning of these resources is required to ensure the eventual `VirtualMachineInstance` created when starting a `VirtualMachine` does not change between restarts if any referenced instance type or set of preferences are updated during the lifetime of the `VirtualMachine`.

This is currently achieved by using [ControllerRevision](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) to retain a copy of the [`VirtualMachineInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachineinstancetype) or [`VirtualMachinePreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1alpha2_virtualmachinepreference) at the time the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) is created. A reference to these [ControllerRevisions](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) are then retained in the VirtualMachineInstancetypeMatcher and VirtualMachinePreferenceMatcher within the [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) for future use.


```yaml
$ kubectl apply -f examples/csmall.yaml -f examples/vm-cirros-csmall.yaml
virtualmachineinstancetype.instancetype.kubevirt.io/csmall created
virtualmachine.kubevirt.io/vm-cirros-csmall created

$ kubectl get vm/vm-cirros-csmall -o json | jq .spec.instancetype
{
  "kind": "VirtualMachineInstancetype",
  "name": "csmall",
  "revisionName": "vm-cirros-csmall-csmall-72c3a35b-6e18-487d-bebf-f73c7d4f4a40-1"
}

$ kubectl get controllerrevision/vm-cirros-csmall-csmall-72c3a35b-6e18-487d-bebf-f73c7d4f4a40-1 -o json | jq .
{
  "apiVersion": "apps/v1",
  "data": {
    "apiVersion": "instancetype.kubevirt.io/v1alpha2",
    "kind": "VirtualMachineInstancetype",
    "metadata": {
      "creationTimestamp": "2022-09-30T12:20:19Z",
      "generation": 1,
      "name": "csmall",
      "namespace": "default",
      "resourceVersion": "10303",
      "uid": "72c3a35b-6e18-487d-bebf-f73c7d4f4a40"
    },
    "spec": {
      "cpu": {
        "guest": 1
      },
      "memory": {
        "guest": "128Mi"
      }
    }
  },
  "kind": "ControllerRevision",
  "metadata": {
    "creationTimestamp": "2022-09-30T12:20:19Z",
    "name": "vm-cirros-csmall-csmall-72c3a35b-6e18-487d-bebf-f73c7d4f4a40-1",
    "namespace": "default",
    "ownerReferences": [
      {
        "apiVersion": "kubevirt.io/v1",
        "blockOwnerDeletion": true,
        "controller": true,
        "kind": "VirtualMachine",
        "name": "vm-cirros-csmall",
        "uid": "5216527a-1d31-4637-ad3a-b640cb9949a2"
      }
    ],
    "resourceVersion": "10307",
    "uid": "a7bc784b-4cea-45d7-8432-15418e1dd7d3"
  },
  "revision": 0
}


$ kubectl delete vm/vm-cirros-csmall
virtualmachine.kubevirt.io "vm-cirros-csmall" deleted

$ kubectl get controllerrevision/controllerrevision/vm-cirros-csmall-csmall-72c3a35b-6e18-487d-bebf-f73c7d4f4a40-1
Error from server (NotFound): controllerrevisions.apps "vm-cirros-csmall-csmall-72c3a35b-6e18-487d-bebf-f73c7d4f4a40-1" not found
```

### Inferring defaults from a Volume

The `inferFromVolume` attribute of both the `InstancetypeMatcher` and `PreferenceMatcher` allows a user to request that defaults are inferred from a volume. When requested KubeVirt will look for the following labels on the underlying `PVC`, `DataSource` or `DataVolume` to determine the default name and kind:

* `instancetype.kubevirt.io/default-instancetype`
* `instancetype.kubevirt.io/default-instancetype-kind` (optional, defaults to `VirtualMachineClusterInstancetype`)
* `instancetype.kubevirt.io/default-preference`
* `instancetype.kubevirt.io/default-preference-kind` (optional, defaults to `VirtualMachineClusterPreference`)

These values are then written into the appropriate matcher by the mutation webhook and used during validation before the `VirtualMachine` is formally accepted.

Failure to find the referenced `Volume` or labels on an underlying resource will cause the request to be rejected.

```yaml
$ kubectl kustomize https://github.com/kubevirt/common-instancetypes.git | kubectl apply -f -
[..]
$ virtctl image-upload pvc cirros-pvc --size=1Gi --image-path=./cirros-0.5.2-x86_64-disk.img
[..]
$ kubectl label pvc/cirros-pvc \
  instancetype.kubevirt.io/default-instancetype=server.tiny \
  instancetype.kubevirt.io/default-preference=cirros
[..]
$ kubectl apply -f - << EOF
---
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataSource
metadata:
  name: cirros-datasource
spec:
  source:
    pvc:
      name: cirros-pvc
      namespace: default
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: cirros
spec:
  instancetype:
    inferFromVolume: cirros-volume
  preference:
    inferFromVolume: cirros-volume
  running: false
  dataVolumeTemplates:
    - metadata:
        name: cirros-datavolume
      spec:
        pvc:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
          storageClassName: local
        sourceRef:
          kind: DataSource
          name: cirros-datasource
          namespace: default
  template:
    spec:
      domain:
        devices: {}
      volumes:
        - dataVolume:
            name: cirros-datavolume
          name: cirros-volume
EOF
[..]
kubectl get vms/cirros -o json | jq '.spec.instancetype, .spec.preference'
{
  "kind": "virtualmachineclusterinstancetype",
  "name": "server.tiny",
  "revisionName": "cirros-server.tiny-76454433-3d82-43df-a7e5-586e48c71f68-1"
}
{
  "kind": "virtualmachineclusterpreference",
  "name": "cirros",
  "revisionName": "cirros-cirros-85823ddc-9e8c-4d23-a94c-143571b5489c-1"
}
```

### Common Instance Types

A set of common instance types and preferences are provided through the [`kubevirt/common-instancetypes`](https://github.com/kubevirt/common-instancetypes) project. To install all resources provided by the project simply build with `kustomize` and apply:

```yaml
$ kubectl kustomize https://github.com/kubevirt/common-instancetypes.git | kubectl apply -f -
```

Alternatively targets for each of the available custom resource types are available for example for `VirtualMachineClusterInstancetype`:

```yaml
$ kubectl kustomize https://github.com/kubevirt/common-instancetypes.git/VirtualMachineClusterInstancetypes | kubectl apply -f -
```

## Examples

Various examples are available within the [`kubevirt`](https://github.com/kubevirt/kubevirt) repo under [`/examples`](https://github.com/kubevirt/kubevirt/tree/main/examples). The following uses an example `VirtualMachine` provided by the [`containerdisk/fedora` repo](https://quay.io/repository/containerdisks/fedora) and replaces much of the `DomainSpec` with the equivalent instance type and preferences:

```yaml
$ kubectl apply -f - << EOF
---
apiVersion: instancetype.kubevirt.io/v1alpha2
kind: VirtualMachineInstancetype
metadata:
  name: cmedium
spec:
  cpu:
    guest: 1
  memory:
    guest: 1Gi
---
apiVersion: instancetype.kubevirt.io/v1alpha2
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
