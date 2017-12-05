# Installation

KubeVirt is a virtualization add-on to Kubernetes and this guide assumes that a
Kubernetes cluster is already installed.

## Requirements

A few requirements need to be met before you can begin:

* [Kubernets](https://kubernetes.io) cluster \([OpenShift](https://github.com/openshift/origin), Tectonic\)
* kubectl client utility
* git

### Minimum Requirements

| Component | Minimum Version |
| --- | --- |
| Kubernetes | 1.7 |
| KubeVirt | 0.0.3 |

### Virtualization support

There are several distributions of Kubernetes, you need to decide on one and
get it deployed.

Hardware with virtualization support is recommended. You can use
virt-host-validate to ensure that your hosts are capable of running
virtualization workloads:

```
$ virt-host-validate qemu
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
...
```

## Cluster side add-on deployment

### Core components

Once Kubernetes is deployed, you will need to deploy the KubeVirt add-on. The
add-on is deployed to a cluster using the `kubectl` tool and manifest file:

```bash
$ RELEASE=v0.0.5
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```

This command will deploy the most recent stable version of KubeVirt to your
cluster. The new components will be deployed in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system
NAME                                           READY     STATUS        RESTARTS   AGE
haproxy-78c7dcf6f6-xbdzz                       1/1       Running       0          28m
libvirt-9zmtl                                  2/2       Running       0          28m
spice-proxy-864ffd698d-7n7cn                   1/1       Running       0          28m
virt-api-54cb7d858-xpssr                       1/1       Running       0          28m
virt-controller-5d9fc8cf8b-n5trt               0/1       Running       0          27m
virt-handler-vwdjx                             1/1       Running       0          28m
```

In order to use the subresources provided by the KubeVirt API-server, one needs
to expose the port the `haproxy` deployment. One way to do this is a service:

```bash
kubectl expose deployment haproxy --port 8184 -l 'kubevirt.io=' -n kube-system --external-ip $EXTERNAL_IP
```

> Note: Work is in progress to provide resource and subresource access without this
> extra service. Either completely via CRDs or a mixed model with CRDs and an
> aggregated API-server.

## Client side `virtctl` deployment

Basic VirtualMachine operations can be peformed with the stock `kubectl`
utility. However, the `virtctl` binary utility is required to use advanced
features such as:

* Serial and graphical console access

Or to have convenience commands for:

* Starting and stopping VirtualMachines
* Live migrating VirtualMachines

The most recent version of the tool can be retrieved from the [official release
page](https://github.com/kubevirt/kubevirt/releases).

### Spice proxy add-on

Optional install the spice-proxy add-on, to allow connecting to the spice
terminal from outside of the cluster with traditional spice clients like
`remote-viewer`:

```bash
$ RELEASE=v0.0.5
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/spice-proxy.yaml
```

This deployment will add an additional squid proxy pod:

```bash
kubectl get pods -n kube-system -l "kubevirt.io/app=spice-proxy"
NAME                                           READY     STATUS        RESTARTS   AGE
spice-proxy-864ffd698d-7n7cn                   1/1       Running       0          28m
```

To allow access from outside the cluster, the `spice-proxy` deployment needs to
be exposed. Again a service can be used for that:

```bash
kubectl expose deployment spice-proxy --port 3128 -l 'kubevirt.io=' -n kube-system --external-ip $EXTERNAL_IP
```

A spice client will now be able to use the proxy endpoint
`http://$EXTERNAL_IP:3128`. In simple setups it can be helpful to let the
apiserver tell the client which proxy entrypoint to use. It is possible to
configure the proxy on `virt-api` by patching it's deployment:

```bash
$ kubectl patch deployment virt-api -n kube-system --patch "$(cat <<EOF
spec:
  template:
    spec:
      containers:
        - name: virt-api
          env:
            - name: SPICE_PROXY
              value: "http://${EXTERNAL_IP}:3128"
---
EOF
)"
```

When fetching the spice connection details from the apiserver, it will now
contain the spice proxy endpoint.

### Deploying from Source

See the [developer getting started
guide](https://github.com/kubevirt/kubevirt/blob/master/docs/getting-started.md)
to understand how to build and deploy Kubevirt from sources.

## Update

> Note: Updates are not yet supported.

Usually it is sufficient to re-apply the manifests for performing a roling
update:

```bash
$ RELEASE=v0.0.5
$ kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt.yaml
```
