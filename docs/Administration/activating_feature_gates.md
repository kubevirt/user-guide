# Activating feature gates

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

## List of feature gates
The list of feature gates (which evolve in time) can be checked directly from
the [source code](https://github.com/kubevirt/kubevirt/blob/main/pkg/virt-config/feature-gates.go#L26).

