# Live Update Network Attachment Definition Reference

Release:

- v1.8.0: Beta
- v1.9.0: GA

KubeVirt supports updating the NetworkAttachmentDefinition (NAD) reference on a running Virtual Machine (VM) without requiring a reboot. 
This allows the user to change the network a VM is connected to by modifying the `networkName` field and waiting for a live migration the VM.

This feature is useful when a VM needs to be moved between networks (e.g., different VLANs) while maintaining the same guest interface properties, including the MAC address.

## Requirements

To use this feature, the following requirements must be met:

- The VM must be live-migratable
- The `LiveUpdateNADRef` [feature-gate](https://kubevirt.io/user-guide/operations/activating_feature_gates/#how-to-activate-a-feature-gate) must be enabled (for v1.8.x Beta release)
- The target NetworkAttachmentDefinition must exist in the same namespace

> **Note**: From KubeVirt v1.9, the feature gate is no longer needed as the feature reached GA.

## What Gets Updated

When a NAD reference is updated:

- **Changed**: The `networkName` field in the network specification
- **Changed**: The pod network attachment (Multus annotation)
- **Preserved**: MAC address of the guest interface
- **Preserved**: Interface name and binding type
- **Preserved**: All other interface properties

## What Cannot Be Changed

This feature has the following limitations:

- Cannot change the CNI type
- Cannot change the network binding or plugin type
- Cannot update NAD reference on non-migratable VMs
- Does not maintain seamless network connectivity during the change
- Does not automatically update guest network configuration if required by the new network

## Updating NAD Reference on a Running VM

Start with a running VM connected to a secondary network:

```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          interfaces:
          - masquerade: {}
            name: defaultnetwork
          - bridge: {}
            name: bridge-net
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: defaultnetwork
        pod: {}
      - name: bridge-net
        multus:
          networkName: nad-with-vlan10
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:devel
        name: containerdisk
```

Two NetworkAttachmentDefinitions should be configured - the current one and the target one.

**Current NAD (nad-with-vlan10)**:
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

**Target NAD (nad-with-vlan20)**:
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

### Update the Network Reference

To change the network, edit the VM spec template and update the `networkName` field:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - masquerade: {}
            name: defaultnetwork
          - bridge: {}
            name: bridge-net
      networks:
      - name: defaultnetwork
        pod: {}
      - name: bridge-net
        multus:
          networkName: nad-with-vlan20  # Updated from nad-with-vlan10
```

This change can be applied using:
```bash
kubectl patch vm vm-fedora --type merge -p '{"spec":{"template":{"spec":{"networks":[{"name":"defaultnetwork","pod":{}},{"name":"bridge-net","multus":{"networkName":"nad-with-vlan20"}}]}}}}'
```

### Apply the Change Through Migration

The change to the NAD reference requires a live migration to take effect. The migration process will create a new pod with the updated network attachment.

#### Automatic Migration (Recommended)

If the [LiveUpdate roll-out strategy](../user_workloads/vm_rollout_strategies.md#liveupdate) is configured on the KubeVirt Custom Resource (CR), the VM will automatically migrate when the NAD reference is updated.

The VM will be migrated automatically, and once the migration completes, the VM will be connected to the new network.

#### Manual Migration

If automatic migration is not configured, a migration must be manually triggered:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: vm-fedora
EOF
```

Please refer to the [Live Migration](../compute/live_migration.md) documentation for more information.

### Verify the Change

Once the migration is completed, the VM connection to the new network can be verified:

```bash
# Check the VMI to see the updated network
kubectl get vmi vm-fedora -o yaml

# Check pod annotations to verify the new NAD reference
kubectl get pod virt-launcher-vm-fedora-xxxxx -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks}'
```

Network connectivity can also be verified from within the guest to ensure the new network is functioning correctly.

## Use Cases

This feature is particularly useful for:

- **VLAN Migration**: Moving VMs between different VLANs without downtime
- **Network Reconfiguration**: Updating network infrastructure while keeping VMs running
- **Tenant Migration**: Moving VMs between different tenant networks
- **Network Segmentation**: Changing network isolation boundaries for running workloads

## Compatibility with Multus Dynamic Networks Controller

If the cluster uses the [Multus Dynamic Networks Controller](https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller), the live NAD reference update will work through migration. However, in-place NAD swapping is not supported because the Dynamic Networks Controller cannot handle swapping a network interface (same MAC and interface name) from one NAD to another.

The migration-based approach ensures compatibility with all cluster configurations, whether or not the Dynamic Networks Controller is present.

## Notes and Best Practices

- The guest OS may require network configuration changes if the new network has different properties (e.g., different IP subnet, gateway). This is not handled automatically.
- Ensure the target NetworkAttachmentDefinition exists before updating the reference to avoid migration failures.
- Network connectivity will be briefly interrupted during the migration process.
- The interface MAC address is preserved, ensuring the guest OS recognizes the same network interface.
- It is recommended to avoid performing additional migrations while a NAD reference update migration is in progress.

> **Note**: This feature only changes which NetworkAttachmentDefinition the interface references. It does not change the binding type, interface model, or other interface properties. For adding or removing interfaces, see [Hotplug Network Interfaces](hotplug_interfaces.md).
