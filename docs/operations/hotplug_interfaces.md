# Hotplug Network Interfaces

**Warning**: The feature is in alpha stage and its API may be changed in the future.

KubeVirt now supports hotplugging network interfaces into a running Virtual
Machine (VM). Hotplug is only supported for interfaces using the
`virtio` model connected through
[bridge binding](http://kubevirt.io/api-reference/main/definitions.html#_v1_interfacebridge).

## Requirements
Adding an interface to a KubeVirt Virtual Machine requires first an interface
to be added to a running pod. This is not trivial, and has some requirements:

- [multus dynamic networks controller](https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller):
  this daemon will listen to annotation changes, and trigger multus to configure
  a new attachment for this pod.
- multus running as a [thick plugin](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/thick-plugin.md):
  this multus version exposes an endpoint to create attachments for a given pod
  on demand.

### Enabling network interface hotplug support
Network interface hotplug support must be enabled via a
[feature gate](https://kubevirt.io/user-guide/operations/activating_feature_gates/#how-to-activate-a-feature-gate).
The feature gates array in the KubeVirt CR must feature `HotplugNICs`.

## Adding an interface to a running VM
First start a VM. You can refer to the following example:
```yaml
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
spec:
  running: true
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
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: defaultnetwork
        pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/kubevirt/fedora-with-test-tooling-container-disk:devel
        name: containerdisk
```

You should configure a network attachment definition - where the pod interface
configuration is held. The snippet below shows an example of a very simple one:
```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: new-fancy-net
spec:
    config: '{
      "cniVersion": "0.3.1",
      "type": "bridge",
      "mtu": 1300,
      "name":"new-fancy-net"
    }'
```

Please refer to the
[multus documentation](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/how-to-use.md#create-network-attachment-definition)
for more info.

Once the virtual machine is running, and the attachment configuration
provisioned, the user can request the interface hotplug operation. Please refer
to the following snippet:
```bash
virtctl addinterface vm-fedora --network-attachment-definition-name new-fancy-net --name dyniface1
```
This will add the interface and network to the VM spec template and to the running VMI object.

**NOTE**: You can use the `--help` parameter for more information on each
parameter.

You can now check the VMI status for the presence of this new interface:
```bash
kubectl get vmi vm-fedora -ojsonpath="{ @.status.interfaces }"
```

## Removing an interface from a running VM
Following the example above, the user can request an interface unplug operation. Please refer to the following snippet:
```bash
virtctl removeinterface vm-fedora --name dyniface1
```
The subject interface state will be set as absent in the VM spec template and the running VMI object.  

>**Note**: Existing VMs from version v0.59.0 and below does not support hot-unplug interfaces.

## Migration based hotplug
In case your cluster doesn't run Multus as [thick plugin](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/thick-plugin.md) and [Multus Dynamic Networks controller](https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller), it's possible to hotplug an interface by migrating the VM.

The actual attachment won't take place immediately, and the new interface will be available in the guest once the migration is completed.

### Add new interface
```bash
virtctl addinterface vm-fedora --network-attachment-definition-name new-fancy-net --name dyniface1
```
At this point the new interface is added to the spec but will not be attached to the running VM. 

### Migrate the VM
```bash
cat <<EOF kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: vmi-fedora
EOF
```
See the [Live Migration](./live_migration.md) docs for more details.

Once the migration is completed the VM will have the new interface attached.

>**Note**: It is recommended to avoid performing migrations in parallel to a hotplug operation. 
> It is safer to assure hotplug succeeded or at least reached the VMI specification before issuing a migration.

### Remove interface
```bash
virtctl removeinterface vm-fedora --name dyniface1
```
At this point the subject interface should be detached from the guest but exist in the pod.

### Migrate the VM
```bash
cat <<EOF kubectl apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  name: migration-job
spec:
  vmiName: vmi-fedora
EOF
```
See the [Live Migration](./live_migration.md) docs for more details.

Once the VM is migrated, the interface will not exist in the migration target pod.

>**Note**: It is recommended to avoid performing migrations in parallel to an unplug operation.
> It is safer to assure unplug succeeded or at least reached the VMI specification before issuing a migration.

### Virtio Limitations
The hotplugged interfaces have `model: virtio`. This imposes several
limitations: each interface will consume a PCI slot in the VM, and there are a
total maximum of 32. Furthermore, other devices will also use these PCI slots
(e.g. disks, guest-agent, etc).

Kubevirt reserves resources for 4 interface to allow later hotplug operations.
The actual maximum amount of available resources depends on the machine
type (e.g. q35 adds another PCI slot).
For more information on maximum limits, see
[libvirt documentation](https://libvirt.org/pci-hotplug.html).

Yet, upon a VM restart, the hotplugged interface will become part of the standard networks;
this mitigates the maximum hotplug interfaces (per machine type) limitation.

**NOTE**: the user can execute this command against a stopped VM - i.e. a VM
without an associated VMI. When this happens, KubeVirt mutates the VM spec
template on behalf of the user.

