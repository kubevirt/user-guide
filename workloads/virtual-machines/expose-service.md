# Expose Service

## Expose VirtualMachine as a service

Once the VirtualMachine is started, in order to connect to a VirtualMachine, you can create a `Service` object for a VirtualMachine.

## Expose VirtualMachine as a NodePort service

Expose the SSH port \(TCP port 22\) of a VirtualMachine running on KubeVirt. Here is an example of a NodePort service:

```text
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
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
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

## Expose VirtualMachine as a single port service

Create a single port `service` object by using `kubectl`:

```bash
$ kubectl expose pod virt-launcher-testvm-ephemeral-9bqv4 --port=27017 --target-port=22 --name=vmservice
```

Query the service object:

```bash
$ kubectl get service
NAME        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
vmservice   ClusterIP   172.30.3.149   <none>        27017/TCP   2m
```

You can connect to the VirtualMachine by service IP and service port inside the clusternetwork:

```bash
$ ssh cirros@172.30.232.73 -p 27017
```

