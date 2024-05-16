# Migration Policies

Migration policies provides a new way of applying migration configurations to Virtual Machines. The policies
can refine Kubevirt CR's `MigrationConfiguration` that sets the cluster-wide migration configurations. This way,
the cluster-wide settings serve as a default that can be refined (i.e. changed, removed or added) by the migration
policy.

Please bear in mind that migration policies are in version `v1alpha1`. This means that this API is not fully stable
yet and that APIs may change in the future.

## Overview

KubeVirt supports [Live Migrations](../compute/live_migration.md) of Virtual Machine workloads.
Before migration policies were introduced, migration settings could be configurable only on the cluster-wide
scope by editing [KubevirtCR's spec](https://kubevirt.io/api-reference/master/definitions.html#_v1_kubevirtspec)
or more specifically [MigrationConfiguration](https://kubevirt.io/api-reference/master/definitions.html#_v1_migrationconfiguration)
CRD.

Several aspects (although not all) of migration behaviour that can be customized are:
- Bandwidth
- Auto-convergence
- Post/Pre-copy
- Max number of parallel migrations
- Timeout

Migration policies generalize the concept of defining migration configurations, so it would be
possible to apply different configurations to specific groups of VMs.

Such capability can be useful for a lot of different use cases on which there is a need to differentiate
between different workloads. Differentiation of different configurations could be needed because different
workloads are considered to be in different priorities, security segregation, workloads with different
requirements, help to converge workloads which aren't migration-friendly, and many other reasons.

## API Examples

#### Migration Configurations
Currently the MigrationPolicy spec will only include the following configurations from KubevirtCR's
MigrationConfiguration (in the future more configurations that aren't part of Kubevirt CR are intended to be added):
```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MigrationPolicy
  spec:
    allowAutoConverge: true
    bandwidthPerMigration: 217Ki
    completionTimeoutPerGiB: 23
    allowPostCopy: false
```

All above fields are optional. When omitted, the configuration will be applied as defined in
KubevirtCR's MigrationConfiguration. This way, KubevirtCR will serve as a configurable set of defaults for both
VMs that are not bound to any MigrationPolicy and VMs that are bound to a MigrationPolicy that does not
define all fields of the configurations.

#### Matching Policies to VMs

Next in the spec are the selectors that define the group of VMs on which to apply the policy. The options to do so
are the following.

**This policy applies to the VMs in namespaces that have all the required labels:**
```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MigrationPolicy
  spec:
  selectors:
    namespaceSelector:
      hpc-workloads: true       # Matches a key and a value 
```

**This policy applies for the VMs that have all the required labels:**
```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MigrationPolicy
  spec:
  selectors:
    virtualMachineInstanceSelector:
      workload-type: db       # Matches a key and a value 
```

**It is also possible to combine the previous two:**
```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MigrationPolicy
  spec:
  selectors:
    namespaceSelector:
      hpc-workloads: true
    virtualMachineInstanceSelector:
      workload-type: db
```

#### Full Manifest:

```yaml
apiVersion: migrations.kubevirt.io/v1alpha1
kind: MigrationPolicy
metadata:
  name: my-awesome-policy
spec:
  # Migration Configuration
  allowAutoConverge: true
  bandwidthPerMigration: 217Ki
  completionTimeoutPerGiB: 23
  allowPostCopy: false
  
  # Matching to VMs
  selectors:
    namespaceSelector:
      hpc-workloads: true
    virtualMachineInstanceSelector:
      workload-type: db
```
## Policies' Precedence

It is possible that multiple policies apply to the same VMI. In such cases, the precedence is in the
same order as the bullets above (VMI labels first, then namespace labels). It is not allowed to define
two policies with the exact same selectors.

If multiple policies apply to the same VMI:
* The most detailed policy will be applied, that is, the policy with the highest number of matching labels

* If multiple policies match to a VMI with the same number of matching labels, the policies will be sorted by the
lexicographic order of the matching labels keys. The first one in this order will be applied.

### Example

For example, let's imagine a VMI with the following labels:

* size: small

* os: fedora

* gpu: nvidia

And let's say the namespace to which the VMI belongs contains the following labels:

* priority: high

* bandwidth: medium

* hpc-workload: true

The following policies are listed by their precedence (high to low):

1) VMI labels: `{size: small, gpu: nvidia}`, Namespace labels: `{priority:high, bandwidth: medium}`
   
  * Matching labels: 4, First key in lexicographic order: `bandwidth`.

2) VMI labels: `{size: small, gpu: nvidia}`, Namespace labels: `{priority:high, hpc-workload:true}`

  * Matching labels: 4, First key in lexicographic order: `gpu`.

3) VMI labels: `{size: small, gpu: nvidia}`, Namespace labels: `{priority:high}`

  * Matching labels: 3, First key in lexicographic order: `gpu`.

4) VMI labels: `{size: small}`, Namespace labels: `{priority:high, hpc-workload:true}`

  * Matching labels: 3, First key in lexicographic order: `hpc-workload`.

5) VMI labels: `{gpu: nvidia}`, Namespace labels: `{priority:high}`

  * Matching labels: 2, First key in lexicographic order: `gpu`.

6) VMI labels: `{gpu: nvidia}`, Namespace labels: `{}`

  * Matching labels: 1, First key in lexicographic order: `gpu`.

7) VMI labels: `{gpu: intel}`, Namespace labels: `{priority:high}`

  * VMI label does not match - policy cannot be applied.
