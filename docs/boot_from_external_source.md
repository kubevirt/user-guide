# Booting From External Source

When installing a new guest virtual machine OS, it is often useful to boot directly from a kernel and initrd stored in
the host physical machine OS, allowing command line arguments to be passed directly to the installer.

Booting from an external source is supported in Kubevirt starting from [version v0.42.0-rc.0](https://github.com/kubevirt/kubevirt/releases/tag/v0.42.0-rc.0).
This enables the capability to define a Virtual Machine that will use a custom kernel / initrd binary, with possible
custom arguments, during its boot process.

The binaries are provided though a container image.
The container is pulled from the container registry and resides on the local node hosting the VMs.

## Use cases
Some use cases for this may be:
- For a kernel developer it may be very convenient to launch VMs that are defined to boot from the latest kernel binary
that is often being changed.
- Initrd can be set with files that need to reside on-memory during all the VM's life-cycle.

## Workflow
Defining an external boot source can be done in the following way:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: ext-kernel-boot-vm
spec:
  runStrategy: Manual
  template:
    spec:
      domain:
        devices: {}
        firmware:
          kernelBoot:
            container:
              image: vmi_ext_boot/kernel_initrd_binaries_container:latest
              initrdPath: /boot/initramfs-virt
              kernelPath: /boot/vmlinuz-virt
              imagePullPolicy: Always
              imagePullSecret: IfNotPresent
            kernelArgs: console=ttyS0
        resources:
          requests:
            memory: 1Gi
```

Notes:

- `initrdPath` and `kernelPath` define the path for the binaries inside the container.

- Kernel and Initrd binaries must be owned by `qemu` user & group.
  - To change ownership: `chown qemu:qemu <binary>` when `<binary>` is the binary file.

- `kernelArgs` can only be provided if a kernel binary is provided (i.e. `kernelPath` not defined). These
arguments will be passed to the default kernel the VM boots from.
  
- `imagePullSecret` and `imagePullPolicy` are optional

- if `imagePullPolicy` is `Always` and the container image is updated then the VM will be booted
  into the new kernel when VM restarts
  
