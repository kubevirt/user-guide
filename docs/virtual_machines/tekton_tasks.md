# KubeVirt Tekton

### Prerequisites
- [Tekton](https://tekton.dev/)
- [KubeVirt](https://kubevirt.io/)
- [CDI](https://github.com/kubevirt/containerized-data-importer)
- [SSP](https://github.com/kubevirt/ssp-operator)

### Deploying SSP
[SSP](https://github.com/kubevirt/ssp-operator) is a Golang based operator, which takes care of deploying 
[kubevirt-tekton-tasks](https://github.com/kubevirt/kubevirt-tekton-tasks) and example pipelines.

SSP is shipped as a part of [hyperconverged-cluster-operator](https://github.com/kubevirt/hyperconverged-cluster-operator) 
or it can be deployed as a stand-alone operator from the latest [release](https://github.com/kubevirt/ssp-operator/releases/latest).

**Note:** SSP requires [Tekton](https://tekton.dev/) to work.

SSP does not deploy KubeVirt Tekton tasks resources by default.

You have to enable `deployTektonTaskResources` feature gate in HCO CR to deploy all its resources:

```yaml
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: kubevirt-hyperconverged
spec:
  featureGates:
    deployTektonTaskResources: true
```

or in SSP CR:
```yaml
apiVersion: ssp.kubevirt.io/v1beta2
kind: SSP
metadata:
  name: ssp
  namespace: kubevirt
spec:
  featureGates:
    deployTektonTaskResources: true
```
or you can use this command to enable `deployTektonTaskResources` feature gate in HCO CR
```console
oc patch hco kubevirt-hyperconverged  --type=merge -p '{"spec":{"featureGates": {"deployTektonTaskResources": true}}}'
```
or by applying a patch on an existing SSP CR:
```console
oc patch ssp ssp  --type=merge -p '{"spec":{"featureGates": {"deployTektonTaskResources": true}}}'
```

**Note:** Once `spec.featureGates.deployTektonTaskResources` is set to `true`, SSP will not delete any tasks or pipeline examples even if it is reverted back to false.

## KubeVirt Tekton tasks 
### What are KubeVirt Tekton tasks?
KubeVirt-specific Tekton tasks, which are focused on:

- Creating and managing resources (VMs, DataVolumes)
- Executing commands in VMs
- Manipulating disk images with libguestfs tools

### Existing tasks

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

### Example pipeline
All these tasks can be used for creating [pipelines](https://github.com/tektoncd/pipeline/blob/main/docs/pipelines.md).
SSP is creating multiple example pipelines, e.g.:

- [Windows BIOS installer](https://github.com/kubevirt/ssp-operator/blob/main/data/tekton-pipelines/windows-bios-installer-pipeline.yaml) - Pipeline will prepare a template and Windows datavolume vith virtio drivers installed. User has to provide a link to working Windows 10 iso file. Pipeline is suitable 
for Windows versions, which uses BIOS. More informations about pipeline can be found [here](https://github.com/kubevirt/kubevirt-tekton-tasks/tree/main/examples/pipelines/windows-bios-installer)

- [Windows efi installer](https://github.com/kubevirt/ssp-operator/blob/main/data/tekton-pipelines/windows-efi-installer-pipeline.yaml) - Pipeline will prepare a template and Windows 11/2k22 datavolume vith virtio drivers installed. User has to provide a link to working Windows 11/2k22 iso file. Pipeline is suitable for Windows versions, which requires EFI (e.g. Windows 11/2k22). More informations about pipeline can be found [here](https://github.com/kubevirt/kubevirt-tekton-tasks/tree/main/examples/pipelines/windows-efi-installer)

- [Windows customize](https://github.com/kubevirt/ssp-operator/blob/main/data/tekton-pipelines/windows-customize-pipeline.yaml) - Pipeline will install SQL server or VS Code in Windows VM. More informations about pipeline can be found [here](https://github.com/kubevirt/kubevirt-tekton-tasks/tree/main/examples/pipelines/windows-customize)

### Using tasks and example pipelines in different namespace
You can set in which namespace the example pipelines and tasks will be deployed by setting `spec.tektonPipelinesNamespace` or `spec.tektonTasksNamespace`in the HCO CR:

```yaml
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: kubevirt-hyperconverged
spec:
  tektonPipelinesNamespace: userNamespace
  tektonTasksNamespace: userNamespace
```

or in SSP CR by setting `spec.tektonPipelines.namespace` or `spec.tektonTasks.namespace`:
```yaml
apiVersion: ssp.kubevirt.io/v1beta2
kind: SSP
metadata:
  name: ssp
  namespace: kubevirt
spec:
  tektonPipelines:
    namespace: kubevirt
  tektonTasks:
    namespace: kubevirt
```

!!! note
    - The namespace has to exists before doing this change. <br />
    - If you define different namespace for pipelines and different namespace for tasks, you will have to create [cluster resolver](https://tekton.dev/docs/pipelines/cluster-resolver/) object. <br />
    - In case you change the `tektonPipelinesNamespace` attribute, the pipelines will be deployed in that namespace. <br />
    - By default, example pipelines create the result datavolume in `kubevirt-os-images`. <br />
    - In case you would like to create result datavolume in different namespace (by specifying `baseDvNamespace` attribute in pipeline), there will be required additional RBAC permissions (list of all required RBAC permissions can be found [here](https://github.com/kubevirt/ssp-operator/blob/master/data/tekton-pipelines/pipelines-rbac.yaml)).
