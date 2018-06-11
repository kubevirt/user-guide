# KubeVirt API Validation

The KubeVirt VirtualMachineInstance API is implemented using a Kubernetes Custom
Resource Definition (CRD). Because of this, KubeVirt is able to leverage a
couple of features Kubernetes provides in order to perform validation checks on
our API as objects created and updated on the cluster.

## How API Validation Works

### CRD OpenAPIv3 Schema

The KubeVirt API is registered with Kubernetes at install time through a series
of CRD definitions. KubeVirt includes an OpenAPIv3 schema in these definitions
which indicates to the Kubernetes Apiserver some very basic information about
our API, such as what fields are required and what type of data is expected for
each value.

This OpenAPIv3 schema validation is installed automatically and requires no
thought on the users part to enable.

### Admission Control Webhooks

The OpenAPIv3 schema validation is limited. It only validates the general
structure of a KubeVirt object looks correct. It does not however verify that
the contents of that object make sense.

With OpenAPIv3 validation alone, users can easily make simple mistakes (like
not referencing a volumeName correctly with a disk) and the cluster will still
accept the object. However, the VirtualMachineInstance will of course not start if
these errors in the API exist. Ideally we'd like to catch configuration issues
as early as possible and not allow an object to even be posted to the cluster
if we can detect there's a problem with the object's Spec.

In order to perform this advanced validation, KubeVirt implements its own
admission controller which is registered with kubernetes as an admission
controller webhook. This webhook is registered with Kubernetes at install time.
As KubeVirt objects are posted to the cluster, the Kubernetes API server
forwards Creation requests to our webhook for validation before persisting the
object into storage.

Note however that the KubeVirt admission controller requires features to be
enabled on the cluster in order to be enabled.

## Enabling KubeVirt Admission Controller on Kubernetes

When provisioning a new Kubernetes cluster, ensure that both the
**MutatingAdmissionWebhook** and **ValidatingAdmissionWebhook** values are
present in the Apiserver's **--admission-control** cli argument.

Below is an example of the **--admission-control** values we use during
development

```
--admission-control='Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota'
```

## Enabling KubeVirt Admission Controller on OpenShift

OpenShift also requires the admission control webhooks to be enabled at install
time. The process is slightly different though. With OpenShift, we enable
webhooks using an admission plugin.

These admission control plugins can be configured in openshift-ansible by
setting the following value in ansible inventory file.

```
openshift_master_admission_plugin_config={"ValidatingAdmissionWebhook":{"configuration":{"kind": "DefaultAdmissionConfig","apiVersion": "v1","disable": false}},"MutatingAdmissionWebhook":{"configuration":{"kind": "DefaultAdmissionConfig","apiVersion": "v1","disable": false}}}
```
