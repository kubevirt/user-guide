# Virtual machine memory dump  

Kubevirt now supports getting a VM memory dump for analysis purposes.

## Prerequisites

### Hot plug Feature Gate

The memory dump process mounts a PVC to the virt-launcher in order to get the output in that PVC, hence the hot plug volumes feature gate must be enabled. The
[feature gates](./activating_feature_gates.md#how-to-activate-a-feature-gate)
field in the KubeVirt CR must be expanded by adding the `HotplugVolumes` to it.

### A PVC to hold the memory dump output

Currently in order to get the memory dump output a pre-existing PVC is required. The size of the PVC must be big enough to hold the memory dump (The VM memory size + 100Mi overhead).

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
```

The PVC must be a FileSystem volume mode PVC.

## Virtctl support

### Get memory dump

Now lets assume we have a running VM and the name of the VM is 'my-vm'.
We can get a memory dump of this VM to the above PVC by using the 'memory-dump get' command available with virtctl

```bash
$ virtctl memory-dump get my-vm --claim-name=my-pvc
```

This will dump the memory of the running VM to the given PVC.
The information of the memory dump will be updated on the VM status.
```yaml
    memoryDumpRequest:
      claimName: memory-dump
      phase: Completed
      startTimestamp: "2022-03-29T11:00:04Z"
      endTimestamp: "2022-03-29T11:00:09Z"
      fileName: my-vm-my-pvc-20220329-110004
```

During the process the volumeStatus on the VMI will be updated with the process information such as the attachment pod information and messages, if all goes well once the process is completed, the PVC is unmounted from the virt-launcher pod and the volumeStatus is deleted.

Getting a new memory dump to the same PVC is possible without the need to use the claim-name flag.
Each memory-dump command will delete the previous dump in that PVC.
In order to get a memory dump to a different PVC you need to 'remove' the current memory-dump PVC and then do a new get with the new PVC name.

### Remove memory dump

As mentioned in order to remove the associated memory dump PVC you need to run a 'memory-dump remove' command. This will allow you to replace the current PVC and get the memory dump to a new one.

```bash
$ virtctl memory-dump remove my-vm
```

## Handle the memory dump
Once the memory dump process is completed the PVC will hold the output.
There are several options to get the dump out of the PVC:
- Copy it from the PVC to your local environment by using virtctl scp command(for more info look for virtctl scp help). This is useful if the VM memory is pretty small.
- Use Export mechanism by:
    - Exporting only the PVC (not supported yet)
    - Include the memory dump in the VMSnapshot and export the whole VMSnapshot (will include both the memory dump and the disks) (not supported yet) 

The output of the memory dump can be used for memory analysis with different tools for example [Volatility3](https://github.com/volatilityfoundation/volatility3)