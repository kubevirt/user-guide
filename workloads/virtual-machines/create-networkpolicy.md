# Enabling NetworkPolicy for VirtualMachineInstance

Before creating NetworkPolicy objects, make sure you are using a networking solution which supports NetworkPolicy. Network isolation is controlled entirely by NetworkPolicy objects. By default, all vmis in a namespace are accessible from other vmis and network endpoints. To isolate one or more vmis in a project, you can create NetworkPolicy objects in that namespace to indicate the allowed incoming connections.

> Note: vmis and pods are treated equally by network policies, since labels are passed through to the pods which contain the running vmi. With other words, labels on vmis can be matched by ```spec.podSelector``` on the policy.

## Create NetworkPolicy to Deny All Traffic

To make a project "deny by default" add a NetworkPolicy object that matches all vmis but accepts no traffic.


```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-by-default
spec:
  podSelector:
  ingress: []
```

## Create NetworkPolicy to only Accept connections from vmis within namespaces

To make vmis accept connections from other vmis in the same namespace, but reject all other connections from vmis in other namespaces:


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

To enable only HTTP and HTTPS access to the vmis, add a NetworkPolicy object similar to:

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

To make one specific vmi with a label ```type: test``` to reject all traffic from other vmis, create:

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

Kubernetes NetworkPolicy Documentation can be found here: [Kubernetes NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
