# Authorization

KubeVirt authorization is performed using Kubernetes's Resource Based
Authorization Control system (RBAC). RBAC allows cluster admins to grant
access to cluster resources by binding RBAC roles to users.

For example, an admin creates an RBAC role that represents the
permissions required to create a VirtualMachineInstance. The admin can
then bind that role to users in order to grant them the permissions
required to launch a VirtualMachineInstance.

With RBAC roles, admins can grant users targeted access to various
KubeVirt features.

## KubeVirt Default RBAC ClusterRoles

KubeVirt comes with a set of predefined RBAC ClusterRoles that can be
used to grant users permissions to access KubeVirt Resources.

### Default View Role

The **kubevirt.io:view** ClusterRole gives users permissions to view all
KubeVirt resources in the cluster. The permissions to create, delete,
modify or access any KubeVirt resources beyond viewing the resource's
spec are not included in this role. This means a user with this role
could see that a VirtualMachineInstance is running, but neither shutdown
nor gain access to that VirtualMachineInstance via console/VNC.

### Default Edit Role

The **kubevirt.io:edit** ClusterRole gives users permissions to modify
all KubeVirt resources in the cluster. For example, a user with this
role can create new VirtualMachineInstances, delete
VirtualMachineInstances, and gain access to both console and VNC.

### Default Admin Role

The **kubevirt.io:admin** ClusterRole grants users full permissions to
all KubeVirt resources, including the ability to delete collections of
resources.

The admin role also grants users access to view and modify the KubeVirt
runtime config. This config exists within the Kubevirt Custom Resource under
the `configuration` key in the namespace the KubeVirt operator is running.

> *NOTE* Users are only guaranteed the ability to modify the kubevirt
> runtime configuration if a ClusterRoleBinding is used. A RoleBinding
> will work to provide kubevirt CR access only if the RoleBinding
> targets the same namespace that the kubevirt CR exists in.

### Binding Default ClusterRoles to Users

The KubeVirt default ClusterRoles are granted to users by creating
either a ClusterRoleBinding or RoleBinding object.

#### Binding within All Namespaces

With a ClusterRoleBinding, users receive the permissions granted by the
role across all namespaces.

#### Binding within Single Namespace

With a RoleBinding, users receive the permissions granted by the role
only within a targeted namespace.

## RBAC Role Aggregation

KubeVirt uses the Kubernetes
[aggregated ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles)
feature to automatically extend the default Kubernetes roles (`admin`,
`edit`, `view`) with KubeVirt permissions. This means that by default,
any user who already has one of these standard Kubernetes roles
automatically receives the corresponding KubeVirt permissions within
their namespace, without any additional configuration.

The mapping between KubeVirt ClusterRoles and Kubernetes default roles
is:

| KubeVirt ClusterRole | Aggregates to Kubernetes Role |
|----------------------|-------------------------------|
| `kubevirt.io:admin`  | `admin`                       |
| `kubevirt.io:edit`   | `edit`                        |
| `kubevirt.io:view`   | `view`                        |

This aggregation is controlled by `aggregate-to-*` labels on the
KubeVirt ClusterRoles (e.g.
`rbac.authorization.k8s.io/aggregate-to-admin: "true"`).

### Controlling Role Aggregation Strategy

> *NOTE* This feature is Alpha and requires the `OptOutRoleAggregation`
> feature gate. It is available starting from KubeVirt v1.8.

While automatic RBAC aggregation is convenient for many deployments,
security-conscious environments may require more granular control over
permissions. KubeVirt provides the `roleAggregationStrategy` field in
the KubeVirt CR configuration, which allows cluster administrators to
opt out of automatic aggregation.

The `roleAggregationStrategy` field accepts two values:

- **`AggregateToDefault`** (default): KubeVirt ClusterRoles are
  aggregated to the default Kubernetes roles. Users with the standard
  `admin`, `edit`, or `view` roles automatically receive the
  corresponding KubeVirt permissions. This is the default behavior when
  the field is not set.

- **`Manual`**: KubeVirt ClusterRoles are **not** aggregated to the
  default Kubernetes roles. Users must be granted KubeVirt permissions
  explicitly through dedicated RoleBindings or ClusterRoleBindings.

#### Enabling Manual Role Aggregation

To use the `Manual` strategy, first enable the `OptOutRoleAggregation`
feature gate, then set `roleAggregationStrategy` to `Manual`:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - OptOutRoleAggregation
    roleAggregationStrategy: Manual
```

See [Activating feature gates](activating_feature_gates.md) for more
details on enabling feature gates.

> *NOTE* Setting `roleAggregationStrategy` to `Manual` without enabling
> the `OptOutRoleAggregation` feature gate will be rejected by the
> admission webhook. The value `AggregateToDefault` (or leaving the
> field unset) does not require the feature gate.

#### Re-enabling Aggregation

To restore the default aggregation behavior, set `roleAggregationStrategy`
to `AggregateToDefault` or remove the field entirely:

```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    roleAggregationStrategy: AggregateToDefault
```

The change takes effect on the next reconciliation cycle without
requiring a KubeVirt reinstallation.

#### Behavior Summary

| Configuration | Fresh Install | Existing Install |
|---------------|---------------|------------------|
| `AggregateToDefault` or unset | ClusterRoles created with aggregate labels | Aggregate labels restored if previously removed |
| `Manual` (with feature gate) | ClusterRoles created without aggregate labels | Aggregate labels removed from existing ClusterRoles |

#### Granting Permissions with Manual Strategy

When `roleAggregationStrategy` is set to `Manual`, users with the
standard Kubernetes `admin`, `edit`, or `view` roles will **not**
automatically receive KubeVirt permissions. Instead, cluster
administrators must explicitly bind the KubeVirt ClusterRoles to users
or groups.

**Granting full KubeVirt admin permissions in a single namespace:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubevirt-admin
  namespace: my-namespace
subjects:
  - kind: User
    name: jane
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: kubevirt.io:admin
  apiGroup: rbac.authorization.k8s.io
```

**Granting view-only access across all namespaces:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubevirt-viewers
subjects:
  - kind: Group
    name: vm-viewers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: kubevirt.io:view
  apiGroup: rbac.authorization.k8s.io
```

**Granting edit access to a group in a specific namespace:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubevirt-editors
  namespace: dev-team
subjects:
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: kubevirt.io:edit
  apiGroup: rbac.authorization.k8s.io
```

> *NOTE* Regardless of the `roleAggregationStrategy` setting, all
> authenticated users retain read access to the KubeVirt CR itself
> (`get`, `list` on `kubevirts.kubevirt.io`). This is granted by the
> **kubevirt.io:default** ClusterRole, which is bound to the
> `system:authenticated` group and is not affected by role aggregation.

## Creating Custom RBAC Roles

If the default KubeVirt ClusterRoles are not expressive enough, admins
can create their own custom RBAC roles to grant user access to KubeVirt
resources. The creation of a RBAC role is inclusive only, meaning
there's no way to deny access. Instead access is only granted.

Below is an example of what KubeVirt's default admin ClusterRole looks
like. A custom RBAC role can be created by reducing the permissions in
this example role.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: my-custom-rbac-role
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachineinstances/console
      - virtualmachineinstances/vnc
    verbs:
      - get
  - apiGroups:
      - kubevirt.io
    resources:
      - virtualmachineinstances
      - virtualmachines
      - virtualmachineinstancepresets
      - virtualmachineinstancereplicasets
    verbs:
      - get
      - delete
      - create
      - update
      - patch
      - list
      - watch
      - deletecollection
```