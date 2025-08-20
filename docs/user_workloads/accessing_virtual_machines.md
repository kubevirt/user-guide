# Accessing Virtual Machines

There are various methods to access `VirtualMachines`, as illustrated below.

To clarify: Consider a `VirtualMachineInstance` as a running `VirtualMachine`.

## Graphical and Serial Console Access

Once a virtual machine is started you are able to connect to the consoles it
exposes. Usually there are two types of consoles:

- Serial Console
- Graphical Console (VNC)

> Note: You need to have `virtctl`
> [installed](../user_workloads/virtctl_client_tool.md) to gain
> access to the VirtualMachineInstance.

### Accessing the Serial Console

The serial console of a virtual machine can be accessed by using the `console`
command:

```shell
virtctl console testvm
```

### Accessing the Graphical Console (VNC)

To access the graphical console of a virtual machine the VNC protocol is
typically used. This requires `remote-viewer` to be installed. Once the
tool is installed, you can access the graphical console using:

```shell
virtctl vnc testvm
```

If you only want to open a vnc-proxy without executing the `remote-viewer`
command, it can be accomplished with:

```shell
virtctl vnc --proxy-only testvm
```

This would print the port number on your machine where you can manually connect
using any VNC viewer.

### Debugging console access

If the connection fails, you can use the `-v` flag to get more verbose
output from both `virtctl` and the `remote-viewer` tool to troubleshoot the
problem.

```shell
virtctl vnc testvm -v 4
```

> **Note:** If you are using virtctl via SSH on a remote machine, you need to
> forward the X session to your machine. Look up the -X and -Y flags of `ssh` if
> you are not familiar with that. As an alternative you can proxy the API server
> port with SSH to your machine (either direct or in combination
> with `kubectl proxy`).

## SSH Access

A common operational pattern used when managing virtual machines is to inject
SSH public keys into the virtual machines at boot. This allows automation tools
(like Ansible) to provision the virtual machine. It also gives operators a way
of gaining secure and passwordless access to a virtual machine.

KubeVirt provides multiple ways to inject SSH public keys into a virtual
machine.

