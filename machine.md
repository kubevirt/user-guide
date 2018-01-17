# Virtualized Hardware Configuration

Finetuning different aspects of the hardware which are not device related
(BIOS, mainboard, ...) is sometimes necessary to allow Guest Operating Systems
to properly boot and reboot.

## SMBIOS Firmware

In order to provide a consistent view on the virtualized hardware for the Guest
OS, the SMBIOS UUID can be set to a constant value via `spec.firmware.uid`:

```
metadata:
  name: myvm
spec:
  domain:
    firmware:
      # this sets the UUID
      uid: 5d307ca9-b3ef-428c-8861-06e72d69f223
    resources:
      requests:
        memory: 512M
    devices:
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimName: myclaim
```

## CPU

**Note**: This is not related to scheduling decisions or resource assignment.

Setting the number of cpu cores is possible via `spec.domain.cpu.cores`.  The
following vm will have a cpu with `3` cores:

```
metadata:
  name: myvm
spec:
  domain:
    cpu:
      # this sets the cores
      cores: 3
    resources:
      requests:
        memory: 512M
    devices:
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimName: myclaim
```

## Clock

### Guest time

Sets the virtualized hardware clock inside the vm to a specific time. Available are

 * **utc**
 * **timezone**

See the [Clock API Reference](https://kubevirt-incubator.github.io/api-reference/master/definitions.html#_v1_clock)
for all possible configuration options.

#### utc

If `utc` is specified, the vm clock will be set to utc.

```
metadata:
  name: myvm
spec:
  domain:
    clock:
      utc: {}
    resources:
      requests:
        memory: 512M
    devices:
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimName: myclaim
```

#### timezone

If `timezone` is specified, the vm clock will be set to the specified local time.

```
metadata:
  name: myvm
spec:
  domain:
    clock:
      timezone: "America/New York"
    resources:
      requests:
        memory: 512M
    devices:
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimName: myclaim
```

### Timers

 * **pit**
 * **rtc**
 * **kvm**
 * **hyperv**

A pretty common timer configuration for vms looks like this:

```
metadata:
  name: myvm
spec:
  domain:
    clock:
      utc: {}
      # here are the timer
      timer:
        hpet:
          present: false
        pit:
          tickPolicy: delay
        rtc:
          tickPolicy: catchup
        hyperv: {}
    resources:
      requests:
        memory: 512M
    devices:
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimName: myclaim
```

`hpet` is disabled,`pit` and `rtc` are configured to use a specific
`tickPolicy`. Finally `hyperv` is made available too.

See the [Timer API Reference](https://kubevirt-incubator.github.io/api-reference/master/definitions.html#_v1_timer)
for all possible configuration options.

**Note**: Timer can be part of a machine type. Thus it may be necessary to
explicitly disable them. We may in the future decide to add them via
cluster-level defaulting, if they are part of a qemu machine definition.

## Features

KubeVirt supports a range of virtualization features which may be tweaked in
order to allow non-linux based operating systems to properly boot. Most
noteworthy are

 * **acpi** 
 * **apic**
 * **hyperv**

A common feature configuration is shown by the following example:

```
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: myvm
spec:
  domain:
    # typical features 
    features:
      acpi: {}
      apic: {}
      hyperv:
        relaxed: {}
        vapic: {}
        spinlocks:
          spinlocks: 8191
    resources:
      requests:
        memory: 512M
    devices:
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimname: myclaim
```

See the [Features API Reference](https://kubevirt-incubator.github.io/api-reference/master/definitions.html#_v1_features)
for all available features and configuration options.
