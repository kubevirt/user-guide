# Enabling NetworkPolicy for VirtualMachine

Before creating NetworkPolicy object, make sure you are using a networking solution which supports NetworkPolicy. Network isolation is controlled entirely by NetworkPolicy object. By default, all vms in a namespace are accessible from other vms and network endpoints. To isolate one or more vms in a project, you can create NetworkPolicy objects in that namespace to indicate the allowed incoming connections.

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
  name: allow-tcp
spec:
  podSelector:
  ingress:
  - ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 8443
```

Kubernetes Networkpolicy Documentation can be found here: [Kubernetes Networkpolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
