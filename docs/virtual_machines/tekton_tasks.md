# KubeVirt Tekton

## KubeVirt Tekton tasks operator (TTO)

### Prerequisites
- [Tekton](https://tekton.dev/)
- [KubeVirt](https://kubevirt.io/)
- [CDI](https://github.com/kubevirt/containerized-data-importer)

### Deploying TTO
[TTO](https://github.com/kubevirt/tekton-tasks-operator) is a Golang based operator, which takes care of deploying 
[kubevirt-tekton-tasks](https://github.com/kubevirt/kubevirt-tekton-tasks) and example pipelines.

TTO is shipped as a part of [hyperconverged-cluster-operator](https://github.com/kubevirt/hyperconverged-cluster-operator) 
or it can be deployed by the user as a stand-alone from the latest [release](https://github.com/kubevirt/tekton-tasks-operator/releases/latest).

!!! Note
    TTO requires [Tekton](https://tekton.dev/) to work.

!!! Note
    TTO does not deploy its resources by default.

The user has to enable `deployTektonTaskResources` feature gate in HCO CR to deploy all its resources

```console
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: kubevirt-hyperconverged
spec:
  featureGates:
    deployTektonTaskResources: true
```

or in TTO CR:
```console
apiVersion: tektontasks.kubevirt.io/v1alpha1
kind: TektonTasks
metadata:
  name: tektontasks
  namespace: kubevirt
spec:
  featureGates:
    deployTektonTaskResources: true
```

Once `spec.featureGates.deployTektonTaskResources` is set to `true`, TTO will not delete any cluster 
tasks or pipeline examples even if it is reverted back to false.

The user can set in which namespace example pipelines will be deployed by setting `spec.tektonPipelinesNamespace` in HCO CR:

```console
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: kubevirt-hyperconverged
spec:
  tektonPipelinesNamespace: userNamespace
```

or in TTO CR by setting `spec.pipelines.namespace`:
```console
apiVersion: tektontasks.kubevirt.io/v1alpha1
kind: TektonTasks
metadata:
  name: tektontasks
  namespace: kubevirt
spec:
  pipelines:
    namespace: userNamespace
```

## KubeVirt Tekton tasks 
### What are KubeVirt Tekton tasks?
KubeVirt-specific Tekton tasks, which are focused on:

- Creating and managing resources (VMs, DataVolumes)
- Executing commands in VMs
- Manipulating disk images with libguestfs tools

### Existing tasks

#### Create Virtual Machines
- create-vm-from-manifest - create a VM from provided manifest.
- create-vm-from-template - create a VM from template (works only on OpenShift).

#### Utilize Templates
- copy-template - Copies the given template and creates a new one (works only on OpenShift).
- modify-vm-template - Modifies a template with user provided data (works only on OpenShift).

#### Create DataVolumes
- create-datavolume-from-manifest - Create a datavolume from a manifest.

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

### Example pipeline
All these tasks can be used for creating [pipelines](https://github.com/tektoncd/pipeline/blob/main/docs/pipelines.md).
TTO is creating multiple example pipelines, e.g.:

- [Windows 10 installer](https://github.com/kubevirt/tekton-tasks-operator/blob/main/data/tekton-pipelines/okd/windows10-installer.yaml) - Pipeline will prepare a template and Windows 10 datavolume. User has to provide a link to working Windows 10 iso file.

- [Windows 10 customize](https://github.com/kubevirt/tekton-tasks-operator/blob/main/data/tekton-pipelines/okd/windows10-customize.yaml) - Pipeline will install sql server in windows 10 VM
