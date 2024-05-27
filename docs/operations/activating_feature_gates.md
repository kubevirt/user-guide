# Activating feature gates

KubeVirt has a set of features that are not mature enough to be enabled by
default. As such, they are protected by a Kubernetes concept called
[feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/).

## How to activate a feature gate
You can activate a specific feature gate directly in KubeVirt's CR, by
provisioning the following yaml, which uses the `LiveMigration` feature gate
as an example:
```bash
cat << END > enable-feature-gate.yaml
---
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration: 
      featureGates:
        - LiveMigration
END

kubectl apply -f enable-feature-gate.yaml
```

Alternatively, the existing kubevirt CR can be altered:
```bash
kubectl edit kubevirt kubevirt -n kubevirt
```

```yaml
...
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - DataVolumes
        - LiveMigration
```

**Note:** the name of the feature gates is case sensitive.

The snippet above assumes KubeVirt is installed in the `kubevirt` namespace.
Change the namespace to suite your installation.

## List of feature gates

FEATURE NAME| FEATURE GATE | ARM SUPPORTED | NOTES | DESCRIPTION
-- | -- | -- | -- | --
ExpandDisks | ExpandDisksGate | No [WIP]| CDI is needed |  
CPUManager | CPUManager | Yes | use taskset to do CPU pinning, do not support kvm-hint-dedicated (this is only works on x86 platform) |  
NUMA | NUMAFeatureGate | No [WIP] | Need to support Hugepage on Arm64 |  
ExperimentalIgnitionSupport| IgnitionGate | Yes | This feature is only used for CoreOS/RhCOS |  
LiveMigration **(Deprecated)** | LiveMigrationGate | Yes | Verified live migration with masquerade network |  
SRIOVLiveMigration **(Deprecated)**| SRIOVLiveMigrationGate | Not verified | Need two same Machine and SRIOV device |  
HypervStrictCheck | HypervStrictCheckGate | No | Hyperv does not work on Arm64 |  
Sidecar | SidecarGate | Yes |   |  
GPU | GPUGate | Not verified | Need GPU device |  
HostDevices| HostDevicesGate | Not verified | Need GPU or sound card |  
Snapshot| SnapshotGate | Yes | Need snapshotter support https://github.com/kubernetes-csi/external-snapshotter |  
VMExport| VMExportGate | Partially Yes | Need snapshotter support https://kubevirt.io/user-guide/operations/export_api/, support exporting pvc, not support exporting DataVolumes and MemoryDump which rely on CDI |  
HotplugVolumes| HotplugVolumesGate | No [WIP] | Rely on datavolume and CDI |  
HostDisk| HostDiskGate | Yes |   |  
ExperimentalVirtiofsSupport| VirtIOFSGate | Yes |   |  
Macvtap **(Deprecated)**| MacvtapGate | No [WIP] | quay.io/kubevirt/macvtap-cni not support Arm64, https://github.com/kubevirt/macvtap-cni#deployment |  
Passt **(Deprecated)**| PasstGate | Yes | VM have same ip with pods; start a process for network /usr/bin/passt --runas 107 -e -t 8080 |  
DownwardMetrics| DownwardMetricsFeatureGate | need more information | It used to let guest get host information, failed on both Arm64 and x86_64. <br><br>The block is successfully attached and can see the following information:<br>  `-blockdev {"driver":"file","filename":"/var/run/kubevirt-private/downwardapi-disks/vhostmd0","node-name":"libvirt-1-storage","cache":{"direct":true,"no-flush":false},"auto-read-only":true, "discard":"unmap"}`<br><br>But unable to get information via `vm-dump-metrics`:<br><br>`LIBMETRICS: read_mdisk(): Unable to read metrics disk`<br>`LIBMETRICS: get_virtio_metrics(): Unable to export metrics: open (/dev/virtio-ports/org.github.vhostmd.1) No such file or directory`<br>`LIBMETRICS: get_virtio_metrics(): Unable to read metrics` |  
**TO DELETE ** | NonRootDeprecated | Yes |   |  
?? | NonRoot | Yes |   |  
Root| RootGate ??? | Yes |   |  
ClusterProfiler | ClusterProfilerGate ??? | Yes | |  
WorkloadEncryptionSEV | WorkloadEncryptionSEV | No | SEV is only available on x86_64 |  
VSOCK | VSOCKGate | Yes |   |  
HotplugNICs| HotplugNetworkIfacesGate | No [WIP] | Need to setup *multus-cni* and *multus-dynamic-networks-controller*: https://github.com/k8snetworkplumbingwg/multus-cni <br>`cat ./deployments/ multus-daemonset-thick.yml \| kubectl apply -f -`https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller <br>`kubectl apply -f manifests/dynamic-networks-controller.yaml` <br><br>Currently, the image ghcr.io/k8snetworkplumbingwg/multus-cni:snapshot-thick does not support Arm64 server. For more information please refer to https://github.com/k8snetworkplumbingwg/multus-cni/pull/1027. |  
CommonInstancetypesDeployment| CommonInstancetypesDeploymentGate | No [WIP] | Support of common-instancetypes instancetypes needs to be tested, common-instancetypes preferences for ARM workloads are still missing |  
AlignCPUs | AlignCPUsGate | Not verified | | |  
AutoResourceLimits | AutoResourceLimitsGate | Not verified | | |  
NetworkBindingPlugins | NetworkBindingPlugingsGate | Not verified | | |  
BochsDisplayForEFIGuests | BochsDisplayForEFIGuestsGate | Not verified | | |  
VMLiveUpdateFeatures | VMLiveUpdateFeaturesGate | Not verified | | |  
MultiArchitecture | MultiArchitectureGate | Not verified | | |  
VMPersistentState | VMPersistentStateGate | Not verified | | |  
PersistentReservation | PersistentReservationGate | Not verified | | |  
DisableMDEVConfiguration | DisableMediatedDevicesHandlingGate | Not verified | | |  
DisableCustomSELinuxPolicy | KubevirtSeccompProfileGate | Not verified | | |  
KubevirtSeccompProfile | DisableCustomSELinuxPolicyGate | Not verified | | |  
DockerSELinuxMCSWorkaround | DockerSELinuxMCSWorkaroundGate | Not verified | | |  



For the last list of feature gates can be checked directly from
the [source code](https://github.com/kubevirt/kubevirt/blob/main/pkg/virt-config/feature-gates.go#L26).


