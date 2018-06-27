# Guest Operating System Information

Guest operating system identity for the VirtualMachineInstance will be provided by the label `kubevirt.io/os` :

```yaml
metadata:
  name: myvmi
  labels:
    kubevirt.io/os: win2k12r2
```

The `kubevirt.io/os` label is based on the short OS identifier from [libosinfo](https://libosinfo.org/) database. The following Short IDs are currently supported:

| Short ID | Name | Version | Family | ID |
| --- | --- | --- | --- | --- |
| **win2k12r2** | Microsoft Windows Server 2012 R2 | 6.3 | winnt | [http://microsoft.com/win/2k12r2](http://microsoft.com/win/2k12r2) |

## Use with presets

A VirtualMachineInstancePreset representing an operating system with a `kubevirt.io/os` label could be applied on any given VirtualMachineInstance that have and match the`kubevirt.io/os` label.

Default presets for the OS identifiers above are included in the current release.

### Windows Server 2012R2 `VirtualMachineInstancePreset` Example

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstancePreset
metadata:
  name: windows-server-2012r2
  selector:
    matchLabels:
      kubevirt.io/os: win2k12r2
spec:
  domain:
    cpu:
      cores: 2
    resources:
      requests:
        memory: 2G
    features:
      acpi: {}
      apic: {}
      hyperv:
        relaxed: {}
        vapic: {}
        spinlocks:
          spinlocks: 8191
    clock:
      utc: {}
      timer:
        hpet:
          present: false
        pit:
          tickPolicy: delay
        rtc:
          tickPolicy: catchup
        hyperv: {}
---
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  labels:
    kubevirt.io/os: win2k12r2  
  name: windows2012r2
spec:
  terminationGracePeriodSeconds: 0
  domain:
    firmware:
      uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
    devices:
      disks:
      - name: server2012r2
        volumeName: server2012r2
        disk:
          dev: vda
  volumes:
    - name: server2012r2
      persistentVolumeClaim:
        claimName: my-windows-image
```

Once the `VirtualMachineInstancePreset` is applied to the `VirtualMachineInstance`, the resulting resource would look like this:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  annotations:
    presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha2
    virtualmachineinstancepreset.kubevirt.io/windows-server-2012r2: kubevirt.io/v1alpha2
  labels:
    kubevirt.io/os: win2k12r2  
  name: windows2012r2
spec:
  terminationGracePeriodSeconds: 0
  domain:
    cpu:
      cores: 2
    resources:
      requests:
        memory: 2G      
    features:
      acpi: {}
      apic: {}
      hyperv:
        relaxed: {}
        vapic: {}
        spinlocks:
          spinlocks: 8191
    clock:
      utc: {}
      timer:
        hpet:
          present: false
        pit:
          tickPolicy: delay
        rtc:
          tickPolicy: catchup
        hyperv: {}
    firmware:
      uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
    devices:
      disks:
      - name: server2012r2
        volumeName: server2012r2
        disk:
          dev: vda
  volumes:
    - name: server2012r2
      persistentVolumeClaim:
        claimName: my-windows-image
```

For more information see [VirtualMachineInstancePresets](presets.md)

