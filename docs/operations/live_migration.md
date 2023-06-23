# Live Migration

Live migration is a process during which a running Virtual Machine
Instance moves to another compute node while the guest workload
continues to run and remain accessible.

## Enabling the live-migration support

Live migration must be enabled in the feature gates to be supported. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `LiveMigration` to it.

## Limitations

- Virtual machines using a PersistentVolumeClaim (PVC) must have a
  shared ReadWriteMany (RWX) access mode to be live migrated.

- Live migration is not allowed with a pod network binding of bridge
  interface type
  (</#/creation/interfaces-and-networks>)

- Live migration requires ports `49152, 49153` to be available in the virt-launcher pod.
  If these ports are explicitly specified in [masquarade interface](../virtual_machines/interfaces_and_networks.md#masquerade), live migration will not function.

## Initiate live migration

Live migration is initiated by posting a VirtualMachineInstanceMigration
(VMIM) object to the cluster. The example below starts a migration
process for a virtual machine instance `vmi-fedora`

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: vmi-fedora
```

### Using virtctl to initiate live migration
Live migration can also be initiated using virtctl
```console
    virtctl migrate vmi-fedora
```


## Migration Status Reporting

### Condition and migration method

When starting a virtual machine instance, it has also been calculated
whether the machine is live migratable. The result is being stored in
the VMI `VMI.status.conditions`. The calculation can be based on
multiple parameters of the VMI, however, at the moment, the calculation
is largely based on the `Access Mode` of the VMI volumes. Live migration
is only permitted when the volume access mode is set to `ReadWriteMany`.
Requests to migrate a non-LiveMigratable VMI will be rejected.

The reported `Migration Method` is also being calculated during VMI
start. `BlockMigration` indicates that some of the VMI disks require
copying from the source to the destination. `LiveMigration` means that
only the instance memory will be copied.

```yaml
Status:
  Conditions:
    Status: True
    Type: LiveMigratable
  Migration Method: BlockMigration
```

### Migration Status

The migration progress status is being reported in the VMI `VMI.status`.
Most importantly, it indicates whether the migration has been
`Completed` or if it `Failed`.

Below is an example of a successful migration.

```
Migration State:
    Completed:        true
    End Timestamp:    2019-03-29T03:37:52Z
    Migration Config:
      Completion Timeout Per GiB:  800
      Progress Timeout:             150
    Migration UID:                  c64d4898-51d3-11e9-b370-525500d15501
    Source Node:                    node02
    Start Timestamp:                2019-03-29T04:02:47Z
    Target Direct Migration Node Ports:
      35001:                      0
      41068:                      49152
      38284:                      49153
    Target Node:                  node01
    Target Node Address:          10.128.0.46
    Target Node Domain Detected:  true
    Target Pod:                   virt-launcher-testvmimcbjgw6zrzcmp8wpddvztvzm7x2k6cjbdgktwv8tkq
```

## Canceling a live migration

Live migration can also be canceled by simply deleting the migration
object. A successfully aborted migration will indicate that the abort
has been requested `Abort Requested`, and that it succeeded:
`Abort Status: Succeeded`. The migration in this case will be `Completed`
and `Failed`.

```
Migration State:
    Abort Requested:  true
    Abort Status:     Succeeded
    Completed:        true
    End Timestamp:    2019-03-29T04:02:49Z
    Failed:           true
    Migration Config:
      Completion Timeout Per GiB:  800
      Progress Timeout:             150
    Migration UID:                  57a693d6-51d7-11e9-b370-525500d15501
    Source Node:                    node02
    Start Timestamp:                2019-03-29T04:02:47Z
    Target Direct Migration Node Ports:
      39445:                      0
      43345:                      49152
      44222:                      49153
    Target Node:                  node01
    Target Node Address:          10.128.0.46
    Target Node Domain Detected:  true
    Target Pod:                   virt-launcher-testvmimcbjgw6zrzcmp8wpddvztvzm7x2k6cjbdgktwv8tkq
```

### Using virtctl to cancel a live migration
Live migration can also be canceled using virtctl, by specifying the name
of a VMI which is currently being migrated
```console
    virtctl migrate-cancel vmi-fedora
```

## Changing Cluster Wide Migration Limits

KubeVirt puts some limits in place, so that migrations don't overwhelm
the cluster. By default, it is configured to only run `5` migrations in
parallel with an additional limit of a maximum of `2` outbound
migrations per node. Finally, every migration is limited to a bandwidth
of `64MiB/s`.

These values can be changed in the `kubevirt` CR:

```
    apiVersion: kubevirt.io/v1
    kind: Kubevirt
    metadata:
      name: kubevirt
      namespace: kubevirt
    spec:
      configuration:
        migrations:
          parallelMigrationsPerCluster: 5
          parallelOutboundMigrationsPerNode: 2
          bandwidthPerMigration: 64Mi
          completionTimeoutPerGiB: 800
          progressTimeout: 150
          disableTLS: false
          nodeDrainTaintKey: "kubevirt.io/drain"
          allowAutoConverge: false
          allowPostCopy: false
          unsafeMigrationOverride: false
```

Bear in mind that most of these configuration can be overridden and fine-tuned to
a specified group of VMs. For more information, please see [Migration Policies](./migration_policies.md).

## Understanding different migration strategies
Live migration is a complex process. During a migration, the source VM needs to transfer its
whole state (mainly RAM) to the target VM. If there are enough resources available, such as
network bandwidth and CPU power, migrations should converge nicely. If this is not the scenario,
however, the migration might get stuck without an ability to progress.

The main factor that affects migrations from the guest perspective is its `dirty rate`, which is the
rate by which the VM dirties memory. Guests with high dirty rate lead to a race during migration. On the
one hand, memory would be transferred continuously to the target, and on the other, the same memory
would get dirty by the guest. On such scenarios, one could consider to use more advanced migration
strategies.

Let's explain the 3 supported migration strategies as of today.

### Pre-copy
Pre-copy is the default strategy. It should be used for most cases.

The way it works is as following:
1. The target VM is created, but the guest keeps running on the source VM.
2. The source starts sending chunks of VM state (mostly memory) to the target. This continues until
all of the state has been transferred to the target.
3. The guest starts executing on the target VM.
4. The source VM is being removed.

Pre-copy is the safest and fastest strategy for most cases. Furthermore, it can be easily cancelled,
can utilize multithreading, and more. If there is no real reason to use another strategy, this is
definitely the strategy to go with.

However, on some cases migrations might not converge easily, that is, by the time the chunk of source
VM state would be received by the target VM, it would already be mutated by the source VM (which is
the VM the guest executes on). There are many reasons for migrations to fail converging, such as a
high dirty-rate or low resources like network bandwidth and CPU. On such scenarios, see the following
alternative strategies below.

### Post-copy
The way post-copy migrations work is as following:
1. The target VM is created.
2. The guest is being run on the **target VM**.
3. The source starts sending chunks of VM state (mostly memory) to the target.
4. When the guest, running on the target VM, would access memory:
   1. If the memory exists on the target VM, the guest can access it.
   2. Otherwise, the target VM asks for a chunk of memory from the source VM.
5. Once all of the memory state is updated at the target VM, the source VM is being removed.

The main idea here is that the guest starts to run immediately on the target VM. This approach
has advantages and disadvantages:

<u>advantages</u>:
* The same memory chink is never being transferred twice. This is possible due to the fact that
with post-copy it doesn't matter that a page had been dirtied since the guest is already running
on the target VM.
  * This means that a high dirty-rate has much less effect.
* Consumes less network bandwidth.

<u>disadvantages</u>:
* When using post-copy, the VM state has no one source of truth. When the guest (running on the
target VM) writes to memory, this memory is one part of the guest's state, but some other parts of
it may still be updated only at the source VM. This situation is generally dangerous, since, for 
example, if either the target or guest VMs crash the state cannot be recovered.
* Slow warmup: when the guest starts executing, no memory is present at the target VM. Therefore,
the guest would have to wait for a lot of memory in a short period of time.
* Slower than pre-copy on most cases.
* Harder to cancel a migration.

### Auto-converge
Auto-converge is a technique to help pre-copy migrations converge faster without changing the core
algorithm of how the migration works.

Since a high dirty-rate is usually the most significant factor for migrations to not converge,
auto-converge simply throttles the guest's CPU. If the migration would converge fast enough,
the guest's CPU would not be throttled or throttled negligibly. But, if the migration would
not converge fast enough, the CPU would be throttled more and more as time goes.

This technique dramatically increases the probability of the migration converging eventually.

## Using a different network for migrations

Live migrations can be configured to happen on a different network than
the one Kubernetes is configured to use.
That potentially allows for more determinism, control and/or bandwidth,
depending on use-cases.

### Creating a migration network on a cluster

A separate physical network is required, meaning that every node on the
cluster has to have at least 2 NICs, and the NICs that will be used for
migrations need to be interconnected, i.e. all plugged to the same switch.
The examples below assume that `eth1` will be used for migrations.

It is also required for the Kubernetes cluster to have
[multus](https://github.com/k8snetworkplumbingwg/multus-cni.git) installed.

If the desired network doesn't include a DHCP server, then
[whereabouts](https://github.com/k8snetworkplumbingwg/whereabouts) will
be needed as well.

Finally, a NetworkAttachmentDefinition needs to be created in the
namespace where KubeVirt is installed. Here is an example:
```
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: migration-network
  namespace: kubevirt
spec:
  config: '{
      "cniVersion": "0.3.1",
      "name": "migration-bridge",
      "type": "macvlan",
      "master": "eth1",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "10.1.1.0/24"
      }
    }'