In general, these methods fall into two categories:
 - [Static key injection](../user_workloads/accessing_virtual_machines.md#static-ssh-key-injection-via-cloud-init),
which places keys on the virtual machine the first time it is booted.
 - [Dynamic key injection](../user_workloads/accessing_virtual_machines.md#dynamic-ssh-key-injection-via-qemu-user-agent),
which allows keys to be dynamically updated both at boot and during runtime.

Once a SSH public key is injected into the virtual machine, it can be
accessed via `virtctl`.

### Static SSH public key injection via cloud-init

Users creating virtual machines can provide startup scripts to their virtual
machines, allowing multiple customization operations.

One option for injecting public SSH keys into a VM is via
[cloud-init startup script](../user_workloads/startup_scripts.md#cloud-init).
However, there are more flexible options available.

The virtual machine's access credential API allows statically injecting SSH
public keys at startup time independently of the cloud-init user data by
placing the SSH public key into a Kubernetes `Secret`. This allows keeping the
application data in the cloud-init user data separate from the credentials
used to access the virtual machine.

A Kubernetes `Secret` can be created from an SSH public key like this:

```shell
# Place SSH public key into a Secret
kubectl create secret generic my-pub-key --from-file=key1=id_rsa.pub
```

The `Secret` containing the public key is then assigned to a virtual machine
using the access credentials API with the `noCloud` propagation method.

KubeVirt injects the SSH public key into the virtual machine by using the
generated cloud-init metadata instead of the user data. This separates
the application user data and user credentials.

> Note: The cloud-init `userData` is not touched.

```shell
# Create a VM referencing the Secret using propagation method noCloud
kubectl create -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          rng: {}
        resources:
          requests:
            memory: 1024M
      terminationGracePeriodSeconds: 0
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: my-pub-key
          propagationMethod:
            noCloud: {}
      volumes:
      - containerDisk:
          image: quay.io/containerdisks/fedora:latest
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
        name: cloudinitdisk
EOF
```

### Dynamic SSH public key injection via qemu-guest-agent

KubeVirt allows the dynamic injection of SSH public keys into a VirtualMachine with the access credentials API.

Utilizing the `qemuGuestAgent` propagation method, configured Secrets are attached to a VirtualMachine when the VM is started. 
This allows for dynamic injection of SSH public keys at runtime by updating the attached Secrets.

Please note that new Secrets cannot be attached to a running VM: You must restart the VM to attach the new Secret.

> Note: This requires the qemu-guest-agent to be installed within the guest.
>
> Note: When using qemuGuestAgent propagation,
> the `/home/$USER/.ssh/authorized_keys` file will be owned by the guest agent.
> Changes to the file not made by the guest agent will be lost.
>
> Note: More information about the motivation behind the access credentials API
> can be found in the
> [pull request description](https://github.com/kubevirt/kubevirt/pull/4195)
> that introduced the API.

In the example below the `Secret` containing the SSH public key is
attached to the virtual machine via the access credentials API with the
`qemuGuestAgent` propagation method. This allows updating the contents of
the `Secret` at any time, which will result in the changes getting applied
to the running virtual machine immediately. The `Secret` may also contain
multiple SSH public keys.

```shell
# Place SSH public key into a secret
kubectl create secret generic my-pub-key --from-file=key1=id_rsa.pub
```

Now reference this secret in the `VirtualMachine` spec with the access
credentials API using
`qemuGuestAgent` propagation.

```shell
# Create a VM referencing the Secret using propagation method qemuGuestAgent
kubectl create -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          rng: {}
        resources:
          requests:
            memory: 1024M
      terminationGracePeriodSeconds: 0
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: my-pub-key
          propagationMethod:
            qemuGuestAgent:
              users:
              - fedora
      volumes:
      - containerDisk:
          image: quay.io/containerdisks/fedora:latest
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
            # Disable SELinux for now, so qemu-guest-agent can write the authorized_keys file
            # The selinux-policy is too restrictive currently, see open bugs:
            #   - https://bugzilla.redhat.com/show_bug.cgi?id=1917024
            #   - https://bugzilla.redhat.com/show_bug.cgi?id=2028762
            #   - https://bugzilla.redhat.com/show_bug.cgi?id=2057310
            bootcmd:
              - setenforce 0
        name: cloudinitdisk
EOF
```

### Accessing a VM or VMI using virtctl

The user can create a websocket backed network tunnel to a port inside a VMI
by using the `virtualmachineinstances/portforward` subresource of a
`VirtualMachineInstance` or the `virtualmachines/portfoward` subresource of a
`VirtualMachine`.

One use case for these subresources is to forward SSH traffic into
a `VirtualMachineInstance` either from the CLI or a web-UI. The `VirtualMachine`
subresource will automatically look up the corresponding `VirtualMachineInstance`.

To connect to a `VirtualMachineInstance` from your local machine, `virtctl`
wraps the local SSH client with the `ssh` command and transparently uses port
forwarding as described above. Refer to the command's help for more details.

```shell
virtctl ssh
```

To transfer files from or to a `VirtualMachineInstance` `virtctl` also
provides an SCP client with the `scp` command. Its usage is similar to the `ssh` command.
Refer to the command's help for more details.

```shell
virtctl scp
```

#### Using virtctl as proxy

The preferred way of connecting to VMs and VMIs is to use `virtctl` to wrap
local OpenSSH clients. If you prefer to use your local OpenSSH client directly
instead, there is also a way of doing that in combination with `virtctl`.

> Note: Most of this applies to the `virtctl scp` command too.

1. By default `virtctl` wraps the local OpenSSH client transparently
   to the user. The executed SSH command can be viewed by increasing the verbosity (`-v 3`).

```shell
virtctl ssh --local-ssh -v 3 vm/testvm/mynamespace
```

2. The `virtctl port-forward` command provides an option to tunnel a single
   port to your local stdout/stdin. This allows the command to be used in
   combination with the OpenSSH client's `ProxyCommand` option.

```shell
ssh -o 'ProxyCommand=virtctl port-forward --stdio=true vm/testvm/mynamespace 22' fedora@vm/testvm/mynamespace
```

To provide easier access to arbitrary virtual machines you can add the following
lines to your SSH `config`:

```
Host vmi/*
   ProxyCommand virtctl port-forward --stdio=true %h %p
Host vm/*
   ProxyCommand virtctl port-forward --stdio=true %h %p
```

This allows you to simply call `ssh user@vm/testvm/mynamespace` and your
SSH `config` and `virtctl` will do the rest. Using this method, it becomes easy
to set up different identities for different namespaces inside your SSH
`config`.

This feature can also be used with Ansible to automate configuration of virtual
machines running on KubeVirt. You can put the snippet above into its own
file (e.g. `~/.ssh/virtctl-proxy-config`) and add the following lines to
your `.ansible.cfg`:

```
[ssh_connection]
ssh_args = -F ~/.ssh/virtctl-proxy-config
```

Note that all port forwarding traffic will be sent over the Kubernetes
control plane. A high amount of connections and traffic can increase
pressure on the API server. If you regularly need a high amount of connections
and traffic consider using a dedicated Kubernetes `Service` instead.

#### Example

1. Create virtual machine and inject SSH public key as explained above

2. SSH into virtual machine

```shell
virtctl ssh -i id_rsa fedora@vm/testvm/mynamespace
```

or

```shell
ssh -o 'ProxyCommand=virtctl port-forward --stdio=true vm/testvm/mynamespace 22' -i id_rsa fedora@vm/testvm/mynamespace
```

3. SCP file to the virtual machine

```shell
virtctl scp -i id_rsa testfile fedora@vm/testvm/mynamespace:/tmp
```

or

```shell
scp -o 'ProxyCommand=virtctl port-forward --stdio=true vmi/testvm/mynamespace 22' -i id_rsa testfile fedora@vm.testvm.mynamespace:/tmp
```

!!! Note
    Local `scp` does not support slashes in hostnames. Therefore the example
    uses dots to separate the type, name and namespace like `virtctl` does when
    wrapping the local SCP client.

#### RBAC permissions for Console/VNC/SSH access

##### Using default RBAC cluster roles

Every KubeVirt installation starting with version v0.5.1 ships a set of default
RBAC cluster roles that can be used to grant users access to
VirtualMachineInstances.

The `kubevirt.io:admin` and `kubevirt.io:edit` cluster roles have console,
VNC and SSH respectively port-forwarding access permissions built into them. By
binding either of these roles to a user, they will have the ability to use
virtctl to access the console, VNC and SSH.

##### Using custom RBAC cluster role

The default KubeVirt cluster roles grant access to more than just the
console, VNC and port-forwarding. The `ClusterRole` below demonstrates how
to craft a custom role, that only allows access to the console, VNC and
port-forwarding.

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: allow-console-vnc-port-forward-access
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachineinstances/console
      - virtualmachineinstances/vnc
    verbs:
      - get
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachineinstances/portforward
    verbs:
      - update
```

When bound with a `ClusterRoleBinding` the `ClusterRole` above grants access
to virtual machines across all namespaces.

In order to reduce the scope to a single namespace, bind this `ClusterRole`
using a `RoleBinding` that targets a single namespace.
