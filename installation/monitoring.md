Monitoring KubeVirt components
==============================

All KubeVirt system-components expose Prometheus metrics at their
`/metrics` REST endpoint.

Custom Service Discovery
------------------------

Prometheus supports service discovery based on
[Pods](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)
and
[Endpoints](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)
out of the box. Both can be used to discover KubeVirt services.

All Pods which expose metrics are labeled with `prometheus.kubevirt.io`
and contain a port-definition which is called `metrics`. In the KubeVirt
release-manifests, the default `metrics` port is `8443`.

The above labels and port informations are collected by a `Service`
called `kubevirt-prometheus-metrics`. Kuberentes automatically creates a
corresponding `Endpoint` with an equal name:

    $ kubectl get endpoints -n kubevirt kubevirt-prometheus-metrics -o yaml
    apiVersion: v1
    kind: Endpoints
    metadata:
      labels:
        kubevirt.io: ""
        prometheus.kubevirt.io: ""
      name: kubevirt-prometheus-metrics
      namespace: kubevirt
    subsets:
    - addresses:
      - ip: 10.244.0.5
        nodeName: node01
        targetRef:
          kind: Pod
          name: virt-handler-cjzg6
          namespace: kubevirt
          resourceVersion: "4891"
          uid: c67331f9-bfcf-11e8-bc54-525500d15501
      - ip: 10.244.0.6
      [...]
      ports:
      - name: metrics
        port: 8443
        protocol: TCP

By watching this endpoint for added and removed IPs to
`subsets.addresses` and appending the `metrics` port from
`subsets.ports`, it is possible to always get a complete list of
ready-to-be-scraped Prometheus targets.

Integrating with the prometheus-operator
----------------------------------------

The [prometheus-operator](https://github.com/coreos/prometheus-operator)
can make use of the `kubevirt-prometheus-metrics` service to
automatically create the appropriate Prometheus config.

KubeVirt’s `virt-operator` checks if the `ServiceMonitor` custom
resource exists when creating an install strategy for deployment.
KubeVirt will automatically create a `ServiceMonitor` resource in the
`monitorNamespace`, as well as an appropriate role and rolebinding in
KubeVirt’s namespace.

Two settings are exposed in the `KubeVirt` custom resource to direct
KubeVirt to create these resources correctly:

-   `monitorNamespace`: The namespace that prometheus-operator runs in.
    Defaults to `openshift-monitoring`.

-   `monitorAccount`: The serviceAccount that prometheus-operator runs
    with. Defaults to `prometheus-k8s`.

If the prometheus-operator for a given deployment uses these defaults,
then these values can be omitted.

An example of the KubeVirt resource depicting these default values:

    apiVersion: kubevirt.io/v1alpha3
    kind: KubeVirt
    metadata:
      name: kubevirt
    spec:
      monitorNamespace: openshift-monitoring
      monitorAccount: prometheus-k8s

Integrating with the OKD cluster-monitoring-operator
----------------------------------------------------

After the
[cluster-monitoring-operator](https://github.com/openshift/cluster-monitoring-operator)
is up and running, KubeVirt will detect the existence of the
`ServiceMonitor` resource. Because the definition contains the
`openshift.io/cluster-monitoring` label, it will automatically be picked
up by the cluster monitor.

Metrics about Virtual Machines
------------------------------

The endpoints report metrics related to the runtime behaviour of the
Virtual Machines. All the relevant metrics are prefixed with
`kubevirt_vmi`.

The metrics have labels that allow to connect to the VMI objects they
refer to. At minimum, the labels will expose `node`, `name` and
`namespace` of the related VMI object.

For example, reported metrics could look like

```
kubevirt_vmi_memory_resident_bytes{domain="default_vm-test-01",name="vm-test-01",namespace="default",node="node01"} 2.5595904e+07
kubevirt_vmi_network_traffic_bytes_total{domain="default_vm-test-01",interface="vnet0",name="vm-test-01",namespace="default",node="node01",type="rx"} 8431
kubevirt_vmi_network_traffic_bytes_total{domain="default_vm-test-01",interface="vnet0",name="vm-test-01",namespace="default",node="node01",type="tx"} 1835
kubevirt_vmi_vcpu_seconds{domain="default_vm-test-01",id="0",name="vm-test-01",namespace="default",node="node01",state="1"} 19
```

Please note the `domain` label in the above example. This label is
deprecated and it will be removed in a future release. You should
identify the VMI using the `node`, `namespace`, `name` labels instead.

Important Queries
-----------------

### Detecting connection issues for the REST client

Use the following query to get a counter for all REST call which
indicate connection issues:

    rest_client_requests_total{code="<error>"}

If this counter is continuously increasing, it is an indicator that the
corresponding KubeVirt component has general issues to connect to the
apiserver
