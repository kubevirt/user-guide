## Accessing a virtual machine

Once a virtual machine is started you are able to connect to the consoles it
exposes. Usually there are two types of consoles:

* Serial Console
* Graphical Console

> Note: You need to have `virtctl` [installed](installation.md) to gain access
> to the VirtualMachine.

### Accessing the serial console

The serial console of a virtual machine can be accessed by using the `console`
command:

```bash
$ virtctl console -s http://mycluster:8184 testvm
```

### Accessing the graphical console

Accessing the graphical console of a virtual machine is usually done through
SPICE, which requires a SPICE client like `remote-viewer`. Once the tool is
installed you can access the graphical console using:

```bash
$ virtctl spice -s http://mycluster:8184 testvm
```

Optional `--proxy` (e.g. `http://192.168.200.2:1234`) can be used. This is
useful when you are outside of the cluster or a non-reachable proxy is provided
by the system.

#### Grapical console connection details

Instead of establishing the connection, `virtctl` can provide the connection
details, which can then be used with a tool of your choice to manually
establish the connection. The connection details can be retrieved by running:

```bash
$ virtctl spice -s http://mycluster:8184 --details testvm
```



