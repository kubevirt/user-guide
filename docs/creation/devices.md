Virtualized Hardware Configuration
==================================

Fine-tuning different aspects of the hardware which are not device
related (BIOS, mainboard, …) is sometimes necessary to allow guest
operating systems to properly boot and reboot.

Machine Type
------------

QEMU is able to work with two different classes of chipsets for x86\_64,
so called machine types. The x86\_64 chipsets are i440fx (also called
pc) and q35. They are versioned based on qemu-system-latexmath:$ARCH,
following the format `pc-${machine_type}-${qemu_version}`,
e.g.`pc-i440fx-2.10` and `pc-q35-2.10`.

KubeVirt defaults to QEMU’s newest q35 machine type. If a custom machine
type is desired, it is configurable through the following structure:

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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

Comparison of the machine types’ internals can be found [at QEMU
wiki](https://wiki.qemu.org/Features/Q35).

BIOS/UEFI
---------

All virtual machines use BIOS by default for booting.

It is possible to utilize UEFI/OVMF by setting a value via
`spec.firmware.bootloader`:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      labels:
        special: vmi-alpine-efi
      name: vmi-alpine-efi
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
        firmware:
          # this sets the bootloader type
          bootloader:
            efi: {}

SecureBoot is not yet supported.

SMBIOS Firmware
---------------

In order to provide a consistent view on the virtualized hardware for
the guest OS, the SMBIOS UUID can be set to a constant value via
`spec.firmware.uuid`:

    metadata:
      name: myvmi
    spec:
      domain:
        firmware:
          # this sets the UUID
          uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
          serial: e4686d2c-6e8d-4335-b8fd-81bee22f4815
        resources:
          requests:
            memory: 512M
        devices:
          disks:
          - name: myimage
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

In addition, the SMBIOS serial number can be set to a constant value via
`spec.firmware.serial`, as demonstrated above.

CPU
---

**Note**: This is not related to scheduling decisions or resource
assignment.

### Topology

Setting the number of CPU cores is possible via `spec.domain.cpu.cores`.
The following VM will have a CPU with `3` cores:

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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

### Enabling cpu compatibility enforcement

To enable the cpu compatibility enforcement, user may expand the
`feature-gates` field in the kubevirt-config config map by adding the
`CPUNodeDiscovery` to it.

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      feature-gates: "CPUNodeDiscovery"
    ...

This feature-gate allows kubevirt to take VM cpu model and cpu features
and create node selectors from them. With these node selectors, VM can
be scheduled on the node which can support VM cpu model and features.

### Labeling nodes with cpu models and cpu features

To properly label the node, user can use (only for cpu models and cpu
features) [node-labeller](https://github.com/kubevirt/node-labeller) in
combination with
[cpu-nfd-plugin](https://github.com/kubevirt/cpu-nfd-plugin) or create
node labels by himself.

To install node-labeller to cluster, user can use
([kubevirt-ssp-operator](https://github.com/MarSik/kubevirt-ssp-operator)),
which will install node-labeller + all available plugins.

Cpu-nfd-plugin uses libvirt to get all supported cpu models and cpu
features on host and Node-labeller create labels from cpu models. Then
Kubevirt can schedule VM on node which has support for VM cpu model and
features.

Cpu-nfd-plugin supports black list of cpu models and minimal baseline
cpu model for features. Both features can be set via config map:

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cpu-plugin-configmap
    data:
      cpu-plugin-configmap.yaml: |-
        obsoleteCPUs:
          - "486"
          - "pentium"
        minCPU: "Penryn"

This config map has to be created before node-labeller is created,
otherwise plugin will show all cpu models. Plugin will not reload when
config map is changed.

Obsolete cpus will not be inserted in labels. In minCPU user can set
baseline cpu model. CPU features, which have this model, are used as
basic features. These basic features are not in the label list. Feature
labels are created as subtraction between set of newer cpu features and
set of basic cpu features, e.g.: Haswell has: aes, apic, clflush Penryr
has: apic, clflush subtraction is: aes. So label will be created only
with aes feature.

### Model

**Note**: Be sure that node CPU model where you run a VM, has the same
or higher CPU family.

**Note**: If CPU model wasn’t defined, the VM will have CPU model
closest to one that used on the node where the VM is running.

**Note**: CPU model is case sensitive.

Setting the CPU model is possible via `spec.domain.cpu.model`. The
following VM will have a CPU with the `Conroe` model:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      domain:
        cpu:
          # this sets the CPU model
          model: Conroe
    ...

You can check list of available models
[here](https://github.com/libvirt/libvirt/blob/master/src/cpu_map/index.xml).

When CPUNodeDiscovery feature-gate is enabled and VM has cpu model,
Kubevirt creates node selector with format:
`feature.node.kubernetes.io/cpu-model-<cpuModel>`, e.g.
`feature.node.kubernetes.io/cpu-model-Conroe`. When VM doesn’t have cpu
model, then no node selector is created.

#### Enabling default cluster cpu model

To enable the default cpu model, user may add the `default-cpu-model`
field in the kubevirt-config config map.

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      default-cpu-model: "EPYC"
    ...

Default CPU model is set when vmi doesn’t have any cpu model. When vmi
has cpu model set, then vmi’s cpu model is preferred. When default cpu
model is not set and vmi’s cpu model is not set too, `host-model` will
be set. Default cpu model can be changed when kubevirt is running. When
CPUNodeDiscovery feature gate is enabled Kubevirt creates node selector
with default cpu model.

#### CPU model special cases

As special cases you can set `spec.domain.cpu.model` equals to: -
`host-passthrough` to passthrough CPU from the node to the VM

    metadata:
      name: myvmi
    spec:
      domain:
        cpu:
          # this passthrough the node CPU to the VM
          model: host-passthrough
    ...

-   `host-model` to get CPU on the VM close to the node one

<!-- -->

    metadata:
      name: myvmi
    spec:
      domain:
        cpu:
          # this set the VM CPU close to the node one
          model: host-model
    ...

See the [CPU API
reference](https://libvirt.org/formatdomain.html#elementsCPU) for more
details.

### Features

Setting CPU features is possible via `spec.domain.cpu.features` and can
contain zero or more CPU features :

    metadata:
      name: myvmi
    spec:
      domain:
        cpu:
          # this sets the CPU features
          features:
          # this is the feature's name
          - name: "apic"
          # this is the feature's policy
           policy: "require"
    ...

**Note**: Policy attribute can either be omitted or contain one of the
following policies: force, require, optional, disable, forbid.

**Note**: In case a policy is omitted for a feature, it will default to
**require**.

Behaviour according to Policies:

-   All policies will be passed to libvirt during virtual machine
    creation.

-   In case the feature gate "CPUNodeDiscovery" is enabled and the
    policy is omitted or has "require" value, then the virtual machine
    could be scheduled only on nodes that support this feature.

-   In case the feature gate "CPUNodeDiscovery" is enabled and the
    policy has "forbid" value, then the virtual machine would **not** be
    scheduled on nodes that support this feature.

Full description about features and policies can be found
[here](https://libvirt.org/formatdomain.html#elementsCPU).

When CPUNodeDiscovery feature-gate is enabled Kubevirt creates node
selector from cpu features with format:
`feature.node.kubernetes.io/cpu-feature-<cpuFeature>`, e.g.
`feature.node.kubernetes.io/cpu-feature-apic`. When VM doesn’t have cpu
feature, then no node selector is created.

Clock
-----

### Guest time

Sets the virtualized hardware clock inside the VM to a specific time.
Available options are

-   **utc**

-   **timezone**

See the [Clock API
Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_clock)
for all possible configuration options.

#### utc

If `utc` is specified, the VM’s clock will be set to UTC.

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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

#### timezone

If `timezone` is specified, the VM’s clock will be set to the specified
local time.

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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

### Timers

-   **pit**

-   **rtc**

-   **kvm**

-   **hyperv**

A pretty common timer configuration for VMs looks like this:

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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

`hpet` is disabled,`pit` and `rtc` are configured to use a specific
`tickPolicy`. Finally, `hyperv` is made available too.

See the [Timer API
Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_timer)
for all possible configuration options.

**Note**: Timer can be part of a machine type. Thus it may be necessary
to explicitly disable them. We may in the future decide to add them via
cluster-level defaulting, if they are part of a QEMU machine definition.

Random number generator (RNG)
-----------------------------

You may want to use entropy collected by your cluster nodes inside your
guest. KubeVirt allows to add a `virtio` RNG device to a virtual machine
as follows.

    metadata:
      name: vmi-with-rng
    spec:
      domain:
        devices:
          rng: {}

For Linux guests, the `virtio-rng` kernel module should be loaded early
in the boot process to acquire access to the entropy source. Other
systems may require similar adjustments to work with the `virtio` RNG
device.

**Note**: Some guest operating systems or user payloads may require the
RNG device with enough entropy and may fail to boot without it. For
example, fresh Fedora images with newer kernels (4.16.4+) may require
the `virtio` RNG device to be present to boot to login.

Video and Graphics Device
-------------------------

By default a minimal Video and Graphics device configuration will be
applied to the VirtualMachineInstance. The video device is `vga`
compatible and comes with a memory size of 16 MB. This device allows
connecting to the OS via `vnc`.

It is possible not attach it by setting
`spec.domain.devices.autoattachGraphicsDevice` to `false`:

    metadata:
      name: myvmi
    spec:
      domain:
        devices:
          autoattachGraphicsDevice: false
          disks:
          - name: myimage
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimName: myclaim

VMIs without graphics and video devices are very often referenced as
`headless` VMIs.

If using a huge amount of small VMs this can be helpful to increase the
VMI density per node, since no memory needs to be reserved for video.

Features
--------

KubeVirt supports a range of virtualization features which may be
tweaked in order to allow non-Linux based operating systems to properly
boot. Most noteworthy are

-   **acpi**

-   **apic**

-   **hyperv**

A common feature configuration is shown by the following example:

    apiVersion: kubevirt.io/v1alpha3
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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimname: myclaim

See the [Features API
Reference](https://kubevirt.github.io/api-reference/master/definitions.html#_v1_features)
for all available features and configuration options.

Resources Requests and Limits
-----------------------------

An optional resource request can be specified by the users to allow the
scheduler to make a better decision in finding the most suitable Node to
place the VM.

    apiVersion: kubevirt.io/v1alpha3
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
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimname: myclaim

### CPU

Specifying CPU limits will determine the amount of *cpu* *shares* set on
the control group the VM is running in, in other words, the amount of
time the VM’s CPUs can execute on the assigned resources when there is a
competition for CPU resources.

For more information please refer to [how Pods with resource limits are
run](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#how-pods-with-resource-limits-are-run).

### Memory Overhead

Various VM resources, such as a video adapter, IOThreads, and
supplementary system software, consume additional memory from the Node,
beyond the requested memory intended for the guest OS consumption. In
order to provide a better estimate for the scheduler, this memory
overhead will be calculated and added to the requested memory.

Please see [how Pods with resource requests are
scheduled](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#how-pods-with-resource-requests-are-scheduled)
for additional information on resource requests and limits.

Hugepages
---------

KubeVirt give you possibility to use hugepages as backing memory for
your VM. You will need to provide desired amount of memory
`resources.requests.memory` and size of hugepages to use
`memory.hugepages.pageSize`, for example for x86\_64 architecture it can
be `2Mi`.

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
          disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimname: myclaim

In the above example the VM will have `64Mi` of memory, but instead of
regular memory it will use node hugepages of the size of `2Mi`.

### Limitations

-   a node must have pre-allocated hugepages

-   hugepages size cannot be bigger than requested memory

-   requested memory must be divisible by hugepages size

Input Devices
-------------

### Tablet

Kubevirt supports input devices. The only type which is supported is
`tablet`. Tablet input device supports only `virtio` and `usb` bus. Bus
can be empty. In that case, `usb` will be selected.

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachine
    metadata:
      name: myvm
    spec:
      domain:
        devices:
          inputs:
          - type: tablet
            bus: virtio
            name: tablet1
          disks:
          - name: myimage
            disk: {}
      volumes:
        - name: myimage
          persistentVolumeClaim:
            claimname: myclaim
