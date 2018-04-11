# Access

Once a virtual machine is started you are able to connect to the consoles it exposes. Usually there are two types of consoles:

* Serial Console
* Graphical Console \(VNC\)

> Note: You need to have `virtctl` [installed](../../installation/) to gain access to the VirtualMachine.

## RBAC Permissions for Console/VNC Access

Admins with full cluster privileges already have access to all virtual machines.

Users and Service Accounts can be granted access to virtual machine console/VNC access via RBAC roles.

Below is an example of a ClusterRole which grants access to all virtual machine consoles and VNC.

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: allow-vnc-console-access
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachines/console
      - virtualmachines/vnc
    verbs:
      - get
```

The ClusterRole above provides access to virtual machines across all namespaces. In order to reduce the scope to a single namespace, use a Role object instead.

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: allow-vnc-console-access
  namespace: default
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachines/console
      - virtualmachines/vnc
    verbs:
      - get
```

## Accessing the serial console

The serial console of a virtual machine can be accessed by using the `console` command:

```bash
$ virtctl console --kubeconfig=$KUBECONFIG testvm
```

## Accessing the graphical console \(VNC\)

Accessing the graphical console of a virtual machine is usually done through VNC, which requires `remote-viewer`. Once the tool is installed you can access the graphical console using:

```bash
$ virtctl vnc --kubeconfig=$KUBECONFIG testvm
```

