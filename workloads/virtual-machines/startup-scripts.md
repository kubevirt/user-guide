# Startup Scripts

## Overview

KubeVirt supports the ability to assign a startup script to a VirtualMachineInstance instance which is executed automatically when the VM initializes.

These scripts are commonly used to automate injection of users and SSH keys into VMs in order to provide remote access to the machine. For example, a startup script can be used to inject credentials into a VM that allows an Ansible job running on a remote host to access and provision the VM.

Startup scripts are not limited to any specific use case though. They can be used to run any arbitrary script in a VM on boot.

### Cloud-init

cloud-init is a widely adopted project used for early initialization of a VM. Used by cloud providers such as AWS and GCP, cloud-init has established itself as the defacto method of providing startup scripts to VMs.

Cloud-init documentation can be found here: [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/).

KubeVirt supports cloud-init's "NoCloud" datasource which involves injecting startup scripts into a VM instance though the use of an ephemeral disk. VMs with the cloud-init package installed will detect the ephemeral disk and execute custom userdata scripts at boot.

### Sysprep

Sysprep is an automation tool for Windows that automates Windows installation, setup, and custom software provisioning.

**Sysprep support is currently not implemented by KubeVirt.** However it is a feature the KubeVirt upstream community has shown interest in. As a result, it is likely Sysprep support will make its way into a future KubeVirt release.

## Cloud-init Examples

KubeVirt supports the cloud-init NoCloud datasource which involves injecting startup scripts through the use of a disk attached to the VM.

In order to assign a custom userdata script to a VirtualMachineInstance using this method, users must define a disk and a volume for the NoCloud datasource in the VirtualMachineInstance's spec.

### Cloud-init user-data as clear text

In the example below, a SSH key is stored in the cloudInitNoCloud Volume's userData field as clean text. There is a corresponding disks entry that references the cloud-init volume and assigns it to the VM's device.

```bash
# Create a VM manifest with the startup script
# a cloudInitNoCloud volume's userData field.

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
        userData: |
          ssh-authorized-keys:
            - ssh-rsa AAAAB3NzaK8L93bWxnyp test@test.com

END

# Post the Virtual Machine spec to KubeVirt.

kubectl create -f my-vmi.yaml
```

### Cloud-init user-data as base64 string

In the example below, a simple bash script is base64 encoded and stored in the cloudInitNoCloud Volume's userDataBase64 field. There is a corresponding disks entry that references the cloud-init volume and assigns it to the VM's device.

_Users also have the option of storing the startup script in a Kubernetes Secret and referencing the Secret in the VM's spec. Examples further down in the document illustrate how that is done._

```bash
# Create a simple startup script

cat << END > startup-script.sh
#!/bin/bash
echo "Hi from startup script!"
END

# Create a VM manifest with the startup script base64 encoded into
# a cloudInitNoCloud volume's userDataBase64 field.

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
        userDataBase64: $(cat startup-script.sh | base64 -w0)
END

# Post the Virtual Machine spec to KubeVirt.

kubectl create -f my-vmi.yaml
```

### Cloud-init UserData as k8s Secret

Users who wish to not store the cloud-init userdata directly in the VirtualMachineInstance spec have the option to store the userdata into a Kubernetes Secret and reference that Secret in the spec.

Multiple VirtualMachineInstance specs can reference the same Kubernetes Secret containing cloud-init userdata.

Below is an example of how to create a Kubernetes Secret containing a startup script and reference that Secret in the VM's spec.

```bash
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
        secretRef:
          name: my-vmi-secret
END

# Post the VM
kubectl create -f my-vmi.yaml
```

### Injecting SSH keys with Cloud-init's Cloud-config

In the examples so far, the cloud-init userdata script has been a bash script. Cloud-init has it's own configuration that can handle some common tasks such as user creation and SSH key injection.

More cloud-config examples can be found here: [Cloud-init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)

Below is an example of using cloud-config to inject an SSH key for the default user \(fedora in this case\) of a [Fedora Atomic](https://getfedora.org/en/atomic/download/) disk image.

```bash
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
apiVersion: kubevirt.io/v1alpha2
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
        volumeName: registryvolume
        disk:
          dev: vda
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          dev: vdb
  volumes:
    - name: registryvolume
      containerDisk:
        image: kubevirt/fedora-atomic-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userDataBase64: $(cat startup-script | base64 -w0)
END

# Post the VirtualMachineInstance spec to KubeVirt.
kubectl create -f my-vmi.yaml

# Connect to VM with passwordless SSH key
ssh -i <insert private key here> fedora@<insert ip here>
```

### Inject SSH key using a Custom Shell Script

Depending on the boot image in use, users may have a mixed experience using cloud-init's cloud-config to create users and inject SSH keys.

Below is an example of creating a user and injecting SSH keys for that user using a script instead of cloud-config.

```bash
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
apiVersion: kubevirt.io/v1alpha2
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
        volumeName: registryvolume
        disk:
          dev: vda
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          dev: vdb
  volumes:
    - name: registryvolume
      containerDisk:
        image: kubevirt/fedora-atomic-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userDataBase64: $(cat startup-script.sh | base64 -w0)
END

# Post the VirtualMachineInstance spec to KubeVirt.
kubectl create -f my-vmi.yaml

# Connect to VM with passwordless SSH key
ssh -i <insert private key here> foo@<insert ip here>
```

## Debugging

Depending on the operating system distribution in use, cloud-init output is often printed to the console output on boot up. When developing userdata scripts, users can connect to the VM's console during boot up to debug.

Example of connecting to console using virtctl:

```bash
virtctl console <name of vmi>
```

