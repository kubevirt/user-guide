# Startup Scripts

KubeVirt supports the ability to assign a startup script to a
VirtualMachineInstance instance which is executed automatically when the
VM initializes.

These scripts are commonly used to automate injection of users and SSH
keys into VMs in order to provide remote access to the machine. For
example, a startup script can be used to inject credentials into a VM
that allows an Ansible job running on a remote host to access and
provision the VM.

Startup scripts are not limited to any specific use case though. They
can be used to run any arbitrary script in a VM on boot.

## Cloud-init

cloud-init is a widely adopted project used for early initialization of
a VM. Used by cloud providers such as AWS and GCP, cloud-init has
established itself as the defacto method of providing startup scripts to
VMs.

Cloud-init documentation can be found here: [Cloud-init
Documentation](https://cloudinit.readthedocs.io/en/latest/).

KubeVirt supports cloud-init's "NoCloud" and "ConfigDrive" datasources
which involve injecting startup scripts into a VM instance through the
use of an ephemeral disk. VMs with the cloud-init package installed will
detect the ephemeral disk and execute custom userdata scripts at boot.

## Sysprep

Sysprep is an automation tool for Windows that automates Windows
installation, setup, and custom software provisioning.

The general flow is:

1. Seal the vm image with the Sysprep tool, for example by running:
    ```console
    %WINDIR%\system32\sysprep\sysprep.exe /generalize /shutdown /oobe /mode:vm
    ```

    More information can be found here:
    * [Sysprep Process Overview](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-process-overview)
    * [Sysprep (Generalize) a Windows installation](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation)

2. Providing an Answer file named `autounattend.xml` in an attached media. The answer file can be provided in a ConfigMap or a Secret with the key `autounattend.xml`

    More information can be found here: [Answer files (unattend.xml)](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs)

    Note that there are also many easy to find online tools available for creating an answer file.

## Cloud-init Examples

### User Data

KubeVirt supports the cloud-init NoCloud and ConfigDrive data sources
which involve injecting startup scripts through the use of a disk
attached to the VM.

In order to assign a custom userdata script to a VirtualMachineInstance
using this method, users must define a disk and a volume for the NoCloud
or ConfigDrive datasource in the VirtualMachineInstance's spec.

#### Data Sources

Under most circumstances users should stick to the NoCloud data source
as it is the simplest cloud-init data source. Only if NoCloud is not
supported by the cloud-init implementation (e.g.
[coreos-cloudinit](https://github.com/coreos/coreos-cloudinit)) users
should switch the data source to ConfigDrive.

Switching the cloud-init data source to ConfigDrive is as easy as
changing the volume type in the VirtualMachineInstance's spec from
`cloudInitNoCloud` to `cloudInitConfigDrive`.

NoCloud data source:

    volumes:
      - name: cloudinitvolume
        cloudInitNoCloud:
          userData: "#cloud-config"

ConfigDrive data source:

    volumes:
      - name: cloudinitvolume
        cloudInitConfigDrive:
          userData: "#cloud-config"

See the examples below for more complete cloud-init examples.

#### Cloud-init user-data as clear text

In the example below, a SSH key is stored in the cloudInitNoCloud
Volume's userData field as clean text. There is a corresponding disks
entry that references the cloud-init volume and assigns it to the VM's
device.

    # Create a VM manifest with the startup script
    # a cloudInitNoCloud volume's userData field.

    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      terminationGracePeriodSeconds: 5
      domain:
        resources:
          requests:
            memory: 64M
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/cirros-container-disk-demo:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              ssh_authorized_keys:
                - ssh-rsa AAAAB3NzaK8L93bWxnyp test@test.com

    END

    # Post the Virtual Machine spec to KubeVirt.

    kubectl create -f my-vmi.yaml

#### Cloud-init user-data as base64 string

In the example below, a simple bash script is base64 encoded and stored
in the cloudInitNoCloud Volume's userDataBase64 field. There is a
corresponding disks entry that references the cloud-init volume and
assigns it to the VM's device.

*Users also have the option of storing the startup script in a
Kubernetes Secret and referencing the Secret in the VM's spec. Examples
further down in the document illustrate how that is done.*

    # Create a simple startup script

    cat << END > startup-script.sh
    #!/bin/bash
    echo "Hi from startup script!"
    END

    # Create a VM manifest with the startup script base64 encoded into
    # a cloudInitNoCloud volume's userDataBase64 field.

    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      terminationGracePeriodSeconds: 5
      domain:
        resources:
          requests:
            memory: 64M
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/cirros-container-disk-demo:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: $(cat startup-script.sh | base64 -w0)
    END

    # Post the Virtual Machine spec to KubeVirt.

    kubectl create -f my-vmi.yaml

#### Cloud-init UserData as k8s Secret

Users who wish to not store the cloud-init userdata directly in the
VirtualMachineInstance spec have the option to store the userdata into a
Kubernetes Secret and reference that Secret in the spec.

Multiple VirtualMachineInstance specs can reference the same Kubernetes
Secret containing cloud-init userdata.

Below is an example of how to create a Kubernetes Secret containing a
startup script and reference that Secret in the VM's spec.

    # Create a simple startup script

    cat << END > startup-script.sh
    #!/bin/bash
    echo "Hi from startup script!"
    END

    # Store the startup script in a Kubernetes Secret
    kubectl create secret generic my-vmi-secret --from-file=userdata=startup-script.sh

    # Create a VM manifest and reference the Secret's name in the cloudInitNoCloud
    # Volume's secretRef field

    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      terminationGracePeriodSeconds: 5
      domain:
        resources:
          requests:
            memory: 64M
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          - name: cloudinitdisk
            disk:
              bus: virtio
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/cirros-registry-disk-demo:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            secretRef:
              name: my-vmi-secret
    END

    # Post the VM
    kubectl create -f my-vmi.yaml

#### Injecting SSH keys with Cloud-init's Cloud-config

In the examples so far, the cloud-init userdata script has been a bash
script. Cloud-init has it's own configuration that can handle some
common tasks such as user creation and SSH key injection.

More cloud-config examples can be found here: [Cloud-init
Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)

Below is an example of using cloud-config to inject an SSH key for the
default user (fedora in this case) of a [Fedora Atomic](https://www.projectatomic.io/) disk image.

    # Create the cloud-init cloud-config userdata.
    cat << END > startup-script
    #cloud-config
    password: atomic
    chpasswd: { expire: False }
    ssh_pwauth: False
    ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6zdgFiLr1uAK7PdcchDd+LseA5fEOcxCCt7TLlr7Mx6h8jUg+G+8L9JBNZuDzTZSF0dR7qwzdBBQjorAnZTmY3BhsKcFr8Gt4KMGrS6r3DNmGruP8GORvegdWZuXgASKVpXeI7nCIjRJwAaK1x+eGHwAWO9Z8ohcboHbLyffOoSZDSIuk2kRIc47+ENRjg0T6x2VRsqX27g6j4DfPKQZGk0zvXkZaYtr1e2tZgqTBWqZUloMJK8miQq6MktCKAS4VtPk0k7teQX57OGwD6D7uo4b+Cl8aYAAwhn0hc0C2USfbuVHgq88ESo2/+NwV4SQcl3sxCW21yGIjAGt4Hy7J fedora@localhost.localdomain
    END

    # Create the VM spec
    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: sshvmi
    spec:
      terminationGracePeriodSeconds: 0
      domain:
        resources:
          requests:
            memory: 1024M
        devices:
          disks:
          - name: containerdisk
            disk:
              dev: vda
          - name: cloudinitdisk
            disk:
              dev: vdb
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/fedora-atomic-registry-disk-demo:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: $(cat startup-script | base64 -w0)
    END

    # Post the VirtualMachineInstance spec to KubeVirt.
    kubectl create -f my-vmi.yaml

    # Connect to VM with passwordless SSH key
    ssh -i <insert private key here> fedora@<insert ip here>

#### Inject SSH key using a Custom Shell Script

Depending on the boot image in use, users may have a mixed experience
using cloud-init's cloud-config to create users and inject SSH keys.

Below is an example of creating a user and injecting SSH keys for that
user using a script instead of cloud-config.

    cat << END > startup-script.sh
    #!/bin/bash
    export NEW_USER="foo"
    export SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6zdgFiLr1uAK7PdcchDd+LseA5fEOcxCCt7TLlr7Mx6h8jUg+G+8L9JBNZuDzTZSF0dR7qwzdBBQjorAnZTmY3BhsKcFr8Gt4KMGrS6r3DNmGruP8GORvegdWZuXgASKVpXeI7nCIjRJwAaK1x+eGHwAWO9Z8ohcboHbLyffOoSZDSIuk2kRIc47+ENRjg0T6x2VRsqX27g6j4DfPKQZGk0zvXkZaYtr1e2tZgqTBWqZUloMJK8miQq6MktCKAS4VtPk0k7teQX57OGwD6D7uo4b+Cl8aYAAwhn0hc0C2USfbuVHgq88ESo2/+NwV4SQcl3sxCW21yGIjAGt4Hy7J $NEW_USER@localhost.localdomain"

    sudo adduser -U -m $NEW_USER
    echo "$NEW_USER:atomic" | chpasswd
    sudo mkdir /home/$NEW_USER/.ssh
    sudo echo "$SSH_PUB_KEY" > /home/$NEW_USER/.ssh/authorized_keys
    sudo chown -R ${NEW_USER}: /home/$NEW_USER/.ssh
    END

    # Create the VM spec
    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: sshvmi
    spec:
      terminationGracePeriodSeconds: 0
      domain:
        resources:
          requests:
            memory: 1024M
        devices:
          disks:
          - name: containerdisk
            disk:
              dev: vda
          - name: cloudinitdisk
            disk:
              dev: vdb
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/fedora-atomic-registry-disk-demo:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            userDataBase64: $(cat startup-script.sh | base64 -w0)
    END

    # Post the VirtualMachineInstance spec to KubeVirt.
    kubectl create -f my-vmi.yaml

    # Connect to VM with passwordless SSH key
    ssh -i <insert private key here> foo@<insert ip here>

### Network Config

A cloud-init [network version
1](https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v1.html)
configuration can be set to configure the network at boot.

Cloud-init [user-data](#user-data) **must** be set for cloud-init to
parse *network-config* even if it is just the user-data config header:

    #cloud-config

#### Cloud-init network-config as clear text

In the example below, a simple cloud-init network-config is stored in
the cloudInitNoCloud Volume's networkData field as clean text. There is
a corresponding disks entry that references the cloud-init volume and
assigns it to the VM's device.

    # Create a VM manifest with the network-config in
    # a cloudInitNoCloud volume's networkData field.

    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha2
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      terminationGracePeriodSeconds: 5
      domain:
        resources:
          requests:
            memory: 64M
        devices:
          disks:
          - name: containerdisk
            volumeName: registryvolume
            disk:
              bus: virtio
          - name: cloudinitdisk
            volumeName: cloudinitvolume
            disk:
              bus: virtio
      volumes:
        - name: registryvolume
          containerDisk:
            image: kubevirt/cirros-container-disk-demo:latest
        - name: cloudinitvolume
          cloudInitNoCloud:
            userData: "#cloud-config"
            networkData: |
              network:
                version: 1
                config:
                - type: physical
                name: eth0
                subnets:
                  - type: dhcp

    END

    # Post the Virtual Machine spec to KubeVirt.

    kubectl create -f my-vmi.yaml

#### Cloud-init network-config as base64 string

In the example below, a simple network-config is base64 encoded and
stored in the cloudInitNoCloud Volume's networkDataBase64 field. There
is a corresponding disks entry that references the cloud-init volume and
assigns it to the VM's device.

*Users also have the option of storing the network-config in a
Kubernetes Secret and referencing the Secret in the VM's spec. Examples
further down in the document illustrate how that is done.*

    # Create a simple network-config

    cat << END > network-config
    network:
      version: 1
      config:
      - type: physical
      name: eth0
      subnets:
        - type: dhcp
    END

    # Create a VM manifest with the networkData base64 encoded into
    # a cloudInitNoCloud volume's networkDataBase64 field.

    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha2
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      terminationGracePeriodSeconds: 5
      domain:
        resources:
          requests:
            memory: 64M
        devices:
          disks:
          - name: containerdisk
            volumeName: registryvolume
            disk:
              bus: virtio
          - name: cloudinitdisk
            volumeName: cloudinitvolume
            disk:
              bus: virtio
      volumes:
        - name: registryvolume
          containerDisk:
            image: kubevirt/cirros-container-disk-demo:latest
        - name: cloudinitvolume
          cloudInitNoCloud:
            userData: "#cloud-config"
            networkDataBase64: $(cat network-config | base64 -w0)
    END

    # Post the Virtual Machine spec to KubeVirt.

    kubectl create -f my-vmi.yaml

#### Cloud-init network-config as k8s Secret

Users who wish to not store the cloud-init network-config directly in
the VirtualMachineInstance spec have the option to store the
network-config into a Kubernetes Secret and reference that Secret in the
spec.

Multiple VirtualMachineInstance specs can reference the same Kubernetes
Secret containing cloud-init network-config.

Below is an example of how to create a Kubernetes Secret containing a
network-config and reference that Secret in the VM's spec.

    # Create a simple network-config

    cat << END > network-config
    network:
      version: 1
      config:
      - type: physical
      name: eth0
      subnets:
        - type: dhcp
    END

    # Store the network-config in a Kubernetes Secret
    kubectl create secret generic my-vmi-secret --from-file=networkdata=network-config

    # Create a VM manifest and reference the Secret's name in the cloudInitNoCloud
    # Volume's secretRef field

    cat << END > my-vmi.yaml
    apiVersion: kubevirt.io/v1alpha2
    kind: VirtualMachineInstance
    metadata:
      name: myvmi
    spec:
      terminationGracePeriodSeconds: 5
      domain:
        resources:
          requests:
            memory: 64M
        devices:
          disks:
          - name: containerdisk
            volumeName: registryvolume
            disk:
              bus: virtio
          - name: cloudinitdisk
            volumeName: cloudinitvolume
            disk:
              bus: virtio
      volumes:
        - name: registryvolume
          containerDisk:
            image: kubevirt/cirros-registry-disk-demo:latest
        - name: cloudinitvolume
          cloudInitNoCloud:
            userData: "#cloud-config"
            networkDataSecretRef:
              name: my-vmi-secret
    END

    # Post the VM
    kubectl create -f my-vmi.yaml

### Debugging

Depending on the operating system distribution in use, cloud-init output
is often printed to the console output on boot up. When developing
userdata scripts, users can connect to the VM's console during boot up
to debug.

Example of connecting to console using virtctl:

    virtctl console <name of vmi>

### Device Role Tagging

KubeVirt provides a mechanism for users to tag devices such as Network
Interfaces with a specific role. The tag will be matched to the hardware
address of the device and this mapping exposed to the guest OS via
cloud-init.

This additional metadata will help the guest OS users with multiple networks
interfaces to identify the devices that may have a specific role, such as a
network device dedicated to a specific service or a disk intended to be used by
a specific application (database, webcache, etc.)

This functionality already exists in platforms such as OpenStack. KubeVirt will
provide the data in a similar format, known to users and services like cloud-init.

For example:
```
kind: VirtualMachineInstance
spec:
  domain:
    devices:
      interfaces:
      - masquerade: {}
        name: default
      - bridge: {}
        name: ptp
	tag: ptp
      - name: sriov-net
        sriov: {}
        tag: nfvfunc
  networks:
  - name: default
    pod: {}
  - multus:
      networkName: ptp-conf
    name: ptp
      networkName: sriov/sriov-network
    name: sriov-net

The metadata will be available in the guests config drive `openstack/latest/meta_data.json`

{
  "devices": [
    {
        "type": "nic",
        "bus": "pci",
        "address": "0000:00:02.0",
        "mac": "01:22:22:42:22:21",
        "tags": ["ptp"]
    },
    {
        "type": "nic",
        "bus": "pci",
        "address": "0000:81:10.1",
        "mac": "01:22:22:42:22:22",
        "tags": ["nfvfunc"]
    },
  ]
}
```

## Sysprep Examples

### Sysprep in a ConfigMap

The answer file can be provided in a ConfigMap:

```console
apiVersion: v1
kind: ConfigMap
metadata:
  name: sysprep-config
data:
  autounattend.xml: |
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
    ...
    </unattend>
```

And attached to the VM like so:

```console
kind: VirtualMachine
metadata:
  name: windows-with-sysprep
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: windows-with-sysprep
    spec:
      domain:
        cpu:
          cores: 3
        devices:
          disks:
          - bootOrder: 1
            disk:
              bus: virtio
            name: harddrive
          - name: sysprep
            cdrom:
              bus: sata
        machine:
          type: q35
        resources:
          requests:
            memory: 6G
      volumes:
      - name: harddrive
        persistentVolumeClaim:
          claimName: windows_pvc
      - name: sysprep
        sysprep:
          configMap:
            name: sysprep-config
```

### Sysprep in a Secret

The answer file can be provided in a Secret:

```console
apiVersion: v1
kind: Secret
metadata:
  name: sysprep-config
stringData:
data:
  autounattend.xml: |
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
    ...
    </unattend>
```

And attached to the VM like so:

```console
kind: VirtualMachine
metadata:
  name: windows-with-sysprep
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: windows-with-sysprep
    spec:
      domain:
        cpu:
          cores: 3
        devices:
          disks:
          - bootOrder: 1
            disk:
              bus: virtio
            name: harddrive
          - name: sysprep
            cdrom:
              bus: sata
        machine:
          type: q35
        resources:
          requests:
            memory: 6G
      volumes:
      - name: harddrive
        persistentVolumeClaim:
          claimName: windows_pvc
      - name: sysprep
        sysprep:
          secret:
            name: sysprep-secret
```
