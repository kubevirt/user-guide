# Hotplug Network Interfaces

**Warning**: The feature is in alpha stage and its API may be changed in the future.

KubeVirt supports hotplugging and unplugging network interfaces into a running Virtual Machine (VM). 

Hotplug is supported for interfaces using the `virtio` model connected through
[bridge binding](http://kubevirt.io/api-reference/main/definitions.html#_v1_interfacebridge) 
or [SR-IOV binding](http://kubevirt.io/api-reference/main/definitions.html#_v1_interfacesriov).

Hot-unplug is supported only for interfaces connected through
[bridge binding](http://kubevirt.io/api-reference/main/definitions.html#_v1_interfacebridge).

## Requirements
Adding an interface to a KubeVirt Virtual Machine requires first an interface
to be added to a running pod. This is not trivial, and has some requirements:

- [Multus Dynamic Networks Controller](https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller):
  this daemon will listen to annotation changes, and trigger Multus to configure
  a new attachment for this pod.
- Multus CNI running as a [thick plugin](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/thick-plugin.md):
  this Multus version exposes an endpoint to create attachments for a given pod
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
[Multus documentation](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/how-to-use.md#create-network-attachment-definition)
for more information.

Once the virtual machine is running, and the attachment configuration
provisioned, the user can request the interface hotplug operation by 
editing the VM spec template and adding the desired interface and network:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
template:
  spec:
    domain:
      devices:
        interfaces:
        - name: defaultnetwork
          masquerade: {}
          # new interface
        - name: dyniface1
          bridge: {}
    networks:
    - name: defaultnetwork
      pod: {}
      # new network
    - name: dyniface1
      multus:
        networkName: new-fancy-net
 ...
```
> **Note**: `virtctl` `addinterface` and `removeinterface` commands are no longer available, hotplug/unplug interfaces is done by editing the VM spec template.

The interface and network will be added to the corresponding VMI object as well by Kubevirt.

You can now check the VMI status for the presence of this new interface:
```bash
kubectl get vmi vm-fedora -ojsonpath="{ @.status.interfaces }"
```

## Removing an interface from a running VM
Following the example above, the user can request an interface unplug operation
by editing the VM spec template and set the desired interface state to `absent`:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
template:
  spec:
    domain:
      devices:
        interfaces:
          - name: defaultnetwork
            masquerade: {}
          # set the interface state to absent 
          - name: dyniface1
            state: absent
            bridge: {}
    networks:
      - name: defaultnetwork
        pod: {}
      - name: dyniface1
        multus:
          networkName: new-fancy-net
```
The interface in the corresponding VMI object will be set with state 'absent' as well by Kubevirt.

>**Note**: Existing VMs from version v0.59.0 and below do not support hot-unplug interfaces.

## Migration based hotplug
In case your cluster doesn't run Multus as 
[thick plugin](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/thick-plugin.md) 
and 
[Multus Dynamic Networks controller](https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller), 
it's possible to hotplug an interface by migrating the VM.

The actual attachment won't take place immediately, and the new interface will be available in the guest once the migration is completed.

### Add new interface
Add the desired interface and network to the VM spec template:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
template:
  spec:
    domain:
      devices:
        interfaces:
        - name: defaultnetwork
          masquerade: {}
          # new interface
        - name: dyniface1
          bridge: {}
    networks:
    - name: defaultnetwork
      pod: {}
      # new network
    - name: dyniface1
      multus:
        networkName: new-fancy-net
 ...
```

At this point the interface and network will be added to the corresponding VMI object as well, but won't be attached to the guest.

#### Migrate the VM
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
Please refer to the [Live Migration](./live_migration.md) documentation for more information.

Once the migration is completed the VM will have the new interface attached.

>**Note**: It is recommended to avoid performing migrations in parallel to a hotplug operation. 
> It is safer to assure hotplug succeeded or at least reached the VMI specification before issuing a migration.

### Remove interface
Set the desired interface state to `absent` in the VM spec template:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
template:
  spec:
    domain:
      devices:
        interfaces:
          - name: defaultnetwork
            masquerade: {}
          # set the interface state to absent 
          - name: dyniface1
            state: absent
            bridge: {}
    networks:
      - name: defaultnetwork
        pod: {}
      - name: dyniface1
        multus:
          networkName: new-fancy-net
```

At this point the subject interface should be detached from the guest but exist in the pod.

>**Note**: Existing VMs from version v0.59.0 and below do not support hot-unplug interfaces.

#### Migrate the VM
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
Please refer to the [Live Migration](./live_migration.md) documentation for more information.

Once the VM is migrated, the interface will not exist in the migration target pod.

>**Note**: It is recommended to avoid performing migrations in parallel to an unplug operation.
> It is safer to assure unplug succeeded or at least reached the VMI specification before issuing a migration.

### SR-IOV interfaces
Kubevirt supports hot-plugging of SR-IOV interfaces to running VMs.

Similar to bridge binding interfaces, edit the VM spec template
and add the desired SR-IOV interface and network:
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
template:
  spec:
    domain:
      devices:
        interfaces:
        - name: defaultnetwork
          masquerade: {}
          # new interface
        - name: sriov-net
          sriov: {}
    networks:
    - name: defaultnetwork
      pod: {}
      # new network
    - name: sriov-net
      multus:
        networkName: sriov-net-1
 ...
```
Please refer to the [Interface and Networks](https://kubevirt.io/user-guide/virtual_machines/interfaces_and_networks/#sriov)
documentation for more information about SR-IOV networking.

At this point the interface and network will be added to the corresponding VMI object as well, but won't be attached to the guest.

#### Migrate the VM
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
Please refer to the [Live Migration](./live_migration.md) documentation for more information.

Once the VM is migrated, the interface will not exist in the migration target pod.
Due to limitation of Kubernetes device plugin API to allocate resources dynamically,
the SR-IOV device plugin cannot allocate additional SR-IOV resources for Kubevirt to hotplug.
Thus, SR-IOV interface hotplug is limited to migration based hotplug only, regardless of Multus "thick" version.

## Virtio Limitations
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

> **Note**: The user can execute this command against a stopped VM - i.e. a VM
> without an associated VMI. When this happens, KubeVirt mutates the VM spec
> template on behalf of the user.

