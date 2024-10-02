# Instance types and preferences

**FEATURE STATE:** 

* `instancetype.kubevirt.io/v1alpha1` (Experimental) as of the [`v0.56.0`](https://github.com/kubevirt/kubevirt/releases/tag/v0.56.0) KubeVirt release
* `instancetype.kubevirt.io/v1alpha2` (Experimental) as of the [`v0.58.0`](https://github.com/kubevirt/kubevirt/releases/tag/v0.58.0) KubeVirt release
* `instancetype.kubevirt.io/v1beta1` as of the [`v1.0.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.0.0) KubeVirt release

See the [Version History](#version-history) section for more details.

## Introduction

KubeVirt's [`VirtualMachine`](https://kubevirt.io/api-reference/main/definitions.html#_v1_virtualmachine) API contains many advanced options for tuning the performance of a VM that goes beyond what typical users need to be aware of. Users have previously been unable to simply define the storage/network they want assigned to their VM and then declare in broad terms what quality of resources and kind of performance characteristics they need for their VM.

Instance types and preferences provide a way to define a set of resource, performance and other runtime characteristics, allowing users to reuse these definitions across multiple `VirtualMachines`.

## VirtualMachineInstancetype

```yaml
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  name: example-instancetype
spec:
  cpu:
    guest: 1
  memory:
    guest: 128Mi
```

KubeVirt provides two [`CRDs`](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) for instance types, a cluster wide [`VirtualMachineClusterInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachineclusterinstancetype) and a namespaced [`VirtualMachineInstancetype`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachineinstancetype). These `CRDs` encapsulate the following resource related characteristics of a `VirtualMachine` through a shared [`VirtualMachineInstancetypeSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachineinstancetypespec):

* [`CPU`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_cpuinstancetype) : Required number of vCPUs presented to the guest
* [`Memory`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_memoryinstancetype) : Required amount of memory presented to the guest
* [`GPUs`](https://kubevirt.io/api-reference/main/definitions.html#_v1_gpu) : Optional list of vGPUs to passthrough
* [`HostDevices`](https://kubevirt.io/api-reference/main/definitions.html#_v1_hostdevice) : Optional list of `HostDevices` to passthrough
* `IOThreadsPolicy` : Optional `IOThreadsPolicy` to be used
* [`LaunchSecurity`](https://kubevirt.io/api-reference/main/definitions.html#_v1_launchsecurity): Optional `LaunchSecurity` to be used

Anything provided within an instance type cannot be overridden within the `VirtualMachine`. For example, as `CPU` and `Memory` are both required attributes of an instance type, if a user makes any requests for `CPU` or `Memory` resources within the underlying `VirtualMachine`, the instance type will conflict and the request will be rejected during creation.

## VirtualMachinePreference

```yaml
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachinePreference
metadata:
  name: example-preference
spec:
  devices:
    preferredDiskBus: virtio
    preferredInterfaceModel: virtio
```

KubeVirt also provides two further preference based `CRDs`, again a cluster wide [`VirtualMachineClusterPreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachineclusterpreference) and namespaced [`VirtualMachinePreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachinepreference). These `CRDs`encapsulate the preferred value of any remaining attributes of a `VirtualMachine` required to run a given workload, again this is through a shared [`VirtualMachinePreferenceSpec`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachinepreferencespec).

Unlike instance types, preferences only represent the preferred values and as such, they can be overridden by values in the `VirtualMachine` provided by the user.

In the example shown below, a user has provided a `VirtualMachine` with a disk bus already defined within a [`DiskTarget`](https://kubevirt.io/api-reference/main/definitions.html#_v1_disktarget) *and* has also selected a set of preferences with [`DevicePreference`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_devicepreferences) and `preferredDiskBus` , so the user's original choice within the `VirtualMachine` and `DiskTarget` are used:

```yaml
$ kubectl apply -f - << EOF
---
apiVersion: instancetype.kubevirt.io/v1beta1
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

### PreferredCPUTopology

A preference can optionally include a `PreferredCPUTopology` that defines how the guest visible CPU topology of the `VirtualMachineInstance` is constructed from vCPUs supplied by an instance type.

```yaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachinePreference
metadata:
  name: example-preference-cpu-topology
spec:
  cpu:
    preferredCPUTopology: cores
```

The allowed values for `PreferredCPUTopology` include:

* `sockets` (default) - Provides vCPUs as sockets to the guest
* `cores` - Provides vCPUs as cores to the guest
* `threads` - Provides vCPUs as threads to the guest
* `spread` - Spreads vCPUs across sockets and cores by default. See the following [SpreadOptions](#### SpreadOptions) section for more details.
* `any` - Provides vCPUs as sockets to the guest, this is also used to express that any allocation of vCPUs is required by the preference. Useful when defining a preference that isn't used alongside an instance type.

Note that support for the original `preferSockets`, `preferCores`, `preferThreads` and `preferSpread` values for `PreferredCPUTopology` is deprecated as of `v1.4.0` ahead of removal in a future release.

#### SpreadOptions

When `spread` is provided as the value of `PreferredCPUTopology` we can further customize how vCPUs are spread across the guest visible CPU topology using `SpreadOptions`:

```yaml
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachinePreference
metadata:
  name: example-preference-cpu-topology
spec:
  cpu:
    preferredCPUTopology: spread
    spreadOptions:
      across: SocketsCoresThreads
      ratio: 4
```

[`spreadOptions`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_spreadoptions) provides the following configurables:

* `across` - Defines how vCPUs should be spread across the guest visible CPU topology
* `ratio`  - Defines the ratio at which vCPUs should be spread (defaults to 2)

The allowed values for `across` include:

* `SocketsCores` (default) - Spreads vCPUs across sockets and cores with a ratio of 1:N where N is the provided ratio.
* `SocketsCoresThreads` - Spreads vCPUs across sockets, cores and threads with a ratio of 1:N:2 where N is the provided ratio.
* `CoresThreads` - Spreads vCPUs across cores and threads with an enforced ratio of 1:2. (requires at least 2 vCPUs to be provided by an instance type)

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

The previous instance type and preference CRDs are matched to a given `VirtualMachine` through the use of a matcher. Each matcher consists of the following:

* `Name` (string): Name of the resource being referenced
* `Kind` (string):  Optional, defaults to the cluster wide CRD kinds of `VirtualMachineClusterInstancetype` or `VirtualMachineClusterPreference` if not provided
* `RevisionName` (string) : Optional, name of a [`ControllerRevision`](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/controller-revision-v1/) containing a copy of the `VirtualMachineInstancetypeSpec` or `VirtualMachinePreferenceSpec` taken when the `VirtualMachine` is first created. See the [Versioning](#versioning) section below for more details on how and why this is captured.
* `InferFromVolume` (string): Optional, see the [Inferring defaults from a Volume](#inferring-defaults-from-a-volume) section below for more details.

## Creating InstanceTypes, Preferences and VirtualMachines

It is possible to streamline the creation of instance types, preferences, and virtual machines with the usage of the virtctl command-line tool. To read more about it, please see the [Creating VirtualMachines](../user_workloads/creating_vms.md#creating-virtualmachines).

## Versioning

Versioning of these resources is required to ensure the eventual `VirtualMachineInstance` created when starting a `VirtualMachine` does not change between restarts if any referenced instance type or set of preferences are updated during the lifetime of the `VirtualMachine`.

This is currently achieved by using `ControllerRevision` to retain a copy of the `VirtualMachineInstancetype` or `VirtualMachinePreference` at the time the `VirtualMachine` is created. A reference to these `ControllerRevisions` are then retained in the [`InstancetypeMatcher`](https://kubevirt.io/api-reference/main/definitions.html#_v1_instancetypematcher) and [`PreferenceMatcher`](https://kubevirt.io/api-reference/main/definitions.html#_v1_preferencematcher) within the `VirtualMachine` for future use.


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
    "apiVersion": "instancetype.kubevirt.io/v1beta1",
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

Users can opt in to moving to a newer generation of an instance type or preference by removing the referenced `revisionName` from the appropriate matcher within the `VirtualMachine` object. This will result in fresh `ControllerRevisions` being captured and used.

The following example creates a `VirtualMachine` using an initial version of the csmall instance type before increasing the number of vCPUs provided by the instance type:

```yaml
$ kubectl apply -f examples/csmall.yaml -f examples/vm-cirros-csmall.yaml
virtualmachineinstancetype.instancetype.kubevirt.io/csmall created
virtualmachine.kubevirt.io/vm-cirros-csmall created

$ kubectl get vm/vm-cirros-csmall -o json | jq .spec.instancetype
{
  "kind": "VirtualMachineInstancetype",
  "name": "csmall",
  "revisionName": "vm-cirros-csmall-csmall-3e86e367-9cd7-4426-9507-b14c27a08671-1"
}

$ virtctl start vm-cirros-csmall
VM vm-cirros-csmall was scheduled to start

$ kubectl get vmi/vm-cirros-csmall -o json | jq .spec.domain.cpu
{
  "cores": 1,
  "model": "host-model",
  "sockets": 1,
  "threads": 1
}

$ kubectl patch VirtualMachineInstancetype/csmall --type merge -p '{"spec":{"cpu":{"guest":2}}}'
virtualmachineinstancetype.instancetype.kubevirt.io/csmall patched
```

In order for this change to be picked up within the `VirtualMachine`, we need to stop the running `VirtualMachine` and clear the `revisionName` referenced by the `InstancetypeMatcher`:

```yaml
$ virtctl stop vm-cirros-csmall
VM vm-cirros-csmall was scheduled to stop

$ kubectl patch vm/vm-cirros-csmall --type merge -p '{"spec":{"instancetype":{"revisionName":""}}}'
virtualmachine.kubevirt.io/vm-cirros-csmall patched

$ kubectl get vm/vm-cirros-csmall -o json | jq .spec.instancetype
{
  "kind": "VirtualMachineInstancetype",
  "name": "csmall",
  "revisionName": "vm-cirros-csmall-csmall-3e86e367-9cd7-4426-9507-b14c27a08671-2"
}
```

As you can see above, the `InstancetypeMatcher` now references a new `ControllerRevision` containing generation 2 of the instance type. We can now start the `VirtualMachine` again and see the new number of vCPUs being used by the `VirtualMachineInstance`:

```yaml
$ virtctl start vm-cirros-csmall
VM vm-cirros-csmall was scheduled to start

$ kubectl get vmi/vm-cirros-csmall -o json | jq .spec.domain.cpu
{
  "cores": 1,
  "model": "host-model",
  "sockets": 2,
  "threads": 1
}
```

## inferFromVolume

The `inferFromVolume` attribute of both the `InstancetypeMatcher` and `PreferenceMatcher` allows a user to request that defaults are inferred from a volume. When requested, KubeVirt will look for the following labels on the underlying `PVC`, `DataSource` or `DataVolume` to determine the default name and kind:

* `instancetype.kubevirt.io/default-instancetype`
* `instancetype.kubevirt.io/default-instancetype-kind` (optional, defaults to `VirtualMachineClusterInstancetype`)
* `instancetype.kubevirt.io/default-preference`
* `instancetype.kubevirt.io/default-preference-kind` (optional, defaults to `VirtualMachineClusterPreference`)

These values are then written into the appropriate matcher by the mutation webhook and used during validation before the `VirtualMachine` is formally accepted.

The validation can be controlled by the value provided to `inferFromVolumeFailurePolicy` in either the `InstancetypeMatcher` or `PreferenceMatcher` of a `VirtualMachine`.

The default value of `Reject` will cause the request to be rejected on failure to find the referenced `Volume` or labels on an underlying resource.

If `Ignore` was provided, the respective `InstancetypeMatcher` or `PreferenceMatcher` will be cleared on a failure instead.

Example with implicit default value of `Reject`:

```yaml
$ kubectl apply -k https://github.com/kubevirt/common-instancetypes.git
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
        storage:
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

Example with explicit value of `Ignore`:

```yaml
$ virtctl image-upload pvc cirros-pvc --size=1Gi --image-path=./cirros-0.5.2-x86_64-disk.img
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
    inferFromVolumeFailurePolicy: Ignore
  preference:
    inferFromVolume: cirros-volume
    inferFromVolumeFailurePolicy: Ignore
  running: false
  dataVolumeTemplates:
    - metadata:
        name: cirros-datavolume
      spec:
        storage:
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
null
null
```

## Hotplug

Support for instance type based vCPU and memory hotplug was introduced in KubeVirt 1.3 and is built on existing [vCPU](../compute/cpu_hotplug.md) hotplug, [memory](../compute/memory_hotplug.md) hotplug and [LiveUpdate](./vm_rollout_strategies.md) support.

All requirements and limitations of these features apply when hot plugging a new instance type into a running `VirtualMachine`.

To invoke an instance type based vCPU and/or memory hotplug users should update the `name` of the referenced instance type while also clearing the `revisionName`, for example:

```shell
$ kubectl patch vm/my-vm --type merge -p '{"spec":{"instancetype":{"name": "new-instancetype", "revisionName":""}}}'
```

This will trigger the same vCPU and memory hot plug logic as a vanilla VirtualMachine assuming that the aforementioned requirements are met.

Otherwise a `RestartRequired` condition will be applied to the `VirtualMachine` to indicate that a reboot is needed for all changes to be made.

## common-instancetypes

The [`kubevirt/common-instancetypes`](https://github.com/kubevirt/common-instancetypes) provide a set of [instancetypes and preferences](../user_workloads/instancetypes.md) to help create KubeVirt [`VirtualMachines`](http://kubevirt.io/api-reference/main/definitions.html#_v1alpha1_virtualmachine).

See [Deploy common-instancetypes](../user_workloads/deploy_common_instancetypes.md) on how to deploy them.

## Examples

Various examples are available within the [`kubevirt`](https://github.com/kubevirt/kubevirt) repo under [`/examples`](https://github.com/kubevirt/kubevirt/tree/main/examples). The following uses an example `VirtualMachine` provided by the [`containerdisk/fedora` repo](https://quay.io/repository/containerdisks/fedora) and replaces much of the `DomainSpec` with the equivalent instance type and preferences:

```yaml
$ kubectl apply -f - << EOF
---
apiVersion: instancetype.kubevirt.io/v1beta1
kind: VirtualMachineInstancetype
metadata:
  name: cmedium
spec:
  cpu:
    guest: 1
  memory:
    guest: 1Gi
---
apiVersion: instancetype.kubevirt.io/v1beta1
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
            ssh_authorized_keys:
              - ssh-rsa AAAA...
        name: cloudinit
EOF
```

## Version History

### `instancetype.kubevirt.io/v1alpha1` (Experimental)

* Initial development version.

### `instancetype.kubevirt.io/v1alpha2` (Experimental)

* This version captured complete `VirtualMachine{Instancetype,ClusterInstancetype,Preference,ClusterPreference}` objects within the created `ControllerRevisions`

* This version is backwardly compatible with `instancetype.kubevirt.io/v1alpha1`.
### `instancetype.kubevirt.io/v1beta1`

* The following instance type attribute has been added:
  * [`Spec.Memory.OvercommitPercent`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_memoryinstancetype)

* The following preference attributes have been added:
  * [`Spec.CPU.PreferredCPUFeatures`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_cpupreferences)
  * [`Spec.Devices.PreferredInterfaceMasquerade`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_devicepreferences)
  * [`Spec.PreferredSubdomain`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachinepreferencespec)
  * [`Spec.PreferredTerminationGracePeriodSeconds`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_virtualmachinepreferencespec)
  * [`Spec.Requirements`](https://kubevirt.io/api-reference/main/definitions.html#_v1beta1_preferencerequirements)

* This version is backwardly compatible with `instancetype.kubevirt.io/v1alpha1` and `instancetype.kubevirt.io/v1alpha2` objects, no modifications are required to existing  `VirtualMachine{Instancetype,ClusterInstancetype,Preference,ClusterPreference}` or `ControllerRevisions`.

* As with the migration to [`kubevirt.io/v1`](https://github.com/kubevirt/kubevirt/blob/main/docs/updates.md#v100-migration-to-new-storage-versions) it is recommend previous users of `instancetype.kubevirt.io/v1alpha1` or `instancetype.kubevirt.io/v1alpha2` use [`kube-storage-version-migrator`](https://github.com/kubernetes-sigs/kube-storage-version-migrator) to upgrade any stored objects to `instancetype.kubevirt.io/v1beta1`.
