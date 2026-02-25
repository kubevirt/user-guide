# VirtualMachine Templates

**FEATURE STATE:**

* `template.kubevirt.io/v1alpha1` (Alpha) as of the [
  `v1.8.0`](https://github.com/kubevirt/kubevirt/releases/tag/v1.8.0) KubeVirt
  release

## Introduction

`VirtualMachineTemplates` provide native, in-cluster VM templating for KubeVirt.
They allow you to define reusable VM blueprints with parameterized values that
can be processed to create `VirtualMachine` objects.

Unlike external templating tools such as Helm or Kustomize,
`VirtualMachineTemplates` can capture storage state (e.g. `DataVolume` snapshots
and cloned disks) that external tools cannot represent. They also work on any
Kubernetes cluster without requiring OpenShift.

!!! Note
    A legacy templating mechanism based on OpenShift Templates can be found on
    OpenShift clusters. See [Templates](templates.md) for details. New deployments
    should use the native `VirtualMachineTemplate` feature described on this page.

### When to use templates vs instancetypes and preferences

For simple VMs where you only need to standardize CPU, memory, and device
preferences, use
[VirtualMachineInstancetype and VirtualMachinePreference](instancetypes.md).
Templates become valuable when you also need to template cluster-specific
resources like networks, volumes, and `DataVolume` sources, things
which instancetypes and preferences cannot cover.

Templates and instancetypes and preferences can also be
[used together](#example) for maximum flexibility.

### CRDs

The feature introduces two Custom Resource Definitions:

- **`VirtualMachineTemplate`**: defines a reusable VM blueprint with parameters
- **`VirtualMachineTemplateRequest`**: creates a template from an existing VM
  (golden image workflow)

## Enabling the feature

The Template feature is an Alpha feature gate and must be explicitly enabled in
the `KubeVirt` CR. This requires KubeVirt v1.8.0 or later. The `Snapshot`
feature gate is also required as a dependency.

Enable both feature gates by patching the `KubeVirt` CR:

```shell
$ kubectl patch kubevirt kubevirt -n kubevirt --type merge -p '{"spec":{"configuration":{"developerConfiguration":{"featureGates":["Snapshot","Template"]}}}}'
```

Or add them to your `KubeVirt` CR YAML:

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
        - Snapshot
        - Template
```

Once enabled, KubeVirt automatically deploys the required components for native
`VirtualMachineTemplates`.

For more details on feature gates, see
[Activating feature gates](../cluster_admin/activating_feature_gates.md).

!!! Note
    The `virtctl template` subcommands require virtctl v1.8.0 or later.

## VirtualMachineTemplate

### Overview

A `VirtualMachineTemplate` is a namespaced resource in the
`template.kubevirt.io/v1alpha1` API group.

It consists of:

- **`spec.parameters`**: a list of parameters that can be substituted when
  processing the template
- **`spec.virtualMachine`**: the `VirtualMachine` spec blueprint with parameter
  placeholders
- **`spec.message`**: an optional message returned after processing

### Parameters

Each parameter in `spec.parameters` supports the following fields:

| Field         | Description                                                                |
|---------------|----------------------------------------------------------------------------|
| `name`        | The parameter name, used as `${NAME}` placeholder in the VM spec           |
| `value`       | Default value if the parameter is not provided during processing           |
| `generate`    | Set to `expression` to auto-generate a value using the `from` pattern      |
| `from`        | A regular expression pattern used to generate values (requires `generate`) |
| `required`    | If `true`, the parameter must be provided and has no default               |
| `displayName` | Human-readable name for UI display                                         |
| `description` | Description of the parameter's purpose                                     |

**Static parameters** have a fixed default value:

```yaml
- name: INSTANCETYPE
  value: u1.medium
  description: Instance type for the VM
```

**Required parameters** must be provided during processing:

```yaml
- name: PASSWORD
  required: true
  description: Password for the cloud-init user
```

**Generated parameters** produce random values based on a pattern:

```yaml
- name: NAME
  generate: expression
  from: "fedora-[a-z0-9]{16}"
  description: Unique VM name
```

The `from` field supports the following expression elements:

| Element | Description                            |
|---------|----------------------------------------|
| `[a-z]` | Lowercase ASCII letter                 |
| `[A-Z]` | Uppercase ASCII letter                 |
| `[0-9]` | Decimal digit                          |
| `\w`    | Alphanumeric character (`[a-zA-Z0-9]`) |
| `\d`    | Decimal digit (`[0-9]`)                |
| `\a`    | Lowercase ASCII letter (`[a-z]`)       |
| `\A`    | Uppercase ASCII letter (`[A-Z]`)       |
| `{n}`   | Repeat the preceding element `n` times |

**Optional parameters** without a default value or generator are not required.
If not provided during processing, their placeholders are replaced with an
empty string.

When a `VirtualMachineTemplate` is created or updated, and all required
parameters have values (either defaults or generated), the template is validated
by performing a dry-run processing. Templates that would produce an invalid
`VirtualMachine` spec are rejected.

### Example

Templates can reference instancetypes and preferences within the VM spec.
Instancetypes define compute resources, preferences define device and OS
defaults, and templates tie everything together with cluster-specific networks,
volumes, and `DataVolume` sources. See
[Instance types and preferences](instancetypes.md) for more details.

The following example defines a Fedora VM template with a generated name, a
default instancetype and preference, and a required password parameter:

```yaml
apiVersion: template.kubevirt.io/v1alpha1
kind: VirtualMachineTemplate
metadata:
  name: fedora-template
spec:
  parameters:
    - name: NAME
      generate: expression
      from: "fedora-[a-z0-9]{16}"
      description: Unique VM name
    - name: INSTANCETYPE
      value: u1.medium
      description: Instance type for the VM
    - name: PASSWORD
      required: true
      description: Password for the cloud-init user
  virtualMachine:
    metadata:
      name: ${NAME}
    spec:
      instancetype:
        kind: VirtualMachineClusterInstancetype
        name: ${INSTANCETYPE}
      preference:
        kind: VirtualMachineClusterPreference
        name: fedora
      runStrategy: Halted
      template:
        spec:
          domain:
            devices: { }
          volumes:
            - containerDisk:
                image: quay.io/containerdisks/fedora:latest
              name: rootdisk
            - cloudInitNoCloud:
                userData: |-
                  #cloud-config
                  user: fedora
                  password: ${PASSWORD}
                  chpasswd: { expire: False }
              name: cloudinitdisk
```

## Processing `VirtualMachineTemplates`

### Viewing template parameters

To list the parameters defined in a template:

```shell
$ virtctl template process fedora-template --print-params
NAME                DESCRIPTION                        GENERATOR    VALUE
NAME                Unique VM name                     expression   fedora-[a-z0-9]{16}
INSTANCETYPE        Instance type for the VM                        u1.medium
PASSWORD            Password for the cloud-init user
```

### Server-side processing

By default, when using `virtctl template process` the template is processed
server-side:

```shell
$ virtctl template process fedora-template -p PASSWORD=secretpass
```

This outputs the resulting `VirtualMachine` YAML with all parameters
substituted.

### Client-side processing

For templates stored as local files, use `--local` to process client-side
without contacting the cluster:

```shell
$ virtctl template process --local -f fedora-template.yaml -p PASSWORD=secretpass
```

### Output formats

Use `--output` to control the output format:

```shell
$ virtctl template process fedora-template -p PASSWORD=secretpass --output yaml
$ virtctl template process fedora-template -p PASSWORD=secretpass --output json
```

The default output format is YAML.

### Direct VM creation

Use `--create` to process the template and create the resulting `VirtualMachine`
in a single step:

```shell
$ virtctl template process fedora-template -p PASSWORD=secretpass --create
```

!!! Note
    Direct VM creation uses a subresource API (API group
    `subresources.template.kubevirt.io`) with separate RBAC controls. Cluster
    administrators can restrict users to only create VMs from predefined templates
    by granting the `process/create` subresource permission without granting
    direct `VirtualMachine` create permissions. See the [RBAC](#rbac) section for
    details.

## Creating templates from existing VMs

### VirtualMachineTemplateRequest

A `VirtualMachineTemplateRequest` creates a `VirtualMachineTemplate` from an
existing `VirtualMachine`. This enables a golden image workflow where you
configure a VM to your needs and then convert it into a reusable template.

### Cross-namespace template creation

One of the primary uses for `VirtualMachineTemplateRequest` is to create
templates in a shared or "catalog" namespace from a VM running in a user's
private namespace.

```shell
$ cat <<EOF | kubectl apply -f -
apiVersion: template.kubevirt.io/v1alpha1
kind: VirtualMachineTemplateRequest
metadata:
  name: promote-to-golden
  namespace: shared-templates  # The template will be created here
spec:
  virtualMachineRef:
    name: my-configured-vm
    namespace: my-namespace  # Source VM in a different namespace
  templateName: my-golden-vm
EOF
```

**RBAC requirements:**
To create a template from a VM in a different namespace, the user (or the
controller's service account) must have the `virtualmachinetemplaterequest/create`
permission in the **source** VM's namespace, as well as permission to create
`VirtualMachineTemplates` and `DataVolumes` in the **target** namespace.

!!! Warning
    The template creation process does **not** perform sysprepping. All secrets,
    credentials, and machine-specific identifiers from the source VM remain in
    the resulting template. You should review and parameterize sensitive values
    before distributing the template.

### Example: Persistent storage with `DataVolumeTemplates`

While `containerDisk` is useful for testing, production templates often use
`dataVolumeTemplates` to clone persistent storage from a golden image PVC.

```yaml
apiVersion: template.kubevirt.io/v1alpha1
kind: VirtualMachineTemplate
metadata:
  name: fedora-pvc-template
spec:
  parameters:
    - name: NAME
      generate: expression
      from: "fedora-[a-z0-9]{16}"
      description: Unique VM name
  virtualMachine:
    metadata:
      name: ${NAME}
    spec:
      runStrategy: Halted
      template:
        spec:
          domain:
            devices:
              disks:
                - disk:
                    bus: virtio
                  name: rootdisk
          volumes:
            - dataVolume:
                name: ${NAME}-rootdisk
              name: rootdisk
      dataVolumeTemplates:
        - metadata:
            name: ${NAME}-rootdisk
          spec:
            source:
              pvc:
                name: fedora-golden
                namespace: shared-templates
            storage: {}
```

### Using virtctl template create

The `virtctl template create` command provides a shortcut for creating a
template from an existing VM:

```shell
$ virtctl template create my-configured-vm
virtualmachinetemplate.template.kubevirt.io/my-configured-vm created
```

## Converting OpenShift `Templates`

### virtctl template convert

If you have existing OpenShift Templates (`template.openshift.io/v1`) containing
a single `VirtualMachine` object, you can convert them to native
`VirtualMachineTemplates`:

```shell
$ virtctl template convert -f openshift-fedora-template.yaml
```

This outputs the converted `VirtualMachineTemplate` YAML. The conversion maps
OpenShift template parameters to `VirtualMachineTemplate` parameters.

!!! Note
    The conversion requires that the OpenShift template contains exactly one
    `VirtualMachine` object. Templates with multiple objects are not supported.

## RBAC

### User personas

| Persona           | Description                                   | Permissions                                                                           |
|-------------------|-----------------------------------------------|---------------------------------------------------------------------------------------|
| VM Owner          | Creates VMs from existing templates           | `process` and `create` subresource on templates (`subresources.template.kubevirt.io`) |
| VM Template Owner | Creates and manages `VirtualMachineTemplates` | Full CRUD on both CRDs                                                                |
| Cluster Admin     | Enforces policies on how VMs are created      | Full CRUD plus RBAC management                                                        |

### Aggregated `ClusterRoles`

The Template feature defines `ClusterRoles` that aggregate into the standard
Kubernetes `admin`, `editor`, and `view` roles.

- **admin / editor**: full CRUD access on `VirtualMachineTemplates` and
  `VirtualMachineTemplateRequests`
- **view**: read-only access to `VirtualMachineTemplates` and
  `VirtualMachineTemplateRequests`

### Restricting VM creation to templates

A key RBAC pattern is to restrict users so they can only create VMs through
templates, not freeform. To achieve this:

1. Grant users the `process/create` subresource permission on
   `VirtualMachineTemplates` (API group `subresources.template.kubevirt.io`)
2. Do **not** grant direct `create` permission on `VirtualMachine` resources
   (API group `kubevirt.io`)

This ensures that all VMs are created from approved templates, giving
administrators control over the VM configurations allowed in the cluster.

## Limitations

!!! Warning
    The Template API (`template.kubevirt.io/v1alpha1`) is an Alpha feature and may
    change in future releases.

- The API is Alpha and subject to breaking changes
- Import/export functionality (OVA/OVF) is planned for v1.9.0
