# Clone API

The `clone.kubevirt.io` API Group defines resources for cloning KubeVirt objects.

This API has two main use-cases:
* Cloning a Virtual Machine.
* Creating "golden snapshots" that would be used as a template for creating new VMs
(see [Using clones as a "golden VM image"](#using-clones-as-a-golden-vm-image) below).

Please bear in mind that the clone API is in version `v1beta1`. This means that this API is not fully stable
yet and that APIs may change in the future.

## Prerequisites

### Snapshot / Restore

Under the hood, the clone API relies upon Snapshot & Restore APIs. Therefore, in order to be able to use the clone API,
please see [Snapshot & Restore prerequisites](../storage/snapshot_restore_api.md#prerequisites).

### Snapshot Feature Gate

Currently, clone API is guarded by Snapshot feature gate. The
[feature gates](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `Snapshot` to it.

## The clone object

Firstly, as written above, the clone API relies upon Snapshot & Restore APIs under the hood. Therefore, it might be helpful
to look at [Snapshot & Restore](../storage/snapshot_restore_api.md) user-guide page for more info.

### VirtualMachineClone object overview

In order to initiate cloning, a `VirtualMachineClone` object (CRD) needs to be created on the cluster. An example
for such an object is:
```yaml
kind: VirtualMachineClone
apiVersion: "clone.kubevirt.io/v1beta1"
metadata:
  name: testclone

spec:
  # source & target definitions
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: vm-cirros
  target:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: vm-clone-target

  # labels & annotations definitions
  labelFilters:
    - "*"
    - "!someKey/*"
  annotationFilters:
    - "anotherKey/*"

  # template labels & annotations definitions
  template:
    labelFilters:
      - "*"
      - "!someKey/*"
    annotationFilters:
      - "anotherKey/*"

  # other identity stripping specs:
  newMacAddresses:
    interfaceName: "00-11-22"
  newSMBiosSerial: "new-serial"
```

In the next section I will go through the different settings to elaborate them.

#### Source & Target

The source and target indicate the source/target API group, kind and name. A few important notes:

* Currently, the only supported kinds are `VirtualMachine` (of `kubevirt.io` api group) and `VirtualMachineSnapshot` (
of `snapshot.kubevirt.io` api group), but more types are expected to be supported in the future.

* The target name is **optional**. If unspecified, the clone controller will generate a name for the target automatically.

* The target and source must reside in the same namespace.

#### Label & Annotation filters

These spec fields are intended to determine which labels / annotations are being copied to the target or stripped away.

The filters are a list of strings. Each string represents a key that may exist at the source. Every source key that matches
to one of these values is being copied to the cloned target. In addition, special regular-expression-like characters can be
used:

* **Wildcard character (\*)** can be used to match anything. Wildcard can be only used at the **end** of the filter.
  * These filters are valid:
    * "*"
    * "some/key*"
  * These filters are invalid:
    * "some/*/key"
    * "*/key"
* **Negation character (!)** can be used to avoid matching certain keys. Negation can be only used at the **beginning** of a filter.
  Note that a Negation and Wildcard can be used together.
  * These filters are valid:
    * "!some/key"
    * "!some/*"
  * These filters are invalid:
    * "key!"
    * "some/!key"

Setting label / annotation filters is **optional**. If unset, all labels / annotations will be copied as a default.

#### Template Label & Template Annotation filters

Some network CNIs such as Kube-OVN or OVN-Kubernetes inject network information into the annotations of a VM. When cloning a VM from a target VM the cloned VM will use the same network. To avoid this you can use template labels and annotation filters.

#### newMacAddresses

This field is used to explicitly replace MAC addresses for certain interfaces. The field is a string to string map; the
keys represent interface names and the values represent the new MAC address for the clone target.

This field is optional. By default, all mac addresses are stripped out. This suits situations when kube-mac-pool is
deployed in the cluster which would automatically assign the target with a fresh valid MAC address.

#### newSMBiosSerial

This field is used to explicitly set an SMBios serial for the target.

This field is optional. By default, the target would have an auto-generated serial that's based on the VM name.

### JSON patches

It is sometimes necessary to modify the specs of VMs further than filtering before cloning them (e.g modifying or adding annotations for CNIs).

JSON patches can be applied to the `specs` and `labels/annotations` of cloned VMs using the `patches` parameter:

```yaml
apiVersion: snapshot.kubevirt.io/v1beta1
kind: VirtualMachineClone
metadata:
  name: cone
spec:
  source:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: vm-cirros
  target:
    apiGroup: kubevirt.io
    kind: VirtualMachine
    name: vm-clone-target
  patches:
    - '{"op": "add", "path": "/metadata/labels/test", "value": "something"}'
    - '{"op": "replace", "path": "/spec/template/metadata/labels/example", "value": "replaced-value"}'
```

**Keep in mind that patches must be carefully applied.** Some fields might be used to reference other resources, or be used as targets by other resources.

Patches are cumulative (and have precedence) with modifications done using template label/annotation filters and MAC address/SMBIOS fields.

### Creating a VirtualMachineClone object

After the clone manifest is ready, we can create it:
```bash
kubectl create -f clone.yaml
```

To wait for a clone to complete, execute:
```bash
kubectl wait vmclone testclone --for condition=Ready
```

You can check the clone's phase in the clone's status. It can be one of the following:

* SnapshotInProgress

* CreatingTargetVM

* RestoreInProgress

* Succeeded

* Failed

* Unknown

After the clone is finished, the target can be inspected:
```bash
kubectl get vm vm-clone-target -o yaml
```

### Using clones as a "golden VM image"

One of the great things that could be accomplished with the clone API when the source is of kind `VirtualMachineSnapshot`
is to create "golden VM images" (a.k.a. Templates / Bookmark VMs / etc). In other words, the following
workflow is available:

**Create a golden image**

* Create a VM

* Prepare a "golden VM" environment. This can mean different things in different contexts.
For example, add certain users, install a database, configure it in a certain way, etc.

* Snapshot the VM

* Optional: Delete the VM

Then, this "golden image" can be duplicated as many times as needed. To instantiate a VM from the snapshot:

* Create a Clone object where the source would point to the previously taken snapshot
* Create as many VMs you need
