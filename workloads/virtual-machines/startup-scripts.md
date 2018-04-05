# Startup Scripts

## Overview

KubeVirt supports the ability to assign a startup script to a Virtual Machine instance which is executed automatically when the Virtual Machine initializes.

These scripts are commonly used to automate injection of users and ssh keys into Virtual Machines in order to provide remote access to the machine. For example, a startup script can be used to inject credentials into a Virtual Machine that allows an Ansible job running on a remote host to access and provision the Virtual Machine.

Startup scripts are not limited to any specific use case though. They can be used to run any arbitrary script in a Virtual Machine on boot.

### Cloud-init

cloud-init is a widely adopted project used for early initialization of a Virtual Machine. Used by cloud providers such as AWS and GCP, cloud-init has established itself as the defacto method of providing startup scripts to Virtual Machines.

Cloud-init documentation can be found at the link below. [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/)

KubeVirt supports cloud-init's "NoCloud" datasource which involves injecting startup scripts into a Virtual Machine instance though the use of an ephemeral disk. Virtual Machines with the cloud-init package installed will detect the ephemeral disk and execute custom userdata script at boot.

### Sysprep

Sysprep is an automation tool for Windows that automates Windows installation, setup, and in custom software provisioning as well.

**Sysprep support is currently not implemented by KubeVirt.** However it is a feature the KubeVirt upstream community has shown interest in. As a result, it is likely Sysprep support will make its way into a future KubeVirt release.

## Cloud-init Examples

KubeVirt supports the cloud-init NoCloud datasource which involves injecting startup scripts through the use of a disk attached to the Virtual Machine.

In order to assign a custom userdata script to a VirtualMachine using this method, users must define disk and volume for the NoCloud datasource in the VirtualMachine's spec.

### Cloud-init user-data as clear text

In the example below, a ssh-key is stored in the cloudInitNoCloud Volume's userData field as clean text. There's a corresponding disks entry that references the cloud-init volume and assigns it to the Virtual Machine's device.

```text
# Create a VM manifest with the startup script
# a cloudInitNoCloud volume's userData field.

cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: myvm
spec:
  terminationGracePeriodSeconds: 5
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          bus: virtio
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          bus: virtio
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userData: |
          ssh-authorized-keys:
            - ssh-rsa AAAAB3NzaK8L93bWxnyp test@test.com

END

# Post the Virtual Machine spec to KubeVirt.

kubectl create -f my-vm.yaml
```

### Cloud-init user-data as base64 string

In the example below, a simple bash script is base64 encoded and stored in the cloudInitNoCloud Volume's userDataBase64 field. There's a corresponding disks entry that references the cloud-init volume and assigns it to the Virtual Machine's device.

_Users also have the option of storing the startup script in a Kubernetes secret and referencing the secret in the Virtual Machine's spec. Examples further down in the document outline how that is done._

```text
# Create a simple startup script

cat << END > startup-script.sh
#!/bin/bash
echo "Hi from startup script!"
END

# Create a VM manifest with the startup script base64 encoded into
# a cloudInitNoCloud volume's userDataBase64 field.

cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: myvm
spec:
  terminationGracePeriodSeconds: 5
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          bus: virtio
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          bus: virtio
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userDataBase64: $(cat startup-script.sh | base64 -w0)
END

# Post the Virtual Machine spec to KubeVirt.

kubectl create -f my-vm.yaml
```

### Cloud-init UserData as k8s Secret

Users who wish to not store the cloud-init userdata directly in the Virtual Machine's spec have the option to store the userdata into a kubernetes secret and reference that secret in the spec.

Multiple VirtualMachine spec's can reference the same kuberentes secret containing cloud-init userdata.

Below is an example of how to create a kubernetes secret containing a startup script and reference that secret in the Virtual Machine's spec.

```text
# Create a simple startup script

cat << END > startup-script.sh
#!/bin/bash
echo "Hi from startup script!"
END

# Store the startup script in a kubernetes secret

cat << END > my-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-vm-secret
type: Opaque
data:
  userdata: $(cat startup-script.sh | base64 -w0)
END

# Create a VM manifest and reference the secret's name in the cloudInitNoCloud
# volume's userDataSecretRef field

cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: myvm
spec:
  terminationGracePeriodSeconds: 5
  domain:
    resources:
      requests:
        memory: 64M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          bus: virtio
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          bus: virtio
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/cirros-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userDataSecretRef: my-vm-secret
END

# Post the secret first, and then post the VM
kubectl create -f my-secret.yaml
kubectl create -f my-vm.yaml
```

### Injecting SSH keys with Cloud-init's Cloud-config

In the examples so far, the cloud-init userdata script has been a bash script. Cloud-init has it's own configuration that can handle some common tasks such as user creation and ssh key injection.

More cloud-config examples can be found here. [Cloud-init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)

Below is an example of using cloud-config to inject an ssh key for the default user \(fedora in this case\) of a [Fedora Atomic](https://getfedora.org/en/atomic/download/) disk image.

```text
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
cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: sshvm
spec:
  terminationGracePeriodSeconds: 0
  domain:
    resources:
      requests:
        memory: 1024M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          dev: vda
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          dev: vdb
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/fedora-atomic-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userDataBase64: $(cat startup-script | base64 -w0)
END

# Post the Virtual Machine spec to KubeVirt.
kubectl create -f my-vm.yaml

# Connect to VM with passwordless ssh key
ssh -i <insert private key here> fedora@<insert ip here>
```

### Inject SSH key using Custom Shell Script

Depending on the boot image in use, users may have a mixed experience using cloud-init's cloud-config to create users and inject ssh keys.

Below is an example of creating a user and injecting ssh keys for that user using a script instead of cloud-config.

```text
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
cat << END > my-vm.yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: sshvm
spec:
  terminationGracePeriodSeconds: 0
  domain:
    resources:
      requests:
        memory: 1024M
    devices:
      disks:
      - name: registrydisk
        volumeName: registryvolume
        disk:
          dev: vda
      - name: cloudinitdisk
        volumeName: cloudinitvolume
        disk:
          dev: vdb
  volumes:
    - name: registryvolume
      registryDisk:
        image: kubevirt/fedora-atomic-registry-disk-demo:latest
    - name: cloudinitvolume
      cloudInitNoCloud:
        userDataBase64: $(cat startup-script.sh | base64 -w0)
END

# Post the Virtual Machine spec to KubeVirt.
kubectl create -f my-vm.yaml

# Connect to VM with passwordless ssh key
ssh -i <insert private key here> foo@<insert ip here>
```

## Debugging

Depending on the operating system distribution in use, cloud-init output is often printed to the console output on bootup. When developing userdata scripts, users can connect to the Virtual Machine's console during bootup to debug.

Example of connecting to console using virtctl

```text
virtctl console <name of vm>
```

