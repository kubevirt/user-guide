# Plugins

## Overview

Plugins allow extending KubeVirt with out-of-tree functionality. A Plugin is a
cluster-scoped Custom Resource that defines domain hooks, node hooks, and
admission references.

The Plugins feature is currently in Alpha and requires the `Plugins` feature gate.

## Enabling the feature gate

Enable the `Plugins` feature gate by following the steps in
[Activating feature gates](activating_feature_gates.md).

## Domain Hooks

Domain hooks modify the libvirt domain XML before a VM is created. There are
two types: CEL hooks for pure domain mutation, and sidecar hooks for cases
that require reading external state (files, APIs, license servers) to feed
into domain XML mutation.

Hooks are applied in declaration order within each plugin. Across plugins,
hooks are applied in alphabetical order by plugin name.

Legacy annotation-based sidecar hooks run before plugin hooks.

### CEL expressions

A CEL expression that transforms the domain XML inline. The expression uses
`vmi` and `domainSpec` variables and must return a `Domain{...}` struct using
[libvirtxml](https://pkg.go.dev/libvirt.org/go/libvirtxml) type names. The result is deep-merged with the generated domain -
only fields mentioned in the expression are overwritten, and unmentioned fields
are left untouched. Slices are replaced wholesale, not merged element-by-element.

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: cel-domain-example
spec:
  domainHooks:
  - cel:
      expression: 'Domain{CPU: DomainCPU{Mode: "host-passthrough"}}'
```

### Sidecar

A sidecar container in virt-launcher communicates via gRPC over a Unix socket.
The sidecar receives the domain spec and returns a modified version. Use sidecar
hooks when you need logic beyond what CEL can express, such as reading external
state or making API calls.

The Plugin CR references the socket path. To inject the sidecar container into
the virt-launcher pod, set up a MutatingAdmissionPolicy (or webhook). This
gives you full control over the sidecar container spec (image, resources,
security context, volumes).

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: my-plugin
spec:
  domainHooks:
  - sidecar:
      socketPath: "/var/run/kubevirt-plugin/my-plugin/hook.sock"
```

**Socket path constraints:**

- The socket must reside under `/var/run/kubevirt-plugin/<plugin-name>/`, defined as a shared volume with the compute container.
- Symlinks are not allowed in socket paths.
- Sidecar volume mounts must use `subPath` to ensure each plugin has isolated access to its own directory.

## Node Hooks

Node hooks execute during VM lifecycle events via gRPC from virt-handler to a
plugin server. The plugin author deploys and manages this server as a DaemonSet,
giving the cluster admin control over its capabilities and resources via
standard Kubernetes mechanisms.

Available hook points:

- `PreVMStart`, `PostVMStart`
- `PreVMStop`, `PostVMStop`
- `PreMigrationSource`, `PreMigrationTarget`, `PostMigrationTarget`

Node hooks may fire multiple times for the same lifecycle event due to
reconciliation retries. Implementations must be idempotent.

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: node-hook-example
spec:
  nodeHooks:
  - socket: /var/run/my-plugin/hook.sock
    permittedHooks:
    - PreVMStart
    - PreVMStop
```

## Admission References

Plugins can reference Kubernetes admission policies and webhooks for pod/VMI modifications:

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: admission-example
spec:
  mutatingAdmissionPolicies:
    - name: "my-mutating-policy"
  validatingAdmissionPolicies:
    - name: "my-validating-policy"
  mutatingAdmissionWebhooks:
    - name: "my-mutating-webhook"
  validatingAdmissionWebhooks:
    - name: "my-validating-webhook"
```

These are listed in the Plugin CR to provide a central place to understand all plugin components.

## Failure Handling and Conditions

- **`failureStrategy`**: `Fail` (default) blocks the operation on error. `Ignore` logs the error and continues. Can be set at plugin level as the default for all hooks, and overridden per hook.
- **`condition`**: A CEL expression that filters which VMIs the plugin applies to. Can be set at plugin level and per hook. Per-hook conditions further narrow the plugin-level filter.
- **`timeout`**: Per-hook maximum wait duration. Defaults to 30s.

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: full-example
spec:
  failureStrategy: Fail
  condition: "vmi.status.phase == 'Running'"
  domainHooks:
  - cel:
      expression: 'Domain{Memory: DomainMemory{Value: uint(2048), Unit: "GiB"}}'
    failureStrategy: Ignore
    condition: "vmi.status.conditions.exists(c, c.type == 'LiveMigratable' && c.status == 'True')"
    timeout: 10s
```

## Developing Plugins

Sidecar domain hooks and node hooks communicate via gRPC. The proto definitions
can be found at
[`pkg/hooks/plugins/v1alpha1/api.proto`](https://github.com/kubevirt/kubevirt/blob/main/pkg/hooks/plugins/v1alpha1/api.proto)
in the KubeVirt repository.

- **Domain hooks** implement the `DomainHookService.MutateDomain` RPC. The request contains the domain XML, the VMI object (as JSON), and a sidecar context with the invocation context (Boot, MigrationSource, or MigrationTarget).
- **Node hooks** implement the `NodeHookService.ExecuteNodeHook` RPC. The request contains the hook point name, the VMI object (as JSON), and node context.

## Related

- [Hook Sidecar Container](../user_workloads/hook-sidecar.md) - legacy mechanism (deprecated).
- [VEP 190](https://github.com/kubevirt/enhancements/blob/main/veps/sig-compute/190-kubevirt-structured-plugins/vep.md) - design details.
