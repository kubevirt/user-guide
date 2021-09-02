# Accessing Virtual Machines

## Graphical and Serial Console Access

Once a virtual machine is started you are able to connect to the
consoles it exposes. Usually there are two types of consoles:

-   Serial Console
-   Graphical Console (VNC)

> Note: You need to have `virtctl`
> [installed](../operations/virtctl_client_tool.md) to gain
> access to the VirtualMachineInstance.


### Accessing the serial console

The serial console of a virtual machine can be accessed by using the
`console` command:

    $ virtctl console --kubeconfig=$KUBECONFIG testvmi


### Accessing the graphical console (VNC)

Accessing the graphical console of a virtual machine is usually done
through VNC, which requires `remote-viewer`. Once the tool is installed
you can access the graphical console using:

    $ virtctl vnc --kubeconfig=$KUBECONFIG testvmi

If you need to open only a vnc-proxy without executing the `remote-viewer` command, it can be done using:

    $ virtctl vnc --kubeconfig=$KUBECONFIG --proxy-only testvmi

this would print the port number on your machine where you can manually connect using any of the vnc viewers

### Debugging console access

Should the connection fail, you can use the `-v` flag to get more output
from both `virtctl` and the `remote-viewer` tool, to troubleshoot the
problem.

    $ virtctl vnc --kubeconfig=$KUBECONFIG testvmi -v 4

> **Note:** If you are using virtctl via ssh on a remote machine, you
> need to forward the X session to your machine (Look up the -X and -Y
> flags of `ssh` if you are not familiar with that). As an alternative
> you can proxy the apiserver port with ssh to your machine (either
> direct or in combination with `kubectl proxy`)


### RBAC Permissions for Console/VNC Access

#### Using Default RBAC ClusterRoles

Every KubeVirt installation after version v0.5.1 comes a set of default
RBAC cluster roles that can be used to grant users access to
VirtualMachineInstances.

The **kubevirt.io:admin** and **kubevirt.io:edit** ClusterRoles have
console and VNC access permissions built into them. By binding either of
these roles to a user, they will have the ability to use virtctl to
access console and VNC.


#### With Custom RBAC ClusterRole

The default KubeVirt ClusterRoles give access to more than just console
in VNC. In the event that an Admin would like to craft a custom role
that targets only console and VNC, the ClusterRole below demonstrates
how that can be done.

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

The ClusterRole above provides access to virtual machines across all
namespaces.

In order to reduce the scope to a single namespace, bind this
ClusterRole using a RoleBinding that targets a single namespace.

## SSH Access

A common operational pattern used when managing virtual machines is to inject
public ssh keys into the virtual machines at boot. This allows automation tools
(like ansible) to provision the virtual machine. It also gives operators a way
of gaining secure passwordless access to a virtual machine.

KubeVirt provides multiple ways to inject ssh public keys into a virtual
machine. In general, these methods fall into two categories. [Static key injection](./accessing_virtual_machines.md#static-ssh-key-injection-via-cloud-init),
 which places keys on the virtual machine the first time it is
booted, and [dynamic injection](./accessing_virtual_machines.md#dynamic-ssh-key-injection-via-qemu-user-agent), which allows keys to be dynamically updated
both at boot and during runtime.

### Static SSH Key Injection via Cloud Init

Users creating virtual machines have the ability to provide startup scripts to
their virtual machines which allow any number of custom operations to take place.
Placing public ssh keys into a [cloud-init startup script](./startup_scripts.md#cloud-init) is one option people
have for getting their public keys into the virtual machine, however there are
some other options that grant more flexibility.

The VM's access credential api allows statically injecting ssh public keys at creation
time independently of the cloud-init user data by placing the ssh public key
in a Kubernetes secret. This is useful because it allows people creating virtual
machines to separate the application data in their cloud-init user data from the
credentials used to access the virtual machine.

For example, someone can put their ssh key into a Kubernetes secret like this.

```
# Place ssh key into a secret

kubectl create secret generic my-pub-key --from-file=key1=/id_rsa.pub
```

Then assign that key to the virtual machine with the access credentials api
using the configDrive propagation method. Note here how the cloud-init user
data is not touched. KubeVirt is injecting the ssh key into the virtual machine
using the machine generated cloud-init metadata, and not the user data. This
keeps the application user date separate from credentials.


```
#Create a vm yaml that references the secret in using the access credentials api.


cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: my-vm
  name: my-vm
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: fedora-dv
    spec:
      pvc:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
        storageClassName: local
      source:
        registry:
          url: docker://quay.io/kubevirt/fedora-cloud-container-disk-demo
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: my-vm
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: disk0
          - disk:
              bus: virtio
            name: disk1
        machine:
          type: ""
        resources:
          requests:
            cpu: 1000m
            memory: 1G
      terminationGracePeriodSeconds: 0
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: my-pub-key
          propagationMethod:
            configDrive: {}
      volumes:
      - dataVolume:
          name: fedora-dv
        name: disk0
      - cloudInitConfigDrive:
          userData: |
            #!/bin/bash
            echo "Application setup goes here"
        name: disk1
END

kubectl create -f my-vm.yaml

```

### Dynamic SSH Key Injection via Qemu User Agent

KubeVirt supports dynamically injecting public ssh keys at run time through the
use of the qemu guest agent. This is achieved through the access credentials
api by using the qemuGuestAgent propagation method.

> Note: This requires the qemu guest agent to be installed within the guest
>
> Note: When using qemuGuestAgent propagation, the `/home/$USER/.ssh/authorized_keys`
> file will be owned by the guest agent. Changes to that file that are made
> outside of the qemu guest agent's control will get deleted.
>
> Note: More information about the motivation behind the access credentials
> api can be found in the [pull request description](https://github.com/kubevirt/kubevirt/pull/4195) that introduced this api.

In the example below, a secret contains an ssh key. When attached to the
VM via the access credential api with the qemuGuestAgent propagation method,
the contents of the secret can be updated at any time which will automatically
get applied to a running VM. The secret can contain multiple public keys.

```
# Place ssh key into a secret

kubectl create secret generic my-pub-key --from-file=key1=/id_rsa.pub
```

Now reference this secret on the VM with the access credentials api using
qemuGuestAgent propagation. This example installs and starts the qemu guest
agent using a cloud-init script in order to ensure the agent is available.

```
# Create a vm yaml that references the secret in using the access credentials api.


cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: my-vm
  name: my-vm
spec:
  dataVolumeTemplates:
  - metadata:
      creationTimestamp: null
      name: fedora-dv
    spec:
      pvc:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
        storageClassName: local
      source:
        registry:
          url: docker://quay.io/kubevirt/fedora-cloud-container-disk-demo
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: my-vm
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: disk0
          - disk:
              bus: virtio
            name: disk1
        machine:
          type: ""
        resources:
          requests:
            cpu: 1000m
            memory: 1G
      terminationGracePeriodSeconds: 0
      accessCredentials:
      - sshPublicKey:
          source:
            secret:
              secretName: my-pub-key
          propagationMethod:
            qemuGuestAgent:
              users:
              - "fedora"
      volumes:
      - dataVolume:
          name: fedora-dv
        name: disk0
      - cloudInitConfigDrive:
          userData: |
            #!/bin/bash

            sudo setenforce Permissive
            sudo yum install -y qemu-guest-agent
            sudo systemctl start qemu-guest-agent
        name: disk1
END

kubectl create -f my-vm.yaml

```
