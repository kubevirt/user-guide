# PCI Topology and Hotplug Port Reservation

KubeVirt virtual machines use the q35 machine type, which relies on PCIe root
ports for device attachment. Each device — disk, network interface, controller —
occupies one root port. To support [hotplugging volumes](../storage/hotplug_volumes.md)
and [hotplugging network interfaces](../network/hotplug_interfaces.md) after
boot, empty root ports must be reserved at VM creation time because libvirt
does not allow adding root ports to a running VM.

The way these ports are reserved determines the PCI bus addresses assigned to
all devices. If the reservation strategy changes between reboots, devices can
shift to different PCI addresses. This is particularly problematic for:

- **Windows VMs**: Windows marks non-OS disks as offline when they appear at
  new PCI addresses (due to the default SAN policy `OfflineShared`).
- **Applications using PCI addresses**: Software that references devices by
  PCI address (udev rules, DPDK bindings) will break when addresses change.

## How Port Reservation Works

KubeVirt reserves hotplug ports by injecting temporary placeholder network
interfaces during the initial domain definition. Libvirt assigns root ports to
these placeholders, then the placeholders are removed in a second pass, leaving
empty ports available for hotplug.

The number of placeholder ports depends on how many network interfaces the VM
has. If the VM has no interfaces, no placeholders are reserved (hotplug
requires at least one interface). Otherwise:

```
placeholders = max(0, 4 - number_of_interfaces)
```

| Interfaces | Placeholders |
|:----------:|:------------:|
| 0          | 0            |
| 1          | 3            |
| 2          | 2            |
| 3          | 1            |
| 4+         | 0            |

Additional hotplug capacity beyond these placeholders is provided by appending
extra `pcie-root-port` controllers. These controllers sit on bus 0 and provide
new buses for devices without affecting the PCI addresses of existing devices.

The number of extra controllers scales based on VM memory:

| Memory | Total minimum hotplug ports |
|:------:|:--------------------------:|
| <= 2GB | 3                          |
| > 2GB  | 6                          |

## PCI Topology Versions

KubeVirt has used three versions of the port reservation strategy. Understanding
these is important when upgrading, as VMs created under different versions may
behave differently.

### v1 — Fixed Placeholders (KubeVirt < 1.6)

The original strategy. Uses `max(0, 4 - interfaces)` placeholders, providing
up to 3 hotplug ports regardless of VM size.

**Example** (1 interface):

```
Bus 0x01: Network interface
Bus 0x02: (empty — available for hotplug)
Bus 0x03: (empty — available for hotplug)
Bus 0x04: (empty — available for hotplug)
Bus 0x05: SCSI controller
Bus 0x06: virtio-serial controller
Bus 0x07: Root disk (vda)
Bus 0x08: Memory balloon
```

### v2 — Memory-Scaled Placeholders (KubeVirt 1.6 and 1.7)

Increased hotplug capacity by scaling the placeholder count based on VM memory.
This was introduced to support more hotplug devices, but it had the side effect
of **shifting all device PCI addresses** compared to v1.

**Example** (1 interface, >2GB memory):

```
Bus 0x01: Network interface
Bus 0x02–0x0a: (empty — available for hotplug)
Bus 0x0b: SCSI controller
Bus 0x0c: virtio-serial controller
Bus 0x0d: Root disk (vda)          ← SHIFTED from 0x07
Bus 0x0e: Memory balloon
```

The disk moved from bus `0x07` to `0x0d`. Additionally, the v2 placeholder
count depended on the total number of ports in use, meaning that adding or
removing disks or interfaces from the VM spec could shift all device addresses
— even without a KubeVirt upgrade.

### v3 — Fixed Placeholders + Extra Controllers (KubeVirt >= 1.8)

Combines the v1 placeholder formula for address stability with extra
`pcie-root-port` controllers for additional hotplug capacity. Controllers are
appended after all devices, so they do not shift any existing PCI addresses.

The v3 fix has also been backported to KubeVirt 1.6.4 and 1.7.2.

**Example** (1 interface, >2GB memory):

```
Bus 0x01: Network interface
Bus 0x02: (empty — available for hotplug)
Bus 0x03: (empty — available for hotplug)
Bus 0x04: (empty — available for hotplug)
Bus 0x05: SCSI controller
Bus 0x06: virtio-serial controller
Bus 0x07: Root disk (vda)          ← SAME as v1
Bus 0x08: Memory balloon
Bus 0x09–0x0e: (extra controllers for hotplug)
```

