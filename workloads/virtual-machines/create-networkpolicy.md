# Enabling NetworkPolicy for VirtualMachineInstance

Before creating NetworkPolicy objects, make sure you are using a networking solution which supports NetworkPolicy. Network isolation is controlled entirely by NetworkPolicy objects. By default, all vms in a namespace are accessible from other vms and network endpoints. To isolate one or more vms in a project, you can create NetworkPolicy objects in that namespace to indicate the allowed incoming connections.

> Note: vms and pods are treated equally by network policies, since labels are passed through to the pods which contain the running vm. With other words, labels on vms can be matched by ```spec.podSelector``` on the policy.

## Create NetworkPolicy to Deny All Traffic

To make a project "deny by default" add a NetworkPolicy object that matches all vms but accepts no traffic.


```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-by-default
spec:
  podSelector:
  ingress: []
```

## Create NetworkPolicy to only Accept connections from vms within namespaces

To make vms accept connections from other vms in the same namespace, but reject all other connections from vms in other namespaces:


```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-same-namespace
spec:
  podSelector:
  ingress:
  - from:
    - podSelector: {}
```


## Create NetworkPolicy to only allow HTTP and HTTPS traffic

To enable only HTTP and HTTPS access to the vms, add a NetworkPolicy object similar to:

```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-http-https
spec:
  podSelector:
  ingress:
  - ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 8443
```


## Create NetworkPolicy to deny traffic by labels

To make one specific vm with a label ```type: test``` to reject all traffic from other vms, create:

```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-by-label
spec:
  podSelector:
    matchLabels:
      type: test
  ingress: []
```

Kubernetes Networkpolicy Documentation can be found here: [Kubernetes Networkpolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
