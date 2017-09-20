## Live migrating a virtual machine

Live migrating a virtual machine allows you to move a VirtualMachine from one host to another, without shutting it down.

Live migration is supported if your cluster has got more than two nodes.

### Starting a live migration

A live migration is triggered by creating a `Migration` object. You need to set a `selector` to specify the VirtualMachine to be migrated.

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

### Aborting a live migration

Aborting a live migration is not yet supported.


## Fine tuning

The previous paragraphs explained the basic flow for live migrating a VirtualMachine.
In this section we are looking at additional tuning parameters which influence
the migration in certain areas.

### Influencing where a VirtualMachine migrates

> **Note:** This section is about using the `nodeSelector` to select migration
> destinations. Node- and Pod-Affinity as present in recent versions of Kubernetes
> is not yet supported for VirtualMachines.

The VirtualMachine will always be scheduled to another node than where it is running on, or
the migration fails. To further influence where VirtualMachine migrates, a `nodeSelector`
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

In this example, the VirtualMachine will only be migrated to nodes which have the label
`ram: fast` assigned.

#### Migrate a VirtualMachine to a specific Node

The scheduler can be forced to migrate a VirtualMachine to a specific node, if enough
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

In this case the VirtualMachine will be migrated to the node `slave1`, or the migration
fails if that is not possible.

#### Merging VirtualMachine and Migration nodeSelector requirements

A VirtualMachine can already contain a `nodeSelector` section itself. A Migration will
always respect them. Both sections will be merged **only** for the current
migration.

Given a VirtualMachine

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
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
nodes which match both, `ram: fast` and `storage: ssd`. The VirtualMachine itself will only
contain the original `nodeSelector` section afterwards. Later migrations are
therefore not influenced by the additional migration labels.

#### Resolving nodeSelector conflicts

Since the `nodeSelector` section is a hard requirement of  the VirtualMachine, they can't
be overwritten. In case the `nodeSelector` section of a Migration conflicts
with the `nodeSelector` section of a VirtualMachine, the migration will fail.