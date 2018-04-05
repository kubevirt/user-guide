# Usage

Using KubeVirt should be fairly nautral if you are used to work with Kubernetes.

The primary way of using KubeVirt is by working with the KubeVirt kinds in the Kubernetes API:

```bash
$ kubectl create -f vm.yaml
$ kubectl get vms
$ kubectl delete vms testvm
```

The following pages describe how to use and discover the API, manage, and access virtual machines.

## User Interface

KubeVirt does not come with a UI, it is only extending the Kuebrnetes API with virtualization functionality.

