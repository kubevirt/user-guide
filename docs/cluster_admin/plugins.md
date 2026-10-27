# Plugins

## Overview

Plugins allow extending KubeVirt with out-of-tree functionality. A Plugin is a
cluster-scoped Custom Resource that defines launcher hooks, node hooks, and
admission references.

The Plugins feature is currently in Alpha (introduced in v1.9) and requires the `Plugins` feature gate.

## Enabling the feature gate

Enable the `Plugins` feature gate by following the steps in
[Activating feature gates](activating_feature_gates.md).

## Launcher Hooks

Launcher hooks run inside the virt-launcher pod at well-defined points in the
VM lifecycle. Each hook is either a CEL expression or a sidecar container.

| Hook point | When it runs | CEL | Sidecar |
|------------|--------------|-----|---------|
| `GuestDefinition` | After the domain is generated, before it is handed to libvirt | Yes | Yes |
| `PreBoot` | After boot artifacts are generated, before the guest starts | No | Yes |
| `PreMigrationSource` | On the migration source, before libvirt starts the migration | No | Yes |

Hooks are applied in declaration order within each plugin. Across plugins,
hooks are applied in alphabetical order by plugin name.

### CEL expressions

A CEL expression targets a single hook point, set in `hookPoint`. CEL is
supported only for the `GuestDefinition` hook point.

