# Presets

## What is a VirtualMachineInstancePreset?

`VirtualMachineInstancePresets` are an extension to general `VirtualMachineInstance` configuration behaving much like `PodPresets` from Kubernetes. When a `VirtualMachineInstance` is created, any applicable `VirtualMachineInstancePresets` will be applied to the existing spec for the `VirtualMachineInstance`. This allows for re-use of common settings that should apply to multiple `VirtualMachineInstances`.

## Create a VirtualMachineInstancePreset

You can describe a `VirtualMachineInstancePreset` in a YAML file. For example, the `vmi-preset.yaml` file below describes a `VirtualMachineInstancePreset` that requests a `VirtualMachineInstance` be created with a resource request for 64M of RAM.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
metadata:
  name: small-qemu
spec:
  selector:
    matchLabels:
      kubevirt.io/size: small
  domain:
    resources:
      requests:
        memory: 64M
```

* Create a `VirtualMachineInstancePreset` based on that YAML file:

```bash
kubectl create -f vmipreset.yaml
```

### Required Fields

As with most Kubernetes resources, a `VirtualMachineInstancePreset` requires `apiVersion`, `kind` and `metadata` fields.

Additionally `VirtualMachineInstancePresets` also need a `spec` section. While not technically required to satisfy syntax, it is strongly recommended to include a `Selector` in the `spec` section, otherwise a `VirtualMachineInstancePreset` will match all `VirtualMachineInstances` in a namespace.

### VirtualMachine Selector

KubeVirt uses Kubernetes `Labels` and `Selectors` to determine which `VirtualMachineInstancePresets` apply to a given `VirtualMachineInstance`, similarly to how `PodPresets` work in Kubernetes. If a setting from a `VirtualMachineInstancePreset` is applied to a `VirtualMachineInstance`, the `VirtualMachineInstance` will be marked with an Annotation upon completion.

Any domain structure can be listed in the `spec` of a `VirtualMachineInstancePreset`, e.g. Clock, Features, Memory, CPU, or Devices such as network interfaces. All elements of the `spec` section of a `VirtualMachineInstancePreset` will be applied to the `VirtualMachineInstance`.

Once a `VirtualMachineInstancePreset` is successfully applied to a `VirtualMachineInstance`, the `VirtualMachineInstance` will be marked with an annotation to indicate that it was applied. If a conflict occurs while a `VirtualMachineInstancePreset` is being applied, that portion of the `VirtualMachineInstancePreset` will be skipped.

Any valid `Label` can be matched against, but it is suggested that a general rule of thumb is to use os/shortname, e.g. `kubevirt.io/os: rhel7`.

### Updating a VirtualMachineInstancePreset

If a `VirtualMachineInstancePreset` is modified, changes will _not_ be applied to existing `VirtualMachineInstances`. This applies to both the `Selector` indicating which `VirtualMachineInstances` should be matched, and also the `Domain` section which lists the settings that should be applied to a `VirtualMachine`.

### Overrides

`VirtualMachineInstancePresets` use a similar conflict resolution strategy to Kubernetes `PodPresets`. If a portion of the domain spec is present in both a `VirtualMachineInstance` and a `VirtualMachineInstancePreset` and both resources have the identical information, then creation of the `VirtualMachineInstance` will continue normally. If however there is a difference between the resources, an Event will be created indicating which `DomainSpec` element of which `VirtualMachineInstancePreset` was overridden. For example: If both the `VirtualMachineInstance` and `VirtualMachineInstancePreset` define a `CPU`, but use a different number of `Cores`, KubeVirt will note the difference.

If any settings from the `VirtualMachineInstancePreset` were successfully applied, the `VirtualMachineInstance` will be annotated.

In the event that there is a difference between the `Domains` of a `VirtualMachineInstance` and `VirtualMachineInstancePreset`, KubeVirt will create an `Event`. `kubectl get events` can be used to show all `Events`. For example:

```bash
$ kubectl get events
....
Events:
  FirstSeen                         LastSeen                        Count From                              SubobjectPath                Reason    Message
  2m          2m           1         myvmi.1515bbb8d397f258                       VirtualMachineInstance                                     Warning   Conflict                  virtualmachineinstance-preset-controller   Unable to apply VirtualMachineInstancePreset 'example-preset': spec.cpu: &{6} != &{4}
