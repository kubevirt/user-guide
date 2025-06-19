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


Booting the kernel with a root file system can be done by specifying the root file system as a
[disk](https://kubevirt.io/user-guide/storage/disks_and_volumes/) (e.g. containerDisk):
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: ext-kernel-boot-vm
spec:
  runStrategy: Manual
  instancetype:
    name: u1.medium
  preference:
    name: fedora
  template:
    spec:
      domain:
        devices:
          disks:
            - name: kernel-modules
              cdrom:
                bus: sata
        firmware:
          kernelBoot:
            container:
              image: custom-containerdisk:latest
              initrdPath: /boot/initramfs
              kernelPath: /boot/vmlinuz
              imagePullPolicy: Always
            kernelArgs: "no_timer_check console=tty1 console=ttyS0,115200n8 systemd=off root=/dev/vda4 rootflags=subvol=root"
      volumes:
        - name: root-filesystem
          containerDisk:
            image: custom-containerdisk:latest
            imagePullPolicy: Always
        - name: kernel-modules
          containerDisk:
            image: custom-containerdisk:latest
            path: /boot/kernel-modules.isofs
            imagePullPolicy: Always
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |-
              #cloud-config
              chpasswd:
                expire: false
              password: fedora
              user: fedora
              runcmd:
                - "sudo mkdir /mnt/kernel-modules-disk"
                - "sudo mount /dev/sr0 /mnt/kernel-modules-disk"
                - "sudo tar -xvf /mnt/kernel-modules-disk/kernel_m.tgz --directory /usr/lib/modules/"
```

Notes:

- It is not necessary to package the root file system into the same `containerDisk` as the kernel. The file system
  could also be pulled in via something like a `dataVolumeDisk`.

- If the custom kernel was configured to build modules, we need to install these in the root file system. For this
  example the kernel modules were bundled into a tarball and packaged into an isofs. This isofs is then added to
  the `containerDisk` and unpacked into the root file system with the cloudinit runcmd.

- Following the [containerDisk Workflow Example](https://kubevirt.io/user-guide/storage/disks_and_volumes/#containerdisk-workflow-example),
  we need to add the initramfs, kernel, root file system and kernel modules isofs to our custom-containerdisk:
  ```dockerfile
  FROM scratch
  ADD --chown=107:107 initramfs /boot/
  ADD --chown=107:107 vmlinuz /boot/
  ADD --chown=107:107 https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2 /disk/
  ADD --chown=107:107 kernel-modules.isofs /boot/
  ```
- The `kernelArgs` must specify the correct root device. In this case, the arguments were simply copied from the cloud
  image's `/proc/cmdline`.
