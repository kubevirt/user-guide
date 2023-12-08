# Virtual machine memory dump  

Kubevirt now supports getting a VM memory dump for analysis purposes.
The Memory dump can be used to diagnose, identify and resolve issues in the VM. Typically providing information about the last state of the programs, applications and system before they were terminated or crashed.

> *Note* This memory dump is not used for saving VM state and resuming it later.

## Prerequisites

### Hot plug Feature Gate

The memory dump process mounts a PVC to the virt-launcher in order to get the output in that PVC, hence the hot plug volumes feature gate must be enabled. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `HotplugVolumes` to it.

## Virtctl support

### Get memory dump

Now lets assume we have a running VM and the name of the VM is 'my-vm'.
We can either dump to an existing pvc, or request one to be created.

#### Existing PVC
The size of the PVC must be big enough to hold the memory dump. The calculation is (VMMemorySize + 100Mi) * FileSystemOverhead, Where `VMMemorySize` is the memory size,
100Mi is reserved space for the memory dump overhead and `FileSystemOverhead` is the value used to adjust requested PVC size with the filesystem overhead.
also the PVC must have a `FileSystem` volume mode.

Example for such PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: rook-ceph-block
  volumeMode: Filesystem
```

We can get a memory dump of the VM to the PVC by using the 'memory-dump get' command available with virtctl

```bash
$ virtctl memory-dump get my-vm --claim-name=my-pvc
```

#### On demand PVC
For on demand PVC, we need to add `--create-claim` flag to the virtctl request:

```bash
$ virtctl memory-dump get my-vm --claim-name=new-pvc --create-claim
```

A PVC with size big enough for the dump will be created. We can also request specific storage class and access mode with appropriate flags.

#### Download memory dump
By adding the `--output` flag, the memory will be dumped to the PVC and then downloaded to the given output path.

```bash
$ virtctl memory-dump get myvm --claim-name=memoryvolume --create-claim --output=memoryDump.dump.gz
```

For downloading the last memory dump from the PVC associated with the VM, without triggering another memory dump, use the memory dump download command.

```bash
$ virtctl memory-dump download myvm --output=memoryDump.dump.gz
```

For downloading a memory dump from a PVC already disassociated from the VM you can use the [virtctl vmexport command](https://github.com/kubevirt/user-guide/blob/main/docs/operations/export_api.md)

### Monitoring the memory dump
Information regarding the memory dump process will be available on the VM's status section
```yaml
memoryDumpRequest:
  claimName: memory-dump
  phase: Completed
  startTimestamp: "2022-03-29T11:00:04Z"
  endTimestamp: "2022-03-29T11:00:09Z"
  fileName: my-vm-my-pvc-20220329-110004
```

During the process the volumeStatus on the VMI will be updated with the process information such as the attachment pod information and messages, if all goes well once the process is completed, the PVC is unmounted from the virt-launcher pod and the volumeStatus is deleted.
A memory dump annotation will be added to the PVC with the memory dump file name.

### Retriggering the memory dump
Getting a new memory dump to the same PVC is possible without the need to use any flag:
```bash
$ virtctl memory-dump get my-vm
```

> *Note* Each memory-dump command will delete the previous dump in that PVC.

In order to get a memory dump to a different PVC you need to 'remove' the current memory-dump PVC and then do a new get with the new PVC name.

### Remove memory dump

As mentioned in order to remove the associated memory dump PVC you need to run a 'memory-dump remove' command. This will allow you to replace the current PVC and get the memory dump to a new one.

```bash
$ virtctl memory-dump remove my-vm
```

## Handle the memory dump
Once the memory dump process is completed the PVC will hold the output.
You can manage the dump in one of the following ways:
- Download the memory dump
- Create a pod with troubleshooting tools that will mount the PVC and inspect it within the pod.
- Include the memory dump in the VM Snapshot (will include both the memory dump and the disks) to save a snapshot of the VM in that point of time and inspect it when needed. (The VM Snapshot can be exported and downloaded).

The output of the memory dump can be inspected with memory analysis tools for example [Volatility3](https://github.com/volatilityfoundation/volatility3)
