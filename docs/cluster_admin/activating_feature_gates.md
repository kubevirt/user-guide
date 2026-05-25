# Activating and deactivating feature gates

KubeVirt has a set of features that are not mature enough to be enabled by
default. As such, they are protected by a Kubernetes concept called
[feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

## Feature gate lifecycle

KubeVirt features progress through maturity stages, each with different
default behavior:

| Stage | Default state | How to change |
|---|---|---|
| **Alpha** | Disabled | Enable via `featureGates` |
| **Beta** | Enabled (from v1.9) | Disable via `disabledFeatureGates` |
| **GA** | Always enabled | Cannot be disabled |

- **Alpha** features are experimental and must be explicitly enabled.
  They may be incomplete, have breaking API changes, or be removed
  entirely.
- **Beta** features are considered stable enough for broad testing.
  Starting from KubeVirt v1.9, all Beta feature gates are
  **enabled by default**. See
  [VEP 229: Beta features on by default](https://github.com/kubevirt/enhancements/blob/main/veps/meta-VEPs/229-beta-features-on-by-default/vep.md)
  and the [blog post](https://kubevirt.io/2026/Beta-Features-On-By-Default-In-v1-9.html)
  for full details.
- **GA** features are always enabled and cannot be toggled. The
  feature gate itself is considered obsolete at this stage.

## Feature gate report

Starting from v1.9, KubeVirt ships a **feature gate report** as
part of every release's artifacts. This JSON file lists every non-GA
feature gate and its current state (Alpha, Beta, or Deprecated).

You can find it in the
[release artifacts](https://github.com/kubevirt/kubevirt/releases)
for each version, or generate it yourself from a KubeVirt source
tree:

```bash
make feature-gate-report
```

The full list of feature gates can also be checked directly from the
[source code](https://github.com/kubevirt/kubevirt/blob/main/pkg/virt-config/featuregate/active.go).

## How to activate a feature gate

Alpha features must be explicitly enabled. You can activate a feature
gate in KubeVirt's CR:

```bash
cat << END > enable-feature-gate.yaml
---
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - AlphaFeatureToEnable
END

kubectl apply -f enable-feature-gate.yaml
```

Alternatively, edit the existing KubeVirt CR:

```bash
kubectl edit kubevirt kubevirt -n kubevirt
```

```yaml
...
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - AlphaFeatureToEnable
```

**Note:** the name of the feature gates is case sensitive.

The snippets above assume KubeVirt is installed in the `kubevirt`
namespace. Change the namespace to suit your installation.

## How to disable a feature gate

Starting from KubeVirt v1.8, you can explicitly disable feature gates
using the `disabledFeatureGates` field. From v1.9, this is the
only way to opt out of Beta features that are enabled by
default.

**It is recommended to disable all Beta feature gates in production**
unless you have explicitly validated them for your environment. Use
the feature gate report from the release artifacts to
programmatically populate this list.

To disable specific feature gates, add them to the
`disabledFeatureGates` list:

```bash
cat << END > disable-feature-gate.yaml
---
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      disabledFeatureGates:
        - BetaFeatureToDisable
END

kubectl apply -f disable-feature-gate.yaml
```

Alternatively, edit the existing KubeVirt CR:

```bash
kubectl edit kubevirt kubevirt -n kubevirt
```

```yaml
...
spec:
  configuration:
    developerConfiguration:
      disabledFeatureGates:
        - BetaFeatureToDisable
```

!!! warning "Important"
    A feature gate cannot be listed in both `featureGates` and
    `disabledFeatureGates` at the same time. This will result in a
    validation error.

## Upgrade considerations

When upgrading to v1.9 or later, be aware that all Beta features
will become active by default. Review the feature gate report for
the target version and configure `disabledFeatureGates` as needed.

The `disabledFeatureGates` mechanism was introduced in v1.8. If
you are upgrading from v1.7 or older directly to v1.9, Beta
features will be unconditionally enabled until you patch the
KubeVirt CR post-upgrade. Upgrading to v1.8 first is recommended.