```

### Usage

`VirtualMachineInstancePresets` are namespaced resources, so should be created in the same namespace as the `VirtualMachineInstances` that will use them:

`kubectl create -f <preset>.yaml [--namespace <namespace>]`

KubeVirt will determine which `VirtualMachineInstancePresets` apply to a Particular `VirtualMachineInstance` by matching `Labels`. For example:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
metadata:
  name: example-preset
  selector:
    matchLabels:
      kubevirt.io/os: win10
  ...
```

would match any `VirtualMachineInstance` in the same namespace with a `Label` of `flavor: foo`. For example:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
version: v1
metadata:
  name: myvmi
  labels:
    kubevirt.io/os: win10
  ...
```

### Conflicts

When multiple `VirtualMachineInstancePresets` match a particular `VirtualMachineInstance`, if they specify the same settings within a Domain, those settings must match. If two `VirtualMachineInstancePresets` have conflicting settings (e.g. for the number of CPU cores requested), an error will occur, and the `VirtualMachineInstance` will enter the `Failed` state, and a `Warning` event will be emitted explaining which settings of which `VirtualMachineInstancePresets` were problematic.

### Matching Multiple `VirtualMachineInstances`

The main use case for `VirtualMachineInstancePresets` is to create re-usable settings that can be applied across various machines. Multiple methods are available to match the labels of a `VirtualMachineInstance` using selectors.

* matchLabels: Each `VirtualMachineInstance` can use a specific label shared by all

    instances.

* matchExpressions: Logical operators for sets can be used to match multiple

    labels.

Using matchLabels, the label used in the `VirtualMachineInstancePreset` must match one of the labels of the `VirtualMachineInstance`:

```yaml
selector:
  matchLabels:
    kubevirt.io/memory: large
```

would match

```yaml
metadata:
  labels:
    kubevirt.io/memory: large
    kubevirt.io/os: win10
```

or

```yaml
metadata:
  labels:
    kubevirt.io/memory: large
    kubevirt.io/os: fedora27
```

Using matchExpressions allows for matching multiple labels of `VirtualMachineInstances` without needing to explicity list a label.

```yaml
selector:
  matchExpressions:
    - {key: kubevirt.io/os, operator: In, values: [fedora27, fedora26]}
```

would match both:

```yaml
metadata:
  labels:
    kubevirt.io/os: fedora26
```

```yaml
metadata:
  labels:
    kubevirt.io/os: fedora27
```

The Kubernetes [documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) has a detailed explanation. Examples are provided below.

### Exclusions

Since `VirtualMachineInstancePresets` use `Selectors` that indicate which `VirtualMachineInstances` their settings should apply to, there needs to exist a mechanism by which `VirtualMachineInstances` can opt out of `VirtualMachineInstancePresets` altogether. This is done using an annotation:

```yaml
kind: VirtualMachineInstance
version: v1
metadata:
  name: myvmi
  annotations:
    virtualmachineinstancepresets.admission.kubevirt.io/exclude: "true"
  ...
```


## Examples

### Simple `VirtualMachineInstancePreset` Example

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
version: v1alpha2
metadata:
  name: example-preset
spec:
  selector:
    matchLabels:
      kubevirt.io/os: win10
  domain:
    features:
      acpi: {}
      apic: {}
      hyperv:
        relaxed: {}
        vapic: {}
        spinlocks:
          spinlocks: 8191
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
version: v1
metadata:
  name: myvmi
  labels:
    kubevirt.io/os: win10
spec:
  domain:
    firmware:
      uuid: c8f99fc8-20f5-46c4-85e5-2b841c547cef
```

Once the `VirtualMachineInstancePreset` is applied to the `VirtualMachineInstance`, the resulting resource would look like this:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  annotations:
    presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
    virtualmachineinstancepreset.kubevirt.io/example-preset: kubevirt.io/v1alpha2
  labels:
    kubevirt.io/os: win10
    kubevirt.io/nodeName: master
  name: myvmi
  namespace: default
spec:
  domain:
    devices: {}
    features:
      acpi:
        enabled: true
      apic:
        enabled: true
      hyperv:
        relaxed:
          enabled: true
        spinlocks:
          enabled: true
          spinlocks: 8191
        vapic:
          enabled: true
    firmware:
      uuid: c8f99fc8-20f5-46c4-85e5-2b841c547cef
    machine:
      type: q35
    resources:
      requests:
        memory: 8Mi
