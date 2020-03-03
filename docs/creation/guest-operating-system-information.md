Guest Operating System Information
==================================

Guest operating system identity for the VirtualMachineInstance will be
provided by the label `kubevirt.io/os` :

    metadata:
      name: myvmi
      labels:
        kubevirt.io/os: win2k12r2

The `kubevirt.io/os` label is based on the short OS identifier from
[libosinfo](https://libosinfo.org/) database. The following Short IDs
are currently supported:

<table>
<colgroup>
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
</colgroup>
<thead>
<tr class="header">
<th>Short ID</th>
<th>Name</th>
<th>Version</th>
<th>Family</th>
<th>ID</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><strong>win2k12r2</strong></p></td>
<td><p>Microsoft Windows Server 2012 R2</p></td>
<td><p>6.3</p></td>
<td><p>winnt</p></td>
<td><p><a href="http://microsoft.com/win/2k12r2">http://microsoft.com/win/2k12r2</a></p></td>
</tr>
</tbody>
</table>

Use with presets
----------------

A VirtualMachineInstancePreset representing an operating system with a
`kubevirt.io/os` label could be applied on any given
VirtualMachineInstance that have and match the\`kubevirt.io/os\` label.

Default presets for the OS identifiers above are included in the current
release.

### Windows Server 2012R2 `VirtualMachineInstancePreset` Example

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstancePreset
    metadata:
      name: windows-server-2012r2
      selector:
        matchLabels:
          kubevirt.io/os: win2k12r2
    spec:
      domain:
        cpu:
          cores: 2
        resources:
          requests:
            memory: 2G
        features:
          acpi: {}
          apic: {}
          hyperv:
            relaxed: {}
            vapic: {}
            spinlocks:
              spinlocks: 8191
        clock:
          utc: {}
          timer:
            hpet:
              present: false
            pit:
              tickPolicy: delay
            rtc:
              tickPolicy: catchup
            hyperv: {}
    ---
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      labels:
        kubevirt.io/os: win2k12r2
      name: windows2012r2
    spec:
      terminationGracePeriodSeconds: 0
      domain:
        firmware:
          uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
        devices:
          disks:
          - name: server2012r2
            disk:
              dev: vda
      volumes:
        - name: server2012r2
          persistentVolumeClaim:
            claimName: my-windows-image

Once the `VirtualMachineInstancePreset` is applied to the
`VirtualMachineInstance`, the resulting resource would look like this:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      annotations:
        presets.virtualmachineinstances.kubevirt.io/presets-applied: kubevirt.io/v1alpha3
        virtualmachineinstancepreset.kubevirt.io/windows-server-2012r2: kubevirt.io/v1alpha3
      labels:
        kubevirt.io/os: win2k12r2
      name: windows2012r2
    spec:
      terminationGracePeriodSeconds: 0
      domain:
        cpu:
          cores: 2
        resources:
          requests:
            memory: 2G
        features:
          acpi: {}
          apic: {}
          hyperv:
            relaxed: {}
            vapic: {}
            spinlocks:
              spinlocks: 8191
        clock:
          utc: {}
          timer:
            hpet:
              present: false
            pit:
              tickPolicy: delay
            rtc:
              tickPolicy: catchup
            hyperv: {}
        firmware:
          uuid: 5d307ca9-b3ef-428c-8861-06e72d69f223
        devices:
          disks:
          - name: server2012r2
            disk:
              dev: vda
      volumes:
        - name: server2012r2
          persistentVolumeClaim:
            claimName: my-windows-image

For more information see [VirtualMachineInstancePresets](presets.md)

HyperV optimizations
--------------------

KubeVirt supports quite a lot of so-called "HyperV enlightenments",
which are optimizations for Windows Guests. Some of these optimization
may require an up to date host kernel support to work properly, or to
deliver the maximum performance gains.

KubeVirt can perform extra checks on the hosts before to run Hyper-V
enabled VMs, to make sure the host has no known issues with Hyper-V
support, properly expose all the required features and thus we can
expect optimal performance. These checks are disabled by default for
backward compatibility and because they depend on the
[node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery)
and on extra configuration.

To enable strict host checking, the user may expand the `feature-gates`
field in the kubevirt-config config map by adding the
`HypervStrictCheck` to it.

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubevirt-config
      namespace: kubevirt
      labels:
        kubevirt.io: ""
    data:
      feature-gates: "HypervStrictCheck"

Alternatively, users can edit an existing kubevirt-config:

`kubectl edit configmap kubevirt-config -n kubevirt`

    data:
      feature-gates: "HypervStrictCheck,CPUManager"