Same hotplug capacity as v2, same device addresses as v1.

## Upgrade Behavior

### Upgrading from v1 (< 1.6) to v3 (1.6.4+, 1.7.2+, or 1.8+)

**No impact.** v3 uses the same placeholder formula as v1, so device addresses
remain stable. The extra controllers are appended after existing devices.

### Upgrading from v2 (1.6 or 1.7) to v3 (1.6.4+, 1.7.2+, or 1.8+)

The behavior depends on whether the VM was **running** or **stopped** during
the upgrade.

#### Running VMs (addresses preserved automatically)

VMs that were running when KubeVirt was upgraded have their PCI topology
automatically detected and preserved:

1. KubeVirt inspects the running VM's domain XML and detects the v2 placeholder
   count.
2. The VM is annotated with `kubevirt.io/pci-topology-version: v2` and
   `kubevirt.io/pci-interface-slot-count` (the frozen placeholder count).
3. These annotations are propagated to the VM spec.
4. On subsequent reboots, the frozen placeholder count is used, keeping PCI
   addresses stable.

**No action is required** for these VMs. The addresses are preserved
automatically.

#### Stopped VMs (one-time address shift)

VMs that were **stopped** during the upgrade cannot be detected as v2, since
there is no running domain to inspect. When they next start:

1. The VM gets the v3 topology (v1 placeholder formula).
2. Device PCI addresses shift back to the v1 layout — a **one-time change**.

This may cause issues for **Windows VMs** that had been running with v2
addresses. See the troubleshooting section below.

## Troubleshooting

### Windows VM Disks Appear Offline After Upgrading to KubeVirt 1.6 or 1.7

**Symptom**: After upgrading to KubeVirt 1.6 or 1.7 and rebooting a VM that
was previously running on an earlier version, Windows data disks appear as
"offline" in Disk Management.

**Cause**: The v2 topology introduced in KubeVirt 1.6 changed the number of
hotplug placeholder ports, which shifted all device PCI addresses. Windows
treats disks at new PCI addresses as new SAN disks and applies the
`OfflineShared` policy, taking them offline.

There are two ways to fix this — choose whichever best fits your situation:

#### Option 1: Apply v3 topology (no guest changes required)

Since v3 uses the same PCI layout as v1, upgrading to a version with the v3
fix restores devices to their original PCI addresses. This is the recommended
approach if your VMs existed before KubeVirt 1.6.

1. Upgrade KubeVirt to 1.6.4, 1.7.2, or 1.8+.

2. If the VM has v2 annotations (because it was running during the upgrade),
   remove them:

    ```bash
    kubectl patch vm <vm-name> --type=json -p '[
      {"op": "remove", "path": "/spec/template/metadata/annotations/kubevirt.io~1pci-topology-version"},
      {"op": "remove", "path": "/spec/template/metadata/annotations/kubevirt.io~1pci-interface-slot-count"}
    ]'
    ```

3. Reboot the VM. It will start with v3 topology and device addresses will
   return to their original v1 positions.

#### Option 2: Fix inside the guest

If you cannot upgrade KubeVirt, or if the VM was created on KubeVirt 1.6/1.7
and has no prior v1 addresses to return to, you can bring the disks back online
from within Windows:

1. Open **Disk Management** (`diskmgmt.msc`) or use `diskpart`:

    ```
    diskpart
    list disk
    select disk <number>
    online disk
    ```

2. Repeat for each offline disk.

To prevent this from happening on future reboots, you can change the SAN
policy to `OnlineAll`:

```
diskpart
san policy=OnlineAll
```

!!! note
    The `OnlineAll` SAN policy tells Windows to automatically bring all newly
    discovered disks online. Only use this if your environment does not require
    the shared disk protection that `OfflineShared` provides.

### Checking a VM's PCI Topology Version

You can inspect the PCI topology annotations on a VM:

```bash
kubectl get vm <vm-name> -o jsonpath='{.spec.template.metadata.annotations}' | jq .
```

Look for:

- `kubevirt.io/pci-topology-version` — `v2` or `v3`
- `kubevirt.io/pci-interface-slot-count` — only present for v2 VMs, indicates
  the frozen placeholder count

If no annotation is present, the VM has not yet been started under a KubeVirt
version with the v3 fix (1.6.4+, 1.7.2+, or 1.8+) and will receive `v3` on
its next start.