```

### Configuring KubeVirt to migrate VMIs over that network

This is just a matter of adding the name of the
NetworkAttachmentDefinition to the KubeVirt CR, like so:
```
    apiVersion: kubevirt.io/v1
    kind: Kubevirt
    metadata:
      name: kubevirt
      namespace: kubevirt
    spec:
      configuration:
        developerConfiguration:
          featureGates:
          - LiveMigration
        migrations:
          network: migration-network
```

That change will trigger a restart of the virt-handler pods, as they
get connected to that new network.

From now on, migrations will happen over that network.

### Configuring KubeVirtCI for testing migration networks

Developers and people wanting to test the feature before deploying
it on a real cluster might want to configure a dedicated migration
network in KubeVirtCI.

KubeVirtCI can simply be configured to include a virtual secondary
network, as well as automatically install multus and whereabouts.
The following environment variables just have to be declared before
running `make cluster-up`:
```
export KUBEVIRT_NUM_NODES=2;
export KUBEVIRT_NUM_SECONDARY_NICS=1;
export KUBEVIRT_DEPLOY_ISTIO=true;
export KUBEVIRT_WITH_CNAO=true
```

## Migration timeouts

Depending on the type, the live migration process will copy virtual
machine memory pages and disk blocks to the destination. During this
process non-locked pages and blocks are being copied and become free for
the instance to use again. To achieve a successful migration, it is
assumed that the instance will write to the free pages and blocks
(pollute the pages) at a lower rate than these are being copied.

### Completion time

In some cases the virtual machine can write to different memory pages /
disk blocks at a higher rate than these can be copied, which will
prevent the migration process from completing in a reasonable amount of
time. In this case, live migration will be aborted if it is running for
a long period of time. The timeout is calculated base on the size of
the VMI, it's memory and the ephemeral disks that are needed to be
copied. The configurable parameter `completionTimeoutPerGiB`, which
defaults to 800s is the time for GiB of data to wait for the migration
to be completed before aborting it. A VMI with 8Gib of memory will time
out after 6400 seconds.

### Progress timeout

Live migration will also be aborted when it will be noticed that copying
memory doesn't make any progress. The time to wait for live migration to
make progress in transferring data is configurable by `progressTimeout`
parameter, which defaults to 150s

## Disabling secure migrations

**FEATURE STATE:** KubeVirt v0.43

Sometimes it may be desirable to disable TLS encryption of migrations to
improve performance. Use `disableTLS` to do that:

```
    apiVersion: kubevirt.io/v1
    kind: Kubevirt
    metadata:
      name: kubevirt
      namespace: kubevirt
    spec:
      configuration:
        developerConfiguration:
          featureGates:
            - "LiveMigration"
        migrationConfiguration:
          disableTLS: true
```

**Note:** While this increases performance it may allow MITM attacks. Be careful.
