# Expose VirtualMachineInstances as a Services

Once the VirtualMachineInstance is started, in order to connect to a VirtualMachineInstance,
you can create a `Service` object for a VirtualMachineInstance. Currently, three types
of service are supported: `ClusterIP`, `NodePort` and `LoadBalancer`. The
default type is `ClusterIP`.

> **Note**: Labels on a VirtualMachineInstance are passed through to the pod, so simply
> add your labels for service creation to the VirtualMachineInstance. From there on it works like
> exposing any other k8s resource, by referencing these labels in a service.

## Expose VirtualMachineInstance as a ClusterIP Service

Give a VirtualMachineInstance with the label `special: key`:

```yaml
apiVersion: kubevirt.io/v1alpha2
kind: VirtualMachineInstance
metadata:
  name: vmi-ephemeral
  labels:
    special: key
spec:
  domain:
    devices:
      disks:
      - disk:
          bus: virtio
        name: containerdisk
        volumeName: registryvolume
    resources:
      requests:
        memory: 64M
  volumes:
  - name: registryvolume
    containerDisk:
      image: kubevirt/cirros-registry-disk-demo:latest
```

we can expose its SSH port (22) by creating a `ClusterIP` service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vmiservice
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 22
  selector:
    special: key
  type: ClusterIP
```

You just need to create this `ClusterIP` service by using `kubectl`:

```bash
$ kubectl create -f vmiservice.yaml
```

Alternatively, the VirtualMachineInstance could be exposed using the `virtctl` command:


```bash
$ virtctl expose virtualmachineinstance vmi-ephemeral --name vmiservice --port 27017 --target-port 22
```

Notes:
* If `--target-port` is not set, it will be take the same value as `--port`
* The cluster IP is usually allocated automatically, but it may also be forced into a value using the `--cluster-ip` flag (assuming value is in the valid range and not taken)

Query the service object:

```bash
$ kubectl get service
NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
vmiservice   ClusterIP   172.30.3.149   <none>        27017/TCP   2m
```

You can connect to the VirtualMachineInstance by service IP and service port inside the cluster network:

```bash
$ ssh cirros@172.30.3.149 -p 27017
```

## Expose VirtualMachineInstance as a NodePort Service

Expose the SSH port (22) of a VirtualMachineInstance running on KubeVirt by creating a
`NodePort` service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport
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

You just need to create this `NodePort` service by using `kubectl`:

```bash
$ kubectl -f nodeport.yaml
```

Alternatively, the VirtualMachineInstance could be exposed using the `virtctl` command:

```bash
$ virtctl expose virtualmachineinstance vmi-ephemeral --name nodeport --type NodePort --port 27017 --target-port 22 --node-port 30000
```

Notes:
* If `--node-port` is not set, its value will be allocated dynamically (in the range above 30000)
* If the `--node-port` value is set, it must be unique across all services

The service can be listed by querying for the service objects:

```bash
$ kubectl get service
NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
nodeport       NodePort   172.30.232.73   <none>        27017:30000/TCP   5m
```

Connect to the VirtualMachineInstance by using a node IP and node port outside the
cluster network:

```bash
$ ssh cirros@$NODE_IP -p 30000
```

## Expose VirtualMachineInstance as a LoadBalancer Service

Expose the RDP port (3389) of a VirtualMachineInstance running on KubeVirt by creating
`LoadBalancer` service. Here is an example:

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
    special: key
  type: LoadBalancer
```

You could create this `LoadBalancer` service by using `kubectl`:

```bash
$ kubectl -f lbsvc.yaml
```

Alternatively, the VirtualMachineInstance could be exposed using the `virtctl` command:

```bash
$ virtctl expose virtualmachineinstance vmi-ephemeral --name lbsvc --type LoadBalancer --port 27017 --target-port 3389
```

Note that the external IP of the service could be forced to a value using the `--external-ip` flag (no validation is performed on this value).

The service can be listed by querying for the service objects:

```bash
$ kubectl get svc
NAME      TYPE           CLUSTER-IP       EXTERNAL-IP                   PORT(S)           AGE
lbsvc     LoadBalancer   172.30.27.5      172.29.10.235,172.29.10.235   27017:31829/TCP   5s
```

Use `vinagre` client to connect your VirtualMachineInstance by using the public IP and
port. 

Note that here the external port here (31829) was dynamically allocated.

