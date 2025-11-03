# Confidential computing

## AMD Secure Encrypted Virtualization (SEV)

**FEATURE STATE:** KubeVirt v0.49.0 (experimental support)

[Secure Encrypted Virtualization (SEV)](https://developer.amd.com/sev/) is a feature of AMD's EPYC CPUs that allows the memory of a virtual machine to be encrypted on the fly.

KubeVirt supports running confidential VMs on AMD EPYC hardware with SEV feature.

### Preconditions

In order to run an SEV guest the following condition must be met:

- `WorkloadEncryptionSEV` [feature gate](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate) must be enabled.
- The guest must support [UEFI boot](../compute/virtual_hardware.md#biosuefi)
- SecureBoot must be disabled for the guest VM

### Running an SEV guest

SEV memory encryption can be requested by setting the `spec.domain.launchSecurity.sev` element in the VMI definition:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    launchSecurity:
      sev: {}
    firmware:
      bootloader:
        efi:
          secureBoot: false
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      rng: {}
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: registry:5000/kubevirt/fedora-with-test-tooling-container-disk:devel
    name: containerdisk
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
    name: cloudinitdisk
```

### Current limitations

- SEV-encrypted VMs cannot contain directly-accessible host devices (that is, PCI passthrough)
- Live Migration is not supported
- The VMs are not attested

## AMD Secure Encrypted Virtualization - Secure Nested Paging (SEV-SNP)

**FEATURE STATE:** KubeVirt v1.7.0 (experimental support)


KubeVirt supports running confidential VMs on AMD EPYC hardware with SEV-SNP support. 

### Prerequisites

- `WorkloadEncryptionSEV` [feature gate](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate) must be enabled.
- The guest must support [UEFI boot](../compute/virtual_hardware.md#biosuefi).
- SecureBoot must be disabled for the guest VM.
- AMD EPYC hardware that is capable of running [SEV-SNP](https://docs.amd.com/v/u/en-US/58207-using-sev-with-amd-epyc-processors).

### Deploying AMD SEV-SNP enabled VMs

SEV-SNP memory encryption can be requested by setting the `spec.domain.launchSecurity.snp` element in the VMI definition:


```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  labels:
    special: vmi-fedora
  name: vmi-fedora
spec:
  domain:
    launchSecurity:
      snp: {}
    firmware:
      bootloader:
        efi:
          secureBoot: false
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
      - disk:
          bus: virtio
        name: cloudinitdisk
      rng: {}
    resources:
      requests:
        memory: 1024M
  terminationGracePeriodSeconds: 0
  volumes:
  - containerDisk:
      image: registry:5000/kubevirt/fedora-with-test-tooling-container-disk:devel
    name: containerdisk
  - cloudInitNoCloud:
      userData: |-
        #cloud-config
        password: fedora
        chpasswd: { expire: False }
    name: cloudinitdisk
```


### Limitations

- SEV/SEV-ES are mutually exclusive from SNP, running both SEV and SNP will not run.
- Uses default policy that QEMU uses (e.g Policy: 0x30000).
- Live Migration is not supported.
- The VMs are not attested.

## IBM Secure Execution for Linux (Secure Execution)

**FEATURE STATE:** KubeVirt v1.6.0 (experimental support)

IBM Secure Execution for Linux is a s390x security technology that is introduced with IBM z15 and LinuxONE III. It protects data of workloads that run in a KVM guest from being inspected or modified by the server environment.

In particular, no hardware administrator, no KVM code, and no KVM administrator can access the data in a guest that was started as an IBM Secure Execution guest.

For more details please read the [official documentation](https://www.ibm.com/docs/en/linux-on-systems?topic=execution-introduction).

### Prerequisites

- IBM z15/LinuxONE III or newer
- Kubernetes Cluster with LPAR worker nodes (No nested virtualization)
- Kubevirt and CDI deployed on the Cluster
- `SecureExecution` [feature gate](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate) must be enabled.
- Secure Execution prepared guest. See the [official docs](https://www.ibm.com/docs/en/linux-on-systems?topic=execution-workload-owner-tasks).

### Preparing the host(s)

On all LPAR worker nodes that should run Secure Execution VMs, the following steps need to be taken to enable them to host the workloads:

1. SSH to the node
2. Add `prot_virt=1` to the kernel cmdline:
  - Edit `zipl.conf`:
  ```
  # vi zipl.conf
  ...
  parameters=" ...prot_virt=1"
  ...
  ```
  - Run `zipl` to ensure the change is picked up during the next reboot
  - Reboot the node
3. Verify that Secure Execution is now enabled:
```
$ cat /sys/firmware/uv/prot_virt_host
1
```

### Running a Secure Execution Guest VM

Ensure that your workload is [uploaded to a data volume using CDI](../storage/containerized_data_importer.md#virtctl-image-upload).

Memory Protection via Secure Execution can be requested by setting `spec.domain.launchSecurity` element in the VMI definition.
```
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: secure-execution-vm
  name: secure-execution-vm
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: secure-execution-vm
    spec:
      domain:
        launchSecurity: {}
        devices:
          disks:
          - disk:
              bus: virtio
            name: rootfs
        resources:
          requests:
            memory: 4Gi
      terminationGracePeriodSeconds: 0
      volumes:
        - name: rootfs
          dataVolume:
            name: secure-execution-dv
```
### Limitations

As the host is not permitted to access the guest memory, certain features do not work with Secure Execution VMs
- live migration
  - VMs need to be moved offline instead
  - If moving between different machines, VMs need to be encrypted with hostkeys of both machines
- Saving and restoring VM from disk
- Memory dump
- Huge Pages
- Pass-through of host devices, for example PCI and CCW.
- Memory ballooning through a virtio-balloon device.
