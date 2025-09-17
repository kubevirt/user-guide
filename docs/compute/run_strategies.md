# Run Strategies
#
> **⚠️ Deprecation Notice:**
> 
> The `spec.running` field is **deprecated** and should no longer be used to control VirtualMachine lifecycle. Use `spec.runStrategy` instead. Defining both `runStrategy` and `running` is **not allowed** and will be rejected by the API server. Always prefer `spec.runStrategy` for new and existing VirtualMachines.

## Overview

VirtualMachines have a `Running` setting that determines whether or not
there should be a guest running or not. Because KubeVirt will always
immediately restart a VirtualMachineInstance for VirtualMachines with
`spec.running: true`, a simple boolean is not always enough to fully
describe desired behavior. For instance, there are cases when a user
would like the ability to shut down a guest from inside the virtual
machine. With `spec.running: true`, KubeVirt would immediately restart
the VirtualMachineInstance.

## RunStrategy

To allow for greater variation of user states, the `RunStrategy` field
has been introduced. This is mutually exclusive with `Running` as they
have somewhat overlapping conditions. There are currently five
RunStrategies defined:

-   Always: The system is tasked with keeping the VM in a running
    state.
    This is achieved by respawning a VirtualMachineInstance whenever
    the current one terminated in a controlled (e.g. shutdown from
    inside the guest) or uncontrolled (e.g. crash) way.
    This behavior is equal to `spec.running: true`.

-   RerunOnFailure: Similar to `Always`, except that the VM is only
    restarted if it terminated in an uncontrolled way (e.g. crash)
    and due to an infrastructure reason (i.e. the node crashed,
    the KVM related process OOMed).
    This allows a user to determine when the VM should be shut down
    by initiating the shut down inside the guest.
    Note: Guest sided crashes (i.e. BSOD) are not covered by this.
    In such cases liveness checks or the use of a watchdog can help.

-   Once: The VM will run once and not be restarted upon completion
    regardless if the completion is of phase Failure or Success.

-   Manual: The system will not automatically turn the VM on or off,
    instead the user manually controlls the VM status by issuing
    start, stop, and restart commands on the VirtualMachine
    subresource endpoints.

-   Halted: The system is asked to ensure that no VM is running.
    This is achieved by stopping any VirtualMachineInstance that is
    associated ith the VM. If a guest is already running, it will be
    stopped.
    This behavior is equal to `spec.running: false`.

*Note*: `RunStrategy` and `running` are mutually exclusive, because
they can be contradictory. The API server will reject VirtualMachine
resources that define both.

> **Best Practice:**
> - Use `spec.runStrategy` for all new and existing VirtualMachines.
> - Do **not** use `spec.running`—it is deprecated and will be removed in future releases.
> - Defining both fields is invalid and will be rejected.

### Virtctl

The `start`, `stop` and `restart` methods of virtctl will invoke their
respective subresources of VirtualMachines. This can have an effect on
the runStrategy of the VirtualMachine as below:

<table style="width: 100% ; display: inline-table">
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead>
<tr class="header">
<th>RunStrategy</th>
<th>start</th>
<th>stop</th>
<th>restart</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><strong>Always</strong></p></td>
<td><p><code>-</code></p></td>
<td><p><code>Halted</code></p></td>
<td><p><code>Always</code></p></td>
</tr>
<tr class="even">
<td><p><strong>RerunOnFailure</strong></p></td>
<td><p><code>RerunOnFailure</code></p></td>
<td><p><code>RerunOnFailure</code></p></td>
<td><p><code>RerunOnFailure</code></p></td>
</tr>
<tr class="odd">
<td><p><strong>Manual</strong></p></td>
<td><p><code>Manual</code></p></td>
<td><p><code>Manual</code></p></td>
<td><p><code>Manual</code></p></td>
</tr>
<tr class="even">
<td><p><strong>Halted</strong></p></td>
<td><p><code>Always</code></p></td>
<td><p><code>-</code></p></td>
<td><p><code>-</code></p></td>
</tr>
</tbody>
</table>

Table entries marked with `-` don't make sense, so won't have an effect
on RunStrategy.

## RunStrategy Examples

### Always

An example usage of the Always RunStrategy.

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: vm-cirros
  name: vm-cirros
spec:
  runStrategy: Always
  template:
    metadata:
      labels:
        kubevirt.io/vm: vm-cirros
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: kubevirt/cirros-container-disk-demo:latest
        name: containerdisk
```
