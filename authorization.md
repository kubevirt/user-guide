# Authorization

KubeVirt authorization is performed using Kubernete's Resource Based
Authorization Control system (RBAC). RBAC allows cluster admins to grant
access to cluster resources by binding RBAC roles to users.

For example, an admin creates an RBAC role that represents the permissions
required to create a VirtualMachine. The admin can then bind that role to users
in order to grant them the permissions required to launch a VirtualMachine.

With RBAC roles, admins can grant users targeted access to various KubeVirt
features.

## KubeVirt Default RBAC ClusterRoles

KubeVirt comes with a set of predefined RBAC ClusterRoles that can be used to
grant users permissions to access KubeVirt Resources.

### Default View Role

The **kubevirt.io:view** ClusterRole gives users permissions to view all
KubeVirt resources in the cluster. The permissions to create, delete, modify
or access any KubeVirt resources beyond viewing the resource's spec are not
included in this role. This means a user with this role could see that a 
VirtualMachine is running, but neither shutdown nor gain access to that
VirtualMachine via console/VNC.

### Default Edit Role

The **kubevirt.io:edit** ClusterRole gives users permissions to modify all
KubeVirt resources in the cluster. For example, a user with this role can
create new VirtualMachines, delete VirtualMachines, and gain access to both
console and VNC.

### Default Admin Role

The **kubevirt.io:admin** ClusterRole grants users full permissions to all
KubeVirt resources, including the ability to delete collections of resources.

The admin role also grants users access to view and modify the KubeVirt runtime
config. This config exists within a configmap called **kubevirt-config** in the
namespace the KubeVirt components are running.

*NOTE* Users are only guaranteed the ability to modify the kubevirt runtime
configuration if a ClusterRoleBinding is used. A RoleBinding will work to
provide kubevirt-config access only if the RoleBinding targets the same
namespace the kubevirt-config exists in.

### Binding Default ClusterRoles to Users

The KubeVirt default ClusterRoles are granted to users by creating either a
ClusterRoleBinding or RoleBinding object.

With a ClusterRoleBinding, users receive the permissions granted by the role
across all namespaces.

With a RoleBinding, users receive the permissions granted by the role only
within a targeted namespace.

## Creating Custom RBAC Roles

If the default KubeVirt ClusterRoles are not expressive enough, admins can
create their own custom RBAC roles to grant user access to KubeVirt resources.
The creation of a RBAC role is inclusive only, meaning there's no way to deny
access. Instead access is only granted.

Below is an example of what KubeVirt's default admin ClusterRole looks like.
A custom RBAC role can be created by reducing the permissions in this example
role.

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: my-custom-rbac-role
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachines/console
      - virtualmachines/vnc
    verbs:
      - get
  - apiGroups:
      - kubevirt.io
    resources:
      - virtualmachines
      - offlinevirtualmachines
      - virtualmachinepresets
      - virtualmachinereplicasets
    verbs:
      - get
      - delete
      - create
      - update
      - patch
      - list
      - watch
      - deletecollection
  - apiGroups: [""]
    resources:
      - configmaps
    resourceNames:
      - kubevirt-config
    verbs:
      - update
      - get
      - patch
```
