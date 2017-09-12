## Live migrating a virtual machine

Live migrating a virtual machine allows you to move a VM from one host to another, without shutting it down.

Live migration is supported if your cluster has got more than two nodes.

### Starting a live migration

A live migration is triggered by creating a `Migration` object. You need to set a `selector` to specify the VM to be migrated.

The example below shows as usual migration object:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: Migration
metadata:
  name: testvm-migration
spec:
  selector:
    name: testvm
```

Once you have specified the migration object, you can submit it to the cluster using `kubectl`:

```bash
$ kubectl create -f migration.yaml
```

> **Note:** Until deleted by a user or the garbage collector, a Migration will stay in the
> cluster. To post a migration with the same name again, either delete the
> succeeded or failed Migration or make use of the `generateName` feature from
> Kubernetes.

### Querying the live migration status

The status of a migration can be retrieved by querying for the migration:

```
$ kubectl get migrations testvm-migration
```

### Influencing with Labels where a VM migrates

The VM will always be scheduled to another node than where it is running on, or
the migration fails. To further influence where VM migrates, a `nodeSelector`
section can be added to a Migration:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: Migration
metadata:
  generateName: testvm-migration
spec:
  selector:
    name: testvm
  nodeSelector:
    ram: fast
```

In this example, the VM will only be migrated to nodes which have the label
`ram: fast` assigned.

#### Migrate a VM to a specific Node

The scheduler can be forced to migrate a VM to a specific node, if enough
resources are available on the target node. For selecting the target node, the
special `kubernetes.io/hostname` label can be used. It is applied by Kubernetes
to every node and is guaranteed to be unique.

First create a Migration with a `nodeSelector` section:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: Migration
metadata:
  name: testvm-migration
spec:
  selector:
    name: testvm
  nodeSelector:
    kubernetes.io/hostname: slave1
```

In this case the VM will be migrated to the node `slave1`, or the migration
fails if that is not possible.

#### Merging VM and Migration nodeSelector requirements

A VM can already contain a `nodeSelector` section itself. A Migration will
always respect them. Both sections will be merged **only** for the current
migration.

Given a VM

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VM
metadata:
  name: testvm
spec:
  nodeSelector:
    ram: fast
  domain:
    devices:
      graphics:
      - type: spice
      consoles:
      - type: pty
```

and a Migration

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: Migration
metadata:
  name: testvm-migration
spec:
  selector:
    name: testvm
  nodeSelector:
    storage: ssd
```

The migration controller will combine the two node selectors, and look for
nodes which match both, `ram: fast` and `storage: ssd`. The VM itself will only
contain the original `nodeSelector` section afterwards. Later migrations are
therefore not influenced by the additional migration labels.

#### Resolving nodeSelector conflicts

Since the `nodeSelector` section is a hard requirement of  the VM, they can't
be overwritten. In case the `nodeSelector` section of a Migration conflicts
with the `nodeSelector` section of a VM, the migration will fail.

### Aborting a live migration

Aborting a live migration is not yet supported.

### Affinity and Anti-Affinity

Recent version of Kubernetes support Node- and Pod-Affinity. This is not
yet supported for VMs.
