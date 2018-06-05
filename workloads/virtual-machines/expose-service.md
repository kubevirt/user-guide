# Expose VirtualMachines as a Services

Once the VirtualMachine is started, in order to connect to a VirtualMachine,
you can create a `Service` object for a VirtualMachine. Currently, three types
of service are supported: `ClusterIP`, `NodePort` and `LoadBalancer`. The
default type is `ClusterIP`.

> **Note**: Labels on a VirtualMachine are passed through to the pod, so simply
> add your labels for service creation to the vm. From there on it works like
> exposing any other k8s resource, by referencing these labels in a service.

## Expose VirtualMachine as a ClusterIP service

Give a VirtualMachine wit the label `special: key`:

```yaml
apiVersion: kubevirt.io/v1alpha1
kind: VirtualMachine
metadata:
  name: vm-ephemeral
  labels:
    special: key
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: registrydisk
        volumeName: registryvolume
    resources:
      requests:
        memory: 64M
  volumes:
  - name: registryvolume
    registryDisk:
      image: kubevirt/cirros-registry-disk-demo:latest
```

we can expose its SSH port (22) by creating a `ClusterIP service`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vmservice
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 22
  selector:
    special: key
  type: ClusterIP
```

You just need to create this `ClusterIP service` by using `kubectl`:

```bash
$ kubectl create -f svc.yaml
```

Query the service object:

```bash
$ kubectl get service
NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
vmservice   ClusterIP   172.30.3.149   <none>        27017/TCP   2m
```

You can connect to the VirtualMachine by service IP and service port inside the cluster network:

```bash
$ ssh cirros@172.30.3.149 -p 27017
```

## Expose VirtualMachine as a NodePort service

Expose the SSH port (22) of a VirtualMachine running on KubeVirt by creating a
`NodePort service`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: testnodeport
spec:
  externalTrafficPolicy: Cluster
  ports:
  - name: nodeport
    nodePort: 30000
    port: 27017
    protocol: TCP
    targetPort: 22
  selector:
    special: key
  type: NodePort
```

You just need to create this `NodePort service` by using `kubectl`:

```bash
$ kubectl -f nodeport.yaml
```

The service can be listed by querying for the service objects:

```bash
$ kubectl get service
NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
nodeportsvc    NodePort   172.30.232.73   <none>        27017:30000/TCP   5m
```

Connect to the VirtualMachine by using a node IP and node port outside the
clusternetwork:

```bash
$ ssh cirros@$NODE_IP -p 30000
```

## Expose VirtualMachine as a LoadBalancer service

Expose the RDP port (3389) of a VirtualMachine running on KubeVirt by creating
`LoadBalancer service`. Here is an example of a LoadBalancer service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: lbsvc
spec:
  externalTrafficPolicy: Cluster
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 3389
  selector:
    speical: key
  type: LoadBalancer
```

You could create this `LoadBalancer` service by using `kubectl`:

```bash
$ kubectl -f lbsvc.yaml
```

The service can be listed by querying for the service objects:

```bash
$ kubectl get svc
NAME      TYPE           CLUSTER-IP       EXTERNAL-IP                   PORT(S)           AGE
lbsvc     LoadBalancer   172.30.27.5      172.29.10.235,172.29.10.235   27017:31829/TCP   5s
```

Use `vinagre` client to connect your VirtualMachine by using the public IP and
port.

## Directly exposing the Pod behind the VirtualMachine

It is also possible to use `kubectl expose` to expose the pod of the
VirtualMachine directly:

```bash
$ kubectl get pod -l "special=key"
NAME                                READY     STATUS    RESTARTS   AGE
virt-launcher-windows2012r2-x9x2f   1/1       Running   0          9m
$ kubectl expose pod virt-launcher-windows2012r2-x9x2f --port=27017 --target-port=3389 --name=lbsvc --type=LoadBalancer
```

We will soon provide a similar command for `virtctl`.
