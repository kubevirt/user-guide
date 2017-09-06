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
  generateName: testvm-migration
spec:
  selector:
    name: testvm
```

Once you have specified the migratin object, you can submit it to the cluster using `kubectl`:

```bash
$ kubectl create -f migration.yaml
```

### Querying the live migration status

The status of a migration can be retrieved by querying for the migration:

```
$ kubectl get migrations testvm-migration-px76k
```

### Aborting a live migration

Aborting a live migration is not yet supported.

