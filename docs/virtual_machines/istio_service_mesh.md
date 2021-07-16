# Istio service mesh

Service mesh allows to monitor, visualize and control traffic between pods.
Kubevirt supports running VMs as a part of Istio service mesh.

## Limitations

- Istio service mesh is only supported with a pod network masquerade binding.

- Istio uses a [list of ports](https://istio.io/latest/docs/ops/deployment/requirements/#ports-used-by-istio) for its own purposes, these ports must not be explicitly specified in a VMI interface.

- Istio only supports IPv4.

## Prerequisites

- This guide assumes that Istio is already deployed and uses Istio CNI Plugin. See [Istio documentation](https://istio.io/latest/docs/) for more information.

- Optionally, `istioctl` binary for troubleshooting. See Istio [installation inctructions](https://istio.io/latest/docs/setup/getting-started/).

- The target namespace where the VM is created must be labelled with `istio-injection=enabled` label.

- If Multus is used to manage CNI, the following `NetworkAttachmentDefinition` is required in the application namespace:
```yaml
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
```

## Create a VirtualMachineInstance with enabled Istio proxy injecton

The example below specifies a VMI with masquerade network interface and `sidecar.istio.io/inject` annotation to register the VM to the service mesh. 

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstance
metadata:
  annotations:
    sidecar.istio.io/inject: "true"
  labels:
    app: vmi-istio
  name: vmi-istio
spec:
  domain:
    devices:
      interfaces:
        - name: default
          masquerade: {}
      disks:
        - disk:
            bus: virtio
          name: containerdisk
    resources:
      requests:
        memory: 1024M
  networks:
    - name: default
      pod: {}
  terminationGracePeriodSeconds: 0
  volumes:
    - name: containerdisk
      containerDisk:
        image: registry:5000/kubevirt/fedora-cloud-container-disk-demo:devel
```

Istio expects each application to be associated with at least one Kubernetes service. Create the following Service exposing port 8080:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vmi-istio
spec:
  selector:
    app: vmi-istio
  ports:
    - port: 8080
      name: http
      protocol: TCP
```

**Note:** Each Istio enabled VMI must feature the `sidecar.istio.io/inject` annotation instructing KubeVirt to perform necessary network configuration.

## Verification

Verify istio-proxy sidecar is deployed and able to synchronize with Istio control plane using `istioctl proxy-status` command. See Istio [Debbuging Envoy and Istiod](https://istio.io/latest/docs/ops/diagnostic-tools/proxy-cmd/) documentation section for more information about `proxy-status` subcommand.

```shell
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
virt-launcher-vmi-istio-ncx7r    3/3     Running   0          7s

$ kubectl get pods virt-launcher-vmi-istio-ncx7r -o jsonpath='{.spec.containers[*].name}'
compute volumecontainerdisk istio-proxy

$ istioctl proxy-status
NAME                                    CDS        LDS        EDS        RDS          ISTIOD                      VERSION
...
virt-launcher-vmi-istio-ncx7r.default   SYNCED     SYNCED     SYNCED     SYNCED       istiod-7c4d8c7757-hshj5     1.10.0
```

## Troubleshooting

### Istio sidecar is not deployed

```shell
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
virt-launcher-vmi-istio-jnw6p    2/2     Running   0          37s

$ kubectl get pods virt-launcher-vmi-istio-jnw6p -o jsonpath='{.spec.containers[*].name}'
compute volumecontainerdisk
```

**Resolution:** Make sure the `istio-injection=enabled` is added to the target namespace. If the issue persists, consult [relevant part of Istio documentation](https://istio.io/latest/docs/ops/configuration/mesh/injection-concepts/).

### Istio sidecar is not ready
```shell
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
virt-launcher-vmi-istio-lg5gp    2/3     Running   0          90s

$ kubectl describe pod virt-launcher-vmi-istio-lg5gp
  ...
  Warning  Unhealthy  2d8h (x3 over 2d8h)  kubelet            Readiness probe failed: Get "http://10.244.186.222:15021/healthz/ready": dial tcp 10.244.186.222:15021: connect: no route to host
  Warning  Unhealthy  2d8h (x4 over 2d8h)  kubelet            Readiness probe failed: Get "http://10.244.186.222:15021/healthz/ready": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```

**Resolution:** Make sure the `sidecar.istio.io/inject: "true"` annotation is defined in the created VMI and that masquerade binding is used for pod network interface.

### Virt-launcher pod for VMI is stuck at initialization phase
```shell
$ kubectl get pods
NAME                             READY   STATUS     RESTARTS   AGE
virt-launcher-vmi-istio-44mws    0/3     Init:0/3   0          29s

$ kubectl describe pod virt-launcher-vmi-istio-44mws
  ...
  Multus: [default/virt-launcher-vmi-istio-44mws]: error loading k8s delegates k8s args: TryLoadPodDelegates: error in getting k8s network for pod: GetNetworkDelegates: failed getting the delegate: getKubernetesDelegate: cannot find a network-attachment-definition (istio-cni) in namespace (default): network-attachment-definitions.k8s.cni.cncf.io "istio-cni" not found

```

**Resolution:** Make sure the `istio-cni` NetworkAttachmentDefinition (provided in the [Prerequisites](#prerequisites) section) is created in the target namespace.