```

### Conflict Example

This is an example of a merge conflict. In this case both the `VirtualMachineInstance` and `VirtualMachineInstancePreset` request different number of CPU's.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
version: v1alpha2
metadata:
  name: example-preset
spec:
  selector:
    matchLabels:
      kubevirt.io/flavor: default-features
  domain:
    cpu:
      cores: 4
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
version: v1
metadata:
  name: myvmi
  labels:
    kubevirt.io/flavor: default-features
spec:
  domain:
    cpu:
      cores: 6
```

In this case the `VirtualMachineInstance` Spec will remain unmodified. Use `kubectl get events` to show events.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  annotations:
    presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
  generation: 0
  labels:
    kubevirt.io/flavor: default-features
  name: myvmi
  namespace: default
spec:
  domain:
    cpu:
      cores: 6
    devices: {}
    machine:
      type: ""
    resources: {}
status: {}
```

Calling `kubectl get events` would have a line like: 2m 2m 1 myvmi.1515bbb8d397f258 VirtualMachineInstance Warning Conflict virtualmachineinstance-preset-controller Unable to apply VirtualMachineInstancePreset 'example-preset': spec.cpu: &{6} != &{4}

### Matching Multiple VirtualMachineInstances Using MatchLabels

These `VirtualMachineInstances` have multiple labels, one that is unique and one that is shared.

Note: This example breaks from the convention of using os-shortname as a `Label` for demonstration purposes.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
metadata:
  name: twelve-cores
spec:
  selector:
    matchLabels:
      kubevirt.io/cpu: dodecacore
  domain:
    cpu:
      cores: 12
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: windows-10
  labels:
    kubevirt.io/os: win10
    kubevirt.io/cpu: dodecacore
spec:
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: windows-7
  labels:
    kubevirt.io/os: win7
    kubevirt.io/cpu: dodecacore
spec:
  terminationGracePeriodSeconds: 0
```

Adding this `VirtualMachineInstancePreset` and these `VirtualMachineInstances` will result in:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  annotations:
    presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
    virtualmachineinstancepreset.kubevirt.io/twelve-cores: kubevirt.io/v1alpha2
  labels:
    kubevirt.io/cpu: dodecacore
    kubevirt.io/os: win10
  name: windows-10
spec:
  domain:
    cpu:
      cores: 12
    devices: {}
    resources:
      requests:
        memory: 4Gi
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  annotations:
    presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
    virtualmachineinstancepreset.kubevirt.io/twelve-cores: kubevirt.io/v1alpha2
  labels:
    kubevirt.io/cpu: dodecacore
    kubevirt.io/os: win7
  name: windows-7
spec:
  domain:
    cpu:
      cores: 12
    devices: {}
    resources:
      requests:
        memory: 4Gi
  terminationGracePeriodSeconds: 0
```

### Matching Multiple VirtualMachineInstances Using MatchExpressions

This `VirtualMachineInstancePreset` has a matchExpression that will match two labels: `kubevirt.io/os: win10` and `kubevirt.io/os: win7`.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
metadata:
  name: windows-vmis
spec:
  selector:
    matchExpressions:
      - {key: kubevirt.io/os, operator: In, values: [win10, win7]}
  domain:
    resources:
      requests:
        memory: 128M
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: smallvmi
  labels:
    kubevirt.io/os: win10
spec:
  terminationGracePeriodSeconds: 60
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: largevmi
  labels:
    kubevirt.io/os: win7
spec:
  terminationGracePeriodSeconds: 120
```

Applying the preset to both VM's will result in:

```yaml
apiVersion: v1
items:
- apiVersion: kubevirt.io/v1alpha2
  kind: VirtualMachineInstance
  metadata:
    annotations:
      presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
      virtualmachineinstancepreset.kubevirt.io/windows-vmis: kubevirt.io/v1alpha2
    labels:
      kubevirt.io/os: win7
    name: largevmi
  spec:
    domain:
      resources:
        requests:
          memory: 128M
    terminationGracePeriodSeconds: 120
- apiVersion: kubevirt.io/v1alpha2
  kind: VirtualMachineInstance
  metadata:
    annotations:
      presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
      virtualmachineinstancepreset.kubevirt.io/windows-vmis: kubevirt.io/v1alpha2
    labels:
      kubevirt.io/os: win10
    name: smallvmi
  spec:
    domain:
      resources:
        requests:
          memory: 128M
    terminationGracePeriodSeconds: 60
```

