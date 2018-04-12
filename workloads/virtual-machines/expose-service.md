# Expose Service

## Expose VirtualMachine as a service

Once the VirtualMachine is started, in order to connect to a VirtualMachine, you can create a `Service` object for a VirtualMachine.
Currently, three types of service are supported: `ClusterIP`, `NodePort` and `LoadBalancer`. The default type is `ClusterIP`.

## Expose VirtualMachine as a ClusterIP service

Expose the SSH port (22) of a VirtualMachine running on KubeVirt by creating a `ClusterIP service`. Here is an example of a ClusterIP service:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    kubevirt.io: virt-launcher
    kubevirt.io/domain: testvm-ephemeral
  name: vmservice
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 22
  selector:
    kubevirt.io: virt-launcher
    kubevirt.io/domain: testvm-ephemeral
  type: ClusterIP
```

You just need to create this `ClusterIP service` by using `kubectl`:

```bash
$ kubectl -f svc.yaml
# OR
$ kubectl get pod
NAME                                   READY     STATUS    RESTARTS   AGE
virt-launcher-testvm-ephemeral-9bqv4   2/2       Running   0          10m
$ kubectl expose pod virt-launcher-testvm-ephemeral-9bqv4 --port=27017 --target-port=22 --name=vmservice
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

Expose the SSH port (22) of a VirtualMachine running on KubeVirt by creating a `NodePort service`. Here is an example of a NodePort service:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    kubevirt.io: virt-launcher
    kubevirt.io/domain: testvm-ephemeral
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
    kubevirt.io: virt-launcher
    kubevirt.io/domain: testvm-ephemeral
  type: NodePort
```

You just need to create this `NodePort service` by using `kubectl`:

```bash
$ kubectl -f nodeport.yaml
# OR
$ kubectl get pod
NAME                                   READY     STATUS    RESTARTS   AGE
virt-launcher-testvm-ephemeral-9bqv4   2/2       Running   0          10m
$ kubectl expose pod virt-launcher-testvm-ephemeral-mxjh8 --port=27017 --target-port=22 --type=NodePort --name=nodeportsvc
```

The service can be listed by querying for the service objects:

```bash
$ kubectl get service
NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
nodeportsvc    NodePort   172.30.232.73   <none>        27017:30000/TCP   5m
```

Connect to the VirtualMachine by using a node IP and node port outside the clusternetwork:

```bash
$ ssh cirros@$NODE_IP -p 30000
```

## Expose VirtualMachine as a LoadBalancer service

Expose the RDP port (3389) of a VirtualMachine running on KubeVirt by creating `LoadBalancer service`. Here is an example of a LoadBalancer service:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    kubevirt.io: virt-launcher
    kubevirt.io/domain: windows2012r2
  name: lbsvc
spec:
  externalTrafficPolicy: Cluster
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 3389
  selector:
    kubevirt.io: virt-launcher
    kubevirt.io/domain: windows2012r2
  type: LoadBalancer
```

You could create this `LoadBalancer` service by using `kubectl`:

```bash
$ kubectl -f lbsvc.yaml
# OR
$ kubectl get pod
NAME                                READY     STATUS    RESTARTS   AGE
virt-launcher-windows2012r2-x9x2f   1/1       Running   0          9m
$ kubectl expose pod virt-launcher-windows2012r2-x9x2f --port=27017 --target-port=3389 --name=lbsvc --type=LoadBalancer
```

The service can be listed by querying for the service objects:

```bash
$ kubectl get svc
NAME      TYPE           CLUSTER-IP       EXTERNAL-IP                   PORT(S)           AGE
lbsvc     LoadBalancer   172.30.27.5      172.29.10.235,172.29.10.235   27017:31829/TCP   5s
```

Use `vinagre` client to connect your VirtualMachine by using the public IP and port.