The expression transforms the domain inline. It uses the `vmi` and `domainSpec`
variables, whose fields are accessed by their Go names (for example
`vmi.Spec.Domain`), and must return a `Domain{...}` struct using
[libvirtxml](https://pkg.go.dev/libvirt.org/go/libvirtxml) type names. The result is deep-merged with the generated domain -
only fields mentioned in the expression are overwritten, and unmentioned fields
are left untouched. Slices are replaced wholesale, not merged element-by-element.

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: cel-domain-example
spec:
  launcherHooks:
  - cel:
      hookPoint: GuestDefinition
      expression: 'Domain{CPU: DomainCPU{Mode: "host-passthrough"}}'
```

### Sidecar

A sidecar container in virt-launcher serves gRPC over a Unix socket. Use
sidecar hooks when you need logic beyond what CEL can express, such as reading
external state, making API calls, or modifying files.

The Plugin CR references the socket path and lists the hook points the sidecar
handles in `permittedHooks`, so a single sidecar can serve several hook points.
To inject the sidecar container into the virt-launcher pod, set up a
MutatingAdmissionPolicy (or webhook). This gives you full control over the
sidecar container spec (image, resources, security context, volumes).

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: my-plugin
spec:
  launcherHooks:
  - sidecar:
      socketPath: "/var/run/kubevirt-plugin/my-plugin/hook.sock"
      permittedHooks:
      - GuestDefinition
      - PreBoot
      - PreMigrationSource
```

**Socket path constraints:**

- The socket must reside under `/var/run/kubevirt-plugin/<plugin-name>/`. KubeVirt adds `/var/run/kubevirt-plugin` to the virt-launcher pod as the `kubevirt-plugin-sockets` volume, shared with the compute container.
- The path must end with `.sock`, be at most 108 bytes long, and contain no `..`, repeated or trailing `/`.
- Symlinks are not allowed in socket paths.
- Sidecars must mount the `kubevirt-plugin-sockets` volume with a `subPath`, so that each plugin has isolated access to its own directory. Pods that violate this are rejected.

At each hook point, virt-launcher waits up to 30 seconds in total for the
sockets of the sidecars handling it to appear. This wait is separate from the
per-hook `timeout`.

### GuestDefinition

The `GuestDefinition` hook mutates the domain before it is handed to libvirt.
It runs when the VM boots and may be called more than once during a single
boot, so implementations must be idempotent.

On the migration target, the hook is also invoked with the `MigrationTarget`
invocation context, so that a sidecar can prepare the target pod. Its returned
domain is not used: the target runs the domain migrated from the source, which
already includes the mutations applied at boot. The hook does not run on the
migration source.

Legacy annotation-based [hook sidecars](../user_workloads/hook-sidecar.md) run
before plugin hooks, so plugins see the domain as modified by them.

### PreBoot

The `PreBoot` hook runs after the boot artifacts (such as the cloud-init ISO)
are generated and before the guest starts. Use it to modify guest
initialization data that depends on runtime information, for example
cloud-init network configuration built from the pod's network-status
annotation.

The request contains the VMI and the paths of the generated artifacts inside
the compute container:

- `cloudInitISO`: the generated cloud-init ISO, if the VM has a cloud-init volume.
- `ephemeralDiskDir`: the directory that holds the ephemeral disks,
  `/var/run/kubevirt-ephemeral-disks`.

To access the artifacts, the sidecar must mount the `ephemeral-disks` volume at
`/var/run/kubevirt-ephemeral-disks`, the same path as in the compute container.
When multiple plugins handle `PreBoot`, each sidecar sees the files as left by
the previous one.

Things to keep in mind:

- `PreBoot` runs only when the VM boots, not on the migration target. Volumes
  hotplugged into a running VM never pass through it.
- `PreBoot` may be called again after a failed start, and file changes are not
  rolled back. Implementations must be idempotent.
- A hook with `failureStrategy: Ignore` is not stopped when it exceeds its
  timeout: the VM starts while the hook may still be modifying files. Hooks
  that modify files should use `failureStrategy: Fail`, write atomically
  (temporary file and rename), and honor the request context.
- `GuestDefinition` hooks run before `PreBoot` hooks.

### PreMigrationSource

The `PreMigrationSource` launcher hook runs on the migration source, right
before virt-launcher hands the migration to libvirt. It allows a plugin to
tune the migration per VM, for example to enable parallel (multifd) migration
or select a compression method.

The request contains the VMI and the migration configuration KubeVirt is
about to pass to libvirt: the `VIR_MIGRATE_*` flags bitmask and the
`VIR_MIGRATE_PARAM_*` parameters. The response contains only the changes:

- `set_flags` adds flag bits and `clear_flags` removes them. A bit present in
  both is an error.
- For each parameter, an unset field keeps the current value, a set field
  overrides it, and an empty wrapper or empty list removes the parameter.
- An empty response changes nothing.

When multiple hooks handle `PreMigrationSource`, each one receives the
configuration as modified by the previous hooks. The result is passed to
libvirt as-is, so the plugin has full control over, and full responsibility
for, the migration configuration, including the migration URIs.

Things to keep in mind:

- If a hook with `failureStrategy: Fail` fails, the migration fails. With
  `Ignore`, the migration proceeds with the configuration returned by the
  previous successful hooks.
- If the migration is aborted while hooks are running, the request context is
  canceled. Hooks should honor it.
- The migration monitor starts after the hooks return, so the time spent in
  hooks does not count towards the migration timeouts.
- The migration monitor follows the resulting `VIR_MIGRATE_POSTCOPY` flag:
  clearing it disables post-copy, and setting it allows post-copy under the
  same conditions as when KubeVirt sets it.

This hook is distinct from the `PreMigrationSource` node hook, which runs on
the node before the migration starts and cannot change the migration
configuration.

## Node Hooks

Node hooks execute during VM lifecycle events via gRPC from virt-handler to a
plugin server. The plugin author deploys and manages this server as a DaemonSet,
giving the cluster admin control over its capabilities and resources via
standard Kubernetes mechanisms.

Available hook points:

- `PreVMStart`: before the VM starts.
- `PostVMStart`: after the VM is running.
- `OnVMStop`: when KubeVirt stops a running VM, for example when the VMI is
  deleted. It does not fire when the guest shuts down or crashes on its own.
- `PostVMStop`: after the VM has stopped.
- `PreMigrationSource`: on the source node, before the migration starts.
- `PreMigrationTarget`: on the target node, before the migration starts.
- `PostMigrationTarget`: on the target node, after the migration completes.

Node hooks may fire multiple times for the same lifecycle event due to
reconciliation retries. Implementations must be idempotent.

The socket must be on a host path that virt-handler mounts, for example under
`/var/run/kubevirt/`.

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: node-hook-example
spec:
  nodeHooks:
  - socket: /var/run/kubevirt/plugins/my-plugin.sock
    permittedHooks:
    - PreVMStart
    - OnVMStop
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

- **`failureStrategy`**: `Fail` (default) blocks the operation on error. `Ignore` logs the error and continues. For launcher hooks, it can be set at plugin level as the default and overridden per hook. Node hooks use only their own `failureStrategy`.
- **`condition`**: A CEL expression that filters which VMIs the plugin applies to. It can reference only `vmi`, using Go field names, and must evaluate to a bool. Can be set at plugin level and per hook. Per-hook conditions further narrow the plugin-level filter. An error while evaluating a condition fails the operation regardless of `failureStrategy`.
- **`timeout`**: Per-hook maximum wait duration for sidecar launcher hooks and node hooks. Defaults to 30s. It does not apply to CEL hooks.

This example applies only to VMIs that carry the `example.com/tuning` label.
The CEL hook further narrows to VMIs where the label value is `cpu`. The
sidecar hook tunes the migration of all labeled VMIs; if it fails or does not
respond within 10 seconds, the migration proceeds without its changes.

```yaml
apiVersion: plugin.kubevirt.io/v1alpha1
kind: Plugin
metadata:
  name: full-example
spec:
  failureStrategy: Fail
  condition: '"example.com/tuning" in vmi.Labels'
  launcherHooks:
  - cel:
      hookPoint: GuestDefinition
      expression: 'Domain{CPU: DomainCPU{Mode: "host-passthrough"}}'
    condition: 'vmi.Labels["example.com/tuning"] == "cpu"'
  - sidecar:
      socketPath: "/var/run/kubevirt-plugin/full-example/hook.sock"
      permittedHooks:
      - PreMigrationSource
    failureStrategy: Ignore
    timeout: 10s
```

## Developing Plugins

Sidecar launcher hooks and node hooks communicate via gRPC. The proto definitions
can be found at
[`pkg/hooks/plugins/v1alpha1/api.proto`](https://github.com/kubevirt/kubevirt/blob/main/pkg/hooks/plugins/v1alpha1/api.proto)
in the KubeVirt repository.

- **Launcher hooks** implement the `LauncherHookService`, with one RPC per hook point:
    - `GuestDefinition`: the request contains the domain XML, the VMI object (as JSON), and a sidecar context with the invocation context (`Boot` or `MigrationTarget`). The response contains the modified domain XML.
    - `PreBoot`: the request contains the VMI object (as JSON) and the artifact paths.
    - `PreMigrationSource`: the request contains the VMI object (as JSON) and the libvirt migration flags and parameters. The response contains the changes to apply.
- **Node hooks** implement the `NodeHookService.ExecuteNodeHook` RPC. The request contains the hook point name, the VMI object (as JSON), and node context.

A sidecar only needs to implement the RPCs for the hook points listed in its
`permittedHooks`.

## Related

- [Hook Sidecar Container](../user_workloads/hook-sidecar.md) - legacy mechanism (deprecated).
- [VEP 190](https://github.com/kubevirt/enhancements/blob/main/veps/sig-compute/190-kubevirt-structured-plugins/vep.md) - design details.
