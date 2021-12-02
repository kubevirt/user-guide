
## Customize KubeVirt Components


### Customize components using patches

> :warning: If the patch created is invalid KubeVirt will not be able to update or deploy the system. This is intended for special use cases and should not be used unless you know what you are doing.

Valid resource types are: Deployment, DaemonSet, Service, ValidatingWebhookConfiguraton, MutatingWebhookConfiguration, APIService, and CertificateSecret. More information can be found in the [API spec](http://kubevirt.io/api-reference/master/definitions.html#_v1_customizecomponentspatch).


Example customization patch:
```
---
apiVersion: kubevirt.io/v1alpha3
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  certificateRotateStrategy: {}
  configuration: {}
  customizeComponents:
    patches:
    - resourceType: Deployment
      resourceName: virt-controller
      patch: '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe"}]'
      type: json
    - resourceType: Deployment
      resourceName: virt-controller
      patch: '{"metadata":{"annotations":{"patch": "true"}}}'
      type: strategic
```

The above example will update the `virt-controller` deployment to have an annotation in it's metadata that says `patch: true` and will remove the livenessProbe from the container definition.


### Customize Flags

> :warning: If the flags are invalid or become invalid on update the component will not be able to run


By using the customize flag option, whichever component the flags are to be applied to, all default flags will be removed and only the flags specified will be used. The available resources to change the flags on are `api`, `controller` and `handler`. You can find our more details about the API in the [API spec](http://kubevirt.io/api-reference/master/definitions.html#_v1_flags).

```
apiVersion: kubevirt.io/v1alpha3
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  certificateRotateStrategy: {}
  configuration: {}
  customizeComponents:
    flags:
      api:
        v: "5"
        port: "8443"
        console-server-port: "8186"
        subresources-only: "true"
```

The above example would produce a `virt-api` pod with the following command

```
...
spec:
  ....
  container:
  - name: virt-api
    command:
    - virt-api
    - --v
    - "5"
    - --console-server-port
    - "8186"
    - --port
    - "8443"
    - --subresources-only
    - "true"
    ...
```    
