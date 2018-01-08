## Accessing a virtual machine

Once a virtual machine is started you are able to connect to the consoles it
exposes. Usually there are two types of consoles:

* Serial Console
* Graphical Console (VNC)

> Note: You need to have `virtctl` [installed](installation.md) to gain access
> to the VirtualMachine.

### Accessing the serial console

The serial console of a virtual machine can be accessed by using the `console`
command:

```bash
$ virtctl console --kubeconfig=$KUBECONFIG testvm
```

### Accessing the graphical console (VNC)

Accessing the graphical console of a virtual machine is usually done through
VNC, which requires `remote-viewer`. Once the tool is installed you can access
the graphical console using:

```bash
$ virtctl vnc --kubeconfig=$KUBECONFIG testvm
```
