# Feature Gate Status on Arm64

This page is based on https://github.com/kubevirt/kubevirt/issues/9749
It records the feature gate status on Arm64 platform. Here is the explanation of the status:

- **Supported**: the feature gate support on Arm64 platform.
- **Not supported yet**: there are some dependencies of the feature gate not support Arm64, so this feature does not support for now. We may support the dependencies in the future.
- **Not supported**: The feature gate is not support on Arm64.
- **Not verified**: The feature has not been verified yet.


FEATURE GATE | STATUS | NOTES
-- | -- | --
ExpandDisksGate | Not supported yet| CDI is needed
CPUManager | Supported | use taskset to do CPU pinning, do not support kvm-hint-dedicated (this is only works on x86 platform)
NUMAFeatureGate | Not supported yet | Need to support Hugepage on Arm64
IgnitionGate | Supported | This feature is only used for CoreOS/RhCOS
LiveMigrationGate | Supported | Verified live migration with masquerade network
SRIOVLiveMigrationGate | Not verified | Need two same Machine and SRIOV device
HypervStrictCheckGate | Not supported | Hyperv does not work on Arm64
SidecarGate | Supported |  
GPUGate | Not verified | Need GPU device
HostDevicesGate | Not verified | Need GPU or sound card
SnapshotGate | Supported | Need snapshotter support https://github.com/kubernetes-csi/external-snapshotter
VMExportGate | Partially supported | Need snapshotter support https://kubevirt.io/user-guide/operations/export_api/, support exporting pvc, not support exporting DataVolumes and MemoryDump which rely on CDI
HotplugVolumesGate | Not supported yet | Rely on datavolume and CDI
HostDiskGate | Supported |  
VirtIOFSGate | Supported |  
MacvtapGate | Not supported yet | quay.io/kubevirt/macvtap-cni not support Arm64, https://github.com/kubevirt/macvtap-cni#deployment
PasstGate | Supported | VM have same ip with pods; start a process for network /usr/bin/passt --runas 107 -e -t 8080
DownwardMetricsFeatureGate | need more information | It used to let guest get host information, failed on both Arm64 and x86_64. <br><br>The block is successfully attached and can see the following information:<br>  `-blockdev {"driver":"file","filename":"/var/run/kubevirt-private/downwardapi-disks/vhostmd0","node-name":"libvirt-1-storage","cache":{"direct":true,"no-flush":false},"auto-read-only":true,"discard":"unmap"}`<br><br>But unable to get information via `vm-dump-metrics`:<br><br>`LIBMETRICS: read_mdisk(): Unable to read metrics disk`<br>`LIBMETRICS: get_virtio_metrics(): Unable to export metrics: open(/dev/virtio-ports/org.github.vhostmd.1) No such file or directory`<br>`LIBMETRICS: get_virtio_metrics(): Unable to read metrics`
NonRootDeprecated | Supported |  
NonRoot | Supported |  
Root | Supported |  
ClusterProfiler | Supported |
WorkloadEncryptionSEV | Not supported | SEV is only available on x86_64
VSOCKGate | Supported |  
HotplugNetworkIfacesGate | Not supported yet | Need to setup *multus-cni* and *multus-dynamic-networks-controller*: https://github.com/k8snetworkplumbingwg/multus-cni <br>`cat ./deployments/multus-daemonset-thick.yml \| kubectl apply -f -`https://github.com/k8snetworkplumbingwg/multus-dynamic-networks-controller <br>`kubectl apply -f manifests/dynamic-networks-controller.yaml` <br><br>Currently, the image ghcr.io/k8snetworkplumbingwg/multus-cni:snapshot-thick does not support Arm64 server. For more information please refer to https://github.com/k8snetworkplumbingwg/multus-cni/pull/1027.

