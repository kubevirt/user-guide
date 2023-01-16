# Client Passthrough

KubeVirt included support for redirecting devices from the client's machine to the VMI with the
support of virtctl command.

## USB Redirection

Support for redirection of client's USB device was introduced in release v0.44. This feature is not
enabled by default. To enable it, add an empty `clientPassthrough` under devices, as such:

```yaml
spec:
  domain:
    devices:
      clientPassthrough: {}
```

This configuration currently adds 4 USB slots to the VMI that can only be used with virtctl.

There are two ways of redirecting the same USB devices: Either using its device's vendor and product
information or the actual bus and device address information. In Linux, you can gather this info
with `lsusb`, a redacted example below:

```shell
> lsusb
Bus 002 Device 008: ID 0951:1666 Kingston Technology DataTraveler 100 G3/G4/SE9 G2/50
Bus 001 Device 003: ID 13d3:5406 IMC Networks Integrated Camera
Bus 001 Device 010: ID 0781:55ae SanDisk Corp. Extreme 55AE
```

### Using Vendor and Product

Redirecting the Kingston storage device.
```
virtctl usbredir 0951:1666 vmi-name
```


### Using Bus and Device address

Redirecting the integrated camera
```
virtctl usbredir 01-03 vmi-name
```

### Requirements

#### usbredirect

The `usbredirect` binary is used by virtctl to handle client's USB device. It comes from the
[usbredir]() project and is supported by most Linux distros. You can either fetch the [latest release]
or [MSI installer]() for Windows support.

[usbredir]: https://gitlab.freedesktop.org/spice/usbredir/
[latest release]: https://www.spice-space.org/download/usbredir/
[MSI installer]: https://www.spice-space.org/download/windows/usbredirect/

#### Permissions

Managing USB devices requires privileged access in most Operation Systems. The user running
`virtctl usbredir` would need to be privileged or run it in a privileged manner (e.g: with `sudo`)

#### Windows support

- Redirecting USB devices on Windows requires the installation of [UsbDk]().
- Be sure to have `usbredirect` included in the PATH Enviroment Variable.

[UsbDk]: https://github.com/daynix/UsbDk
