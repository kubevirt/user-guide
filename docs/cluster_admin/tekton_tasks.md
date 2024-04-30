# KubeVirt Tekton

### Prerequisites
- [Tekton](https://tekton.dev/)
- [KubeVirt](https://kubevirt.io/)
- [CDI](https://github.com/kubevirt/containerized-data-importer)

## KubeVirt Tekton Tasks 
### What are KubeVirt Tekton Tasks?
KubeVirt-specific Tekton Tasks, which are focused on:

- Creating and managing resources (VMs, DataVolumes)
- Executing commands in VMs
- Manipulating disk images with libguestfs tools

KubeVirt Tekton Tasks and example Pipelines are available in [artifacthub.io](https://artifacthub.io/packages/search?org=kubevirt&sort=relevance&page=1) from where you can easily deploy them to your cluster.

### Existing Tasks

#### Create Virtual Machines
- create-vm-from-manifest - create a VM from provided manifest or with virtctl.
- create-vm-from-template - create a VM from template (works only on OpenShift).

#### Utilize Templates
- copy-template - Copies the given template and creates a new one (works only on OpenShift).
- modify-vm-template - Modifies a template with user provided data (works only on OpenShift).

#### Modify Data Objects
- modify-data-object - Creates / modifies / deletes a datavolume / datasource

#### Generate SSH Keys
- generate-ssh-keys - Generates a private and public key pair, and injects it into a VM.

#### Execute commands in Virtual Machines
- execute-in-vm - Execute commands over SSH in a VM.
- cleanup-vm - Execute commands and/or stop/delete VMs.

#### Manipulate PVCs with libguestfs tools
- disk-virt-customize - execute virt-customize commands in PVCs.
- disk-virt-sysprep- execute virt-sysprep commands in PVCs.

#### Wait for Virtual Machine Instance Status
- wait-for-vmi-status - Waits for a VMI to be running.

#### Modify Windows iso
- modify-windows-iso-file - modifies windows iso (replaces prompt bootloader with no-prompt bootloader) and replaces original iso 
  in PVC with updated one. This helps with automated installation of Windows in EFI boot mode. By default Windows in EFI boot mode 
  uses a prompt bootloader, which will not continue with the boot process until a key is pressed. By replacing it with the non-prompt 
  bootloader no key press is required to boot into the Windows installer.

### Example Pipeline
All these Tasks can be used for creating [Pipelines](https://github.com/tektoncd/pipeline/blob/main/docs/pipelines.md).
We prepared example Pipelines which show what can you do with the KubeVirt Tasks.

- [Windows efi installer](https://github.com/kubevirt/kubevirt-tekton-tasks/blob/main/release/pipelines/windows-efi-installer/windows-efi-installer.yaml) - This Pipeline will prepare a Windows 10/11/2k22 datavolume with virtio drivers installed. User has to provide a working link to a Windows 10/11/2k22 iso file. The Pipeline is suitable for Windows versions, which requires EFI (e.g. Windows 10/11/2k22). More information about Pipeline can be found [here](https://github.com/kubevirt/kubevirt-tekton-tasks/blob/main/release/pipelines/windows-efi-installer/README.md)

- [Windows customize](https://github.com/kubevirt/kubevirt-tekton-tasks/blob/main/release/pipelines/windows-customize/windows-customize.yaml) - This Pipeline will install a SQL server or a VS Code in a Windows VM. More information about Pipeline can be found [here](https://github.com/kubevirt/kubevirt-tekton-tasks/blob/main/release/pipelines/windows-customize/README.md)

!!! note
    - If you define a different namespace for Pipelines and a different namespace for Tasks, you will have to create a [cluster resolver](https://tekton.dev/docs/pipelines/cluster-resolver/) object. <br />
    - By default, example Pipelines create the resulting datavolume in the `kubevirt-os-images` namespace. <br />
    - In case you would like to create resulting datavolume in different namespace (by specifying `baseDvNamespace` attribute in Pipeline), additional RBAC permissions will be required (list of all required RBAC permissions can be found [here](https://github.com/kubevirt/kubevirt-tekton-tasks/tree/main/release/tasks/modify-data-object#usage-in-different-namespaces)). <br />
    - In case you would like to live migrate the VM while a given Pipeline is running, the following [prerequisities](../operations/live_migration.md#limitations) must be met 
