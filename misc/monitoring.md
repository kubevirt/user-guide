# Monitoring KubeVirt components

All KubeVirt system-components expose Prometheus metrics at their `/metrics`
REST endpoint.

## Custom Service Discovery

Prometheus supports service discovery based on
[Pods](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)
and
[Endpoints](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)
out of the box. Both can be used to discover KubeVirt services.

All Pods which expose metrics are labeled with `prometheus.kubevirt.io` and
contain a port-definition which is called `metrics`. In the KubeVirt
release-manifests, the default `metrics` port is `8443`.

The above labels and port informations are collected by a `Service` called
`kubevirt-prometheus-metrics`. Kuberentes automatically creates a corresponding
`Endpoint` with an equal name:

```
$ kubectl get endpoints -n kube-system kubevirt-prometheus-metrics -o yaml
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    kubevirt.io: ""
    prometheus.kubevirt.io: ""
  name: kubevirt-prometheus-metrics
  namespace: kube-system
subsets:
- addresses:
  - ip: 10.244.0.5
    nodeName: node01
    targetRef:
      kind: Pod
      name: virt-handler-cjzg6
      namespace: kube-system
      resourceVersion: "4891"
      uid: c67331f9-bfcf-11e8-bc54-525500d15501
  - ip: 10.244.0.6
  [...]
  ports:
  - name: metrics
    port: 8443
    protocol: TCP
```

By watching this endpoint for added and removed IPs to `subsets.addresses` and
appending the `metrics` port from `subsets.ports`, it is possible to always get
a complete list of ready-to-be-scraped Prometheus targets.

## Integrating with the prometheus-operator

The [prometheus-operator](https://github.com/coreos/prometheus-operator) can
make use of the `kubevirt-prometheus-metrics` service to automatically create
the appropriate Prometheus config.

First deploy the prometheus-operator, then create a prometheus instance:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus
spec:
  serviceAccountName: prometheus
  serviceMonitorSelector:
    matchLabels:
      prometheus.kubevirt.io: ""
  resources:
    requests:
      memory: 400Mi
```

Then create a `ServiceMonitor` which references the
`kubevirt-prometheus-metrics` via the `prometheus.kubevirt.io` label:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kubevirt
  labels:
    openshift.io/cluster-monitoring: ""
    prometheus.kubevirt.io: ""
spec:
  selector:
    matchLabels:
      prometheus.kubevirt.io: ""
  endpoints:
  - port: metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
```

## Integrating with the OpenShift cluster-monitoring-operator

After the
[cluster-monitoring-operator](https://github.com/openshift/cluster-monitoring-operator)
is up and running, deploy the `ServiceMonitor` definition from above. Because
the definition contains the `openshift.io/cluster-monitoring` label, it will
automatically be picked up by the cluster monitor.

## Important Queries

### Detecting connection issues for the REST client

Use the following query to get a counter for all REST call which indicate
connection issues:
```
rest_client_requests_total{code="<error>"}
```
If this counter is continuously increasing, it is an indicator that the
corresponding KubeVirt component has general issues to connect to the apiserver
