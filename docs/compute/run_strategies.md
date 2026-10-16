# Run Strategies

## Overview

VirtualMachines have a `spec.runStrategy` field that determines whether
or not there should be a guest running, and what KubeVirt should do when
the guest stops.

Older manifests use the boolean `spec.running` field instead. Because
KubeVirt will always immediately restart a VirtualMachineInstance for
VirtualMachines with `spec.running: true`, a simple boolean is not always
enough to fully describe desired behavior. For instance, there are cases
when a user would like the ability to shut down a guest from inside the
virtual machine. With `spec.running: true`, KubeVirt would immediately
restart the VirtualMachineInstance.

!!! warning
    `spec.running` is deprecated since KubeVirt v1.4.0. Use
    `spec.runStrategy` instead: `spec.running: true` corresponds to
    `runStrategy: Always`, and `spec.running: false` corresponds to
    `runStrategy: Halted`. The API server still accepts `spec.running`,
    but returns the warning
    `spec.running is deprecated, please use spec.runStrategy instead.`
    when a VirtualMachine that sets it is created or updated.

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
    associated with the VM. If a guest is already running, it will be
    stopped.
    This behavior is equal to `spec.running: false`.

*Note*: `RunStrategy` and `running` are mutually exclusive, because
they can be contradictory. The API server will reject VirtualMachine
resources that define both.

### Virtctl

The `start`, `stop` and `restart` methods of virtctl will invoke their
respective subresources of VirtualMachines. This can have an effect on
the runStrategy of the VirtualMachine as below:

| RunStrategy        | start              | stop               | restart            |
|--------------------|--------------------|--------------------|--------------------| 
| **Always**         | `-`                | `Halted`           | `Always`           |
| **RerunOnFailure** | `RerunOnFailure`   | `RerunOnFailure`   | `RerunOnFailure`   |
| **Manual**         | `Manual`           | `Manual`           | `Manual`           |
| **Halted**         | `Always`           | `-`                | `-`                |

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
