# Virtualized Hardware Configuration

Fine-tuning different aspects of the hardware which are not device related \(BIOS, mainboard, ...\) is sometimes necessary to allow guest operating systems to properly boot and reboot.

## Machine Type

QEMU is able to work with two different classes of chipsets for x86\_64, so called machine types. The x86\_64 chipsets are i440fx \(also called pc\) and q35. They are versioned based on qemu-system-$ARCH, following the format `pc-${machine_type}-${qemu_version}`, e.g. `pc-i440fx-2.10` and `pc-q35-2.10`.

KubeVirt defaults to QEMU's newest q35 machine type. If a custom machine type is desired, it is configurable through the following structure:

```yaml
metadata:
  name: myvmi
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

Comparison of the machine types' internals can be found [at QEMU wiki](https://wiki.qemu.org/Features/Q35).

## BIOS/UEFI

All virtual machines currently use BIOS for booting. UEFI/OVMF is not yet supported.

## SMBIOS Firmware

In order to provide a consistent view on the virtualized hardware for the guest OS, the SMBIOS UUID can be set to a constant value via `spec.firmware.uuid`:

```yaml
metadata:
  name: myvmi
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

### Topology

Setting the number of CPU cores is possible via `spec.domain.cpu.cores`. The following VM will have a CPU with `3` cores:

```yaml
metadata:
  name: myvmi
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

### Model

**Note**: Be sure that node CPU model where you run a VM, has the same or higher CPU family.

**Note**: If CPU model wasn't defined, the VM will have CPU model closest to one that used on the node where the VM is running.

Setting the CPU model is possible via `spec.domain.cpu.model`. The following VM will have a CPU with the `Conroe` model:

```yaml
metadata:
  name: myvmi
spec:
  domain:
    cpu:
      # this sets the CPU model
      model: Conroe
...
```

You can check list of available models [here](https://github.com/libvirt/libvirt/blob/master/src/cpu_map/index.xml).

#### CPU model special cases

As special cases you can set `spec.domain.cpu.model` equals to:
- `host-passthrough` to passthrough CPU from the node to the VM
```yaml
metadata:
  name: myvmi
spec:
  domain:
    cpu:
      # this passthrough the node CPU to the VM
      model: host-passthrough
...
```
- `host-model` to get CPU on the VM close to the node one
```yaml
metadata:
  name: myvmi
spec:
  domain:
    cpu:
      # this set the VM CPU close to the node one
      model: host-model
...
```

See the [CPU API reference](https://libvirt.org/formatdomain.html#elementsCPU) for more details.

## Clock

### Guest time

Sets the virtualized hardware clock inside the VM to a specific time. Available options are

* **utc**
* **timezone**

See the [Clock API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_clock) for all possible configuration options.

#### utc

If `utc` is specified, the VM's clock will be set to UTC.

```yaml
metadata:
  name: myvmi
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

If `timezone` is specified, the VM's clock will be set to the specified local time.

```yaml
metadata:
  name: myvmi
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

A pretty common timer configuration for VMs looks like this:

```yaml
metadata:
  name: myvmi
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

`hpet` is disabled,`pit` and `rtc` are configured to use a specific `tickPolicy`. Finally, `hyperv` is made available too.

See the [Timer API Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_timer) for all possible configuration options.

**Note**: Timer can be part of a machine type. Thus it may be necessary to explicitly disable them. We may in the future decide to add them via cluster-level defaulting, if they are part of a QEMU machine definition.

## Video and Graphics Device

By default a minimal Video and Graphics device configuration will be applied to
the VirtualMachineInstance. The video device is `vga` compatible and comes with
a memory size of 16 MB. This device allows connecting to the OS via `vnc`.

It is possible not attach it by setting
`spec.domain.devices.autoattachGraphicsDevice` to `false`:

```yaml
metadata:
  name: myvmi
spec:
  domain:
    devices:
      autoattachGraphicsDevice: false
      disks:
      - name: myimage
        volumeName: myimage
        disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimName: myclaim
```

VMIs without graphics and video devices are very often referenced as `headless`
VMIs.

If using a huge amount of small VMs this can be helpful to increase the VMI
density per node, since no memory needs to be reserved for video.

## Features

KubeVirt supports a range of virtualization features which may be tweaked in order to allow non-Linux based operating systems to properly boot. Most noteworthy are

* **acpi** 
* **apic**
* **hyperv**

A common feature configuration is shown by the following example:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: myvmi
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

An optional resource request can be specified by the users to allow the scheduler to make a better decision in finding the most suitable Node to place the VM.

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: myvmi
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

Specifying CPU limits will determine the amount of _cpu_ _shares_ set on the control group the VM is running in, in other words, the amount of time the VM's CPUs can execute on the assigned resources when there is a competition for CPU resources.

For more information please refer to [how Pods with resource limits are run](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#how-pods-with-resource-limits-are-run).

#### Memory Overhead

Various VM resources, such as a video adapter, IOThreads, and supplementary system software, consume additional memory from the Node, beyond the requested memory intended for the guest OS consumption. In order to provide a better estimate for the scheduler, this memory overhead will be calculated and added to the requested memory.

Please see [how Pods with resource requests are scheduled](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#how-pods-with-resource-requests-are-scheduled) for additional information on resource requests and limits.

## Hugepages

KubeVirt give you possibility to use hugepages as backing memory for your VM. You will need to provide desired amount of memory `resources.requests.memory` and size of hugepages to use `memory.hugepages.pageSize`, for example for x86_64 architecture it can be `2Mi`.

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: myvm
spec:
  domain:
    resources:
      requests:
        memory: "64Mi"
    memory:
      hugepages:
        pageSize: "2Mi"
    disks:
    - name: myimage
      volumeName: myimage
      disk: {}
  volumes:
    - name: myimage
      persistentVolumeClaim:
        claimname: myclaim
```

In the above example the VM will have `64Mi` of memory, but instead of regular memory it will use node hugepages of the size of `2Mi`.

#### Limitations

- a node must have pre-allocated hugepages
- hugepages size cannot be bigger than requested memory
- requested memory must be divisible by hugepages size

