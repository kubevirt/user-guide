# Graphical and Serial Console Access

Once a virtual machine is started you are able to connect to the consoles it
exposes. Usually there are two types of consoles:

* Serial Console
* Graphical Console \(VNC\)

> Note: You need to have `virtctl` [installed](/installation/?id=client-side-virtctl-deployment) to gain access to the VirtualMachineInstance.

## Accessing the serial console

The serial console of a virtual machine can be accessed by using the
`console` command:

```bash
$ virtctl console --kubeconfig=$KUBECONFIG testvmi
```

## Accessing the graphical console \(VNC\)

Accessing the graphical console of a virtual machine is usually done through
VNC, which requires `remote-viewer`. Once the tool is installed you can
access the graphical console using:

```bash
$ virtctl vnc --kubeconfig=$KUBECONFIG testvmi
```

## Debugging console access

Should the connection fail, you can use the `-v` flag to get more output
from both `virtctl` and the `remote-viewer` tool, to troubleshoot the problem.

```bash
$ virtctl vnc --kubeconfig=$KUBECONFIG testvmi -v 4
```

> **Note:** If you are using virtctl via ssh on a remote machine, you need to
> forward the X session to your machine (Look up the -X and -Y flags of `ssh`
> if you are not familiar with that). As an alternative you can proxy the
> apiserver port with ssh to your machine (either direct or in combination with
> `kubectl proxy`)

## RBAC Permissions for Console/VNC Access

### Using Default RBAC ClusterRoles

Every KubeVirt installation after version v0.5.1 comes a set of default RBAC
cluster roles that can be used to grant users access to VirtualMachineInstances.

The **kubevirt.io:admin** and **kubevirt.io:edit** ClusterRoles have console
and VNC access permissions built into them. By binding either of these roles
to a user, they will have the ability to use virtctl to access console and VNC.

### With Custom RBAC ClusterRole

The default KubeVirt ClusterRoles give access to more than just console in VNC.
In the event that an Admin would like to craft a custom role that targets only
console and VNC, the ClusterRole below demonstrates how that can be done.

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: allow-vnc-console-access
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachineinstances/console
      - virtualmachineinstances/vnc
    verbs:
      - get
```

The ClusterRole above provides access to virtual machines across all namespaces.

In order to reduce the scope to a single namespace, bind this ClusterRole using
a RoleBinding that targets a single namespace.
