# Live Migration

Live migration is a process during which a running Virtual Machine
Instance moves to another compute node while the guest workload
continues to run and remain accessable.

## Enabling the live-migration support

Live migration must be eabled in the featue gates to be supported. The
`feature-gates` field in the kubevirt-config config map can be expanded
by adding the `LiveMigration` to it.

```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      feature-gates: "LiveMigration"
```

Alternatively, existing kubevirt-config can be altered:

```kubectl edit configmap kubevirt-config -n kubevirt`

```
    data:
      feature-gates: "DataVolumes,LiveMigration"
```

## Limitations

-   Virtual machines using a PersistentVolumeClaim (PVC) must have a
    shared ReadWriteMany (RWX) access mode to be live migrated.

-   Live migration is not allowed with a pod network binding of bridge
    interface type
    (<https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/interfaces-and-networks.html>)

## Initiate live migration

Live migration is initiated by posting a VirtualMachineInstanceMigration
(VMIM) object to the cluster. The example below starts a migration
process for a virtual machine instance `vmi-fedora`

```
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: vmi-fedora
```

## Migration Status Reporting

# Condition and migration method

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

```
Status:
  Conditions:
    Status:                True
    Type:                  LiveMigratable
  Migration Method:  BlockMigration
```

# Migration Status

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

## Cancel live migration

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

## Changing Cluster Wide Migration Limits

KubeVirt puts some limits in place, so that migrations don’t overwhelm
the cluster. By default it is configured to only run `5` migrations in
parallel with an additional limit of a maximum of `2` outbound
migrations per node. Finally every migration is limited to a bandwidth
of `64MiB/s`.

These values can be change in the `kubevirt-config`:

```
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      feature-gates: "LiveMigration"
      migrations: |-
        parallelMigrationsPerCluster: 5
        parallelOutboundMigrationsPerNode: 2
        bandwidthPerMigration: 64Mi
        completionTimeoutPerGiB: 800
        progressTimeout: 150
```

# Migration timeouts

Depending on the type, the live migration process will copy virtual
machine memory pages and disk blocks to the destination. During this
process non-locked pages and blocks are being copied and become free for
the instance to use again. To achieve a successful migration, it is
assumed that the instance will write to the free pages and blocks
(pollute the pages) at a lower rate than these are being copied.

## Completion time

In some cases the virtual machine can write to different memory pages /
disk blocks at a higher rate than these can be copied, which will
prevent the migration process from completing in a reasonable amount of
time. In this case, live migration will be aborted if it is running for
a long perioud of time. The timeout is calculated base on the size of
the VMI, it’s memory and the ephemeral disks that are needed to be
copied. The configurable parameter `completionTimeoutPerGiB`, which
deafults to 800s is the time for GiB of data to wait for the migration
to be completed before aborting it. A VMI with 8Gib of memory will time
out after 6400 seconds.

## Progress timeout

Live migration will also be aborted when it will be noticed that copying
memory doesn’t make any progress. The time to wait for live migration to
make progress in transferring data is configurable by `progressTimeout`
parameter, which defaults to 150s
