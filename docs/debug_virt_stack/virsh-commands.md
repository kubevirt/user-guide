# Execute virsh commands in virt-launcher pod

A powerful utility to check and troubleshoot the VM state is [`virsh`](https://www.libvirt.org/manpages/virsh.html) and the utility is already installed in the `compute` container on the virt-launcher pod.

For example, it possible to run any QMP commands.

For a full list of QMP command, please refer to the [QEMU documentation](https://qemu-project.gitlab.io/qemu/interop/qemu-qmp-ref.html).

```console
$ kubectl get po
NAME                                READY   STATUS    RESTARTS   AGE
virt-launcher-vmi-ephemeral-xg98p   3/3     Running   0          44m
$ kubectl exec -ti virt-launcher-vmi-debug-tools-fk64q -- bash
bash-5.1$ virsh list
 Id   Name                      State
-----------------------------------------
 1    default_vmi-debug-tools   running
bash-5.1$ virsh qemu-monitor-command default_vmi-debug-tools query-status --pretty
{
  "return": {
    "status": "running",
    "singlestep": false,
    "running": true
  },
  "id": "libvirt-439"
}
$ virsh qemu-monitor-command default_vmi-debug-tools query-kvm --pretty
{
  "return": {
    "enabled": true,
    "present": true
  },
  "id": "libvirt-438"
}
```

Another useful virsh command is the `qemu-monitor-event`. Once invoked, it observes and reports the QEMU events.

The following example shows the events generated for pausing and unpausing the guest.

```console
$ kubectl get po
NAME                                READY   STATUS    RESTARTS   AGE
virt-launcher-vmi-ephemeral-nqcld   3/3     Running   0          57m
$ kubectl exec -ti virt-launcher-vmi-ephemeral-nqcld -- virsh qemu-monitor-event --pretty --loop
```

Then, you can, for example, pause and then unpause the guest and check the triggered events:
```console
$ virtctl pause vmi vmi-ephemeral
VMI vmi-ephemeral was scheduled to pause
 $ virtctl unpause vmi vmi-ephemeral
VMI vmi-ephemeral was scheduled to unpause
```

From the monitored events:
```console
$ kubectl exec -ti virt-launcher-vmi-ephemeral-nqcld -- virsh qemu-monitor-event --pretty --loop
event STOP at 1698405797.422823 for domain 'default_vmi-ephemeral': <null>
event RESUME at 1698405823.162458 for domain 'default_vmi-ephemeral': <null>
```
