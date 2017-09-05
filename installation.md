## Installation

KubeVirt is an add-on to Kubernetes.

This implies that KubeVirt requires a Kubernetes cluster to be already installed.

### Requirements

* Kubernets cluster \(Kubernetes, OpenShift, Tectonic\)
* kubectl client utility
* git

### Add-on deployment

The add-on is getting deployed through a pre-compiled manifest:

`kubectl create -f run.kubevirt.io/on/kubernetes.yaml`

### Client side `virtctl` deployment

Basic VM operations can be peformed with the stock `kubectl` utility. But the `virtctl` binary is required to use advanced features, i.e.:

* Serial and graphical console access
* Actions for starting and stopping
* Action for live-migration