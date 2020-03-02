# Retrieving the `virtctl` client tool

Basic VirtualMachineInstance operations can be performed with the stock
`kubectl` utility. However, the `virtctl` binary utility is required to
use advanced features such as:

-   Serial and graphical console access

It also provides convenience commands for:

-   Starting and stopping VirtualMachineInstances

-   Live migrating VirtualMachineInstances

There are two ways to get it:

-   the most recent version of the tool can be retrieved from the
    [official release
    page](https://github.com/kubevirt/kubevirt/releases)

-   it can be installed as a `kubectl` plugin using
    [krew](https://krew.dev/)

Example:

```
export VERSION=v0.26.1
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-x86_64
```

## Install `virtctl` with `krew`

It is required to [install `krew` plugin
manager](https://github.com/kubernetes-sigs/krew/#installation)
beforehand. If `krew` is installed, `virtctl` can be installed via
`krew`:

    $ kubectl krew install virt

Then `virtctl` can be used as a kubectl plugin. For a list of available
commands run:

    $ kubectl virt help

Every occurrence throughout this guide of

    $ ./virtctl <command>...

should then be read as

    $ kubectl virt <command>...

