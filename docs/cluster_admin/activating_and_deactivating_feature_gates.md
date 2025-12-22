# Activating and deactivating feature gates

KubeVirt has a set of features that are not mature enough to be enabled by
default. As such, they are protected by a Kubernetes concept called
[feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

## How to activate a feature gate
You can activate a specific feature gate directly in KubeVirt's CR, by
provisioning the following yaml, which uses the `LiveMigration` feature gate
as an example:
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
        - LiveMigration
END

kubectl apply -f enable-feature-gate.yaml
```

Alternatively, the existing kubevirt CR can be altered:
```bash
kubectl edit kubevirt kubevirt -n kubevirt
```

```yaml
...
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - DataVolumes
        - LiveMigration
```

**Note:** the name of the feature gates is case sensitive.

The snippet above assumes KubeVirt is installed in the `kubevirt` namespace.
Change the namespace to suite your installation.

## How to disable a feature gate

Starting from KubeVirt v1.8, you can explicitly disable feature gates using the `disabledFeatureGates` field.
This is particularly useful when you want to disable beta features that may be enabled by default.

To disable specific feature gates, add them to the `disabledFeatureGates` list:

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
      featureGates:
        - ExperimentalFeatureToEnable
      disabledFeatureGates:
        - ExperimentalFeatureToDisable
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
      featureGates:
        - ExperimentalFeatureToEnable
      disabledFeatureGates:
        - ExperimentalFeatureToDisable
```

**Important note:**
- A feature gate cannot be listed in both `featureGates` and `disabledFeatureGates` at the same time. This will result in a validation error.

## List of feature gates
The list of feature gates (which evolve in time) can be checked directly from
the [source code](https://github.com/kubevirt/kubevirt/blob/main/pkg/virt-config/featuregate/active.go) (use the const string values in the yaml configuration).

