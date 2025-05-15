# Running legacy Windows versions

Legacy Windows versions like Windows XP or Windows Server 2003 are unable to
boot on KubeVirt out of the box. This is due to the combination of the Q35
machine-type and a 64-Bit PCI hole reported to the guest,
that is not supported by these operating systems.

To run legacy Windows versions on KubeVirt, reporting of the 64-Bit PCI hole
needs to be disabled. This can be achieved by adding the
`kubevirt.io/disablePCIHole64` annotation with a value of `true` to a
`VirtualMachineInstance`'s annotations.

## Example

With this `VirtualMachine` definition a legacy Windows guest is able to boot:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: xp
spec:
  runStrategy: Always
  template:
    metadata:
      annotations:
        kubevirt.io/disablePCIHole64: "true"
    spec:
      domain:
        devices: {}
        memory:
          guest: 512Mi
      terminationGracePeriodSeconds: 180
      volumes:
      - containerDisk:
          image: my/windowsxp:containerdisk
        name: xp-containerdisk-0
```
