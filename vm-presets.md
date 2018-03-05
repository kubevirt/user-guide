Virtual Machine Presets
=============================

`VirtualMachinePresets` are an extension to general `VirtualMachine`
configuration behaving much like `PodPresets` from Kubernetes. When a
`VirtualMachine` is created, any applicable `VirtualMachinePresets`
will be applied to the existing spec for the `VirtualMachine`. This allows
for re-use of common settings that should apply to multiple `VirtualMachines`.


Usage
------------------------

KubeVirt uses Kubernetes `Labels` and `Selectors` to determine which
`VirtualMachinePresets` apply to any given `VirtualMachine`, similarly to how
`PodPresets` work in Kubernetes. If any setting from a `VirtualMachinePreset`
is applied to a `VirtualMachine`, the `VirtualMachine` will be marked with an
Annotation upon completion.

Any domain structure can be listed in the `spec` of a `VirtualMachinePreset`.
e.g. Clock, Features, Memory, CPU, or Devices such network interfaces.  All
elements of the `spec` section of a `VirtualMachinePreset` will be applied
to the `VirtualMachine`.

Once a `VirtualMachinePreset` is successfully applied to a `VirtualMachine`,
the `VirtualMachine` will be marked with an annotation to indicate that it
was applied. If a conflict occurs while a `VirtualMachinePreset` is being
applied that portion of the `VirtualMachinePreset` will be skipped.


Conflicts
------------------------

`VirtualMachinePresets` use a similar conflict resolution strategy to
Kubernetes `PodPresets`. If a portion of the domain spec is present in both a
`VirtualMachine` and a `VirtualMachinePreset` and both resources have the
identical information, then no conflict will occur and `VirtualMachine` creation
will continue normally. If however there is a conflict between the resources,
an Event will be created indicating which `DomainSpec` element of which
`VirtualMachinePreset` was problematic. For example: If both the `VirtualMachine`
and `VirtualMachinePreset` define a `CPU`, but use a different number of `Cores`,
KubeVirt will note the conflict.

If any settings from the `VirtualMachinePreset` were successfully applied, the
`VirtualMachine` will still be annotated.

In the event that a conflict occurs, KubeVirt will create an `Event`.
`kubectl get events` can be used to show all `Events`. For example:

```
$ kubectl get events
....
Events:
  FirstSeen                         LastSeen                        Count From                              SubobjectPath                Reason    Message
  2m          2m           1         myvm.1515bbb8d397f258                       VirtualMachine                                     Warning   Conflict                  virtualmachine-preset-controller   Unable to apply VirtualMachinePreset 'example-preset': spec.cpu: &{6} != &{4}
```

Creation and Usage
------------------------

`VirtualMachinePresets` are namespaced resources, so should be created in the
same namespace as the `VirtualMachines` that will use them:

`kubectl create -f <preset>.yaml [--namespace <namespace>]`

KubeVirt will determine which `VirtualMachinePresets` apply to a Particular
`VirtualMachine` by matching `Labels`. For example:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachinePreset
metadata:
  name: example-preset
  selector:
    matchLabels:
      kubevirt.io/flavor: foo
  ...
```

would match any `VirtualMachine` in the same namespace with a `Label` of
`flavor: foo`. For example:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
version: v1
metadata:
  name: myvm
  labels:
    kubevirt.io/flavor: foo
  ...
```

Examples
=============================

Simple `VirtualMachinePreset` Example
------------------------

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachinePreset
version: v1alpha1
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
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
version: v1
metadata:
  name: myvm
  labels:
    kubevirt.io/os: win10
spec:
  domain:
    firmware:
      uuid: c8f99fc8-20f5-46c4-85e5-2b841c547cef
```

Once the `VirtualMachinePreset` is applied to the `VirtualMachine`, the
resulting resource would look like this:


```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  annotations:
    presets.virtualmachines.kubevirt.io/presets-applied: kubevirt.io/v1alpha1
    virtualmachinepreset.kubevirt.io/example-preset: kubevirt.io/v1alpha1
  labels:
    kubevirt.io/os: win10
    kubevirt.io/nodeName: master
  name: myvm
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

Conflict Example
------------------------

This is an example of a merge conflict. In this case both the `VirtualMachine`
and `VirtualMachinePreset` request different number of CPU's.


```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachinePreset
version: v1alpha1
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
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
version: v1
metadata:
  name: myvm
  labels:
    kubevirt.io/flavor: default-features
spec:
  domain:
    cpu:
      cores: 6
```

In this case the `VirtualMachine` Spec will remain unmodified. Use
`kubectl get events` to show events.

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  annotations:
    presets.virtualmachines.kubevirt.io/presets-applied: kubevirt.io/v1alpha1
  generation: 0
  labels:
    kubevirt.io/flavor: default-features
  name: myvm
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

Calling `kubectl get events` would have a line like:
2m          2m           1         myvm.1515bbb8d397f258                       VirtualMachine                                     Warning   Conflict                  virtualmachine-preset-controller   Unable to apply VirtualMachinePreset 'example-preset': spec.cpu: &{6} != &{4}
