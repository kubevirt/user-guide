## VM persistence

### Preparation

To persist a VM, the `Persistent Virtual Machine` add-on must be installed
first.

```bash
git clone https://github.com/petrkotas/virt-vmconfig-crd
cd virt-vmconfig-crd
```

### Installation

Adding the persistent VM functionality to the cluster is done by adding the supplied manifest:

```bash
kubectl apply -f manifests/persistentvm-resource.yaml
```

Alternatively, if vagrant kubevirt deployment is used, the add-on contains a makefile that is able to deploy directly to the vagrant cluster:

```bash
make vagrant-deploy
```

### Usage

The term `Persistent Virtual Machine` is shortened to `PVM` for the rest of this guide.

#### Creating a PVM

Given an example PVM specification saved in a file called `example.json`

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: PersistentVirtualMachine
metadata:
  name: testvm
spec:
  domain:
    devices:
      consoles:
      - type: pty
      disks:
      - device: disk
        driver:
          cache: none
          name: qemu
          type: raw
        snapshot: external
        source:
          host:
            name: iscsi-demo-target.default
            port: "3260"
          name: iqn.2017-01.io.kubevirt:sn.42/2
          protocol: iscsi
        target:
          dev: vda
        type: network
      graphics:
      - type: spice
      interfaces:
      - source:
          network: default
        type: network
      video:
      - type: qxl
    memory:
      unit: MB
      value: 64
    os:
      type:
        os: hvm
    type: qemu
```

the actual PVM object can be created using a kubectl:

```bash
kubectl create -f example.yaml
```

#### Starting a PVM

```bash
kubectl get pvm testvm -o json | jq ".kind = 'VirtualMachine"
```

Please note that the example used command `jq` that may not be present on a system by default. The equivalent effect can be had by using `sed`.

```bash
kubectl get pvm testvm -o yaml | sed 's/PersistentVirtualMachine/VirtualMachine/' | kubectl create -f -
```

#### Stopping a PVM

Starting the PVM required us to create an actual `VirtualMachine` object, therefore we treat it as `VirtualMachine` from that point on. See [Life-cycle](vm-life-cycle.md).


#### Deleting a PVM

Simply delete the object from the cluster using the `kubectl` command.

```bash
kubectl delete -f example.yaml
```