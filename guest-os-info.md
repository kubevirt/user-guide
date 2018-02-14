## Guest Operating System Information

Guest operating system identity for the Virtual Machine will be provided by the label ``kubevirt.io/os`` :

```
metadata:
  name: myvm
  labels:
    kubevirt.io/os: win2k12r2
```

The ``kubevirt.io/os`` label is based on the short OS identifier from [libosinfo](https://libosinfo.org/)
database.
The following Short IDs are currently supported:

| Short ID | Name | Version | Family | ID |
| --- | --- | --- | --- | --- |
| **win2k12r2** | Microsoft Windows Server 2012 R2 | 6.3 | winnt | http://microsoft.com/win/2k12r2 |


### Use with presets

A Virtual Machine Preset representing an operating system with a ``kubevirt.io/os`` label could be applied on any given
Virtual Machine that have and match the``kubevirt.io/os`` label.


