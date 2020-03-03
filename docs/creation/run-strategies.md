Run Strategies
==============

Overview
--------

VirtualMachines have a `Running` setting that determines whether or not
there should be a guest running or not. Because KubeVirt will always
immediately restart a VirtualMachineInstance for VirtualMachines with
`spec.running: true`, a simple boolean is not always enough to fully
describe desired behavior. For instance, there are cases when a user
would like the ability to shut down a guest from inside the virtual
machine. With `spec.running: true`, KubeVirt would immediately restart
the VirtualMachineInstance.

### RunStrategy

To allow for greater variation of user states, the `RunStrategy` field
has been introduced. This is mutually exclusive with `Running` as they
have somewhat overlapping conditions. There are currently four
RunStrategies defined:

-   Always: A VirtualMachineInstance will always be present. If the
    VirtualMachineInstance crashed, a new one will be spawned. This is
    the same behavior as `spec.running: true`.

-   RerunOnFailure: A VirtualMachineInstance will be respawned if the
    previous instance failed in an error state. It will not be
    re-created if the guest stopped successfully (e.g. shut down from
    inside guest).

-   Manual: The presence of a VirtualMachineInstance or lack thereof is
    controlled exclusively by the start/stop/restart VirtualMachint
    subresource endpoints.

-   Halted: No VirtualMachineInstance will be present. If a guest is
    already running, it will be stopped. This is the same behavior as
    `spec.running: false`.

*Note*: RunStrategy and Running are mutually exclusive, because they can
be contradictory. The API server will reject VirtualMachine resources
that define both.

Virtctl
-------

The `start`, `stop` and `restart` methods of virtctl will invoke their
respective subresources of VirtualMachines. This can have an effect on
the runStrategy of the VirtualMachine as below:

<table>
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
<td><p><code>-</code></p></td>
<td><p><code>Halted</code></p></td>
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

Table entries marked with `-` don’t make sense, so won’t have an effect
on RunStrategy.

RunStrategy Examples
--------------------

### Always

An example usage of the Always RunStrategy.

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachine
    metadata:
      labels:
        kubevirt.io/vm: vm-cirros
      name: vm-cirros
    spec:
      runStrategy: always
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
