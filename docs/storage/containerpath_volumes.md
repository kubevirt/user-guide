# ContainerPath Volumes

ContainerPath volumes allow VirtualMachines to access files and directories from the virt-launcher pod's filesystem via virtiofs. This enables VMs to consume data that is dynamically injected into the pod by Kubernetes or platform-specific mechanisms such as cloud provider workload identity webhooks.

## Enabling ContainerPath volumes

ContainerPath volume support must be enabled via the `ContainerPathVolumes`
[feature gate](../cluster_admin/activating_feature_gates.md#how-to-activate-a-feature-gate)
in the KubeVirt CR:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
      - ContainerPathVolumes
```

## Motivation

Kubernetes and cloud platforms provide mechanisms for injecting credentials into pods at runtime:

- **Projected service account tokens** for workload identity (e.g., AWS IRSA, Azure Workload Identity)
- **Dynamic secrets** via admission webhooks (e.g., HashiCorp Vault agent, cert-manager)
- **Confidential computing** attestation tokens and runtime secrets injected by platform infrastructure

These mechanisms inject data directly into pod containers, but VMs running inside those pods cannot natively access this injected data. ContainerPath volumes bridge this gap by exposing specific paths from the virt-launcher container to the guest VM via virtiofs.

## Basic usage

A ContainerPath volume requires two things in the VM spec:

1. A **volume** entry with a `containerPath` source specifying the path inside the virt-launcher pod
2. A corresponding **filesystem** device entry referencing the volume by name

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: my-vm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          filesystems:
          - name: my-data
            virtiofs: {}
          disks:
          - name: containerdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 1Gi
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/fedora:latest
      - name: my-data
        containerPath:
          path: /path/to/data
```

Inside the guest VM, mount the filesystem:

```bash
mount -t virtiofs my-data /mnt/data
```

## Example: AWS IRSA

A common use case is enabling VMs to authenticate to AWS using IAM Roles for Service Accounts (IRSA).

When a pod uses a ServiceAccount with an IRSA annotation, EKS automatically injects a projected token at `/var/run/secrets/eks.amazonaws.com/serviceaccount/`. The VM can access this token via a ContainerPath volume.

For AWS IRSA setup prerequisites, see the [Amazon EKS IRSA documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

First, create a ServiceAccount annotated for IRSA:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-workload-sa
  annotations:
    eks.amazonaws.com/role-arn: "<iam-role-arn>"
```

Then create a VirtualMachine that uses that ServiceAccount and exposes the injected token via a ContainerPath volume:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: aws-workload
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          filesystems:
          - name: sa-volume
            virtiofs: {}
          - name: aws-token
            virtiofs: {}
          disks:
          - name: containerdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 2Gi
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/fedora:latest
      - name: sa-volume
        serviceAccount:
          serviceAccountName: aws-workload-sa
      - name: aws-token
        containerPath:
          path: /var/run/secrets/eks.amazonaws.com/serviceaccount
```

**Why both volumes?**

- `sa-volume`: Ensures the virt-launcher pod uses the IRSA-annotated ServiceAccount, which triggers token injection.
- `aws-token`: Exposes the injected EKS token path to the VM via virtiofs.

Inside the VM:

```bash
# Mount the IRSA token filesystem
mount -t virtiofs aws-token /mnt/aws-creds

# Configure AWS SDK to use web identity token
export AWS_WEB_IDENTITY_TOKEN_FILE=/mnt/aws-creds/token
export AWS_ROLE_ARN="<iam-role-arn>"

# AWS CLI and SDKs will use these credentials
aws s3 ls
```

## Example: Azure Workload Identity

Azure Workload Identity injects a federated token into pods at `/var/run/secrets/azure/tokens`. To enable this, the pod template must include the label `azure.workload.identity/use: "true"` and use a ServiceAccount annotated with the Azure managed identity client ID.

For Azure Workload Identity setup prerequisites, see the [AKS workload identity documentation](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview).

First, create a ServiceAccount for workload identity:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: azure-workload-sa
  annotations:
    azure.workload.identity/client-id: "<managed-identity-client-id>"
    # Optional if tenant is configured cluster-wide:
    # azure.workload.identity/tenant-id: "<tenant-id>"
```

The Azure managed identity must also have a federated credential for this ServiceAccount subject (for example, `system:serviceaccount:<namespace>:azure-workload-sa`).

Then create a VirtualMachine that uses this ServiceAccount and exposes the injected token path:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: azure-workload
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      domain:
        devices:
          filesystems:
          - name: sa-volume
            virtiofs: {}
          - name: az-token
            virtiofs: {}
          disks:
          - name: containerdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 2Gi
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/containerdisks/fedora:latest
      - name: sa-volume
        serviceAccount:
          serviceAccountName: azure-workload-sa
      - name: az-token
        containerPath:
          path: /var/run/secrets/azure/tokens
```

**Why both volumes?**

- `sa-volume`: Ensures the virt-launcher pod uses the workload identity ServiceAccount, which triggers token injection.
- `az-token`: Exposes the injected Azure token path to the VM via virtiofs.

Inside the VM:

```bash
# Mount the Azure token filesystem
mount -t virtiofs az-token /mnt/az-creds

# Configure Azure SDK to use workload identity token
export AZURE_FEDERATED_TOKEN_FILE=/mnt/az-creds/azure-identity-token
export AZURE_CLIENT_ID="<managed-identity-client-id>"

# Azure CLI and SDKs can use these credentials
```

## Webhook-injected volumes

Admission webhooks can inject volumes into virt-launcher pods. Use ContainerPath to expose these to VMs:

```yaml
volumes:
- name: injected-config
  containerPath:
    path: /opt/injected-config
```

A corresponding filesystem device is also required in `spec.domain.devices.filesystems`.

## Path requirements

- The specified `path` must be an absolute path that exists within the virt-launcher pod's `compute` container
- The path must correspond to (or be a subpath of) a volumeMount in the compute container
- The path should exist before VM startup, or be continuously populated by a sidecar or webhook-injected mechanism
- Paths containing `..` components or symlinks that would escape the volumeMount boundary are rejected
- Paths are read-only from the VM's perspective
- The path must not conflict with KubeVirt-internal mount points

## Supported volume types

ContainerPath volumes only support paths backed by the following Kubernetes volume types:

| Volume Type | Description |
|---|---|
| ConfigMap | Configuration data |
| Secret | Sensitive data like credentials |
| Projected | Combinations of ConfigMaps, Secrets, DownwardAPI, and ServiceAccountToken |
| DownwardAPI | Pod and container metadata |
| EmptyDir | Ephemeral pod-local storage |

Other volume types (PVC, HostPath, etc.) are not supported.

## Live migration

ContainerPath volumes do not block live migration, but whether the data remains accessible after migration depends on how the path is populated:

**Generally works with migration:**

- **Secrets, ConfigMaps, ServiceAccount tokens** — Kubernetes re-projects these on the target node
- **Sidecar-populated volumes** — If a sidecar container populates the path (e.g., Vault agent), the sidecar runs on the target node and repopulates the data

**Does not work with migration:**

- **EmptyDir volumes without sidecars** — Data is not copied to the target node

When using ContainerPath volumes with live migration, verify that the mechanism populating your container path will function correctly on the target node.

## Security considerations

- VMs gain access to any files within the specified container path — only expose paths containing data intended for VM consumption
- Use RBAC and admission policies to control which service accounts and roles can be used with VMs
- ContainerPath volumes inherit the security context of the virt-launcher pod
- Only [supported volume types](#supported-volume-types) are allowed

## Troubleshooting

### VM has Synchronized=False with MissingVirtiofsContainers

If a VM reports `Synchronized=False` with reason `MissingVirtiofsContainers`, the specified path does not exist in the virt-launcher pod.

Check the path in the compute container:

```bash
kubectl exec -n <namespace> <virt-launcher-pod> -c compute -- ls -la /path/to/volume
```

Common causes:

- Typo in the `path` field
- The expected volume was not injected (check the pod spec with `kubectl get pod <virt-launcher-pod> -o yaml`)
- Timing issue: the path is populated after virtiofs initialization
- The `ContainerPathVolumes` feature gate is not enabled
