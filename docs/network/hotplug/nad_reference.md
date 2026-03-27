# Live update NAD Reference

Release:

- v1.8.0: Beta
- v1.9.0: GA (planned)

KubeVirt supports updating the NetworkAttachmentDefinition (NAD) reference on a running Virtual Machine (VM) without requiring a reboot.
This allows the user to change the network a VM is connected to by modifying the `networkName` field and waiting for a live migration of the VMI.

This feature is useful when a VM needs to be moved between networks (e.g., different VLANs) while maintaining the same guest interface properties like name or MAC address.

## Requirements

To use this feature, the following requirements must be met:

- The VM must be live-migratable
- The `LiveUpdateNADRef` [feature-gate](https://kubevirt.io/user-guide/operations/activating_feature_gates/#how-to-activate-a-feature-gate) must be enabled (for v1.8 Beta release)
- The target NetworkAttachmentDefinition must exist

## Process of updating NAD Reference on a Running VM
Current NAD
```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: nad-with-vlan10
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "nad-with-vlan10",
    "type": "bridge",
    "bridge": "br1",
    "vlan": 10
  }'
```

Target NAD
```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: nad-with-vlan20
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "nad-with-vlan20",
    "type": "bridge",
    "bridge": "br2",
    "vlan": 20
  }'
```

Start with a running VM connected to a secondary network attached to the current NAD:

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
...
  template:
    spec:
      domain:
        devices:
          interfaces:
          - bridge: {}
            name: bridge-net
...
      networks:
      - name: bridge-net
        multus:
          networkName: nad-with-vlan10
...
```

To change the network, edit the VM spec template and update the `networkName` field:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
...
  template:
    spec:
      domain:
        devices:
          interfaces:
          - bridge: {}
            name: bridge-net
      networks:
      - name: bridge-net
        multus:
          networkName: nad-with-vlan20  # Updated from nad-with-vlan10
```

This change will trigger a live migration which in turn creates a new pod connected to the new NAD.
Please refer to the [Live Migration](../../compute/live_migration.md) documentation for more information.

## Limitations
- This feature is not supported with [Multus Dynamic networks Controller](https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller)
- Moving to a different CNI type may fail, especially if the new CNI type requires additional configuration.
- Switching to a new binding type/binding plugin is not supported.
- Only migratable VMs can be updated as migration cannot be triggered on non migratable VMIs, which have `LiveMigratable`: `False` condition in their status.
- Network connectivity may be interrupted during the live migration process.
- When updating multiple VMs only a limited number of migrations run in parallel. So updates may be queued. For more information, see [Changing Cluster Wide Migration Configuration](../../compute/live_migration.md#changing-cluster-wide-migration-configuration).

