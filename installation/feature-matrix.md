# Feature matrix

## Kubernetes feature dependencies

The following table lists the required Kubernetes version for a given KubeVirt release. The dependency arises from features in Kubernetes that KubeVirt builds upon.

| KubeVirt Release | Required Kubernetes and kubectl Version | Note |
| --- | --- | --- |
| v0.1.0 | 1.6 |  |
| v0.2.0 | 1.8 |  |
| v0.3.0 | 1.9 | Due to block storage |

## Resource Types

The following table lists the available resource types.

| Resource Type | Available since | Required Kubernetes and kubectl Version |
| --- | --- | --- |
| Virtual Machine | v0.1.0 | 1.6 |
| ~Migration~ | ~v0.1.0~ | ~1.6~ |
| Virtual Machine Presets | unreleased |  |
| Offline Virtual Machine | unreleased |  |

Migrations are temporarily removed and will be re-enabled soon. Track [\#676](https://github.com/kubevirt/kubevirt/issues/676) to follow the progress.

## Virtual Machine API

The following table lists the major features of the Virtual Machine API.

| Virtual Machine Feature | Available since | Required Kubernetes and kubectl Version |
| --- | --- | --- |
| Storage, PVC \(iSCSI\) | v0.0.2 | 1.6 |
| Access, Serial Console | v0.2.0 | 1.9 |
| Access, VNC Console | v0.2.0 | 1.9 |

## Artifacts

The following table lists deployment related features.

| Deployment Feature | Available since | Required Kubernetes and kubectl Version |
| --- | --- | --- |
| Reference manifests | v0.1.0 | 1.6 |
| KubeVirt ansible | v0.2.0 | 1.8 |

