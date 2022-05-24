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

        %WINDIR%\system32\sysprep\sysprep.exe /generalize /shutdown /oobe /mode:vm

    !!! Note
        We need to make sure the base vm does not restart, which can be done by setting the vm run strategy as `RerunOnFailure`.
          
          VM runStrategy:

            spec:
              runStrategy: RerunOnFailure

    More information can be found here:

    * [Sysprep Process Overview](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-process-overview)
    * [Sysprep (Generalize) a Windows installation](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation)

    !!! Note
        It is important that there is no answer file detected when the Sysprep Tool is triggered, because Windows Setup searches for answer files at the beginning of each configuration pass and caches it. If that happens, when the OS will start - it will just use the cached answer file, ignoring the one we provide through the Sysprep API. More information can be found [here](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview#implicit-answer-file-search-order).

2. Providing an Answer file named `autounattend.xml` in an attached media. The answer file can be provided in a ConfigMap or a Secret with the key `autounattend.xml`

    The configuration file can be generated with [Windows SIM](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/windows-system-image-manager-overview-topics) or it can be specified manually according to the information found here:

    * [Answer files (unattend.xml)](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs)
    * [Answer File Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/answer-files-overview)
    * [Answer File Components Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/components-b-unattend)

    !!! Note
        There are also many easy to find online tools available for creating an answer file.

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

<!-- markdown-link-check-disable -->
Below is an example of using cloud-config to inject an SSH key for the
default user (fedora in this case) of a [Fedora Atomic](https://www.projectatomic.io/) disk image.
<!-- markdown-link-check-enable -->

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

### Base Sysprep VM

In the example below, a configMap with `autounattend.xml` file is used to modify the Windows iso image which is downloaded from Microsoft
and creates a base installed Windows machine with virtio drivers installed and all the commands executed in `post-install.ps1`
For the below manifests to work it needs to have `win10-iso` DataVolume.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: win10-template-configmap
data:
  autounattend.xml: |-
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
      <settings pass="windowsPE">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <SetupUILanguage>
            <UILanguage>en-US</UILanguage>
          </SetupUILanguage>
          <InputLocale>0409:00000409</InputLocale>
          <SystemLocale>en-US</SystemLocale>
          <UILanguage>en-US</UILanguage>
          <UILanguageFallback>en-US</UILanguageFallback>
          <UserLocale>en-US</UserLocale>
        </component>
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <DriverPaths>
            <PathAndCredentials wcm:keyValue="4b29ba63" wcm:action="add">
              <Path>E:\amd64\2k19</Path>
            </PathAndCredentials>
            <PathAndCredentials wcm:keyValue="25fe51ea" wcm:action="add">
              <Path>E:\NetKVM\2k19\amd64</Path>
            </PathAndCredentials>
          </DriverPaths>
        </component>
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <DiskConfiguration>
            <Disk wcm:action="add">
              <CreatePartitions>
                <CreatePartition wcm:action="add">
                  <Order>1</Order>
                  <Type>Primary</Type>
                  <Size>100</Size>
                </CreatePartition>
                <CreatePartition wcm:action="add">
                  <Extend>true</Extend>
                  <Order>2</Order>
                  <Type>Primary</Type>
                </CreatePartition>
              </CreatePartitions>
              <ModifyPartitions>
                <ModifyPartition wcm:action="add">
                  <Format>NTFS</Format>
                  <Label>System Reserved</Label>
                  <Order>1</Order>
                  <PartitionID>1</PartitionID>
                  <TypeID>0x27</TypeID>
                </ModifyPartition>
                <ModifyPartition wcm:action="add">
                  <Format>NTFS</Format>
                  <Label>OS</Label>
                  <Letter>C</Letter>
                  <Order>2</Order>
                  <PartitionID>2</PartitionID>
                </ModifyPartition>
              </ModifyPartitions>
              <DiskID>0</DiskID>
              <WillWipeDisk>true</WillWipeDisk>
            </Disk>
          </DiskConfiguration>
          <ImageInstall>
            <OSImage>
              <InstallFrom>
                <MetaData wcm:action="add">
                  <Key>/Image/Description</Key>
                  <Value>Windows 10 Pro</Value>
                </MetaData>
              </InstallFrom>
              <InstallTo>
                <DiskID>0</DiskID>
                <PartitionID>2</PartitionID>
              </InstallTo>
            </OSImage>
          </ImageInstall>
          <UserData>
            <AcceptEula>true</AcceptEula>
            <FullName/>
            <Organization/>
            <ProductKey>
              <Key/>
            </ProductKey>
          </UserData>
        </component>
      </settings>
      <settings pass="offlineServicing">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <EnableLUA>false</EnableLUA>
        </component>
      </settings>
      <settings pass="specialize">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <InputLocale>0409:00000409</InputLocale>
          <SystemLocale>en-US</SystemLocale>
          <UILanguage>en-US</UILanguage>
          <UILanguageFallback>en-US</UILanguageFallback>
          <UserLocale>en-US</UserLocale>
        </component>
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <SkipAutoActivation>true</SkipAutoActivation>
        </component>
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <CEIPEnabled>0</CEIPEnabled>
        </component>
      </settings>
      <settings pass="oobeSystem">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <NetworkLocation>Work</NetworkLocation>
            <SkipUserOOBE>true</SkipUserOOBE>
            <SkipMachineOOBE>true</SkipMachineOOBE>
            <ProtectYourPC>3</ProtectYourPC>
          </OOBE>
          <AutoLogon>
            <Password>
              <Value>123456</Value>
              <PlainText>true</PlainText>
            </Password>
            <Enabled>true</Enabled>
            <Username>Administrator</Username>
          </AutoLogon>
          <UserAccounts>
            <AdministratorPassword>
              <Value>123456</Value>
              <PlainText>true</PlainText>
            </AdministratorPassword>
          </UserAccounts>
          <RegisteredOrganization/>
          <RegisteredOwner/>
          <TimeZone>Eastern Standard Time</TimeZone>
          <FirstLogonCommands>
            <SynchronousCommand wcm:action="add">
              <CommandLine>powershell -ExecutionPolicy Bypass -NoExit -NoProfile f:\post-install.ps1</CommandLine>
              <RequiresUserInput>false</RequiresUserInput>
              <Order>1</Order>
              <Description>Post Installation Script</Description>
            </SynchronousCommand>
          </FirstLogonCommands>
        </component>
      </settings>
    </unattend>

  
  post-install.ps1: |-
    # Remove AutoLogin
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 0 /f

    # install Qemu Tools (Drivers)
    Start-Process msiexec -Wait -ArgumentList '/i e:\virtio-win-gt-x64.msi /qn /passive /norestart'

    # install Guest Agent
    Start-Process msiexec -Wait -ArgumentList '/i e:\guest-agent\qemu-ga-x86_64.msi /qn /passive /norestart'

    # Rename cached unattend.xml to avoid it is picked up by sysprep
    mv C:\Windows\Panther\unattend.xml C:\Windows\Panther\unattend.install.xml

    # Eject CD, to avoid that the autounattend.xml on the CD is picked up by sysprep
    (new-object -COM Shell.Application).NameSpace(17).ParseName('F:').InvokeVerb('Eject')

    # Run Sysprep and Shutdown
    C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /mode:vm

---

apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  annotations:
    name.os.template.kubevirt.io/win10: Microsoft Windows 10
    vm.kubevirt.io/validations: |
      [
        {
          "name": "minimal-required-memory",
          "path": "jsonpath::.spec.domain.resources.requests.memory",
          "rule": "integer",
          "message": "This VM requires more memory.",
          "min": 2147483648
        }, {
          "name": "windows-virtio-bus",
          "path": "jsonpath::.spec.domain.devices.disks[*].disk.bus",
          "valid": "jsonpath::.spec.domain.devices.disks[*].disk.bus",
          "rule": "enum",
          "message": "virto disk bus type has better performance, install virtio drivers in VM and change bus type",
          "values": ["virtio"],
          "justWarning": true
        }, {
          "name": "windows-disk-bus",
          "path": "jsonpath::.spec.domain.devices.disks[*].disk.bus",
          "valid": "jsonpath::.spec.domain.devices.disks[*].disk.bus",
          "rule": "enum",
          "message": "disk bus has to be either virtio or sata or scsi",
          "values": ["virtio", "sata", "scsi"]
        }, {
          "name": "windows-cd-bus",
          "path": "jsonpath::.spec.domain.devices.disks[*].cdrom.bus",
          "valid": "jsonpath::.spec.domain.devices.disks[*].cdrom.bus",
          "rule": "enum",
          "message": "cd bus has to be sata",
          "values": ["sata"]
        }
      ]
  name: win10-template
  namespace: default
  labels:
    app: win10-template
    flavor.template.kubevirt.io/medium: 'true'
    os.template.kubevirt.io/win10: 'true'
    vm.kubevirt.io/template: windows10-desktop-medium
    vm.kubevirt.io/template.namespace: openshift
    vm.kubevirt.io/template.revision: '1'
    vm.kubevirt.io/template.version: v0.14.0
    workload.template.kubevirt.io/desktop: 'true'
spec:
  runStrategy: RerunOnFailure
  dataVolumeTemplates:
    - metadata:
        name: win10-template-windows-iso
      spec:
        pvc:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 20Gi
        source:
          pvc:
            name: windows10-iso
            namespace: default
    - metadata:
        name: win10-template
      spec:
        pvc:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 25Gi
          volumeMode: Filesystem
        source:
          blank: {}
  template:
    metadata:
      annotations:
        vm.kubevirt.io/flavor: medium
        vm.kubevirt.io/os: windows10
        vm.kubevirt.io/workload: desktop
      labels:
        flavor.template.kubevirt.io/medium: 'true'
        kubevirt.io/domain: win10-template
        kubevirt.io/size: medium
        os.template.kubevirt.io/win10: 'true'
        vm.kubevirt.io/name: win10-template
        workload.template.kubevirt.io/desktop: 'true'
    spec:
      domain:
        clock:
          timer:
            hpet:
              present: false
            hyperv: {}
            pit:
              tickPolicy: delay
            rtc:
              tickPolicy: catchup
          utc: {}
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - bootOrder: 1
              disk:
                bus: virtio
              name: win10-template
            - bootOrder: 2
              cdrom:
                bus: sata
              name: windows-iso
            - cdrom:
                bus: sata
              name: windows-guest-tools
            - name: sysprep
              cdrom:
                bus: sata
          inputs:
            - bus: usb
              name: tablet
              type: tablet
          interfaces:
            - masquerade: {}
              model: virtio
              name: default
        features:
          acpi: {}
          apic: {}
          hyperv:
            reenlightenment: {}
            ipi: {}
            synic: {}
            synictimer:
              direct: {}
            spinlocks:
              spinlocks: 8191
            reset: {}
            relaxed: {}
            vpindex: {}
            runtime: {}
            tlbflush: {}
            frequencies: {}
            vapic: {}
        machine:
          type: pc-q35-rhel8.4.0
        resources:
          requests:
            memory: 4Gi
      hostname: win10-template
      networks:
        - name: default
          pod: {}
      volumes:
        - dataVolume:
            name: win10-iso
          name: windows-iso
        - dataVolume:
            name: win10-template-windows-iso
          name: win10-template
        - containerDisk:
            image: quay.io/kubevirt/virtio-container-disk
          name: windows-guest-tools
        - name: sysprep
          sysprep:
            configMap:
              name: win10-template-configmap

```

### Launching a VM from template

From the above example after the sysprep command is executed in the `post-install.ps1` and the vm is in shutdown state,
A new VM can be launched from the base `win10-template` with additional changes mentioned from the below `unattend.xml` in `sysprep-config`.
The new VM can take upto 5 minutes to be in running state since Windows goes through oobe setup in the background with the customizations specified in the below `unattend.xml` file.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: sysprep-config
data:
  autounattend.xml: |-
    <?xml version="1.0" encoding="utf-8"?>
    <!-- responsible for installing windows, ignored on sysprepped images -->
  unattend.xml: |-
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
      <settings pass="oobeSystem">
        <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <NetworkLocation>Work</NetworkLocation>
            <SkipUserOOBE>true</SkipUserOOBE>
            <SkipMachineOOBE>true</SkipMachineOOBE>
            <ProtectYourPC>3</ProtectYourPC>
          </OOBE>
          <AutoLogon>
            <Password>
            <Value>123456</Value>
              <PlainText>true</PlainText>
            </Password>
            <Enabled>true</Enabled>
        <Username>Administrator</Username>
    </AutoLogon>
    <UserAccounts>
         <AdministratorPassword>
                <Value>123456</Value>
                <PlainText>true</PlainText>
        </AdministratorPassword>
          </UserAccounts>
          <RegisteredOrganization>Kuebvirt</RegisteredOrganization>
          <RegisteredOwner>Kubevirt</RegisteredOwner>
          <TimeZone>Eastern Standard Time</TimeZone>
                <FirstLogonCommands>
                    <SynchronousCommand wcm:action="add">
                    <CommandLine>powershell -ExecutionPolicy Bypass -NoExit -WindowStyle Hidden -NoProfile d:\customize.ps1</CommandLine>
                        <RequiresUserInput>false</RequiresUserInput>
                        <Order>1</Order>
                <Description>Customize Script</Description>
            </SynchronousCommand>
                </FirstLogonCommands>
        </component>
      </settings>
    </unattend>
  customize.ps1: |-
    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"


    # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
    # Install the OpenSSH Server
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    # Start the sshd service
    Start-Service sshd

    Set-Service -Name sshd -StartupType 'Automatic'

    # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration
    # use powershell as default shell for ssh
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force


    # Add ssh authorized_key for administrator
    # https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
    $MyDir = $MyInvocation.MyCommand.Path | Split-Path -Parent
    $PublicKey = Get-Content -Path $MyDir\id_rsa.pub
    $authrized_keys_path = $env:ProgramData + "\ssh\administrators_authorized_keys" 
    Add-Content -Path $authrized_keys_path -Value $PublicKey
    icacls.exe $authrized_keys_path /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"


    # install application via exe file installer from url
    function Install-Exe {
      $dlurl = $args[0]
      $installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)
      Invoke-WebRequest -UseBasicParsing $dlurl -OutFile $installerPath
      Start-Process -FilePath $installerPath -Args "/S" -Verb RunAs -Wait
      Remove-Item $installerPath

    }

    # Wait for networking before running a task at startup
    do {
      $ping = test-connection -comp kubevirt.io -count 1 -Quiet
    } until ($ping)

    # Installing the Latest Notepad++ with PowerShell
    $BaseUri = "https://notepad-plus-plus.org"
    $BasePage = Invoke-WebRequest -Uri $BaseUri -UseBasicParsing
    $ChildPath = $BasePage.Links | Where-Object { $_.outerHTML -like '*Current Version*' } | Select-Object -ExpandProperty href
    $DownloadPageUri = $BaseUri + $ChildPath
    $DownloadPage = Invoke-WebRequest -Uri $DownloadPageUri -UseBasicParsing
    $DownloadUrl = $DownloadPage.Links | Where-Object { $_.outerHTML -like '*npp.*.Installer.x64.exe"*' } | Select-Object -ExpandProperty href
    Install-Exe $DownloadUrl
  id_rsa.pub: |-
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6zdgFiLr1uAK7PdcchDd+LseA5fEOcxCCt7TLlr7Mx6h8jUg+G+8L9JBNZuDzTZSF0dR7qwzdBBQjorAnZTmY3BhsKcFr8Gt4KMGrS6r3DNmGruP8GORvegdWZuXgASKVpXeI7nCIjRJwAaK1x+eGHwAWO9Z8ohcboHbLyffOoSZDSIuk2kRIc47+ENRjg0T6x2VRsqX27g6j4DfPKQZGk0zvXkZaYtr1e2tZgqTBWqZUloMJK8miQq6MktCKAS4VtPk0k7teQX57OGwD6D7uo4b+Cl8aYAAwhn0hc0C2USfbuVHgq88ESo2/+NwV4SQcl3sxCW21yGIjAGt4Hy7J fedora@localhost.localdomain


```
