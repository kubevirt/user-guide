# Virtualized Hardware Configuration

Finetuning different aspects of the hardware which are not device related \(BIOS, mainboard, ...\) is sometimes necessary to allow Guest Operating Systems to properly boot and reboot.

## Machine Type

QEMU is able to work with two different classes of chipsets for x86\_64, so called machine types. The x86\_64 chipsets are i440fx \(also called pc\) and q35. They are versioned based on qemu-system-$ARCH, following the format `pc-${machine_type}-${qemu_version}`, e.g. `pc-i440fx-2.10` and `pc-q35-2.10`.

KubeVirt defaults to QEMU's newest q35 machine type. If a custom machine type is desired, it is configurable via following structure:

```text
metadata:
  name: myvm
spec:
  domain:
    machine:
      # This value indicates QEMU machine type.
      type: pc-q35-2.10
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

Comparision of the machine types' internals can be found [at QEMU wiki](https://wiki.qemu.org/Features/Q35).

## BIOS/UEFI

All virtual machines currently use BIOS for booting. UEFI/OVMF is not yet supported.

## SMBIOS Firmware

In order to provide a consistent view on the virtualized hardware for the Guest OS, the SMBIOS UUID can be set to a constant value via `spec.firmware.uuid`:

```text
metadata:
  name: myvm
spec:
  domain:
    firmware:
      # this sets the UUID
      uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
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

Setting the number of cpu cores is possible via `spec.domain.cpu.cores`. The following vm will have a cpu with `3` cores:

```text
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

See the [Clock API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_clock) for all possible configuration options.

#### utc

If `utc` is specified, the vm clock will be set to utc.

```text
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

```text
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

```text
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

`hpet` is disabled,`pit` and `rtc` are configured to use a specific `tickPolicy`. Finally `hyperv` is made available too.

See the [Timer API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_timer) for all possible configuration options.

**Note**: Timer can be part of a machine type. Thus it may be necessary to explicitly disable them. We may in the future decide to add them via cluster-level defaulting, if they are part of a qemu machine definition.

## Features

KubeVirt supports a range of virtualization features which may be tweaked in order to allow non-linux based operating systems to properly boot. Most noteworthy are

* **acpi** 
* **apic**
* **hyperv**

A common feature configuration is shown by the following example:

```text
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

See the [Features API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_features) for all available features and configuration options.

## Resources Requests and Limits

An optional resource request can be specified by the users to allow the scheduler to make a better decision in finding the most suitable Node to place the Virtual Machine on.

```text
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: myvm
spec:
  domain:
    resources:
      requests:
        memory: "1Gi"
        cpu: "2"
      limits:
        memory: "2Gi"
        cpu: "1"
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimname: myclaim
```

#### CPU

Specifying CPU limits will determine the amount of cpu _shares_ set on the control group the Virtual Machine is running in, in other words, the amount of time Virtual Machine CPUs can execute on the assigned resources when there is a competition for CPU resources.

For more information please refer to [how Pods with resource limits are run](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#how-pods-with-resource-limits-are-run).

#### Memory Overhead

Various Virtual Machine resources, such as a video adapter, IOThreads, and supplementary system software, consume additional memory from the Node, beyond the requested memory intended for the guest OS consumption. In order to provide a better estimate for the scheduler, this memory overhead will be calculated and added to the requested memory.

Please see [how Pods with resource requests are scheduled](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#how-pods-with-resource-requests-are-scheduled) for additional information on resources requests and limits.

