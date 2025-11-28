---
hide:
  - navigation
---

# KubeVirt release notes


## v1.7.0

Released on: Wednesday Nov 27 2025

KubeVirt v1.7 is built for Kubernetes v1.34 and additionally supported for the previous two versions. See the [KubeVirt support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information.

To see the list of talented people who contirbuted to this release, see the [KubeVirt release tag for v1.7.0](https://github.com/kubevirt/kubevirt/releases/tag/v1.7.0).

### API change
- [[PR #16129]](https://github.com/kubevirt/kubevirt/pull/16129)[kubevirt-bot] Add RestartRequired when detaching CD-ROMs from a running VM
- [[PR #16097]](https://github.com/kubevirt/kubevirt/pull/16097)[kubevirt-bot] Introduce a new subresource `/evacuate/cancel` and `virtctl evacuate-cancel` command to allow users to cancel the evacuation process for a VirtualMachineInstance (VMI). This clears the `evacuationNodeName` field in the VMI's status, stopping the automatic creation of migration resources and fully aborting the eviction cycle.
- [[PR #16033]](https://github.com/kubevirt/kubevirt/pull/16033)[noamasu] VMSnapshot: add SourceIndications status field to list snapshot indications with descriptions for clearer meaning.
- [[PR #16051]](https://github.com/kubevirt/kubevirt/pull/16051)[kubevirt-bot] Introduce pool.kubevirt.io/v1beta1
- [[PR #16027]](https://github.com/kubevirt/kubevirt/pull/16027)[kubevirt-bot] VMPool: Add support for auto-healing startegy
- [[PR #15999]](https://github.com/kubevirt/kubevirt/pull/15999)[kubevirt-bot] VMpool: Add Scale-in strategy support with Proactive, opportunistic modes and statePreservation
- [[PR #15887]](https://github.com/kubevirt/kubevirt/pull/15887)[fossedihelm] Alpha: Generalized Migration Priority in KubeVirt
- [[PR #14575]](https://github.com/kubevirt/kubevirt/pull/14575)[zhencliu] Experimental support of Intel TDX
- [[PR #15123]](https://github.com/kubevirt/kubevirt/pull/15123)[Sreeja1725] VMpool: Add UpdateStrategy support with Proactive, Opportunistic modes and Selection policies
- [[PR #14845]](https://github.com/kubevirt/kubevirt/pull/14845)[alancaldelas] Experimental support for AMD SEV-SNP that is behind the `WorkloadEncruptionSEV` feature gate.
- [[PR #15783]](https://github.com/kubevirt/kubevirt/pull/15783)[orelmisan] Specify correct label selection when creating a service via virtctl expose. The expose command on virtctl v1.7 and above will not work with older KubeVirt versions.
- [[PR #15698]](https://github.com/kubevirt/kubevirt/pull/15698)[Acedus] It is now possible to configure discard_granularity for VM disks.
- [[PR #15552]](https://github.com/kubevirt/kubevirt/pull/15552)[nirdothan] NONR
- [[PR #15539]](https://github.com/kubevirt/kubevirt/pull/15539)[tiraboschi] Add VirtualMachineInstanceEvictionRequested condition for eviction tracking
- [[PR #15798]](https://github.com/kubevirt/kubevirt/pull/15798)[lyarwood] Support for the `ioThreads` VMI configurable is added to the `instancetype.kubevirt.io/v1beta1` API allowing `supplementalPoolThreadCount` to now be provided by an instance type.
- [[PR #15398]](https://github.com/kubevirt/kubevirt/pull/15398)[lyarwood] Preferences can now express preferred and required architecture values for use within VirtualMachines
- [[PR #15400]](https://github.com/kubevirt/kubevirt/pull/15400)[lyarwood] The deprecated `instancetype.kubevirt.io/v1alpha{1,2}` API and CRDs have been removed
- [[PR #15681]](https://github.com/kubevirt/kubevirt/pull/15681)[jean-edouard] Memory overcommit is now recalculated on migration.
- [[PR #15406]](https://github.com/kubevirt/kubevirt/pull/15406)[Sreeja1725] Add VMpool finalizer to ensure proper cleanup
- [[PR #14772]](https://github.com/kubevirt/kubevirt/pull/14772)[ShellyKa13] ChangedBlockTracking: enable add/remove of qcow2 overlay if vm matches label selector
- [[PR #15238]](https://github.com/kubevirt/kubevirt/pull/15238)[victortoso] Does Screenshot without the usage of VNC
- [[PR #15344]](https://github.com/kubevirt/kubevirt/pull/15344)[SkalaNetworks] Added VolumeOwnershipPolicy to decide how volumes are owned once they are restored.
- [[PR #14976]](https://github.com/kubevirt/kubevirt/pull/14976)[dasionov] remove ppc64le architecture configuration support
- [[PR #14983]](https://github.com/kubevirt/kubevirt/pull/14983)[sradco] This PR adds the following alerts: GuestPeakVCPUQueueHighWarning, GuestPeakVCPUQueueHighCritical
- [[PR #15096]](https://github.com/kubevirt/kubevirt/pull/15096)[lyarwood] The `foregroundDeleteVirtualMachine` has been deprecated and replaced with the domain-qualified `kubevirt.io/foregroundDeleteVirtualMachine`.
- [[PR #14879]](https://github.com/kubevirt/kubevirt/pull/14879)[machadovilaca] Add GuestAgentInfo info metrics
- [[PR #15017]](https://github.com/kubevirt/kubevirt/pull/15017)[nekkunti] Added support for architecture-specific configuration of `s390x` (IBM Z) in KubeVirt cluster config.
- [[PR #15022]](https://github.com/kubevirt/kubevirt/pull/15022)[awels] The synchronization controller migration network IP address is advertised by the KubeVirt CR
- [[PR #15021]](https://github.com/kubevirt/kubevirt/pull/15021)[awels] Decentralized migration resource now shows the synchronization address
- [[PR #14365]](https://github.com/kubevirt/kubevirt/pull/14365)[alaypatel07] Add support for DRA devices such as GPUs and HostDevices.
- [[PR #14882]](https://github.com/kubevirt/kubevirt/pull/14882)[awels] Decentralized live migration is available to allow migration across namespaces and clusters
- [[PR #14875]](https://github.com/kubevirt/kubevirt/pull/14875)[nirdothan] Support seamless TCP migration with passt (alpha)

### Bug fix
- [[PR #16198]](https://github.com/kubevirt/kubevirt/pull/16198)[kubevirt-bot] Bug fix: KubeVirt.spec.imagetag installation is working again
- [[PR #16011]](https://github.com/kubevirt/kubevirt/pull/16011)[kubevirt-bot] BugFix: The migration limit was not accurately being used with decentralized live migrations
- [[PR #15001]](https://github.com/kubevirt/kubevirt/pull/15001)[noamasu] bugfix: Enable vmsnapshot for paused VMs
- [[PR #15867]](https://github.com/kubevirt/kubevirt/pull/15867)[xpivarc] Bug fix: Thousands of migrations should not cause failures of active migrations
- [[PR #15788]](https://github.com/kubevirt/kubevirt/pull/15788)[mhenriks] Fix RestartRequired handling for hotplug volumes
- [[PR #15676]](https://github.com/kubevirt/kubevirt/pull/15676)[xpivarc] Bug fix, virt-launcher is properly reaped
- [[PR #15692]](https://github.com/kubevirt/kubevirt/pull/15692)[awels] BugFix: Restoring naked PVCs from a VMSnapshot are now properly owned by the VM if the restore policy is set to VM
- [[PR #15759]](https://github.com/kubevirt/kubevirt/pull/15759)[lyarwood] Only a single `Signaled Graceful Shutdown` event is now sent to avoid spamming the event recorder during long graceful shutdown attempts
- [[PR #13111]](https://github.com/kubevirt/kubevirt/pull/13111)[brianmcarey] build: update to bazel v6.5.0 and rules_oci
- [[PR #15605]](https://github.com/kubevirt/kubevirt/pull/15605)[awels] BugFix: Able to cancel in flight decentralized live migrations properly
- [[PR #15642]](https://github.com/kubevirt/kubevirt/pull/15642)[akalenyu] BugFix: Windows VM with vTPM that was previously Storage Migrated cannot live migrate
- [[PR #15603]](https://github.com/kubevirt/kubevirt/pull/15603)[akalenyu] BugFix: Fix volume migration for VMs with long name
- [[PR #15509]](https://github.com/kubevirt/kubevirt/pull/15509)[alromeros] Bugfix: Exclude lost+found from export server
- [[PR #15557]](https://github.com/kubevirt/kubevirt/pull/15557)[fossedihelm] Fix: grpc client in handler rest requests are properly closed
- [[PR #13500]](https://github.com/kubevirt/kubevirt/pull/13500)[brandboat] Fix incorrect metric name kubevirt_vmi_migration_disk_transfer_rate_bytes to kubevirt_vmi_migration_memory_transfer_rate_bytes
- [[PR #15470]](https://github.com/kubevirt/kubevirt/pull/15470)[awels] BugFix: Unable to delete source VM on failed decentralized live migration
- [[PR #15423]](https://github.com/kubevirt/kubevirt/pull/15423)[tiraboschi] Derive eviction-in-progress annotation from VMI eviction status
- [[PR #15170]](https://github.com/kubevirt/kubevirt/pull/15170)[dasionov] bugfix: ensure grace period metadata cache is synced in virt-launcher
- [[PR #15397]](https://github.com/kubevirt/kubevirt/pull/15397)[ShellyKa13] bugfix: prevent VMSnapshotContent repeated update with the same error message
- [[PR #15167]](https://github.com/kubevirt/kubevirt/pull/15167)[Sreeja1725] Add Command line flag to disable Node Labeller service
- [[PR #15365]](https://github.com/kubevirt/kubevirt/pull/15365)[tiraboschi] Aligning descheduler opt-out annotation name
- [[PR #15093]](https://github.com/kubevirt/kubevirt/pull/15093)[Acedus] bugfix: volume hotplug pod is no longer evicted when associated VM can live migrate.
- [[PR #15305]](https://github.com/kubevirt/kubevirt/pull/15305)[Acedus] bugfix: snapshot and restore now works correctly for VMs after a storage volume migration
- [[PR #15314]](https://github.com/kubevirt/kubevirt/pull/15314)[xpivarc] Common Names are now enforce for aggregated API
- [[PR #15182]](https://github.com/kubevirt/kubevirt/pull/15182)[akalenyu] BugFix: export fails when VMExport has dots in secret
- [[PR #15099]](https://github.com/kubevirt/kubevirt/pull/15099)[akalenyu] BugFix: export fails when VMExport has dots in name
- [[PR #15067]](https://github.com/kubevirt/kubevirt/pull/15067)[alromeros] Bugfix: Label upload PVCs to support CDI WebhookPvcRendering
- [[PR #15706]](https://github.com/kubevirt/kubevirt/pull/15706)[ksimon1] fix: prioritize expired cert removal over 50-cert limit in MergeCABundle

### SIG-compute
- [[PR #16168]](https://github.com/kubevirt/kubevirt/pull/16168)[kubevirt-bot] Migration is using dedicated certificate for mTLS.
- [[PR #16150]](https://github.com/kubevirt/kubevirt/pull/16150)[kubevirt-bot] fix: KSM is enabled in case of node pressure within 3 minutes
- [[PR #16108]](https://github.com/kubevirt/kubevirt/pull/16108)[kubevirt-bot] Allow migration when host model changes after libvirt upgrade.
- [[PR #16089]](https://github.com/kubevirt/kubevirt/pull/16089)[kubevirt-bot] A decentralized live migration failure is properly propagates between source and target
- [[PR #15936]](https://github.com/kubevirt/kubevirt/pull/15936)[kubevirt-bot] Updated common-instancetypes bundles to v1.5.1
- [[PR #15008]](https://github.com/kubevirt/kubevirt/pull/15008)[fossedihelm] Fix possible nil pointer caused by migration during kv upgrade
- [[PR #15712]](https://github.com/kubevirt/kubevirt/pull/15712)[lyarwood] The `DefaultVirtHandler{QPS,Burst}` values are increased to ensure no bottleneck forms within `virt-handler`
- [[PR #14902]](https://github.com/kubevirt/kubevirt/pull/14902)[tiraboschi] The list of annotations and labels synced from VM.spec.template.metadata to VMI and then to virt-launcher pods can be extended
- [[PR #15503]](https://github.com/kubevirt/kubevirt/pull/15503)[Sreeja1725] Enhance VMPool unit tests to make use of fake client
- [[PR #15422]](https://github.com/kubevirt/kubevirt/pull/15422)[lyarwood] The `DefaultVirtWebhookClient{QPS,Burst}` values are aligned with `DefaultVirtWebhookClient{QPS,Burst}` to help avoid saturating the webhook client with requests it is unable to serve during mass eviction events
- [[PR #15513]](https://github.com/kubevirt/kubevirt/pull/15513)[jean-edouard] Fixed priority escalation bug in migration controller
- [[PR #15478]](https://github.com/kubevirt/kubevirt/pull/15478)[0xFelix] virtctl: The --local-ssh flag and native ssh and scp clients are removed from virtctl. From now on the local ssh and scp clients on a host are always wrapped by virtctl ssh and scp.
- [[PR #15267]](https://github.com/kubevirt/kubevirt/pull/15267)[victortoso] Add `preserve session` option to VNC endpoint
- [[PR #15475]](https://github.com/kubevirt/kubevirt/pull/15475)[0xFelix] virtctl (portfoward|ssh|scp): Drop support for legacy dot syntax. In case the old dot syntax was used virtctl could ask for verification of the host key again. In some cases the known_hosts file might need to be updated manually.
- [[PR #15253]](https://github.com/kubevirt/kubevirt/pull/15253)[0xFelix] Bumped the bundled common-instancetypes to v1.4.0 which add new preferences.
- [[PR #15016]](https://github.com/kubevirt/kubevirt/pull/15016)[fossedihelm] Fix postcopy multifd compatibility during upgrade
- [[PR #14685]](https://github.com/kubevirt/kubevirt/pull/14685)[seanbanko] allows virtual machine instances with an instance type to specify memory fields that do not conflict with the instance type
- [[PR #14888]](https://github.com/kubevirt/kubevirt/pull/14888)[akalenyu] Cleanup: libvmi: add consistently named cpu/mem setters
- [[PR #15037]](https://github.com/kubevirt/kubevirt/pull/15037)[jean-edouard] HostDisk: KubeVirt no longer performs chown/chmod to compensate for storage that doesn't support fsGroup

### SIG-storage
- [[PR #14973]](https://github.com/kubevirt/kubevirt/pull/14973)[Barakmor1] support live migration for ImageVolume with modified container disk images
- [[PR #15651]](https://github.com/kubevirt/kubevirt/pull/15651)[dcarrier] Add WithUploadSource builder to libdv

### SIG-network
- [[PR #15669]](https://github.com/kubevirt/kubevirt/pull/15669)[HarshithaMS005] Normalise iface status to ensure test stability of hotplug and hotunplug tests
- [[PR #15661]](https://github.com/kubevirt/kubevirt/pull/15661)[nirdothan] Support Istio versions 1.25 and above.

### SIG-scale
- [[PR #15061]](https://github.com/kubevirt/kubevirt/pull/15061)[lyarwood] Support for all `*_SHASUM` environment variables has been removed from the `virt-operator` component. Users should instead use the remaining `*_IMAGE` environment variables to request a specific image version using a tag, digest or both.

### SIG-observability
- [[PR #15504]](https://github.com/kubevirt/kubevirt/pull/15504)[sradco] Update metric kubevirt_vm_container_free_memory_bytes_based_on_rss and kubevirt_vm_container_free_memory_bytes_based_on_working_set_bytes names to kubevirt_vm_container_memory_request_margin_based_on_rss_bytes and kubevirt_vm_container_memory_request_margin_based_on_working_set_bytes so they will be clearer
- [[PR #15181]](https://github.com/kubevirt/kubevirt/pull/15181)[avlitman] Add kubevirt_vm_labels metric which shows vm labels converted to Prometheus labels, and can be configured using config map with ignore and allow lists.
- [[PR #15227]](https://github.com/kubevirt/kubevirt/pull/15227)[sradco] New VM alerts - VirtualMachineStuckInUnhealthyState, VirtualMachineStuckOnNode
- [[PR #15464]](https://github.com/kubevirt/kubevirt/pull/15464)[avlitman] Added virt-launcher to kubevirt_memory_delta_from_requested_bytes metric and cnv_abnormal metrics.

### Other
- [[PR #16076]](https://github.com/kubevirt/kubevirt/pull/16076)[kubevirt-bot] NodeRestriction: Source of node update is now verified
- [[PR #16041]](https://github.com/kubevirt/kubevirt/pull/16041)[kubevirt-bot] The KubevirtSeccompProfile feature is now in Beta
- [[PR #16039]](https://github.com/kubevirt/kubevirt/pull/16039)[kubevirt-bot] Promote IBM Secure Execution Feature to Beta stage.
- [[PR #16005]](https://github.com/kubevirt/kubevirt/pull/16005)[kubevirt-bot] promote ImageVolume FG to Beta
- [[PR #15939]](https://github.com/kubevirt/kubevirt/pull/15939)[dasionov] Beta: VideoConfig
- [[PR #15878]](https://github.com/kubevirt/kubevirt/pull/15878)[Sreeja1725] Add v1.6.0 perf and scale benchmarks data
- [[PR #15830]](https://github.com/kubevirt/kubevirt/pull/15830)[varunrsekar] Beta: PanicDevices
- [[PR #15615]](https://github.com/kubevirt/kubevirt/pull/15615)[alromeros] Object Graph: Include NADs and ServiceAccounts
- [[PR #15690]](https://github.com/kubevirt/kubevirt/pull/15690)[lyarwood] Replicas of `virt-api` are now scaled depending on the number of nodes within the environment with the `kubevirt.io/schedulable=true` label.
- [[PR #15630]](https://github.com/kubevirt/kubevirt/pull/15630)[awels] Allow decentralized live migration on L3 networks
- [[PR #15357]](https://github.com/kubevirt/kubevirt/pull/15357)[dasionov] ensure default Firmware.Serial value on newly created vms
- [[PR #15157]](https://github.com/kubevirt/kubevirt/pull/15157)[jean-edouard] virt-operator won't schedule on worker nodes
- [[PR #15118]](https://github.com/kubevirt/kubevirt/pull/15118)[dankenigsberg] Drop an arbitrary limitation on VM's domain.firmaware.serial. Any string is passed verbatim to smbios. Illegal may be tweaked or ignored based on qemu/smbios version.
- [[PR #14964]](https://github.com/kubevirt/kubevirt/pull/14964)[xpivarc] Beta: NodeRestriction
- [[PR #14986]](https://github.com/kubevirt/kubevirt/pull/14986)[awels] Possible to trust additional CAs for verifying kubevirt infra structure components
- [[PR #15531]](https://github.com/kubevirt/kubevirt/pull/15531)[Yu-Jack] bump prometheus operator to 0.80.1
- [[PR #16026]](https://github.com/kubevirt/kubevirt/pull/16026)[fossedihelm] support v0.32.5 code generator
- [[PR #15098]](https://github.com/kubevirt/kubevirt/pull/15098)[dominikholler] Update dependecy golang.org/x/oauth2 to v0.27.0
- [[PR #15100]](https://github.com/kubevirt/kubevirt/pull/15100)[dominikholler] Update dependecy golang.org/x/net to v0.38.0
- [[PR #15784]](https://github.com/kubevirt/kubevirt/pull/15784)[brianmcarey] Build KubeVirt with go v1.24.7
- [[PR #15718]](https://github.com/kubevirt/kubevirt/pull/15718)[Vicente-Cheng] Bump k8s v1.33

## v1.6.0

Released on: Thursday Jul 31 2025

KubeVirt v1.6 is built for Kubernetes v1.33 and additionally supported for the previous two versions. See the [KubeVirt support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information.

To see the list of bodacious contributors for this release, see the [KubeVirt release tag for v1.6.0](https://github.com/kubevirt/kubevirt/releases/tag/v1.6.0).

### API change
- [[PR #15080]](https://github.com/kubevirt/kubevirt/pull/15080)[kubevirt-bot] The synchronization controller migration network IP address is advertised by the KubeVirt CR
- [[PR #15039]](https://github.com/kubevirt/kubevirt/pull/15039)[alaypatel07] Add support for DRA devices such as GPUs and HostDevices.
- [[PR #15014]](https://github.com/kubevirt/kubevirt/pull/15014)[kubevirt-bot] Support seamless TCP migration with passt (alpha)
- [[PR #14935]](https://github.com/kubevirt/kubevirt/pull/14935)[alromeros] Add virtctl objectgraph command
- [[PR #13103]](https://github.com/kubevirt/kubevirt/pull/13103)[varunrsekar] Feature: Support for defining panic devices in VirtualMachineInstances to catch crash signals from the guest.
- [[PR #13764]](https://github.com/kubevirt/kubevirt/pull/13764)[xpivarc] KubeVirt doesn't use PDBs anymore
- [[PR #14801]](https://github.com/kubevirt/kubevirt/pull/14801)[arsiesys] VirtualMachinePool now supports a `.ScaleInStrategy.Proactive.SelectionPolicy.BasePolicy` field to control scale-down behavior. The new `"DescendingOrder"` strategy deletes VMs by descending ordinal index, offering predictable downscale behavior. Defaults to `"random"` if not specified.
- [[PR #14259]](https://github.com/kubevirt/kubevirt/pull/14259)[orelmisan] Integrate NIC hotplug with LiveUpdate rollout strategy
- [[PR #14673]](https://github.com/kubevirt/kubevirt/pull/14673)[dasionov] Add Video Configuration Field for VMs to Enable Explicit Video Device Selection
- [[PR #14681]](https://github.com/kubevirt/kubevirt/pull/14681)[victortoso] Windows offline activation with ACPI MSDM table
- [[PR #14723]](https://github.com/kubevirt/kubevirt/pull/14723)[SkalaNetworks] Add VolumeRestorePolicies and VolumeRestoreOverrides to VMRestores
- [[PR #14040]](https://github.com/kubevirt/kubevirt/pull/14040)[jschintag] Add support for Secure Execution VMs on IBM Z
- [[PR #13847]](https://github.com/kubevirt/kubevirt/pull/13847)[mhenriks] Declarative Volume Hotplug with CD-ROM Inject/Eject
- [[PR #14807]](https://github.com/kubevirt/kubevirt/pull/14807)[alromeros] Add Object Graph subresource
- [[PR #14183]](https://github.com/kubevirt/kubevirt/pull/14183)[aqilbeig] Add maxUnavailable support to VirtualMachinePool
- [[PR #14616]](https://github.com/kubevirt/kubevirt/pull/14616)[awels] VirtualMachineInstanceMigrations can now express that they are source or target migrations
- [[PR #14617]](https://github.com/kubevirt/kubevirt/pull/14617)[SkalaNetworks] Added support for custom JSON patches in VirtualMachineClones.
- [[PR #14602]](https://github.com/kubevirt/kubevirt/pull/14602)[orelmisan] The "RestartRequired" condition is not set on VM objects for live-updatable network fields
- [[PR #14267]](https://github.com/kubevirt/kubevirt/pull/14267)[Barakmor1] Implement container disk functionality using ImageVolume, protected by the ImageVolume feature gate.
- [[PR #14539]](https://github.com/kubevirt/kubevirt/pull/14539)[nirdothan] Enable vhost-user mode for passt network binding plugin
- [[PR #14449]](https://github.com/kubevirt/kubevirt/pull/14449)[0xFelix] The 64-Bit PCI hole can now be disabled by adding the kubevirt.io/disablePCIHole annotation to VirtualMachineInstances. This allows legacy OSes such as Windows XP or Server 2003 to boot on KubeVirt using the Q35 machine type.
- [[PR #14437]](https://github.com/kubevirt/kubevirt/pull/14437)[jschintag] Ensure stricter check for valid machine type when validating VMI
- [[PR #13911]](https://github.com/kubevirt/kubevirt/pull/13911)[avlitman] VirtHandlerRESTErrorsHigh, VirtOperatorRESTErrorsHigh, VirtAPIRESTErrorsHigh and VirtControllerRESTErrorsHigh alerts removed.
- [[PR #14277]](https://github.com/kubevirt/kubevirt/pull/14277)[HarshithaMS005] Enable Watchdog device support on s390x using the Diag288 device model.
- [[PR #14405]](https://github.com/kubevirt/kubevirt/pull/14405)[jpeimer] supplementalPool added to the description of the ioThreadsPolicy possible values
- [[PR #14219]](https://github.com/kubevirt/kubevirt/pull/14219)[lyarwood] A request to create a VirtualMachines that references a non-existent  instance type or preference are no longer rejected. The VirtualMachine will be created but will fail to start until the missing resources are created in the cluster.
- [[PR #14048]](https://github.com/kubevirt/kubevirt/pull/14048)[lyarwood] The `v1alpha{1,2}` versions of the `instancetype.kubevirt.io` API group are no longer served or supported.
- [[PR #14316]](https://github.com/kubevirt/kubevirt/pull/14316)[lyarwood] A new `Enabled` attribute has been added to the `TPM` device allowing users to explicitly disable the device regardless of any referenced preference.
- [[PR #14050]](https://github.com/kubevirt/kubevirt/pull/14050)[lyarwood] The `InstancetypeReferencePolicy` feature has graduated to GA and no longer requires the associated feature gate to be enabled.
- [[PR #14065]](https://github.com/kubevirt/kubevirt/pull/14065)[jean-edouard] VM Persistent State GA
- [[PR #14096]](https://github.com/kubevirt/kubevirt/pull/14096)[ShellyKa13] VMSnapshot: add QuiesceFailed indication to snapshot if freeze failed
- [[PR #14068]](https://github.com/kubevirt/kubevirt/pull/14068)[jean-edouard] Default VM Rollout Strategy is now LiveUpdate. Important: to preserve previous behavior, rolloutStrategy needs to be set to "Stage" in the KubeVirt CR.
- [[PR #12725]](https://github.com/kubevirt/kubevirt/pull/12725)[tiraboschi] Support live migration to a named node
- [[PR #13807]](https://github.com/kubevirt/kubevirt/pull/13807)[Barakmor1] virt-launcher now uses bash to retrieve disk info and verify container-disk files, requiring bash to be included in the launcher image
- [[PR #13744]](https://github.com/kubevirt/kubevirt/pull/13744)[nirdothan] Network interfaces state can be set to `down` or `up` in order to set the link state accordingly when VM is running. Hot plugging of interface in these states is also supported.
- [[PR #13536]](https://github.com/kubevirt/kubevirt/pull/13536)[jean-edouard] Interrupted migrations will now be reconciled on next VM start.
- [[PR #13916]](https://github.com/kubevirt/kubevirt/pull/13916)[lyarwood] Instance type and preference runtime data is now stored under `Status.{Instancetype,Preference}Ref` and is no longer mutated into the core VirtualMachine `Spec`.
- [[PR #13831]](https://github.com/kubevirt/kubevirt/pull/13831)[ShellyKa13] VMClone: Remove webhook that checks Snapshot Source
- [[PR #13815]](https://github.com/kubevirt/kubevirt/pull/13815)[acardace] GA ClusterProfiler FG and add a config to enable it

### Bug fix
- [[PR #14130]](https://github.com/kubevirt/kubevirt/pull/14130)[dasionov] bug-fix: persist VM's firmware UUID for existing VMs
- [[PR #14338]](https://github.com/kubevirt/kubevirt/pull/14338)[dasionov] Bug fix: MaxSockets is limited so maximum of vcpus doesn't go over 512.
- [[PR #13690]](https://github.com/kubevirt/kubevirt/pull/13690)[dasionov] bug-fix: add machine type to `NodeSelector` to prevent breaking changes on unsupported nodes
- [[PR #15114]](https://github.com/kubevirt/kubevirt/pull/15114)[kubevirt-bot] Bugfix: Label upload PVCs to support CDI WebhookPvcRendering
- [[PR #15202]](https://github.com/kubevirt/kubevirt/pull/15202)[kubevirt-bot] BugFix: export fails when VMExport has dots in secret
- [[PR #15171]](https://github.com/kubevirt/kubevirt/pull/15171)[kubevirt-bot] BugFix: export fails when VMExport has dots in name
- [[PR #13898]](https://github.com/kubevirt/kubevirt/pull/13898)[brandboat] Changed the time unit conversion in the kubevirt_vmi_vcpu_seconds_total metric from microseconds to nanoseconds.
- [[PR #14961]](https://github.com/kubevirt/kubevirt/pull/14961)[akalenyu] BugFix: Can't LiveMigrate Windows VM after Storage Migration from HPP to OCS
- [[PR #14632]](https://github.com/kubevirt/kubevirt/pull/14632)[iholder101] virt-handler: Reduce Get() calls for KSM handling
- [[PR #14658]](https://github.com/kubevirt/kubevirt/pull/14658)[alromeros] Bugfix: Update backend-storage logic so it works with PVCs with non-standard naming convention
- [[PR #14695]](https://github.com/kubevirt/kubevirt/pull/14695)[alromeros] Bugfix: Fix online expansion by requeuing VMIs on PVC size change
- [[PR #14640]](https://github.com/kubevirt/kubevirt/pull/14640)[xpivarc] ARM: CPU pinning doesn't panic now
- [[PR #13951]](https://github.com/kubevirt/kubevirt/pull/13951)[alromeros] Bugfix: Truncate volume names in export pod
- [[PR #14145]](https://github.com/kubevirt/kubevirt/pull/14145)[ayushpatil2122] handle nil pointer dereference in cellToCell
- [[PR #14281]](https://github.com/kubevirt/kubevirt/pull/14281)[ShellyKa13] VMRestore: Keep VM RunStrategy as before the restore
- [[PR #14309]](https://github.com/kubevirt/kubevirt/pull/14309)[alicefr] Fixed persistent reservation support for multipathd by improving socket access and multipath files in pr-helper
- [[PR #14325]](https://github.com/kubevirt/kubevirt/pull/14325)[vamsikrishna-siddu] fix: disks-images-provider is pointing to wrong alpine image for s390x.
- [[PR #14286]](https://github.com/kubevirt/kubevirt/pull/14286)[machadovilaca] Register k8s client-go latency metrics on init
- [[PR #13870]](https://github.com/kubevirt/kubevirt/pull/13870)[dasionov] Ensure launcher pods are finalized and deleted before removing the VMI finalizer when the VMI is marked for deletion.
- [[PR #14071]](https://github.com/kubevirt/kubevirt/pull/14071)[alicefr] Add entrypoint to the pr-helper for creating the symlink to the multipath socket

### SIG-compute
- [[PR #15256]](https://github.com/kubevirt/kubevirt/pull/15256)[kubevirt-bot] Bumped the bundled common-instancetypes to v1.4.0 which add new preferences.
- [[PR #15214]](https://github.com/kubevirt/kubevirt/pull/15214)[dhiller] Quarantine flaky test `[sig-compute]VM state with persistent TPM VM option enabled should persist VM state of EFI across migration and restart`
- [[PR #15178]](https://github.com/kubevirt/kubevirt/pull/15178)[kubevirt-bot] Fix postcopy multifd compatibility during upgrade
- [[PR #14744]](https://github.com/kubevirt/kubevirt/pull/14744)[tiraboschi] A few dynamic annotations are synced from VMs template to VMIs and to virt-launcher pods
- [[PR #14907]](https://github.com/kubevirt/kubevirt/pull/14907)[mhenriks] Allow virtio bus for hotplugged disks
- [[PR #14754]](https://github.com/kubevirt/kubevirt/pull/14754)[mhenriks] Allocate more PCI ports for hotplug
- [[PR #14705]](https://github.com/kubevirt/kubevirt/pull/14705)[jean-edouard] The migration controller in virt-handler has been re-architected, migrations should be more stable
- [[PR #14793]](https://github.com/kubevirt/kubevirt/pull/14793)[jean-edouard] Failed post-copy migrations now always end in VMI failure
- [[PR #14827]](https://github.com/kubevirt/kubevirt/pull/14827)[orelmisan] Fix network setup when emulation is enabled
- [[PR #14768]](https://github.com/kubevirt/kubevirt/pull/14768)[oshoval] Expose CONTAINER_NAME on hook sidecars.
- [[PR #14728]](https://github.com/kubevirt/kubevirt/pull/14728)[orelmisan] CPU hotplug with net multi-queue is now allowed
- [[PR #14619]](https://github.com/kubevirt/kubevirt/pull/14619)[cloud-j-luna] virtctl vnc command now supports user provided VNC clients.
- [[PR #14599]](https://github.com/kubevirt/kubevirt/pull/14599)[HarshithaMS005] Enabled watchdog validation on watchdog device models
- [[PR #13806]](https://github.com/kubevirt/kubevirt/pull/13806)[iholder101] Dirty rate is reported as part of a new `GetDomainDirtyRateStats()` gRPC method and by a Prometheus metric: `kubevirt_vmi_dirty_rate_bytes_per_second`.
- [[PR #14520]](https://github.com/kubevirt/kubevirt/pull/14520)[dasionov] Enable node-labeller for ARM64 clusters, supporting machine-type labels.
- [[PR #13297]](https://github.com/kubevirt/kubevirt/pull/13297)[mhenriks] hotplug volume: Boot from hotpluggable disk
- [[PR #13422]](https://github.com/kubevirt/kubevirt/pull/13422)[mhenriks] guest console log: make virt-tail a proper sidecar
- [[PR #14374]](https://github.com/kubevirt/kubevirt/pull/14374)[kubevirt-bot] Updated common-instancetypes bundles to v1.3.1
- [[PR #14288]](https://github.com/kubevirt/kubevirt/pull/14288)[qinqon] Don't expose as VMI status the implicit qemu domain pause at the end of live migration
- [[PR #14328]](https://github.com/kubevirt/kubevirt/pull/14328)[akalenyu] Cleanup: Fix unit tests on a sane, non-host-cgroup-sharing development setup
- [[PR #14141]](https://github.com/kubevirt/kubevirt/pull/14141)[jean-edouard] Large number of migrations should no longer lead to active migrations timing out
- [[PR #13939]](https://github.com/kubevirt/kubevirt/pull/13939)[0xFelix] The virtctl port-forward/ssh/scp syntax was changed to type/name[/namespace]. It now supports resources with dots in their name properly.
- [[PR #13928]](https://github.com/kubevirt/kubevirt/pull/13928)[kubevirt-bot] Updated common-instancetypes bundles to v1.3.0

### SIG-storage
- [[PR #14737]](https://github.com/kubevirt/kubevirt/pull/14737)[ShellyKa13] virt-Freeze: skip freeze if domain is not in running state
- [[PR #14637]](https://github.com/kubevirt/kubevirt/pull/14637)[alromeros] Label backend PVC to support CDI WebhookPvcRendering

### SIG-network
- [[PR #14887]](https://github.com/kubevirt/kubevirt/pull/14887)[oshoval] Release passt CNI image, instead the CNI binary itself.
- [[PR #14738]](https://github.com/kubevirt/kubevirt/pull/14738)[oshoval] Clean absent interfaces and their relative networks from stopped VMs.
- [[PR #14509]](https://github.com/kubevirt/kubevirt/pull/14509)[phoracek] Network conformance tests are now marked using the `Conformance` decorator. Use `--ginkgo.label-filter '(sig-network && conformance)` to select them.

### SIG-scale
- [[PR #13888]](https://github.com/kubevirt/kubevirt/pull/13888)[Sreeja1725] Add v1.5.0 perf and scale benchmarks data

### SIG-observability
- [[PR #14805]](https://github.com/kubevirt/kubevirt/pull/14805)[machadovilaca] Replace metric labels' none values with empty values
- [[PR #14203]](https://github.com/kubevirt/kubevirt/pull/14203)[machadovilaca] Trigger VMCannotBeEvicted only for running VMIs
- [[PR #14327]](https://github.com/kubevirt/kubevirt/pull/14327)[machadovilaca] Handle lowercase instancetypes/preference keys in VM monitoring
- [[PR #14426]](https://github.com/kubevirt/kubevirt/pull/14426)[avlitman] Added kubevirt_vmi_migrations_in_unset_phase, instead of including it in kubevirt_vmi_migration_failed.
- [[PR #14108]](https://github.com/kubevirt/kubevirt/pull/14108)[machadovilaca] Add interface name label to kubevirt_vmi_status_addresses
- [[PR #13805]](https://github.com/kubevirt/kubevirt/pull/13805)[machadovilaca] Fetch non-cluster instance type and preferences with namespace key

### Other
- [[PR #15264]](https://github.com/kubevirt/kubevirt/pull/15264)[fossedihelm] Quarantined `should live migrate a container disk vm, with an additional PVC mounted, should stay mounted after migration` test
- [[PR #15191]](https://github.com/kubevirt/kubevirt/pull/15191)[kubevirt-bot] Drop an arbitrary limitation on VM's domain.firmaware.serial. Any string is passed verbatim to smbios. Illegal may be tweaked or ignored based on qemu/smbios version.
- [[PR #15201]](https://github.com/kubevirt/kubevirt/pull/15201)[xpivarc] Known issue: ParallelOutboundMigrationsPerNode might be ignored because of race condition
- [[PR #15047]](https://github.com/kubevirt/kubevirt/pull/15047)[kubevirt-bot] Beta: NodeRestriction
- [[PR #15020]](https://github.com/kubevirt/kubevirt/pull/15020)[kubevirt-bot] Possible to trust additional CAs for verifying kubevirt infra structure components
- [[PR #14956]](https://github.com/kubevirt/kubevirt/pull/14956)[RobertoMachorro] Added CRC to ADOPTERS document.
- [[PR #14538]](https://github.com/kubevirt/kubevirt/pull/14538)[iholder101] Move cgroup v1 to maintenance mode
- [[PR #14823]](https://github.com/kubevirt/kubevirt/pull/14823)[xmulligan] Adding Isovalent to Adopters

- [[PR #14440]](https://github.com/kubevirt/kubevirt/pull/14440)[pstaniec-catalogicsoftware] add CloudCasa by Catalogic to integrations in the adopters.md
- [[PR #14428]](https://github.com/kubevirt/kubevirt/pull/14428)[jean-edouard] To use nfs-csi, the env variable KUBEVIRT_NFS_DIR has to be set to a location on the host for NFS data
- [[PR #13940]](https://github.com/kubevirt/kubevirt/pull/13940)[tiraboschi] The node-restriction Validating Admission Policy will return consistent reasons on failures
- [[PR #14215]](https://github.com/kubevirt/kubevirt/pull/14215)[dominikholler] Update module golang.org/x/oauth2 to v0.27.0
- [[PR #14222]](https://github.com/kubevirt/kubevirt/pull/14222)[dominikholler] Update module golang.org/x/net to v0.36.0
- [[PR #14218]](https://github.com/kubevirt/kubevirt/pull/14218)[dominikholler] Update golang.org/x/crypto to v0.35.0
- [[PR #14217]](https://github.com/kubevirt/kubevirt/pull/14217)[dominikholler] Update module github.com/opencontainers/runc to v1.1.14
- [[PR #14101]](https://github.com/kubevirt/kubevirt/pull/14101)[qinqon] libvirt: 10.10.0-7, qemu: 9.1.0-15
- [[PR #15101]](https://github.com/kubevirt/kubevirt/pull/15101)[dominikholler] Update dependecy golang.org/x/oauth2 to v0.27.0
- [[PR #14304]](https://github.com/kubevirt/kubevirt/pull/14304)[jean-edouard] Update module github.com/containers/common to v0.60.4
- [[PR #14664]](https://github.com/kubevirt/kubevirt/pull/14664)[brianmcarey] Build KubeVirt with go v1.23.9
- [[PR #15102]](https://github.com/kubevirt/kubevirt/pull/15102)[dominikholler] Update dependecy golang.org/x/net to v0.38.0

## v1.5.0

Released on: Wed Mar 05 2025

KubeVirt v1.5 is built for Kubernetes v1.32 and additionally supported for the previous two versions. See the [KubeVirt support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information.

To see the list of wonderful individuals who contributed to this release, see the [KubeVirt release tag for v1.5.0](https://github.com/kubevirt/kubevirt/releases/tag/v1.5.0).

### API change
- [[PR #13850]](https://github.com/kubevirt/kubevirt/pull/13850)[nirdothan] Network interfaces state can be set to `down` or `up` in order to set the link state accordingly.
- [[PR #13708]](https://github.com/kubevirt/kubevirt/pull/13708)[orelmisan] Network interfaces' link state will be reported for interfaces present in VMI spec
- [[PR #13208]](https://github.com/kubevirt/kubevirt/pull/13208)[davidvossel] Add VM reset functionality to virtctl and api
- [[PR #13711]](https://github.com/kubevirt/kubevirt/pull/13711)[ShellyKa13] VMSnapshot: honor StorageProfile snapshotClass when choosing volumesnapshotclass
- [[PR #13667]](https://github.com/kubevirt/kubevirt/pull/13667)[arnongilboa] Set VM status indication if storage exceeds quota
- [[PR #13288]](https://github.com/kubevirt/kubevirt/pull/13288)[alicefr] Graduation of VolumeUpdateStrategy and VolumeMigration feature gates
- [[PR #13520]](https://github.com/kubevirt/kubevirt/pull/13520)[iholder101] Graduate the clone API to v1beta1 and deprecate v1alpha1
- [[PR #13110]](https://github.com/kubevirt/kubevirt/pull/13110)[alicefr] Add the iothreads option to specify number of iothreads to be used
- [[PR #13152]](https://github.com/kubevirt/kubevirt/pull/13152)[akalenyu] VMExport: exported DV uses the storage API
- [[PR #13305]](https://github.com/kubevirt/kubevirt/pull/13305)[ShellyKa13] VMRestore: remove VMSnapshot logic from vmrestore webhook
- [[PR #13243]](https://github.com/kubevirt/kubevirt/pull/13243)[orelmisan] Dynamic pod interface naming is declared GA
- [[PR #13314]](https://github.com/kubevirt/kubevirt/pull/13314)[EdDev] Network Binding Plugin feature is declared GA
- [[PR #13195]](https://github.com/kubevirt/kubevirt/pull/13195)[ShellyKa13] Vmrestore - add options to handle cases when target is not ready
- [[PR #12750]](https://github.com/kubevirt/kubevirt/pull/12750)[lyarwood] The inflexible `PreferredUseEFi` and `PreferredUseSecureBoot` preference fields have been deprecated ahead of removal in a future version of the `instancetype.kubevirt.io` API. Users should instead use `PreferredEfi` to provide a preferred `EFI` configuration for their `VirtualMachine`.

### Breaking change
- [[PR #13497]](https://github.com/kubevirt/kubevirt/pull/13497)[tiraboschi] As an hardening measure (principle of least privilege), the right of creating, editing and deleting `VirtualMachineInstanceMigrations` are not anymore assigned by default to namespace admins.

### Bug fix
- [[PR #13803]](https://github.com/kubevirt/kubevirt/pull/13803)[ShellyKa13] BugFix: VMSnapshot: wait for volumes to be bound instead of skip
- [[PR #13713]](https://github.com/kubevirt/kubevirt/pull/13713)[akalenyu] Enhancement: Declare to libvirt upfront which filesystems are shared to allow migration on some NFS backed provisioners
- [[PR #13682]](https://github.com/kubevirt/kubevirt/pull/13682)[alromeros] Bugfix: Support online snapshot of VMs with backend storage
- [[PR #13606]](https://github.com/kubevirt/kubevirt/pull/13606)[dasionov] add support for virtio video device for amd64
- [[PR #13207]](https://github.com/kubevirt/kubevirt/pull/13207)[alromeros] Bugfix: Support offline snapshot of VMs with backend storage
- [[PR #13546]](https://github.com/kubevirt/kubevirt/pull/13546)[akalenyu] BugFix: Volume hotplug broken with crun >= 1.18
- [[PR #13496]](https://github.com/kubevirt/kubevirt/pull/13496)[0xFelix] virtctl expose now uses the unique `vm.kubevirt.io/name` label found on every virt-launcher Pod as a service selector.
- [[PR #13547]](https://github.com/kubevirt/kubevirt/pull/13547)[0xFelix] virtctl create vm validates disk names and prevents disk names that will lead to rejection of a VM upon creation.
- [[PR #13544]](https://github.com/kubevirt/kubevirt/pull/13544)[jean-edouard] Fixed bug where VMs may not get the persistent EFI they requested
- [[PR #13460]](https://github.com/kubevirt/kubevirt/pull/13460)[alromeros] Bugfix: Support exporting backend PVC
- [[PR #13424]](https://github.com/kubevirt/kubevirt/pull/13424)[fossedihelm] Bugfix: fix possible virt-handler race condition and stuck situation during shutdown
- [[PR #13426]](https://github.com/kubevirt/kubevirt/pull/13426)[dasionov] bug-fix: prevent status update for old migrations
- [[PR #13367]](https://github.com/kubevirt/kubevirt/pull/13367)[xpivarc] Bug-fix: Reduced probability of false "failed to detect socket for containerDisk disk0: ... connection refused" warnings
- [[PR #13138]](https://github.com/kubevirt/kubevirt/pull/13138)[mhenriks] Avoid NPE when getting filesystem overhead
- [[PR #13270]](https://github.com/kubevirt/kubevirt/pull/13270)[ShellyKa13] VMSnapshot: propagate freeze error failure
- [[PR #13260]](https://github.com/kubevirt/kubevirt/pull/13260)[akalenyu] BugFix: VMSnapshot 'InProgress' and Failing for a VM with InstanceType and Preference
- [[PR #13240]](https://github.com/kubevirt/kubevirt/pull/13240)[awels] Fix issue starting Virtual Machine Export when succeed/failed VMI exists for that VM
- [[PR #13219]](https://github.com/kubevirt/kubevirt/pull/13219)[jean-edouard] backend-storage will now correctly use the default virtualization storage class
- [[PR #13197]](https://github.com/kubevirt/kubevirt/pull/13197)[akalenyu] BugFix: VMSnapshots broken on OpenShift

### Deprecation
- [[PR #13871]](https://github.com/kubevirt/kubevirt/pull/13871)[0xFelix] By default the local SSH client on the machine running `virtctl ssh` is now used. The `--local-ssh` flag is now deprecated.
- [[PR #13918]](https://github.com/kubevirt/kubevirt/pull/13918)[0xFelix] `type` being optional in the syntax of virtctl port-forward/ssh/scp is now deprecated.
- [[PR #13817]](https://github.com/kubevirt/kubevirt/pull/13817)[Barakmor1] The `AutoResourceLimits` feature gate is now deprecated with the feature state graduated to `GA` and thus enabled by default
- [[PR #13437]](https://github.com/kubevirt/kubevirt/pull/13437)[arnongilboa] Remove deprecated DataVolume garbage collection tests

### SIG-compute
- [[PR #13936]](https://github.com/kubevirt/kubevirt/pull/13936)[kubevirt-bot] Updated common-instancetypes bundles to v1.3.0
- [[PR #13838]](https://github.com/kubevirt/kubevirt/pull/13838)[iholder101] Add the KeepValueUpdated() method to time-defined cache
- [[PR #13642]](https://github.com/kubevirt/kubevirt/pull/13642)[0xFelix] VMs in a VMPool are able to receive individual configuration through individually indexed ConfigMaps and Secrets.
- [[PR #12624]](https://github.com/kubevirt/kubevirt/pull/12624)[victortoso] Better handle unsupported volume type with Slic table
- [[PR #13756]](https://github.com/kubevirt/kubevirt/pull/13756)[germag] Live migration support for VMIs with (virtiofs) filesystem devices
- [[PR #13777]](https://github.com/kubevirt/kubevirt/pull/13777)[0xFelix] virtctl: VMs/VMIs with dots in their name are now supported in virtctl portforward, ssh and scp.
- [[PR #11266]](https://github.com/kubevirt/kubevirt/pull/11266)[jean-edouard] KubeVirt will no longer deploy a custom SELinux policy on worker nodes
- [[PR #13562]](https://github.com/kubevirt/kubevirt/pull/13562)[kubevirt-bot] Updated common-instancetypes bundles to v1.2.1
- [[PR #13263]](https://github.com/kubevirt/kubevirt/pull/13263)[jean-edouard] /var/lib/kubelet on the nodes can now be a symlink
- [[PR #13252]](https://github.com/kubevirt/kubevirt/pull/13252)[iholder101] Unconditionally disable libvirt's VMPort feature which is relevant for VMWare only
- [[PR #12705]](https://github.com/kubevirt/kubevirt/pull/12705)[iholder101] Auto-configured parallel QEMU-level migration threads (a.k.a. multifd)
- [[PR #12925]](https://github.com/kubevirt/kubevirt/pull/12925)[0xFelix] virtctl: Image uploads are retried up to 15 times

### SIG-storage
- [[PR #13857]](https://github.com/kubevirt/kubevirt/pull/13857)[ShellyKa13] VMSnapshot: allow creating snapshot when source doesnt exist yet
- [[PR #13864]](https://github.com/kubevirt/kubevirt/pull/13864)[alromeros] Reject VM clone when source uses backend storage PVC
- [[PR #13717]](https://github.com/kubevirt/kubevirt/pull/13717)[alicefr] Refuse to volume migrate to legacy datavolumes using no-CSI storageclasses
- [[PR #13586]](https://github.com/kubevirt/kubevirt/pull/13586)[akalenyu] storage tests: assemble storage-oriented conformance test suite
- [[PR #13603]](https://github.com/kubevirt/kubevirt/pull/13603)[akalenyu] Storage tests: eliminate runtime skips
- [[PR #12800]](https://github.com/kubevirt/kubevirt/pull/12800)[alicefr] Enable volume migration for hotplugged volumes
- [[PR #12628]](https://github.com/kubevirt/kubevirt/pull/12628)[ShellyKa13] VMs admitter: remove validation of vm clone volume from the webhook
- [[PR #13091]](https://github.com/kubevirt/kubevirt/pull/13091)[acardace] GA the `VMLiveUpdateFeatures` feature-gate.

### SIG-network
- [[PR #13775]](https://github.com/kubevirt/kubevirt/pull/13775)[sbrivio-rh] This version of KubeVirt upgrades the passt package, providing user-mode networking, to match upstream version 2025_01_21.4f2c8e7.
- [[PR #13458]](https://github.com/kubevirt/kubevirt/pull/13458)[orelmisan] Adjust managedTap binding to work with VMs with Address Conflict Detection enabled

### SIG-scale
- [[PR #13204]](https://github.com/kubevirt/kubevirt/pull/13204)[Sreeja1725] Add release v1.4.0 perf and scale benchmarks data
- [[PR #12546]](https://github.com/kubevirt/kubevirt/pull/12546)[Sreeja1725] Update promql query of cpu and memory metrics for sig-performance tests

### SIG-observability
- [[PR #13610]](https://github.com/kubevirt/kubevirt/pull/13610)[avlitman] Added kubevirt_vm_vnic_info and kubevirt_vmi_vnic_info metrics
- [[PR #13535]](https://github.com/kubevirt/kubevirt/pull/13535)[machadovilaca] Collect resource requests and limits from VM instance type/preference
- [[PR #13428]](https://github.com/kubevirt/kubevirt/pull/13428)[machadovilaca] Add kubevirt_vmi_migration_(start|end)_time_seconds metrics
- [[PR #13423]](https://github.com/kubevirt/kubevirt/pull/13423)[machadovilaca] Add kubevirt_vmi_migration_data_total_bytes metric
- [[PR #13587]](https://github.com/kubevirt/kubevirt/pull/13587)[sradco] Alert KubevirtVmHighMemoryUsage has been deprecated.
- [[PR #13431]](https://github.com/kubevirt/kubevirt/pull/13431)[avlitman] Add kubevirt_vm_create_date_timestamp_seconds metric
- [[PR #13386]](https://github.com/kubevirt/kubevirt/pull/13386)[machadovilaca] Ensure IP not empty in kubevirt_vmi_status_addresses metric
- [[PR #13250]](https://github.com/kubevirt/kubevirt/pull/13250)[Sreeja1725] Add virt-handler cpu and memory usage metrics
- [[PR #13325]](https://github.com/kubevirt/kubevirt/pull/13325)[machadovilaca] Add node label to migration metrics
- [[PR #13148]](https://github.com/kubevirt/kubevirt/pull/13148)[avlitman] added a new label to kubevirt_vmi_info metric named vmi_pod and contain the current pod name that runs the VMI.
- [[PR #13294]](https://github.com/kubevirt/kubevirt/pull/13294)[machadovilaca] Add Guest and Hugepages memory to kubevirt_vm_resource_requests
- [[PR #12765]](https://github.com/kubevirt/kubevirt/pull/12765)[avlitman] kubevirt_vm_disk_allocated_size_bytes metric added in order to monitor vm sizes

### Uncategorized
- [[PR #11964]](https://github.com/kubevirt/kubevirt/pull/11964)[ShellyKa13] VMClone: Remove webhook that checks VM Source
- [[PR #11997]](https://github.com/kubevirt/kubevirt/pull/11997)[jcanocan] Drop `ExperimentalVirtiofsSupport` feature gate in favor of `EnableVirtioFsConfigVolumes` for sharing ConfigMaps, Secrets, DownwardAPI and ServiceAccounts and `EnableVirtioFsPVC` for sharing PVCs.
- [[PR #13109]](https://github.com/kubevirt/kubevirt/pull/13109)[xpivarc] Test suite: 3 new labels are available to filter tests: HostDiskGate, requireHugepages1Gi, blockrwo
- [[PR #13588]](https://github.com/kubevirt/kubevirt/pull/13588)[Yu-Jack] Ensure virt-tail and virt-monitor have the same timeout, preventing early termination of virt-tail while virt-monitor is still starting
- [[PR #13545]](https://github.com/kubevirt/kubevirt/pull/13545)[alicefr] Upgrade of virt stack
- [[PR #12844]](https://github.com/kubevirt/kubevirt/pull/12844)[jschintag] Enable virt-exportproxy and virt-exportserver image for s390x
- [[PR #13006]](https://github.com/kubevirt/kubevirt/pull/13006)[chomatdam] Added labels, annotations to VM Export resources and configurable pod readiness timeout
- [[PR #13699]](https://github.com/kubevirt/kubevirt/pull/13699)[brianmcarey] Build KubeVirt with go v1.23.4
- [[PR #13641]](https://github.com/kubevirt/kubevirt/pull/13641)[andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 10.10.0 and QEMU 9.1.0.
- [[PR #13495]](https://github.com/kubevirt/kubevirt/pull/13495)[brianmcarey] Build KubeVirt with go v1.22.10


## v1.4.0

Released on: Wed Nov 13 2024

KubeVirt v1.4 is built for Kubernetes v1.31 and additionally supported for the previous two versions. See the [KubeVirt support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information.

To see the list of very excellent people who contributed to this release, see the [KubeVirt release tag for v1.4.0](https://github.com/kubevirt/kubevirt/releases/tag/v1.4.0).

### API change
- [[PR #13030]](https://github.com/kubevirt/kubevirt/pull/13030) [alicefr] Removed the ManualRecoveryRequired field from the VolumeMigrationState and convert it to the VM condition ManualRecoveryRequired
- [[PR #12933]](https://github.com/kubevirt/kubevirt/pull/12933) [ShellyKa13] VM admitter: improve validation of vm spec datavolumetemplate
- [[PR #12986]](https://github.com/kubevirt/kubevirt/pull/12986) [lyarwood] The `PreferredEfi` preference is now only applied when a user has not already enabled either `EFI` or `BIOS` within the underlying `VirtualMachine`.
- [[PR #12169]](https://github.com/kubevirt/kubevirt/pull/12169) [lyarwood] `PreferredDiskDedicatedIoThread` is now only applied to `virtio` disk devices
- [[PR #13090]](https://github.com/kubevirt/kubevirt/pull/13090) [acardace] Allow live updating VMs' tolerations
- [[PR #12629]](https://github.com/kubevirt/kubevirt/pull/12629) [jean-edouard] backend-storage now supports RWO FS
- [[PR #13086]](https://github.com/kubevirt/kubevirt/pull/13086) [lyarwood] A new `spec.configuration.instancetype.referencePolicy` configurable has been added to the `KubeVirt` CR with support for `reference` (default), `expand` and `expandAll` policies provided.
- [[PR #12967]](https://github.com/kubevirt/kubevirt/pull/12967) [xpivarc] BochsDisplayForEFIGuests is GAed, use  "kubevirt.io/vga-display-efi-x86" annotation on Kubevirt CR before upgrading in case you need retain compatibility.
- [[PR #13001]](https://github.com/kubevirt/kubevirt/pull/13001) [awels] Relaxed check on modify VM spec during VM snapshot to only check disks/volumes
- [[PR #13018]](https://github.com/kubevirt/kubevirt/pull/13018) [orelmisan] Support Dynamic Primary Pod NIC Name
- [[PR #13078]](https://github.com/kubevirt/kubevirt/pull/13078) [qinqon] Add dynamic pod interface name feature gate
- [[PR #13059]](https://github.com/kubevirt/kubevirt/pull/13059) [EdDev] Network hotplug feature is declared as GA.
- [[PR #12753]](https://github.com/kubevirt/kubevirt/pull/12753) [lyarwood] The `CommonInstancetypesDeploymentGate` feature gate and underlying feature are graduated to GA and now always enabled by default. A single new `KubeVirt` configurable is also introduced to allow cluster admins a way of explicitly disabling deployment when required.
- [[PR #12232]](https://github.com/kubevirt/kubevirt/pull/12232) [lyarwood] The `NUMA` feature gate is now deprecated with the feature state graduated to `GA` and thus enabled by default
- [[PR #12943]](https://github.com/kubevirt/kubevirt/pull/12943) [Barakmor1] The `GPU` feature gate is now deprecated with the feature state graduated to `GA` and thus enabled by default

### Bug fix
- [[PR #12829]](https://github.com/kubevirt/kubevirt/pull/12829) [0xFelix] fix: Proxies configured in kubeconfig are used in client-go for asynchronous subresources like VNC or Console
- [[PR #12733]](https://github.com/kubevirt/kubevirt/pull/12733) [alromeros] Bugfix: Fix disk expansion logic by checking usable size instead of requested capacity
- [[PR #13040]](https://github.com/kubevirt/kubevirt/pull/13040) [awels] BugFix: Allow VMExport to work with VM columes that have dots in its name
- [[PR #12867]](https://github.com/kubevirt/kubevirt/pull/12867) [jschintag] Fixed additional broken amd64 image in some image manifests
- [[PR #12861]](https://github.com/kubevirt/kubevirt/pull/12861) [ShellyKa13] bugfix: fix possible miss update of datavolumename on vmrestore restores
- [[PR #12599]](https://github.com/kubevirt/kubevirt/pull/12599) [xpivarc] MaxCpuSockets won't block creation of VMs with more Sockets than MaxCpuSockets declare
- [[PR #12857]](https://github.com/kubevirt/kubevirt/pull/12857) [akalenyu] BugFix: Fail to create VMExport via virtctl vmexport create
- [[PR #12835]](https://github.com/kubevirt/kubevirt/pull/12835) [ShellyKa13] bugfix: In case of err in vmrestore, leave VM without RestoreInProgress annotation allowing it to be started
- [[PR #12809]](https://github.com/kubevirt/kubevirt/pull/12809) [dasionov] bug-fix: Ensure PDB associated with a VMI is deleted when it Reaches Succeeded or Failed phase
- [[PR #12813]](https://github.com/kubevirt/kubevirt/pull/12813) [akalenyu] BugFix: can't create export pod on OpenShift
- [[PR #12764]](https://github.com/kubevirt/kubevirt/pull/12764) [ShellyKa13] bugfix: vmrestore create DVs before creation/update of restored VM
- [[PR #12638]](https://github.com/kubevirt/kubevirt/pull/12638) [akalenyu] BugFix: "Cannot allocate memory" warnings for containerdisk VMs
- [[PR #12592]](https://github.com/kubevirt/kubevirt/pull/12592) [awels] Fixed issue emitting created secret events when not actually creating secrets during VMExport setup
- [[PR #12460]](https://github.com/kubevirt/kubevirt/pull/12460) [mhenriks] virt-api: unencode authorization extra headers
- [[PR #12451]](https://github.com/kubevirt/kubevirt/pull/12451) [fossedihelm] Fix: eviction requests to completed virt-launcher pods cannot trigger a live migration
- [[PR #12261]](https://github.com/kubevirt/kubevirt/pull/12261) [fossedihelm] Fix: persistent tpm can be used with vmis containing dots in their name
- [[PR #12181]](https://github.com/kubevirt/kubevirt/pull/12181) [akalenyu] BugFix: Grant namespace admin RBAC to passthrough a client USB to a VMI
- [[PR #12096]](https://github.com/kubevirt/kubevirt/pull/12096) [machadovilaca] Fix missing performance metrics for VMI resources
- [[PR #12212]](https://github.com/kubevirt/kubevirt/pull/12212) [acardace] enable only for VMs with memory >= 1Gi
- [[PR #12193]](https://github.com/kubevirt/kubevirt/pull/12193) [acardace] fix RerunOnFailure stuck in Provisioning
- [[PR #12180]](https://github.com/kubevirt/kubevirt/pull/12180) [0xFelix] VMs with a single socket and NetworkInterfaceMultiqueue enabled require a restart to hotplug additional CPU sockets.
- [[PR #12128]](https://github.com/kubevirt/kubevirt/pull/12128) [acardace] Memory Hotplug fixes and stabilization
- [[PR #11911]](https://github.com/kubevirt/kubevirt/pull/11911) [alromeros] Bugfix: Implement retry mechanism in export server and vmexport
- [[PR #12119]](https://github.com/kubevirt/kubevirt/pull/12119) [acardace] Fix VMPools when `LiveUpdate` as `vmRolloutStrategy` is used.
- [[PR #12209]](https://github.com/kubevirt/kubevirt/pull/12209) [orenc1] Fix wrong KubeVirtVMIExcessiveMigrations alert calculation in an upgrade scenario.
- [[PR #13050]](https://github.com/kubevirt/kubevirt/pull/13050) [vamsikrishna-siddu] fix the cpu model issue for s390x.
- [[PR #13027]](https://github.com/kubevirt/kubevirt/pull/13027) [awels] BugFix: Stop creating tokenSecretRef when no volumes to export
- [[PR #12613]](https://github.com/kubevirt/kubevirt/pull/12613) [orelmisan] Bridge binding: Static routes to subnets containing the pod's NIC IP address are passed to the VM.
- [[PR #13203]](https://github.com/kubevirt/kubevirt/pull/13203) [kubevirt-bot] BugFix: VMSnapshots broken on OpenShift
- [[PR #13225]](https://github.com/kubevirt/kubevirt/pull/13225) [kubevirt-bot] backend-storage will now correctly use the default virtualization storage class


### Deprecation
- [[PR #13019]](https://github.com/kubevirt/kubevirt/pull/13019) [0xFelix] virtctl: The flags `--volume-clone-pvc`, `--volume-datasource` and `--volume-blank` are deprecated in favor of the `--volume-import` flag.
- [[PR #12940]](https://github.com/kubevirt/kubevirt/pull/12940) [Barakmor1] Deprecate the DockerSELinuxMCS FeatureGate
- [[PR #12578]](https://github.com/kubevirt/kubevirt/pull/12578) [dasionov] Mark Running field as deprecated
- [[PR #11927]](https://github.com/kubevirt/kubevirt/pull/11927) [lyarwood] All `preferredCPUTopology` constants prefixed with `Prefer` have been deprecated and will be removed in a future version of the `instancetype.kubevirt.io` API.

### SIG-compute
- [[PR #12848]](https://github.com/kubevirt/kubevirt/pull/12848) [iholder101] Reduce default CompletionTimeoutPerGiB from 800s to 150s
- [[PR #12739]](https://github.com/kubevirt/kubevirt/pull/12739) [lyarwood] A new `PreferredEfi` field has been added to preferences to express the preferred `EFI` configuration for a given `VirtualMachine`.
- [[PR #12617]](https://github.com/kubevirt/kubevirt/pull/12617) [Acedus] grpc from go.mod is now correctly shipped in release images
- [[PR #12419]](https://github.com/kubevirt/kubevirt/pull/12419) [nunnatsa] Add timeout to validation webhooks
- [[PR #11881]](https://github.com/kubevirt/kubevirt/pull/11881) [lyarwood] The `expand-spec` subresource API now applies defaults to the returned `VirtualMachine` to ensure the `VirtualMachineInstanceSpec` within is closer to the eventual version used when starting the original `VirtualMachine`.
- [[PR #12268]](https://github.com/kubevirt/kubevirt/pull/12268) [fossedihelm] Drop `ForceRestart` and `ForceStop` methods from client-go
- [[PR #12053]](https://github.com/kubevirt/kubevirt/pull/12053) [vladikr] Only a single vgpu display option with ramfb will be configured per VMI.
- [[PR #11982]](https://github.com/kubevirt/kubevirt/pull/11982) [RamLavi] Introduce validatingAdmissionPolicy to restrict node patches on virt-handler
- [[PR #13053]](https://github.com/kubevirt/kubevirt/pull/13053) [0xFelix] virtctl: Users can specify a sysprep volume in VMs created with virtctl create vm
- [[PR #12855]](https://github.com/kubevirt/kubevirt/pull/12855) [0xFelix] virtctl expose: Drop flag to set deprecated LoadBalancerIP option
- [[PR #13008]](https://github.com/kubevirt/kubevirt/pull/13008) [0xFelix] virtctl: Allow creating a basic cloud-init config with virtctl create vm
- [[PR #12786]](https://github.com/kubevirt/kubevirt/pull/12786) [0xFelix] virtctl: Created VMs can infer an instancetype or preference from PVC, Registry and Snapshot sources now.
- [[PR #12557]](https://github.com/kubevirt/kubevirt/pull/12557) [codingben] Optionally create data source using virtctl image upload.
- [[PR #13072]](https://github.com/kubevirt/kubevirt/pull/13072) [0xFelix] virtctl: virtctl create vm can now use the Access Credentials API to add credentials to a new VM

### SIG-storage
- [[PR #12355]](https://github.com/kubevirt/kubevirt/pull/12355) [alicefr] Add the volume migration state in the VM status
- [[PR #12726]](https://github.com/kubevirt/kubevirt/pull/12726) [awels] Concurrent addvolume/removevolume using virtctl no longer fail if concurrent modifications happen
- [[PR #12582]](https://github.com/kubevirt/kubevirt/pull/12582) [mhenriks] vmsnapshot: when checking if a VM is running, ignore runStrategy
- [[PR #12605]](https://github.com/kubevirt/kubevirt/pull/12605) [mhenriks] vmexport: enable status subresource for VirtualMachineExport
- [[PR #12547]](https://github.com/kubevirt/kubevirt/pull/12547) [mhenriks] virt-api: skip clone auth check when DataVolume already exists
- [[PR #12395]](https://github.com/kubevirt/kubevirt/pull/12395) [alicefr] Add new condition for VMIStorageLiveMigratable
- [[PR #12194]](https://github.com/kubevirt/kubevirt/pull/12194) [mhenriks] VM supports kubevirt.io/immediate-data-volume-creation: "false" which delays creating DataVolumeTemplates until VM is started
- [[PR #12254]](https://github.com/kubevirt/kubevirt/pull/12254) [jkinred] * Reduced the severity of log messages when a `VolumeSnapshotClass` is not found. When snapshots are not enabled for a volume, the reason will still be displayed in the `status.volumeSnapshotStatuses` field of a `VirtualMachine` resource.
- [[PR #12601]](https://github.com/kubevirt/kubevirt/pull/12601) [mhenriks] vmsnapshot: Enable status subresource for snapshot.kubevirt.io api group

### SIG-network
- [[PR #13024]](https://github.com/kubevirt/kubevirt/pull/13024) [EdDev] network binding plugin: Introduce a new `managedTap` `domainAttachmentType`
- [[PR #13060]](https://github.com/kubevirt/kubevirt/pull/13060) [EdDev] Network binding plugins feature is declared as Beta.
- [[PR #12235]](https://github.com/kubevirt/kubevirt/pull/12235) [orelmisan] Network binding plugins: Enable the ability to specify compute memory overhead
- [[PR #11802]](https://github.com/kubevirt/kubevirt/pull/11802) [matthewei] Adding newMacAddresses validatewebhook for  VMCloneAPI
- [[PR #11754]](https://github.com/kubevirt/kubevirt/pull/11754) [nickolaev] Adding support for the `igb` network interface model
- [[PR #12354]](https://github.com/kubevirt/kubevirt/pull/12354) [qinqon] Use optional interface at passt binding sidecar
- [[PR #13018]](https://github.com/kubevirt/kubevirt/pull/13018) [orelmisan] Support Dynamic Primary Pod NIC Name

### SIG-scale
- [[PR #12117]](https://github.com/kubevirt/kubevirt/pull/12117) [Sreeja1725] Integrate kwok with sig-scale tests
- [[PR #12716]](https://github.com/kubevirt/kubevirt/pull/12716) [Sreeja1725] Update kubevirt_rest_client_request_latency_seconds to count list calls if made using query params
- [[PR #12247]](https://github.com/kubevirt/kubevirt/pull/12247) [Sreeja1725] Add perf-scale benchmarks for release v1.3
- [[PR #12116]](https://github.com/kubevirt/kubevirt/pull/12116) [Sreeja1725] Add CPU/Memory utilization of components metrics to kubevirt benchmarks

### Monitoring
- [[PR #13045]](https://github.com/kubevirt/kubevirt/pull/13045) [dasionov] Add 'machine_type' label for kubevirt_vm_info metric
- [[PR #12992]](https://github.com/kubevirt/kubevirt/pull/12992) [machadovilaca] Add a 'outdated' label to kubevirt_vmi_info metric
- [[PR #12645]](https://github.com/kubevirt/kubevirt/pull/12645) [avlitman] Add kubevirt_vmsnapshot_succeeded_timestamp_seconds metric
- [[PR #12718]](https://github.com/kubevirt/kubevirt/pull/12718) [machadovilaca] Add kubevirt_vm_info metric
- [[PR #12737]](https://github.com/kubevirt/kubevirt/pull/12737) [machadovilaca] Add evictable label to kubevirt_vmi_info
- [[PR #12625]](https://github.com/kubevirt/kubevirt/pull/12625) [machadovilaca] Add kubevirt_vm_resource_requests for CPU resource
- [[PR #12593]](https://github.com/kubevirt/kubevirt/pull/12593) [machadovilaca] Add kubevirt_vm_resource_requests metric for memory resource
- [[PR #12910]](https://github.com/kubevirt/kubevirt/pull/12910) [machadovilaca] Rename kubevirt_vm_resource_requests 'vmi' label to 'name'
- [[PR #12441]](https://github.com/kubevirt/kubevirt/pull/12441) [machadovilaca] Increase periodicity in domainstats migration metrics
- [[PR #13071]](https://github.com/kubevirt/kubevirt/pull/13071) [machadovilaca] Add kubevirt_vm_resource_limits metric
- [[PR #12802]](https://github.com/kubevirt/kubevirt/pull/12802) [machadovilaca] Add kubevirt_vmi_status_addresses metric

### Uncategorized
- [[PR #11097]](https://github.com/kubevirt/kubevirt/pull/11097) [vamsikrishna-siddu] add s390x support for kubevirt builder
- [[PR #10562]](https://github.com/kubevirt/kubevirt/pull/10562) [dhiller] Continue changes to Ginkgo V2 Serial runs
- [[PR #12476]](https://github.com/kubevirt/kubevirt/pull/12476) [jschintag] Enable live-migration and node labels on s390x
- [[PR #12616]](https://github.com/kubevirt/kubevirt/pull/12616) [orenc1] replace `Update()` with `Patch()` for `test VirtualMachineInstancesPerNode`
- [[PR #12575]](https://github.com/kubevirt/kubevirt/pull/12575) [Barakmor1] Advise users to use RunStrategy in virt-api messages
- [[PR #12195]](https://github.com/kubevirt/kubevirt/pull/12195) [awels] Virt export route has an edge termination of redirect
- [[PR #12594]](https://github.com/kubevirt/kubevirt/pull/12594) [tiraboschi] [tests] introduce a decorator for Periodic_only tests
- [[PR #12516]](https://github.com/kubevirt/kubevirt/pull/12516) [vamsikrishna-siddu] enable initial e2e tests for s390x.
- [[PR #12466]](https://github.com/kubevirt/kubevirt/pull/12466) [orenc1] tests/vm_tests.go: replace Update() with Patch()
- [[PR #11856]](https://github.com/kubevirt/kubevirt/pull/11856) [Sreeja1725] Add unit tests to check for API backward compatibility
- [[PR #12425]](https://github.com/kubevirt/kubevirt/pull/12425) [fudancoder] fix some comments
- [[PR #12452]](https://github.com/kubevirt/kubevirt/pull/12452) [andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 10.5.0 and QEMU 9.0.0.
- [[PR #12584]](https://github.com/kubevirt/kubevirt/pull/12584) [brianmcarey] Build KubeVirt with go v1.22.6
- [[PR #13052]](https://github.com/kubevirt/kubevirt/pull/13052) [fossedihelm] Update code-generators to 1.31.1
- [[PR #12882]](https://github.com/kubevirt/kubevirt/pull/12882) [brianmcarey] Build KubeVirt with go v1.22.8
- [[PR #12729]](https://github.com/kubevirt/kubevirt/pull/12729) [fossedihelm] Update k8s dependencies to 0.31.0
- [[PR #12186]](https://github.com/kubevirt/kubevirt/pull/12186) [kubevirt-bot] Updated common-instancetypes bundles to v1.0.1
- [[PR #12548]](https://github.com/kubevirt/kubevirt/pull/12548) [kubevirt-bot] Updated common-instancetypes bundles to v1.1.0
- [[PR #13082]](https://github.com/kubevirt/kubevirt/pull/13082) [kubevirt-bot] Updated common-instancetypes bundles to v1.2.0
- [[PR #12125]](https://github.com/kubevirt/kubevirt/pull/12125) [ksimon1] chore: bump virtio-win image version to 0.1.248

## v1.3.0

Release on: Wed Jul 17 2024

KubeVirt v1.3 is built for Kubernetes v1.30 and additionally supported for the previous two versions. See the [KubeVirt support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information.

To see the list of fine folks who contributed to this release, see the [KubeVirt release tag for v1.3.0](https://github.com/kubevirt/kubevirt/releases/tag/v1.3.0).

### API change
- [[PR #11156]](https://github.com/kubevirt/kubevirt/pull/11156) [nunnatsa] Move some verification from the VMI create validation webhook to the CRD
- [[PR #11500]](https://github.com/kubevirt/kubevirt/pull/11500) [iholder101] Support HyperV Passthrough: automatically use all available HyperV features
- [[PR #11641]](https://github.com/kubevirt/kubevirt/pull/11641) [alicefr] Add kubevirt.io/testWorkloadUpdateMigrationAbortion annotation and a mechanism to abort workload updates
- [[PR #11700]](https://github.com/kubevirt/kubevirt/pull/11700) [alicefr] Add the updateVolumeStrategy field
- [[PR #11729]](https://github.com/kubevirt/kubevirt/pull/11729) [lyarwood] `spreadOptions` have been introduced to preferences in order to allow for finer grain control of the `preferSpread` `preferredCPUTopology`. This includes the ability to now spread vCPUs across guest visible sockets, cores and threads.
- [[PR #10545]](https://github.com/kubevirt/kubevirt/pull/10545) [lyarwood] `ControllerRevisions` containing instance types and preferences are now upgraded to their latest available version when the `VirtualMachine` owning them is resync'd by `virt-controller`.
- [[PR #11955]](https://github.com/kubevirt/kubevirt/pull/11955) [mhenriks] Introduce snapshot.kibevirt.io/v1beta1
- [[PR #11956]](https://github.com/kubevirt/kubevirt/pull/11956) [mhenriks] Introduce export.kibevirt.io/v1beta1
- [[PR #11533]](https://github.com/kubevirt/kubevirt/pull/11533) [alicefr] Implement volume migration and introduce the migration updateVolumesStrategy field
- [[PR #10490]](https://github.com/kubevirt/kubevirt/pull/10490) [jschintag] Add support for building and running kubevirt on s390x.
- [[PR #11330]](https://github.com/kubevirt/kubevirt/pull/11330) [jean-edouard] More information in the migration state of VMI / migration objects
- [[PR #11773]](https://github.com/kubevirt/kubevirt/pull/11773) [jean-edouard] Persistent TPM/UEFI will use the default storage class if none is specified in the CR.

### Bug fix
- [[PR #12296]](https://github.com/kubevirt/kubevirt/pull/12296) [orelmisan] Network binding plugins: Enable the ability to specify compute memory overhead
- [[PR #12279]](https://github.com/kubevirt/kubevirt/pull/12279) [fossidhelm] Fix: persistent tpm can be used with vmis containing dots in their name
- [[PR #12226]](https://github.com/kubevirt/kubevirt/pull/12226) [awels] Virt export route has an edge termination of redirect
- [[PR #12249]](https://github.com/kubevirt/kubevirt/pull/12249) [machadovilaca] Fix missing performance metrics for VMI resources
- [[PR #12237]](https://github.com/kubevirt/kubevirt/pull/12237) [vladikr] Only a single vgpu display option with ramfb will be configured per VMI.
- [[PR #12064]](https://github.com/kubevirt/kubevirt/pull/12064) [akalenyu] BugFix: Graceful deletion skipped for any delete call to the VM (not VMI) resource
- [[PR #11996]](https://github.com/kubevirt/kubevirt/pull/11996) [ShellyKa13] BugFix: Fix restore panic in case of volumesnapshot missing
- [[PR #11973]](https://github.com/kubevirt/kubevirt/pull/11973) [fossedihelm] Bug fix: Correctly reflect RestartRequired condition
- [[PR #11922]](https://github.com/kubevirt/kubevirt/pull/11922) [alromeros] Bugfix: Fix VM manifest rendering in export controller
- [[PR #11367]](https://github.com/kubevirt/kubevirt/pull/11367) [alromeros] Bugfix: Allow vmexport download redirections by printing logs into stderr
- [[PR #11219]](https://github.com/kubevirt/kubevirt/pull/11219) [alromeros] Bugfix: Improve handling of IOThreads with incompatible buses
- [[PR #11372]](https://github.com/kubevirt/kubevirt/pull/11372) [xpivarc] Bug-fix: Fix nil panic if VM update fails
- [[PR #11267]](https://github.com/kubevirt/kubevirt/pull/11267) [mhenriks] BugFix: Ensure DataVolumes created by virt-controller (DataVolumeTemplates) are recreated and owned by the VM in the case of DR and backup/restore.
- [[PR #10900]](https://github.com/kubevirt/kubevirt/pull/10900) [KarstenB] BugFix: Fixed incorrect APIVersion of APIResourceList
- [[PR #11306]](https://github.com/kubevirt/kubevirt/pull/11306) [fossedihelm] fix(ksm): set the `kubevirt.io/ksm-enabled` node label to true if the ksm is managed by KubeVirt, instead of reflect the actual ksm value.
- [[PR #11264]](https://github.com/kubevirt/kubevirt/pull/11264) [machadovilaca] Fix perfscale buckets error
- [[PR #11058]](https://github.com/kubevirt/kubevirt/pull/11058) [fossedihelm] fix(vmclone): delete vmclone resource when the target vm is deleted
- [[PR #11265]](https://github.com/kubevirt/kubevirt/pull/11265) [xpivarc] Bug fix: VM controller doesn't corrupt its cache anymore
- [[PR #11205]](https://github.com/kubevirt/kubevirt/pull/11205) [akalenyu] Fix migration breaking in case the VM has an rng device after hotplugging a block volume on cgroupsv2
- [[PR #11051]](https://github.com/kubevirt/kubevirt/pull/11051) [alromeros] Bugfix: Improve error reporting when fsfreeze fails
- [[PR #12016]](https://github.com/kubevirt/kubevirt/pull/12016) [acardace] fix starting VM with Manual RunStrategy
- [[PR #11963]](https://github.com/kubevirt/kubevirt/pull/11963) [acardace] Fix RerunOnFailure RunStrategy
- [[PR #11718]](https://github.com/kubevirt/kubevirt/pull/11718) [fossedihelm] Fix: SEV methods in client-go now satisfy the proxy server configuration, if provided
- [[PR #12122]](https://github.com/kubevirt/kubevirt/pull/12122) [kubevirt-bot] Fix VMPools when `LiveUpdate` as `vmRolloutStrategy` is used.
- [[PR #12201]](https://github.com/kubevirt/kubevirt/pull/12201) [kubevirt-bot] fix RerunOnFailure stuck in Provisioning
- [[PR #12151]](https://github.com/kubevirt/kubevirt/pull/12151) [kubevirt-bot] Bugfix: Implement retry mechanism in export server and vmexport
- [[PR #12146]](https://github.com/kubevirt/kubevirt/pull/12146) [kubevirt-bot] Memory Hotplug fixes and stabilization
- [[PR #12185]](https://github.com/kubevirt/kubevirt/pull/12185) [kubevirt-bot] VMs with a single socket and NetworkInterfaceMultiqueue enabled require a restart to hotplug additional CPU sockets.
- [[PR #12171]](https://github.com/kubevirt/kubevirt/pull/12171) [kubevirt-bot] `PreferredDiskDedicatedIoThread` is now only applied to `virtio` disk devices

### Deprecation
- [[PR #11701]](https://github.com/kubevirt/kubevirt/pull/11701) [EdDev] The SLIRP core binding is deprecated and removed.
- [[PR #11901]](https://github.com/kubevirt/kubevirt/pull/11901) [EdDev] The 'macvtap' core network binding is discontinued and removed.
- [[PR #11915]](https://github.com/kubevirt/kubevirt/pull/11915) [ormergi] The 'passt' core network binding is discontinued and removed.
- [[PR #11404]](https://github.com/kubevirt/kubevirt/pull/11404) [avlitman] KubeVirtComponentExceedsRequestedCPU and KubeVirtComponentExceedsRequestedMemory alerts are deprecated; they do not indicate a genuine issue.

### SIG-compute
- [[PR #11498]](https://github.com/kubevirt/kubevirt/pull/11498) [acardace] Allow to hotplug memory for VMs with memory limits set
- [[PR #11479]](https://github.com/kubevirt/kubevirt/pull/11479) [vladikr] virtual machines instance will no longer be stuck in an irrecoverable state after an interrupted postcopy migration. Instead, these will fail and could be restarted again.
- [[PR #11685]](https://github.com/kubevirt/kubevirt/pull/11685) [fossedihelm] Updated go version of the client-go to 1.21
- [[PR #11344]](https://github.com/kubevirt/kubevirt/pull/11344) [aerosouund] Refactor device plugins to use a base plugin and define a common interface
- [[PR #12025]](https://github.com/kubevirt/kubevirt/pull/12025) [fossedihelm] Add descheduler compatibility
- [[PR #12109]](https://github.com/kubevirt/kubevirt/pull/12109) [acardace] Support Memory Hotplug with Hugepages
- [[PR #11883]](https://github.com/kubevirt/kubevirt/pull/11883) [orelmisan] Restart of a VM is required when the CPU socket count is reduced
- [[PR #11655]](https://github.com/kubevirt/kubevirt/pull/11655) [acardace] Allow to hotplug vcpus for VMs with CPU requests and/or limits set
- [[PR #11455]](https://github.com/kubevirt/kubevirt/pull/11455) [lyarwood] `LiveUpdates`  of VMs using instance types are now supported with the same caveats as when making changes to a vanilla VM.
- [[PR #11681]](https://github.com/kubevirt/kubevirt/pull/11681) [lyarwood] The `CommonInstancetypesDeployment` feature and gate are retrospectively moved to Beta from the 1.2.0 release.
- [[PR #11648]](https://github.com/kubevirt/kubevirt/pull/11648) [kubevirt-bot] Updated common-instancetypes bundles to v1.0.0
- [[PR #12240]](https://github.com/kubevirt/kubevirt/pull/12240) [kubevirt-bot] Updated common-instancetypes bundles to v1.0.1

### SIG-storage
- [[PR #11095]](https://github.com/kubevirt/kubevirt/pull/11095) [ShellyKa13] Expose volumesnapshot error in vmsnapshot object
- [[PR #11312]](https://github.com/kubevirt/kubevirt/pull/11312) [alromeros] Improve handling of export resources in virtctl vmexport
- [[PR #11770]](https://github.com/kubevirt/kubevirt/pull/11770) [alicefr] Fix the live updates for volumes and disks
- [[PR #11957]](https://github.com/kubevirt/kubevirt/pull/11957) [mhenriks] snapshot: Ignore unfreeze error if VMSnapshot deleting

### SIG-network
- [[PR #11653]](https://github.com/kubevirt/kubevirt/pull/11653) [EdDev] Build the `passt`custom CNI binary statically, for the `passt` network binding plugin.
- [[PR #11678]](https://github.com/kubevirt/kubevirt/pull/11678) [Vicente-Cheng] Improve the handling of ordinal pod interface name for upgrade
- [[PR #11618]](https://github.com/kubevirt/kubevirt/pull/11618) [AlonaKaplan] Extend network binding plugin to support device-info DownwardAPI.
- [[PR #11256]](https://github.com/kubevirt/kubevirt/pull/11256) [andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 10.0.0 and QEMU 8.2.0.
- [[PR #11788]](https://github.com/kubevirt/kubevirt/pull/11788) [ormergi] The network-info annotation is now used for mapping between SR-IOV network and the underlying device PCI address
- [[PR #11659]](https://github.com/kubevirt/kubevirt/pull/11659) [iholder101] Require scheduling infra components onto control-plane nodes
- [[PR #12079]](https://github.com/kubevirt/kubevirt/pull/12079) [EdDev] Network hotplug feature is declared as Beta.

### SIG-scale
- [[PR #11272]](https://github.com/kubevirt/kubevirt/pull/11272) [dharmit] Make 'image' field in hook sidecar annotation optional.
- [[PR #11676]](https://github.com/kubevirt/kubevirt/pull/11676) [machadovilaca] Rename rest client metrics to include kubevirt prefix
- [[PR #11387]](https://github.com/kubevirt/kubevirt/pull/11387) [alaypatel07] add perf-scale benchmarks for release v1.2

### Monitoring
- [[PR #11307]](https://github.com/kubevirt/kubevirt/pull/11307) [machadovilaca] Add e2e tests for metrics
- [[PR #11294]](https://github.com/kubevirt/kubevirt/pull/11294) [machadovilaca] Fix kubevirt_vm_created_total being broken down by virt-api pod
- [[PR #11557]](https://github.com/kubevirt/kubevirt/pull/11557) [avlitman] New memory statistics added named kubevirt_memory_delta_from_requested_bytes
- [[PR #11283]](https://github.com/kubevirt/kubevirt/pull/11283) [assafad] Collect VMI OS info from the Guest agent as `kubevirt_vmi_phase_count` metric labels
- [[PR #11906]](https://github.com/kubevirt/kubevirt/pull/11906) [machadovilaca] Create kubevirt_vmi_info metric
- [[PR #11934]](https://github.com/kubevirt/kubevirt/pull/11934) [assafad] Add kubevirt_vmi_last_connection_timestamp_seconds metric
- [[PR #12000]](https://github.com/kubevirt/kubevirt/pull/12000) [machadovilaca] Create kubevirt_vmi_launcher_memory_overhead_bytes metric
- [[PR #11484]](https://github.com/kubevirt/kubevirt/pull/11484) [jcanocan] Reduce the downwardMetrics server maximum number of request per second to 1.

### Uncategorized
- [[PR #12132]](https://github.com/kubevirt/kubevirt/pull/12132) [kubevirt-bot] Introduce validatingAdmissionPolicy to restrict node patches on virt-handler
- [[PR #12009]](https://github.com/kubevirt/kubevirt/pull/12009) [xpivarc] By enabling NodeRestriction feature gate, Kubevirt now authorize virt-handler's requests to modify VMs.
- [[PR #12089]](https://github.com/kubevirt/kubevirt/pull/12089) [jean-edouard] Less privileged virt-operator ClusterRole
- [[PR #11969]](https://github.com/kubevirt/kubevirt/pull/11969) [iholder101] Infra components control-plane nodes NoSchedule toleration
- [[PR #11835]](https://github.com/kubevirt/kubevirt/pull/11835) [talcoh2x] add Intel Gaudi to adopters.
- [[PR #11790]](https://github.com/kubevirt/kubevirt/pull/11790) [aburdenthehand] Re-adding Cloudflare to our ADOPTERS list
- [[PR #11331]](https://github.com/kubevirt/kubevirt/pull/11331) [anjuls] add cloudraft to adopters.
- [[PR #11942]](https://github.com/kubevirt/kubevirt/pull/11942) [ido106] Update virtctl to use v1beta1 endpoint for both regular and async image upload
- [[PR #11908]](https://github.com/kubevirt/kubevirt/pull/11908) [victortoso] sidecar-shim: allow stderr log from binary hooks
- [[PR #11846]](https://github.com/kubevirt/kubevirt/pull/11846) [victortoso] SMBios sidecar can be built out-of-tree
- [[PR #11482]](https://github.com/kubevirt/kubevirt/pull/11482) [brianmcarey] Build KubeVirt with go v1.22.2
- [[PR #11470]](https://github.com/kubevirt/kubevirt/pull/11470) [brianmcarey] Build KubeVirt with Go version 1.21.8
- [[PR #12097]](https://github.com/kubevirt/kubevirt/pull/12097) [fossedihelm] Bump k8s deps to 0.30.0
- [[PR #11416]](https://github.com/kubevirt/kubevirt/pull/11416) [dhiller] emission of k8s logs when using programmatic focus with `FIt`
- [[PR #11183]](https://github.com/kubevirt/kubevirt/pull/11183) [dhiller] Extend OWNERS for sig-buildsystem
- [[PR #11149]](https://github.com/kubevirt/kubevirt/pull/11149) [0xFelix] virtctl: It is possible to import volumes from GCS when creating a VM now
- [[PR #11146]](https://github.com/kubevirt/kubevirt/pull/11146) [RamLavi] node-labeller: Remove obsolete functionalities

## v1.2.0

Released on: Tue Mar 05 2024

KubeVirt v1.2 is built for Kubernetes v1.29 and additionally supported for the previous two versions. See the [KubeVirt support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md) for more information.

### API change
- [[PR #11064]](https://github.com/kubevirt/kubevirt/pull/11064) [AlonaKaplan] Introduce a new API to mark a binding plugin as migratable.
- [[PR #10970]](https://github.com/kubevirt/kubevirt/pull/10970) [alromeros] Expose fs disk information via GuestOsInfo
- [[PR #10905]](https://github.com/kubevirt/kubevirt/pull/10905) [tiraboschi] Aggregate DVs conditions on VMI (and so VM)
- [[PR #10872]](https://github.com/kubevirt/kubevirt/pull/10872) [RamLavi] IsolateEmulatorThread: Add cluster-wide parity completion setting
- [[PR #10846]](https://github.com/kubevirt/kubevirt/pull/10846) [RamLavi] Change vm.status.PrintableStatus default value to "Stopped"
- [[PR #10774]](https://github.com/kubevirt/kubevirt/pull/10774) [victortoso] Windows offline activation with ACPI SLIC table
- [[PR #10732]](https://github.com/kubevirt/kubevirt/pull/10732) [AlonaKaplan] Extend kubvirt CR by adding domain attachment option to the network binding plugin API.
- [[PR #10658]](https://github.com/kubevirt/kubevirt/pull/10658) [matthewei] Support "Clone API" to filter VirtualMachine.spec.template.annotation and VirtualMachine.spec.template.label

### Bug fix
- [[PR #11271]](https://github.com/kubevirt/kubevirt/pull/11271) [kubevirt-bot] Bug fix: VM controller doesn't corrupt its cache anymore
- [[PR #11242]](https://github.com/kubevirt/kubevirt/pull/11242) [kubevirt-bot] Fix migration breaking in case the VM has an rng device after hotplugging a block volume on cgroupsv2
- [[PR #11069]](https://github.com/kubevirt/kubevirt/pull/11069) [ormergi] Bug fix: Packet drops during the initial phase of VM live migration https://issues.redhat.com/browse/CNV-28040
- [[PR #11065]](https://github.com/kubevirt/kubevirt/pull/11065) [fossedihelm] fix(vmclone): Generate VM patches from vmsnapshotcontent, instead of current VM
- [[PR #11050]](https://github.com/kubevirt/kubevirt/pull/11050) [fossedihelm] restrict default cluster role to authenticated only users
- [[PR #11047]](https://github.com/kubevirt/kubevirt/pull/11047) [jschintag] Fix potential crash when trying to list USB devices on host without any
- [[PR #10963]](https://github.com/kubevirt/kubevirt/pull/10963) [alromeros] Bugfix: Reject volume exports when no output is specified
- [[PR #10916]](https://github.com/kubevirt/kubevirt/pull/10916) [orelmisan] Fix the value of VMI `Status.GuestOSInfo.Version`
- [[PR #10888]](https://github.com/kubevirt/kubevirt/pull/10888) [fossedihelm] [Bugfix] Clone VM with WaitForFirstConsumer binding mode PVC now works.
- [[PR #10860]](https://github.com/kubevirt/kubevirt/pull/10860) [akalenyu] BugFix: Double cloning with filter fails
 isolateEmulatorThread feature (BZ#2228103).
- [[PR #10845]](https://github.com/kubevirt/kubevirt/pull/10845) [orelmisan] Reject VirtualMachineClone creation when target name is equal to source name
- [[PR #10753]](https://github.com/kubevirt/kubevirt/pull/10753) [victortoso] Fixes  permission when using USB host passthrough
- [[PR #10747]](https://github.com/kubevirt/kubevirt/pull/10747) [acardace] Fix KubeVirt for CRIO 1.28 by using checksums to verify containerdisks when migrating VMIs
- [[PR #10699]](https://github.com/kubevirt/kubevirt/pull/10699) [qinqon] virt-launcher: fix qemu non root log path
- [[PR #10689]](https://github.com/kubevirt/kubevirt/pull/10689) [akalenyu] BugFix: cgroupsv2 device allowlist is bound to virt-handler internal state/block disk device overwritten on hotplug
- [[PR #10593]](https://github.com/kubevirt/kubevirt/pull/10593) [RamLavi] Fixes SMT Alignment Error in virt-launcher pod by optimizing

### Deprecation
- [[PR #10924]](https://github.com/kubevirt/kubevirt/pull/10924) [AlonaKaplan] Deprecate macvtap

### SIG-compute
- [[PR #11054]](https://github.com/kubevirt/kubevirt/pull/11054) [jean-edouard] New cluster-wide `vmRolloutStrategy` setting to define whether changes to VMs should either be always staged or live-updated when possible.
- [[PR #11001]](https://github.com/kubevirt/kubevirt/pull/11001) [fossedihelm] Allow `kubevirt.io:default` clusterRole to get,list kubevirts
- [[PR #10961]](https://github.com/kubevirt/kubevirt/pull/10961) [jcanocan] Reduced VM rescheduling time on node failure
- [[PR #10918]](https://github.com/kubevirt/kubevirt/pull/10918) [orelmisan] VMClone: Emit an event in case restore creation fails
- [[PR #10898]](https://github.com/kubevirt/kubevirt/pull/10898) [matthewei] vmi status's guestOsInfo adds `Machine`
- [[PR #10840]](https://github.com/kubevirt/kubevirt/pull/10840) [acardace] Requests/Limits can now be configured when using CPU/Memory hotplug
- [[PR #10839]](https://github.com/kubevirt/kubevirt/pull/10839) [RamLavi] Change second emulator thread assign strategy to best-effort.
- [[PR #10809]](https://github.com/kubevirt/kubevirt/pull/10809) [orelmisan] Source virt-launcher: Log migration info by default
- [[PR #10783]](https://github.com/kubevirt/kubevirt/pull/10783) [RamLavi] Support multiple CPUs in Housekeeping cgroup
- [[PR #10571]](https://github.com/kubevirt/kubevirt/pull/10571) [tiraboschi] vmi memory footprint increase by 35M when guest serial console logging is turned on (default on).

### SIG-storage
- [[PR #10657]](https://github.com/kubevirt/kubevirt/pull/10657) [germag] Exposing Filesystem Persistent Volumes (PVs)  to the VM using unprivilege virtiofsd.
- [[PR #10529]](https://github.com/kubevirt/kubevirt/pull/10529) [alromeros] Allow LUN disks to be hotplugged

### SIG-network
- [[PR #10981]](https://github.com/kubevirt/kubevirt/pull/10981) [AlonaKaplan] Report IP of interfaces using network binding plugin.
- [[PR #10866]](https://github.com/kubevirt/kubevirt/pull/10866) [AlonaKaplan] Raise an error in case passt feature gate or API are used.
- [[PR #10800]](https://github.com/kubevirt/kubevirt/pull/10800) [AlonaKaplan] Support macvtap as a binding plugin
- [[PR #10425]](https://github.com/kubevirt/kubevirt/pull/10425) [ormergi] Introduce network binding plugin for Passt networking, interfacing with Kubevirt new network binding plugin API.

### SIG-infra
- [[PR #11025]](https://github.com/kubevirt/kubevirt/pull/11025) [0xFelix] Allow unprivileged users read-only access to VirtualMachineCluster{Instancetypes,Preferences} by default.
- [[PR #10922]](https://github.com/kubevirt/kubevirt/pull/10922) [kubevirt-bot] Updated common-instancetypes bundles to v0.4.0

### Monitoring
- [[PR #10982]](https://github.com/kubevirt/kubevirt/pull/10982) [machadovilaca] Refactor monitoring metrics
- [[PR #10962]](https://github.com/kubevirt/kubevirt/pull/10962) [machadovilaca] Update monitoring file structure
- [[PR #10853]](https://github.com/kubevirt/kubevirt/pull/10853) [machadovilaca] Refactor monitoring collectors
- [[PR #10700]](https://github.com/kubevirt/kubevirt/pull/10700) [machadovilaca] Refactor monitoring alerts
- [[PR #10693]](https://github.com/kubevirt/kubevirt/pull/10693) [machadovilaca] Remove MigrateVmiDiskTransferRateMetric
- [[PR #10651]](https://github.com/kubevirt/kubevirt/pull/10651) [machadovilaca] Refactor monitoring  recording-rules
- [[PR #10570]](https://github.com/kubevirt/kubevirt/pull/10570) [machadovilaca] Fix LowKVMNodesCount not firing
- [[PR #10418]](https://github.com/kubevirt/kubevirt/pull/10418) [machadovilaca] Add total VMs created metric

### Uncategorized
- [[PR #11144]](https://github.com/kubevirt/kubevirt/pull/11144) [0xFelix] virtctl: Specifying size when creating a VM and using --volume-import to clone a PVC or a VolumeSnapshot is optional now
- [[PR #11122]](https://github.com/kubevirt/kubevirt/pull/11122) [brianmcarey] Update runc dependency to v1.1.12
- [[PR #11068]](https://github.com/kubevirt/kubevirt/pull/11068) [brianmcarey] Update container base image to use current stable debian 12 base
- [[PR #10914]](https://github.com/kubevirt/kubevirt/pull/10914) [brianmcarey] KubeVirt is now built with go 1.21.5
- [[PR #10879]](https://github.com/kubevirt/kubevirt/pull/10879) [brianmcarey] Built with golang 1.20.12
- [[PR #10863]](https://github.com/kubevirt/kubevirt/pull/10863) [dhiller] Remove year from generated code copyright
- [[PR #10787]](https://github.com/kubevirt/kubevirt/pull/10787) [matthewei] virtctl support to add template label and annotation filters
- [[PR #10720]](https://github.com/kubevirt/kubevirt/pull/10720) [awels] Restored hotplug attachment pod request/limit to original value
- [[PR #10637]](https://github.com/kubevirt/kubevirt/pull/10637) [dharmit] Functional tests for sidecar hook with ConfigMap
- [[PR #10615]](https://github.com/kubevirt/kubevirt/pull/10615) [orelmisan] Remove leftover NonRoot feature gate
- [[PR #10598]](https://github.com/kubevirt/kubevirt/pull/10598) [alicefr] Add PVC option to the hook sidecars for supplying additional debugging tools
- [[PR #10596]](https://github.com/kubevirt/kubevirt/pull/10596) [mhenriks] Disable HTTP/2 to mitigate CVE-2023-44487
- [[PR #10582]](https://github.com/kubevirt/kubevirt/pull/10582) [orelmisan] Remove leftover NonRootExperimental feature gate
- [[PR #10567]](https://github.com/kubevirt/kubevirt/pull/10567) [awels] Attachment pod creation is now rate limited
- [[PR #10526]](https://github.com/kubevirt/kubevirt/pull/10526) [cfilleke]  Documents steps to build the KubeVirt builder container
- [[PR #10479]](https://github.com/kubevirt/kubevirt/pull/10479) [dharmit] Ability to run scripts through hook sidecardevice
- [[PR #10244]](https://github.com/kubevirt/kubevirt/pull/10244) [hshitomi] Added “adm” subcommand under “virtctl”, and “log-verbosity" subcommand under “adm”. The log-verbosity command is: to show the log verbosity of one or more components, to set the log verbosity of one or more components, and to reset the log verbosity of all components (reset to the default verbosity (2)).
- [[PR #10046]](https://github.com/kubevirt/kubevirt/pull/10046) [victortoso] Add v1alpha3 for hooks and fix migration when using sidecars

## v1.1.0

Released on: Tue Nov 07 2023

### API change
- [#10568][ormergi] Network binding plugin API support CNIs, new integration point on virt-launcher pod creation.
- [#10309][lyarwood] cluster-wide [`common-instancetypes`](https://github.com/kubevirt/common-instancetypes) resources can now deployed by `virt-operator` using the `CommonInstancetypesDeploymentGate` feature gate.
- [#10463][0xFelix] VirtualMachines: Introduce InferFromVolumeFailurePolicy in Instancetype- and PreferenceMatchers
- [#10447][fossedihelm] Add a Feature Gate to KV CR to automatically set memory limits when a resource quota with memory limits is associated to the creation namespace
- [#10477][jean-edouard] Dynamic KSM enabling and configuration
- [#10110][tiraboschi] Stream guest serial console logs from a dedicated container
- [#10015][victortoso] Implements USB host passthrough in permittedHostDevices of KubeVirt CRD
- [#10184][acardace] Add memory hotplug feature
- [#10231][kvaps] Propogate public-keys to cloud-init NoCloud meta-data
- [#9673][germag] DownwardMetrics: Expose DownwardMetrics through virtio-serial channel.
- [#10086][vladikr] allow live updating VM affinity and node selector
- [#10272][ormergi] Introduce network binding plugin for Slirp networking, interfacing with Kubevirt new network binding plugin API.
- [#10284][AlonaKaplan] Introduce an API for network binding plugins. The feature is behind "NetworkBindingPlugins" gate.
- [#10101][acardace] Deprecate `spec.config.machineType` in KubeVirt CR.
- [#9878][jean-edouard] The EFI NVRAM can now be configured to persist across reboots
- [#9932][lyarwood] `ControllerRevisions` containing `instancetype.kubevirt.io` `CRDs` are now decorated with labels detailing specific metadata of the underlying stashed object
- [#10058][alicefr] Add field errorPolicy for disks
- [#10004][AlonaKaplan] Hoyplug/unplug interfaces should be done by updating the VM spec template. virtctl and REST API endpoints were removed.
- [#9896][ormergi] The VM controller now replicates spec interfaces MAC addresses to the corresponding interfaces in the VMI spec.
- [#7708][VirrageS] `nodeSelector` and `schedulerName` fields have been added to VirtualMachineInstancetype spec.
- [#7197][vasiliy-ul] Experimantal support of SEV attestation via the new API endpoints
- [#9737][AlonaKaplan] On hotunplug - remove bridge, tap and dummy interface from virt-launcher and the caches (file and volatile) from the node.

### Bug fixes:
- [#10515][iholder101] Bug-fix: Stop copying VMI spec to VM during snapshots
- [#10393][iholder101] [Bugfix] [Clone API] Double-cloning is now working as expected.
- [#10391][awels] BugFix: VMExport now works in a namespace with quotas defined.
- [#10380][alromeros] Bugfix: Allow image-upload to recover from PendingPopulation phase
- [#10099][iholder101] Bugfix: target virt-launcher pod hangs when migration is cancelled.
- [#10165][awels] BugFix: deleting hotplug attachment pod will no longer detach volumes that were not removed.
- [#10067][iholder101] Bug fix: `virtctl create clone` marshalling and replacement of `kubectl` with `kubectl virt`
- [#9935][xpivarc] Bug fix - correct logging in container disk
- [#9872][alromeros] Bugfix: Allow lun disks to be mapped to DataVolume sources
- [#10039][simonyangcj] fix guaranteed qos of virt-launcher pod broken when use virtiofs
- [#9861][rmohr] Fix the possibility of data corruption when requesting a force-restart via "virtctl restart"

### Deprecation
- [#10486][assafad] Deprecation notice for the metrics listed in the PR. Please update your systems to use the new metrics names.
- [#9821][sradco] Deprecation notice for the metrics listed in the PR. Please update your systems to use the new metrics names.

### SIG-compute
- [#10566][fossedihelm] Add 100Mi of memory overhead for vmi with dedicatedCPU or that wants GuaranteedQos
- [#10496][fossedihelm] Automatically set cpu limits when a resource quota with cpu limits is associated to the creation namespace and the `AutoResourceLimits` FeatureGate is enabled
- [#10543][0xFelix] Clear VM guest memory when ignoring inference failures
- [#10320][victortoso] sidecar-shim implements PreCloudInitIso hook
- [#10253][rmohr] Stop trying to create unused directory /var/run/kubevirt-ephemeral-disk in virt-controller
- [#10050][victortoso] Updating the virt stack: QEMU 8.0.0, libvirt to 9.5.0, edk2 20230524, passt 20230818, libguestfs and guestfs-tools 1.50.1, virtiofsd 1.7.2
- [#9231][victortoso] Introduces sidecar-shim container image
- [#10254][rmohr] Don't mark the KubeVirt "Available" condition as false on up-to-date and ready but misscheduled virt-handler pods.
- [#10182][iholder101] Stop considering nodes without `kubevirt.io/schedulable` label when finding lowest TSC frequency on the cluster
- [#10056][jean-edouard] UEFI guests now use Bochs display instead of VGA emulation
- [#10106][acardace] Add boot-menu wait time when starting the VM as paused.

### SIG-storage
- [#10532][alromeros] Add --volume-mode flag in image-upload
- [#10020][akalenyu] Use auth API for DataVolumes, stop importing kubevirt.io/containerized-data-importer
- [#10400][alromeros] Add new vmexport flags to download raw images, either directly (--raw) or by decompressing (--decompress) them
- [#10148][alromeros] Add port-forward functionalities to vmexport
- [#10275][awels] Ensure new hotplug attachment pod is ready before deleting old attachment pod
- [#10118][akalenyu] Change exportserver default UID to succeed exporting CDI standalone PVCs (not attached to VM)
- [#9918][ShellyKa13] Fix for hotplug with WFFC SCI storage class which uses CDI populators

### SIG-network
- [#10366][ormergi] Kubevirt now delegates Slirp networking configuration to Slirp network binding plugin.  In case you haven't registered Slirp network binding plugin image yet (i.e.: specify in Kubevirt config) the following default image would be used: `quay.io/kubevirt/network-slirp-binding:20230830_638c60fc8`. On next release (v1.2.0) no default image will be set and registering an image would be mandatory.
- [#10185][AlonaKaplan] Add support to migration based SRIOV hotplug.
- [#10116][ormergi] Existing detached interfaces with 'absent' state will be cleared from VMI spec.
- [#9958][AlonaKaplan] Disable network interface hotplug/unplug for VMIs. It will be supported for VMs only.
- [#10489][maiqueb] Remove the network-attachment-definition `list` and `watch` verbs from virt-controller's RBAC

### SIG-infra
- [#10438][lyarwood] A new `instancetype.kubevirt.io:view` `ClusterRole` has been introduced that can be bound to users via a `ClusterRoleBinding` to provide read only access to the cluster scoped `VirtualMachineCluster{Instancetype,Preference}` resources.

### SIG-scale
- [#9989][alaypatel07] Add perf scale benchmarks for VMIs

### Uncategorized
- [#9590][xuzhenglun] fix embed version info of virt-operator
- [#10044][machadovilaca] Add operator-observability package
- [#10450][0xFelix] virtctl: Enable inference in create vm subcommand by default
- [#10386][liuzhen21] KubeSphere added to the adopter's file!
- [#10167][0xFelix] virtctl: Apply namespace to created manifests
- [#10173][rmohr] Move coordination/lease RBAC permissions to Roles
- [#10138][machadovilaca] Change `kubevirt_vmi_*_usage_seconds` from Gauge to Counter
- [#10107][PiotrProkop] Expose `kubevirt_vmi_vcpu_delay_seconds_total` reporting amount of seconds VM spent in waiting in the queue instead of running.
- [#10070][machadovilaca] Remove affinities label from `kubevirt_vmi_cpu_affinity` and use sum as value
- [#9982][fabiand] Introduce a support lifecycle and Kubernetes target version.
- [#10001][machadovilaca] Fix `kubevirt_vmi_phase_count` not being created
- [#9840][dhiller] Increase probability for flake checker script to find flakes
- [#9988][enp0s3] Always deploy the outdated VMI workload alert
- [#9882][dhiller] Add some context for initial contributors about automated testing and draft pull requests.
- [#9552][phoracek] gRPC client now works correctly with non-Go gRPC servers
- [#9818][akrejcir] Added "virtctl credentials" commands to dynamically change SSH keys in a VM, and to set user's password.
- [#9073][machadovilaca] Fix incorrect KubevirtVmHighMemoryUsage description

## v1.0.0

Released on: Thu Jul 11 17:39:42 2023 +0000

### API changes
- [PR #9572][fossedihelm] Enable freePageReporting for new non high performance vmi
- [PR #8156][jean-edouard] TPM VM device can now be set to persistent
- [PR #8575][iholder101] QEMU-level migration parallelism (a.k.a. multifd) + Upgrade QEMU to 7.2.0-11.el9
- [PR #9322][iholder101] Add guest-to-request memory headroom ratio.
- [PR #9422][awels] Ability to specify cpu/mem request limit for supporting containers (hotplug/container disk/virtiofs/side car)
- [PR #9177][alicefr] Adding SCSI persistent reservation
- [PR #9145][awels] Show VirtualMachine name in the VMExport status
- [PR #9491][orelmisan] API, AddInterfaceOptions: Rename NetworkName to NetworkAttachmentDefinitionName and InterfaceName to Name
- [PR #9442][EdDev] Remove the VMI Status interface `podConfigDone` field in favor of a new source option in `infoSource`.
- [PR #6852][maiqueb] Dev preview: Enables network interface hotplug for VMs / VMIs
- [PR #9193][qinqon] Add annotation for live migration and bridged pod interface
- [PR #9421][lyarwood] Requests to update the target `Name` of a `{Instancetype,Preference}Matcher` without also updating the `RevisionName` are now rejected.

### Bug fixes
- [PR #9591][awels] BugFix: allow multiple NFS disks to be used/hotplugged
- [PR #9536][akalenyu] BugFix: virtualmachineclusterinstancetypes/preferences show up for get all -n <namespace>
- [PR #9300][xpivarc] Bug fix: API and virtctl invoked migration is not rejected when the VM is paused
- [PR #9189][xpivarc] Bug fix: DNS integration continues to work after migration
- [PR #9241][akalenyu] BugFix: Guestfs image url not constructed correctly
- [PR #9260][ShellyKa13] Fix bug of possible re-trigger of memory dump
- [PR #9478][xpivarc] Bug fix: Fixes case when migration is not retried if the migration Pod gets denied.
- [PR #9330][qinqon] Skip label kubevirt.io/migrationTargetNodeName from virtctl expose service selector
- [PR #9603][qinqon] Adapt node-labeller.sh script to work at non kvm envs with emulation.

### Deprecation
- [PR #9047][machadovilaca] Deprecate VM stuck in status alerts

### SIG-compute
- [PR #9640][jean-edouard] TSC-enabled VMs can now migrate to a node with a non-identical (but close-enough) frequency
- [PR #9629][0xFelix] virtctl: Allow to specify the boot order of volumes when creating VMs
- [PR #9435][rmohr] Ensure existence of all PVCs attached to the VMI before creating the VM target pod.
- [PR #9470][machadovilaca] Enable libvirt GetDomainStats on paused VMs
- [PR #9163][vladikr] fixes the requests/limits CPU number mismatch for VMs with isolatedEmulatorThread
- [PR #9250][vladikr] externally created mediated devices will not be deleted by virt-handler

### SIG-storage
- [PR #9376][ShellyKa13] Fix vmrestore with WFFC snapshotable storage class
- [PR #9392][awels] virtctl supports retrieving vm manifest for VM export
- [PR #9188][awels] Default RBAC for clone and export
- [PR #9133][ShellyKa13] Fix addvolume not rejecting adding existing volume source, fix removevolume allowing to remove non hotpluggable volume

### SIG-network
- [PR #9399][maiqueb] Compute the interfaces to be hotplugged based on the current domain info, rather than on the interface status.
- [PR #9220][orelmisan] client-go: Added context to VirtualMachine's methods.

### SIG-infra
- [PR #9651][0xFelix] virtctl: Allow to specify memory of created VMs. Default to 512Mi if no instancetype was specified or is inferred.
- [PR #9169][lyarwood] The `dedicatedCPUPlacement` attribute is once again supported within the `VirtualMachineInstancetype` and `VirtualMachineClusterInstancetype` CRDs after a recent bugfix improved `VirtualMachine` validations, ensuring defaults are applied before any attempt to validate.

### Uncategorized
- [PR #9632][toelke] * Add Genesis Cloud to the adopters list
- [PR #9596][iholder101] Add "virtctl create clone" command
- [PR #9407][assafad] Use env `RUNBOOK_URL_TEMPLATE` for the runbooks URL template
- [PR #9327][jcanocan] DownwardMetrics: Swap KubeVirt build info with qemu version in VirtProductInfo field
- [PR #9367][machadovilaca] Add VM instancetype and preference label to vmi_phase_count metric
- [PR #8906][machadovilaca] Alert if there are no available nodes to run VMs
- [PR #9320][darfux] node-labeller: Check arch on the handler side
- [PR #9127][fossedihelm] Use ECDSA instead of RSA for key generation
- [PR #9228][rumans] Bump virtiofs container limit
- [PR #9159][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 9.0.0 and QEMU 7.2.0.
- [PR #8989][rthallisey] Integrate multi-architecture container manifests into the bazel make recipes
- [PR #8937][fossedihelm] Added foreground finalizer to  virtual machine

## v0.59.0

Released on: Wed Mar 1 16:49:27 2023 +0000

- [PR #9311][kubevirt-bot] fixes the requests/limits CPU number mismatch for VMs with isolatedEmulatorThread
- [PR #9276][fossedihelm] Added foreground finalizer to  virtual machine
- [PR #9295][kubevirt-bot] Fix bug of possible re-trigger of memory dump
- [PR #9270][kubevirt-bot] BugFix: Guestfs image url not constructed correctly
- [PR #9234][kubevirt-bot] The `dedicatedCPUPlacement` attribute is once again supported within the `VirtualMachineInstancetype` and `VirtualMachineClusterInstancetype` CRDs after a recent bugfix improved `VirtualMachine` validations, ensuring defaults are applied before any attempt to validate.
- [PR #9267][fossedihelm] This version of KubeVirt includes upgraded virtualization technology based on libvirt 9.0.0 and QEMU 7.2.0.
- [PR #9197][kubevirt-bot] Fix addvolume not rejecting adding existing volume source, fix removevolume allowing to remove non hotpluggable volume
- [PR #9120][0xFelix] Fix access to portforwarding on VMs/VMIs with the cluster roles kubevirt.io:admin and kubevirt.io:edit
- [PR #9116][EdDev] Allow the specification of the ACPI Index on a network interface.
- [PR #8774][avlitman] Added new Virtual machines CPU metrics:
- [PR #9087][zhuchenwang] Open `/dev/vhost-vsock` explicitly to ensure that the right vsock module is loaded
- [PR #9020][feitnomore] Adding support for status/scale subresources so that VirtualMachinePool now supports HorizontalPodAutoscaler
- [PR #9085][0xFelix] virtctl: Add options to infer instancetype and preference when creating a VM
- [PR #8917][xpivarc] Kubevirt can be configured with Seccomp profile. It now ships a custom profile for the launcher.
- [PR #9054][enp0s3] do not inject LimitRange defaults into VMI
- [PR #7862][vladikr] Store the finalized VMI migration status in the migration objects.
- [PR #8878][0xFelix] Add 'create vm' command to virtctl
- [PR #9048][jean-edouard] DisableCustomSELinuxPolicy feature gate introduced to disable our custom SELinux policy
- [PR #8953][awels] VMExport now has endpoint containing entire VM definition.
- [PR #8976][iholder101] Fix podman CRI detection
- [PR #9043][iholder101] Adjust operator functional tests to custom images specification
- [PR #8875][machadovilaca] Rename migration metrics removing 'total' keyword
- [PR #9040][lyarwood] `inferFromVolume` now uses labels instead of annotations to lookup default instance type and preference details from a referenced `Volume`. This has changed in order to provide users with a way of looking up suitably decorated resources through these labels before pointing to them within the `VirtualMachine`.
- [PR #9039][orelmisan] client-go: Added context to additional VirtualMachineInstance's methods.
- [PR #9018][orelmisan] client-go: Added context to additional VirtualMachineInstance's methods.
- [PR #9025][akalenyu] BugFix: Hotplug pods have hardcoded resource req which don't comply with LimitRange maxLimitRequestRatio of 1
- [PR #8908][orelmisan] client-go: Added context to some of VirtualMachineInstance's methods.
- [PR #6863][rmohr] The install strategy job will respect the infra node placement from now on
- [PR #8948][iholder101] Bugfix: virt-handler socket leak
- [PR #8649][acardace] KubeVirt is now able to run VMs inside restricted namespaces.
- [PR #8992][iholder101] Align with k8s fix for default limit range requirements
- [PR #8889][rmohr] Add basic TLS encryption support for vsock websocket connections
- [PR #8660][huyinhou] Fix remoteAddress field in virt-api log being truncated when it is an ipv6 address
- [PR #8961][rmohr] Bump distroless base images
- [PR #8952][rmohr] Fix read-only sata disk validation
- [PR #8657][fossedihelm] Use an increasingly exponential backoff before retrying to start the VM, when an I/O error occurs.
- [PR #8480][lyarwood] New `inferFromVolume` attributes have been introduced to the `{Instancetype,Preference}Matchers` of a `VirtualMachine`. When provided the `Volume` referenced by the attribute is checked for the following annotations with which to populate the `{Instancetype,Preference}Matchers`:
- [PR #7762][VirrageS] Service `kubevirt-prometheus-metrics` now sets `ClusterIP` to `None` to make it a headless service.
- [PR #8599][machadovilaca] Change KubevirtVmHighMemoryUsage threshold from 20MB to 50MB
- [PR #7761][VirrageS] imagePullSecrets field has been added to KubeVirt CR to support deployments form private registries
- [PR #8887][iholder101] Bugfix: use virt operator image if provided
- [PR #8750][jordigilh] Fixes an issue that prevented running real time workloads in non-root configurations due to libvirt's dependency on CAP_SYS_NICE to change the vcpu's thread's scheduling and priority to FIFO and 1. The change of priority and scheduling is now executed in the virt-launcher for both root and non-root configurations, removing the dependency in libvirt.
- [PR #8845][lyarwood] An empty `Timer` is now correctly omitted from `Clock` fixing bug #8844.
- [PR #8842][andreabolognani] The virt-launcher pod no longer needs the SYS_PTRACE capability.
- [PR #8734][alicefr] Change libguestfs-tools image using root appliance in qcow2 format
- [PR #8764][ShellyKa13] Add list of included and excluded volumes in vmSnapshot
- [PR #8811][iholder101] Custom components: support gs
- [PR #8770][dhiller] Add Ginkgo V2 Serial decorator to serial tests as preparation to simplify parallel vs. serial test run logic
- [PR #8808][acardace] Apply migration backoff only for evacuation migrations.
- [PR #8525][jean-edouard] CR option mediatedDevicesTypes is deprecated in favor of mediatedDeviceTypes
- [PR #8792][iholder101] Expose new custom components env vars to csv-generator and manifest-templator
- [PR #8701][enp0s3] Consider the ParallelOutboundMigrationsPerNode when evicting VMs
- [PR #8740][iholder101] Fix: Align Reenlightenment flows between converter.go and template.go
- [PR #8530][acardace] Use exponential backoff for failing migrations
- [PR #8720][0xFelix] The expand-spec subresource endpoint was renamed to expand-vm-spec and made namespaced
- [PR #8458][iholder101] Introduce support for clones with a snapshot source (e.g. clone snapshot -> VM)
- [PR #8716][rhrazdil] Add overhead of interface with Passt binding when no ports are specified
- [PR #8619][fossedihelm] virt-launcher: use `virtqemud` daemon instead of `libvirtd`
- [PR #8736][knopt] Added more precise rest_client_request_latency_seconds histogram buckets
- [PR #8624][zhuchenwang] Add the REST API to be able to talk to the application in the guest VM via VSOCK.
- [PR #8625][AlonaKaplan] iptables are no longer used by masquerade binding. Nodes with iptables only won't be able to run VMs with masquerade binding.
- [PR #8673][iholder101] Allow specifying custom images for core components
- [PR #8622][jean-edouard] Built with golang 1.19
- [PR #8336][alicefr] Flag for setting the guestfs uid and gid
- [PR #8667][huyinhou] connect VM vnc failed when virt-launcher work directory is not /
- [PR #8368][machadovilaca] Use collector to set migration metrics
- [PR #8558][xpivarc] Bug-fix: LimitRange integration now works when VMI is missing namespace
- [PR #8404][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 8.7.0, QEMU 7.1.0 and CentOS Stream 9.
- [PR #8652][akalenyu] BugFix: Exporter pod does not comply with restricted PSA
- [PR #8563][xpivarc] Kubevirt now runs with nonroot user by default
- [PR #8442][kvaps] Add Deckhouse to the Adopters list
- [PR #8546][zhuchenwang] Provides the Vsock feature for KubeVirt VMs.
- [PR #8598][acardace] VMs configured with hugepages can now run using the default container_t SELinux type
- [PR #8594][kylealexlane] Fix permission denied on on selinux relabeling on some kernel versions
- [PR #8521][akalenyu] Add an option to specify a TTL for VMExport objects
- [PR #7918][machadovilaca] Add alerts for VMs unhealthy states
- [PR #8516][rhrazdil] When using Passt binding, virl-launcher has unprivileged_port_start set to 0, so that passt may bind to all ports.
- [PR #7772][jean-edouard] The SELinux policy for virt-launcher is down to 4 rules, 1 for hugepages and 3 for virtiofs.
- [PR #8402][jean-edouard] Most VMIs now run under the SELinux type container_t
- [PR #8513][alromeros] [Bug-fix] Fix error handling in virtctl image-upload

## v0.58.1

Released on: Thu Feb 11 00:08:46 2023 +0000

- [PR #9203][jean-edouard] Most VMIs now run under the SELinux type container_t
- [PR #9191][kubevirt-bot] Default RBAC for clone and export
- [PR #9150][kubevirt-bot] Fix access to portforwarding on VMs/VMIs with the cluster roles kubevirt.io:admin and kubevirt.io:edit
- [PR #9128][kubevirt-bot] Rename migration metrics removing 'total' keyword
- [PR #9034][akalenyu] BugFix: Hotplug pods have hardcoded resource req which don't comply with LimitRange maxLimitRequestRatio of 1
- [PR #9002][iholder101] Bugfix: virt-handler socket leak
- [PR #8907][kubevirt-bot] Bugfix: use virt operator image if provided
- [PR #8784][kubevirt-bot] Use exponential backoff for failing migrations
- [PR #8816][iholder101] Expose new custom components env vars to csv-generator, manifest-templator and gs
- [PR #8798][iholder101] Fix: Align Reenlightenment flows between converter.go and template.go
- [PR #8731][kubevirt-bot] Allow specifying custom images for core components
- [PR #8785][0xFelix] The expand-spec subresource endpoint was renamed to expand-vm-spec and made namespaced
- [PR #8806][kubevirt-bot] Consider the ParallelOutboundMigrationsPerNode when evicting VMs
- [PR #8738][machadovilaca] Use collector to set migration metrics
- [PR #8747][kubevirt-bot] Add alerts for VMs unhealthy states
- [PR #8685][kubevirt-bot] BugFix: Exporter pod does not comply with restricted PSA
- [PR #8647][akalenyu] BugFix: Add an option to specify a TTL for VMExport objects
- [PR #8609][kubevirt-bot] Fix permission denied on on selinux relabeling on some kernel versions
- [PR #8578][rhrazdil] When using Passt binding, virl-launcher has unprivileged_port_start set to 0, so that passt may bind to all ports.


## v0.58.0

Released on: Thu Oct 13 00:24:51 2022 +0000

- [PR #8578][rhrazdil] When using Passt binding, virl-launcher has unprivileged_port_start set to 0, so that passt may bind to all ports.
- [PR #8463][Barakmor1] Improve metrics documentation
- [PR #8282][akrejcir] Improves instancetype and preference controller revisions. This is a backwards incompatible change and introduces a new v1alpha2 api for instancetype and preferences.
- [PR #8272][jean-edouard] No more empty section in the kubevirt-cr manifest
- [PR #8536][qinqon] Don't show a failure if ConfigDrive cloud init has UserDataSecretRef and not NetworkDataSecretRef
- [PR #8375][xpivarc] Virtiofs can be used with Nonroot feature gate
- [PR #8465][rmohr] Add a vnc screenshot REST endpoint and a "virtctl vnc screenshot" command for UI and script integration
- [PR #8418][alromeros] Enable automatic token generation for VirtualMachineExport objects
- [PR #8488][0xFelix] virtctl: Be less verbose when using the local ssh client
- [PR #8396][alicefr] Add group flag for setting the gid and fsgroup in guestfs
- [PR #8476][iholder-redhat] Allow setting virt-operator log verbosity through Kubevirt CR
- [PR #8366][rthallisey] Move KubeVirt to a 15 week release cadence
- [PR #8479][arnongilboa] Enable DataVolume GC by default in cluster-deploy
- [PR #8474][vasiliy-ul] Fixed migration failure of VMs with containerdisks on systems with containerd
- [PR #8316][ShellyKa13] Fix possible race when deleting unready vmsnapshot and the vm remaining frozen
- [PR #8436][xpivarc] Kubevirt is able to run with restricted Pod Security Standard enabled with an automatic escalation of namespace privileges.
- [PR #8197][alromeros] Add vmexport command to virtctl
- [PR #8252][fossedihelm] Add `tlsConfiguration` to Kubevirt Configuration
- [PR #8431][rmohr] Fix shadow status updates and periodic status updates on VMs, performed by the snapshot controller
- [PR #8359][iholder-redhat] [Bugfix]: HyperV Reenlightenment VMIs should be able to start when TSC Frequency is not exposed
- [PR #8330][jean-edouard] Important: If you use docker with SELinux enabled, set the `DockerSELinuxMCSWorkaround` feature gate before upgrading
- [PR #8401][machadovilaca] Rename metrics to follow the naming convention

## v0.57.0

Released on: Mon Sep 12 14:00:44 2022 +0000

- [PR #8129][mlhnono68] Fixes virtctl to support connection to clusters proxied by RANCHER or having special paths
- [PR #8337][0xFelix] virtctl's native SSH client is now useable in the Windows console without workarounds
- [PR #8257][awels] VirtualMachineExport now supports VM export source type.
- [PR #8367][vladikr] fix the guest memory conversion by setting it to resources.requests.memory when guest memory is not explicitly provided
- [PR #7990][ormergi] Deprecate SR-IOV live migration feature gate.
- [PR #8069][lyarwood] The VirtualMachineInstancePreset resource has been deprecated ahead of removal in a future release. Users should instead use the VirtualMachineInstancetype and VirtualMachinePreference resources to encapsulate any shared resource or preferences characteristics shared by their VirtualMachines.
- [PR #8326][0xFelix] virtctl: Do not log wrapped ssh command by default
- [PR #8325][rhrazdil] Enable route_localnet sysctl option for masquerade binding at virt-handler
- [PR #8159][acardace] Add support for USB disks
- [PR #8006][lyarwood] `AutoattachInputDevice` has been added to `Devices` allowing an `Input` device to be automatically attached to a `VirtualMachine` on start up.  `PreferredAutoattachInputDevice` has also been added to `DevicePreferences` allowing users to control this behaviour with a set of preferences.
- [PR #8134][arnongilboa] Support DataVolume garbage collection
- [PR #8157][StefanKro] TrilioVault for Kubernetes now supports KubeVirt for backup and recovery.
- [PR #8273][alaypatel07] add server-side validations for spec.topologySpreadConstraints during object creation
- [PR #8049][alicefr] Set RunAsNonRoot as default for the guestfs pod
- [PR #8107][awels] Allow VirtualMachineSnapshot as a VirtualMachineExport source
- [PR #7846][janeczku] Added support for configuring topology spread constraints for virtual machines.
- [PR #8215][alaypatel07] support validation for spec.affinity fields during vmi creation
- [PR #8071][oshoval] Relax networkInterfaceMultiqueue semantics: multi queue will configure only what it can (virtio interfaces).
- [PR #7549][akrejcir] Added new API subresources to expand instancetype and preference.

## v0.56.0

Released on: Thu Aug 18 20:10:29 2022 +0000

- [PR #7599][iholder-redhat] Introduce a mechanism to abort non-running migrations - fixes "Unable to cancel live-migration if virt-launcher pod in pending state" bug
- [PR #8027][alaypatel07] Wait deletion to succeed all the way till objects are finalized in perfscale tests
- [PR #8198][rmohr] Improve path handling for non-root virt-launcher workloads
- [PR #8136][iholder-redhat] Fix cgroups unit tests: mock out underlying runc cgroup manager
- [PR #8047][iholder-redhat] Deprecate live migration feature gate
- [PR #7986][iholder-redhat] [Bug-fix]: Windows VM with WSL2 guest fails to migrate
- [PR #7814][machadovilaca] Add VMI filesystem usage metrics
- [PR #7849][AlonaKaplan] [TECH PREVIEW] Introducing passt - a new approach to user-mode networking for virtual machines
- [PR #7991][ShellyKa13] Virtctl memory dump with create flag to create a new pvc
- [PR #8039][lyarwood] The flavor API and associated CRDs of `VirtualMachine{Flavor,ClusterFlavor}` are renamed to instancetype and `VirtualMachine{Instancetype,ClusterInstancetype}`.
- [PR #8112][AlonaKaplan] Changing the default of `virtctl expose` `ip-family` parameter to be empty value instead of IPv4.
- [PR #8073][orenc1] Bump runc to v1.1.2
- [PR #8092][Barakmor1] Bump the version of emicklei/go-restful from 2.15.0 to 2.16.0
- [PR #8053][alromeros] [Bug-fix]: Fix mechanism to fetch fs overhead when CDI resource has a different name
- [PR #8035][0xFelix] Add option to wrap local scp client to scp command
- [PR #7981][lyarwood] Conflicts will now be raised when using flavors if the `VirtualMachine` defines any `CPU` or `Memory` resource requests.
- [PR #8068][awels] Set cache mode to match regular disks on hotplugged disks.

## v0.55.0

Released on: Thu Jul 14 16:33:25 2022 +0000

- [PR #7336][iholder-redhat] Introduce clone CRD, controller and API
- [PR #7791][iholder-redhat] Introduction of an initial deprecation policy
- [PR #7875][lyarwood] `ControllerRevisions` of any `VirtualMachineFlavorSpec` or `VirtualMachinePreferenceSpec` are stored during the initial start of a `VirtualMachine` and used for subsequent restarts ensuring changes to the original `VirtualMachineFlavor` or `VirtualMachinePreference` do not modify the `VirtualMachine` and the `VirtualMachineInstance` it creates.
- [PR #8011][fossedihelm] Increase virt-launcher memory overhead
- [PR #7963][qinqon] Bump alpine_with_test_tooling
- [PR #7881][ShellyKa13] Enable memory dump to be included in VMSnapshot
- [PR #7926][qinqon] tests: Move main clean function to global AfterEach and create a VM per each infra_test.go Entry.
- [PR #7845][janeczku] Fixed a bug that caused `make generate` to fail when API code comments contain backticks. (#7844, @janeczku)
- [PR #7932][marceloamaral] Addition of kubevirt_vmi_migration_phase_transition_time_from_creation_seconds metric to monitor how long it takes to transition a VMI Migration object to a specific phase from creation time.
- [PR #7879][marceloamaral] Faster VM phase transitions thanks to an increased virt-controller QPS/Burst
- [PR #7807][acardace] make cloud-init 'instance-id' persistent across reboots
- [PR #7928][iholder-redhat] bugfix: node-labeller now removes "host-model-cpu.node.kubevirt.io/" and "host-model-required-features.node.kubevirt.io/" prefixes
- [PR #7841][jean-edouard] Non-root VMs will now migrate to root VMs after a cluster disables non-root.
- [PR #7933][akalenyu] BugFix: Fix vm restore in case of restore size bigger then PVC requested size
- [PR #7919][lyarwood] Device preferences are now applied to any default network interfaces or missing volume disks added to a `VirtualMachineInstance` at runtime.
- [PR #7910][qinqon] tests: Create the expected readiness probe instead of liveness
- [PR #7732][acardace] Prevent virt-handler from starting a migration twice
- [PR #7594][alicefr] Enable to run libguestfs-tools pod to run as noroot user
- [PR #7811][raspbeep] User now gets information about the type of commands which the guest agent does not support.
- [PR #7590][awels] VMExport allows filesystem PVCs to be exported as either disks or directories.
- [PR #7683][alicefr] Add --command and --local-ssh-opts" options to virtctl ssh to execute remote command using local ssh method

## v0.54.0

Released on: Wed Jun 8 14:15:43 2022 +0000

- [PR #7757][orenc1] new alert for excessive number of VMI migrations in a period of time.
- [PR #7517][ShellyKa13] Add virtctl Memory Dump command
- [PR #7801][VirrageS] Empty (`nil` values) of `Address` and `Driver` fields in XML will be omitted.
- [PR #7475][raspbeep] Adds the reason of a live-migration failure to a recorded event in case EvictionStrategy is set but live-migration is blocked due to its limitations.
- [PR #7739][fossedihelm] Allow `virtualmachines/migrate` subresource to admin/edit users
- [PR #7618][lyarwood] The requirement to define a `Disk` or `Filesystem` for each `Volume` associated with a `VirtualMachine` has been removed. Any `Volumes` without a `Disk` or `Filesystem` defined will have a `Disk` defined within the `VirtualMachineInstance` at runtime.
- [PR #7529][xpivarc] NoReadyVirtController and NoReadyVirtOperator should be properly fired.
- [PR #7465][machadovilaca] Add metrics for migrations and respective phases
- [PR #7592][akalenyu] BugFix: virtctl guestfs incorrectly assumes image name

## v0.53.1

Released on: Tue May 17 14:55:54 2022 +0000

- [PR #7749][kubevirt-bot] NoReadyVirtController and NoReadyVirtOperator should be properly fired.

## v0.53.0

Released on: Mon May 9 14:02:20 2022 +0000

- [PR #7533][akalenyu] Add several VM snapshot metrics
- [PR #7574][rmohr] Pull in cdi dependencies with minimized transitive dependencies to ease API adoption
- [PR #7318][iholder-redhat] Snapshot restores now support restoring to a target VM different than the source
- [PR #7474][borod108] Added the following metrics for live migration: kubevirt_migrate_vmi_data_processed_bytes, kubevirt_migrate_vmi_data_remaining_bytes, kubevirt_migrate_vmi_dirty_memory_rate_bytes
- [PR #7441][rmohr] Add `virtctl scp` to ease copying files from and to VMs and VMIs
- [PR #7265][rthallisey] Support steady-state job types in the load-generator tool
- [PR #7544][fossedihelm] Upgraded go version to 1.17.8
- [PR #7582][acardace] Fix failed reported migrations when actually they were successful.
- [PR #7546][0xFelix] Update virtio-container-disk to virtio-win version 0.1.217-1
- [PR #7530][iholder-redhat] [External Kernel Boot]: Disallow kernel args without providing custom kernel
- [PR #7493][davidvossel] Adds new EvictionStrategy "External" for blocking eviction which is handled by an external controller
- [PR #7563][akalenyu] Switch VolumeSnapshot to v1
- [PR #7406][acardace] Reject `LiveMigrate` as a workload-update strategy if the `LiveMigration` feature gate is not enabled.
- [PR #7103][jean-edouard] Non-persistent vTPM now supported. Keep in mind that the state of the TPM is wiped after each shutdown. Do not enable Bitlocker!
- [PR #7277][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 8.0.0 and QEMU 6.2.0.
- [PR #7130][Barakmor1] Add field to kubevirtCR to set Prometheus ServiceMonitor object's namespace
- [PR #7401][iholder-redhat] virt-api deployment is now scalable - replicas are determined by the number of nodes in the cluster
- [PR #7500][awels] BugFix: Fixed RBAC for admin/edit user to allow virtualmachine/addvolume and removevolume. This allows for persistent disks
- [PR #7328][apoorvajagtap] Don't ignore --identity-file when setting --local-ssh=true on `virtctl ssh`
- [PR #7469][xpivarc] Users can now enable the NonRoot feature gate instead of NonRootExperimental
- [PR #7451][fossedihelm] Reduce virt-launcher memory usage by splitting monitoring and launcher processes

## v0.52.0

Released on: Fri Apr 8 16:17:56 2022 +0000

- [PR #7024][fossedihelm] Add an warning message if the client and server virtctl versions are not aligned
- [PR #7486][rmohr] Move stable.txt location to a more appropriate path
- [PR #7372][saschagrunert] Fixed `KubeVirtComponentExceedsRequestedMemory` alert complaining about many-to-many matching not allowed.
- [PR #7426][iholder-redhat] Add warning for manually determining core-component replica count in Kubevirt CR
- [PR #7424][maiqueb] Provide interface binding types descriptions, which will be featured in the KubeVirt API.
- [PR #7422][orelmisan] Fixed setting custom guest pciAddress and bootOrder parameter(s) to a list of SR-IOV NICs.
- [PR #7421][rmohr] Fix knowhosts file corruption for virtctl ssh
- [PR #6854][rmohr] Make virtctl ssh work with ssh-rsa+ preauthentication
- [PR #7267][iholder-redhat] Applied migration configurations can now be found in VMI's status
- [PR #7321][iholder-redhat] [Migration Policies]: precedence to VMI labels over Namespace labels
- [PR #7326][oshoval] The Ginkgo dependency has been upgraded to v2.1.3 (major version upgrade)
- [PR #7361][SeanKnight] Fixed a bug that prevents virtctl from working with clusters accessed via Rancher authentication proxy, or any other cluster where the server URL contains a path component. (#3760)
- [PR #7255][tyleraharrison] Users are now able to specify `--address [ip_address]` when using `virtctl vnc` rather than only using 127.0.0.1
- [PR #7275][enp0s3] Add observedGeneration to virt-operator to have a race-free way to detect KubeVirt config rollouts
- [PR #7233][xpivarc] Bug fix: Successfully aborted migrations should be reported now
- [PR #7158][AlonaKaplan] Add masquerade VMs support to single stack IPv6.
- [PR #7227][rmohr] Remove VMI informer from virt-api to improve scaling characteristics of virt-api
- [PR #7288][raspbeep] Users now don't need to specify container for `kubectl logs <vmi-pod>` and `kubectl exec <vmi-pod>`.
- [PR #6709][xpivarc] Workloads will be migrated to nonroot implementation if NonRoot feature gate is set. (Except VirtioFS)
- [PR #7241][lyarwood] Fixed a bug that prevents only a unattend.xml configmap or secret being provided as contents for a sysprep disk. (#7240, @lyarwood)

## v0.51.0

Released on: Tue Mar 8 21:06:59 2022 +0000

- [PR #7102][machadovilaca] Add Virtual Machine name label to virt-launcher pod
- [PR #7139][davidvossel] Fixes inconsistent VirtualMachinePool VM/VMI updates by using controller revisions
- [PR #6754][jean-edouard] New and resized disks are now always 1MiB-aligned
- [PR #7086][acardace] Add 'EvictionStrategy' as a cluster-wide setting in the KubeVirt CR
- [PR #7232][rmohr] Properly format the PDB scale event during migrations
- [PR #7223][Barakmor1] Add a name label to virt-operator pods
- [PR #7221][davidvossel] RunStrategy: Once - allows declaring a VM should run once to a finalized state
- [PR #7091][EdDev] SR-IOV interfaces are now reported in the VMI status even without an active guest-agent.
- [PR #7169][rmohr] Improve device plugin de-registration in virt-handler and some test stabilizations
- [PR #6604][alicefr] Add shareable option to identify if the disk is shared with other VMs
- [PR #7144][davidvossel] Garbage collect finalized migration objects only leaving the most recent 5 objects
- [PR #6110][xpivarc] [Nonroot] SRIOV is now available.

## v0.50.0

Released on: Wed Feb 9 18:01:08 2022 +0000

- [PR #7056][fossedihelm] Update k8s dependencies to 0.23.1
- [PR #7135][davidvossel] Switch from reflects.DeepEquals to equality.Semantic.DeepEquals() across the entire project
- [PR #7052][sradco] Updated recording rule "kubevirt_vm_container_free_memory_bytes"
- [PR #7000][iholder-redhat] Adds a possibility to override default libvirt log filters though VMI annotations
- [PR #7064][davidvossel] Fixes issue associated with blocked uninstalls when VMIs exist during removal
- [PR #7097][iholder-redhat] [Bug fix] VMI with kernel boot stuck on "Terminating" status if more disks are defined
- [PR #6700][VirrageS] Simplify replacing `time.Ticker` in agent poller and fix default values for `qemu-*-interval` flags
- [PR #6581][ormergi] SRIOV network interfaces are now hot-plugged when disconnected manually or due to aborted migrations.
- [PR #6924][EdDev] Support for legacy GPU definition is removed. Please see https://kubevirt.io/user-guide/virtual_machines/host-devices on how to define host-devices.
- [PR #6735][uril] The command `migrate_cancel` was added to virtctl. It cancels an active VM migration.
- [PR #6883][rthallisey] Add instance-type to cloud-init metadata
- [PR #6999][maya-r] When expanding disk images, take the minimum between the request and the capacity - avoid using the full underlying file system on storage like NFS, local.
- [PR #6946][vladikr] Numa information of an assigned device will be presented in the devices metadata
- [PR #6042][iholder-redhat] Fully support cgroups v2, include a new cohesive package and perform major refactoring.
- [PR #6968][vladikr] Added Writeback disk cache support
- [PR #6995][sradco] Alert OrphanedVirtualMachineImages name was changed to OrphanedVirtualMachineInstances.
- [PR #6923][rhrazdil] Fix issue with ssh being unreachable on VMIs with Istio proxy
- [PR #6821][jean-edouard] Migrating VMIs that contain dedicated CPUs will now have properly dedicated CPUs on target
- [PR #6793][oshoval] Add infoSource field to vmi.status.interfaces.

## v0.49.0

Released on: Tue Jan 11 17:27:09 2022 +0000

- [PR #7004][iholder-redhat] Bugfix: Avoid setting block migration for volumes used by read-only disks
- [PR #6959][enp0s3] generate event when target pod enters unschedulable phase
- [PR #6888][assafad] Added common labels into alert definitions
- [PR #6166][vasiliy-ul] Experimental support of AMD SEV
- [PR #6980][vasiliy-ul] Updated the dependencies to include the fix for CVE-2021-43565 (KubeVirt is not affected)
- [PR #6944][iholder-redhat] Remove disabling TLS configuration from Live Migration Policies
- [PR #6800][jean-edouard] CPU pinning doesn't require hardware-assisted virtualization anymore
- [PR #6501][ShellyKa13] Use virtctl image-upload to upload archive content
- [PR #6918][iholder-redhat] Bug fix: Unscheduable host-model VMI alert is now properly triggered
- [PR #6796][Barakmor1] 'kubevirt-operator' changed to 'virt-operator' on 'managed-by' label in kubevirt's components made by virt-operator
- [PR #6036][jean-edouard] Migrations can now be done over a dedicated multus network
- [PR #6933][erkanerol] Add a new lane for monitoring tests
- [PR #6949][jean-edouard] KubeVirt components should now be successfully removed on CR deletion, even when using only 1 replica for virt-api and virt-controller
- [PR #6954][maiqueb] Update the `virtctl` exposed services `IPFamilyPolicyType` default to `IPFamilyPolicyPreferDualStack`
- [PR #6931][fossedihelm] added DryRun to AddVolumeOptions and RemoveVolumeOptions
- [PR #6379][nunnatsa] Fix issue https://bugzilla.redhat.com/show_bug.cgi?id=1945593
- [PR #6399][iholder-redhat] Introduce live migration policies that allow system-admins to have fine-grained control over migration configuration for different sets of VMs.
- [PR #6880][iholder-redhat] Add full Podman support for `make` and `make test`
- [PR #6702][acardace] implement virt-handler canary upgrade and rollback for faster and safer rollouts
- [PR #6717][davidvossel] Introducing the VirtualMachinePools feature for managing stateful VMs at scale
- [PR #6698][rthallisey] Add tracing to the virt-controller work queue
- [PR #6762][fossedihelm] added DryRun mode to virtcl to migrate command
- [PR #6891][rmohr] Fix "Make raw terminal failed: The handle is invalid?" issue with "virtctl console" when not executed in a pty
- [PR #6783][rmohr] Skip SSH RSA auth if no RSA key was explicitly provided and not key exists at the default location

## v0.48.1

Released on: Wed Dec 15 15:11:55 2021 +0000

- [PR #6900][kubevirt-bot] Skip SSH RSA auth if no RSA key was explicitly provided and not key exists at the default location
- [PR #6902][kubevirt-bot] Fix "Make raw terminal failed: The handle is invalid?" issue with "virtctl console" when not executed in a pty

## v0.48.0

Released on: Mon Dec 6 18:26:51 2021 +0000

- [PR #6670][futuretea] Added 'virtctl soft-reboot' command to reboot the VMI.
- [PR #6861][orelmisan] virtctl errors are written to stderr instead of stdout
- [PR #6836][enp0s3] Added PHASE and VMI columns for the 'kubectl get vmim' CLI output
- [PR #6784][nunnatsa] kubevirt-config configMap is no longer supported for KubeVirt configuration
- [PR #6839][ShellyKa13] fix restore of VM with RunStrategy
- [PR #6533][zcahana] Paused VMIs are now marked as unready even when no readinessProbe is specified
- [PR #6858][rmohr] Fix a nil pointer in virtctl in combination with some external auth plugins
- [PR #6780][fossedihelm] Add PatchOptions to the Patch request of the VirtualMachineInstanceInterface
- [PR #6773][iholder-redhat] alert if migration for VMI with host-model CPU is stuck since no node is suitable
- [PR #6714][rhrazdil] Shorten timeout for Istio proxy detection
- [PR #6725][fossedihelm] added DryRun mode to virtcl for pause and unpause commands
- [PR #6737][davidvossel] Pending migration target pods timeout after 5 minutes when unschedulable
- [PR #6814][fossedihelm] Changed some terminology to be more inclusive
- [PR #6649][Barakmor1] Designate the apps.kubevirt.io/component label for KubeVirt components.
- [PR #6650][victortoso] Introduces support to ich9 or ac97 sound devices
- [PR #6734][Barakmor1] replacing the command that extract libvirtd's pid  to avoid this error:
- [PR #6802][rmohr] Maintain a separate api package which synchronizes to kubevirt.io/api for better third party integration with client-gen
- [PR #6730][zhhray] change kubevrit cert secret type from Opaque to kubernetes.io/tls
- [PR #6508][oshoval] Add missing domain to guest search list, in case subdomain is used.
- [PR #6664][vladikr] enable the display and ramfb for vGPUs by default
- [PR #6710][iholder-redhat] virt-launcher fix - stop logging successful shutdown when it isn't true
- [PR #6162][vladikr] KVM_HINTS_REALTIME will always be set when dedicatedCpusPlacement is requested
- [PR #6772][zcahana] Bugfix: revert #6565 which prevented upgrades to v0.47.
- [PR #6722][zcahana] Remove obsolete scheduler.alpha.kubernetes.io/critical-pod annotation
- [PR #6723][acardace] remove stale pdbs created by < 0.41.1 virt-controller
- [PR #6721][iholder-redhat] Set default CPU model in VMI spec, even if not defined in KubevirtCR
- [PR #6713][zcahana] Report WaitingForVolumeBinding VM status when PVC/DV-type volumes reference unbound PVCs
- [PR #6681][fossedihelm] Users can use --dry-run flag
- [PR #6663][jean-edouard] The number of virt-api and virt-controller replicas is now configurable in the CSV
- [PR #5981][maya-r] Always resize disk.img files to the largest size at boot.

## v0.47.1

Released on: Thu Nov 11 15:52:59 2021 +0000

- [PR #6775][kubevirt-bot] Bugfix: revert #6565 which prevented upgrades to v0.47.
- [PR #6703][mhenriks] Fix BZ 2018521 - On upgrade VirtualMachineSnapshots going to Failed
- [PR #6511][knopt] Fixed virt-api significant memory usage when using Cluster Profiler with large KubeVirt deployments. (#6478, @knopt)
- [PR #6629][awels] BugFix: Hotplugging more than one block device would cause IO error (#6564)
- [PR #6657][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 7.6.0 and QEMU 6.0.0.
- [PR #6565][Barakmor1] 'kubevirt-operator' changed to 'virt-operator' on 'managed-by' label in kubevirt's components made by virt-operator
- [PR #6642][ShellyKa13] Include hot-plugged disks in a Online VM Snapshot
- [PR #6513][brybacki] Adds force-bind flag to virtctl imageupload
- [PR #6588][erkanerol] Fix recording rules based on up metrics
- [PR #6575][davidvossel] VM controller now syncs VMI conditions to corresponding VM object
- [PR #6661][rmohr] Make the kubevirt api compatible with client-gen to make selecting compatible k8s golang dependencies easier
- [PR #6535][rmohr] Migrations use digests to reference containerDisks and kernel boot images to ensure disk consistency
- [PR #6651][ormergi] Kubevirt Conformance plugin now supports passing tests images registry.
- [PR #6589][iholder-redhat] custom kernel / initrd to boot from is now pre-pulled which improves stability
- [PR #6199][ormergi] Kubevirt Conformance plugin now supports passing image tag or digest
- [PR #6477][zcahana] Report DataVolumeError VM status when referenced a DataVolume indicates an error
- [PR #6593][rhrazdil] Removed python dependencies from virt-launcher and virt-handler containers
- [PR #6026][akrejcir] Implemented minimal VirtualMachineFlavor functionality.
- [PR #6570][erkanerol] Use honorLabels instead of labelDrop for namespace label on metrics
- [PR #6182][jordigilh] adds support for real time workloads
- [PR #6177][rmohr] Switch the node base images to centos8 stream
- [PR #6171][zcahana] Report ErrorPvcNotFound/ErrorDataVolumeNotFound VM status when PVC/DV-type volumes reference non-existent objects
- [PR #6437][VirrageS] Fix deprecated use of watch API to prevent reporting incorrect metrics.
- [PR #6482][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #6375][dhiller] Rely on kubevirtci installing cdi during testing

## v0.46.1

Released on: Tue Oct 19 15:41:10 2021 +0000

- [PR #6557][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions

## v0.46.0

Released on: Fri Oct 8 21:12:33 2021 +0000

- [PR #6425][awels] Hotplug disks are possible when iothreads are enabled.
- [PR #6297][acardace] mutate migration PDBs instead of creating an additional one for the duration of the migration.
- [PR #6464][awels] BugFix: Fixed hotplug race between kubelet and virt-handler when virt-launcher dies unexpectedly.
- [PR #6465][salanki] Fix corrupted DHCP Gateway Option from local DHCP server, leading to rejected IP configuration on Windows VMs.
- [PR #6458][vladikr] Tagged SR-IOV interfaces will now appear in the config drive metadata
- [PR #6446][brybacki] Access mode for virtctl image upload is now optional. This version of virtctl now requires CDI v1.34 or greater
- [PR #6391][zcahana] Cleanup obsolete permissions from virt-operator's ClusterRole
- [PR #6419][rthallisey] Fix virt-controller panic caused by lots of deleted VMI events
- [PR #5972][kwiesmueller] Add a `ssh` command to `virtctl` that can be used to open SSH sessions to VMs/VMIs.
- [PR #6403][jrife] Removed go module pinning to an old version (v0.3.0) of github.com/go-kit/kit
- [PR #6367][brybacki] virtctl imageupload now uses DataVolume.spec.storage
- [PR #6198][iholder-redhat] Fire a Prometheus alert when a lot of REST failures are detected in virt-api
- [PR #6211][davidvossel] cluster-profiler pprof gathering tool and corresponding "ClusterProfiler" feature gate
- [PR #6323][vladikr] switch live migration to use unix sockets
- [PR #6374][vladikr] Fix the default setting of CPU requests on vmipods
- [PR #6283][rthallisey] Record the time it takes to delete a VMI and expose it as a metric
- [PR #6251][rmohr] Better place vcpu threads on host cpus to form more efficient passthrough architectures
- [PR #6377][rmohr] Don't fail on failed selinux relabel attempts if selinux is permissive
- [PR #6308][awels] BugFix: hotplug was broken when using it with a hostpath volume that was on a separate device.
- [PR #6186][davidvossel] Add resource and verb labels to rest_client_requests_total metric

## v0.45.1

Released on: Tue Oct 19 15:39:42 2021 +0000

- [PR #6537][kubevirt-bot] Fix corrupted DHCP Gateway Option from local DHCP server, leading to rejected IP configuration on Windows VMs.
- [PR #6556][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #6480][kubevirt-bot] BugFix: Fixed hotplug race between kubelet and virt-handler when virt-launcher dies unexpectedly.
- [PR #6384][kubevirt-bot] Better place vcpu threads on host cpus to form more efficient passthrough architectures

## v0.45.0

Released on: Wed Sep 8 13:56:47 2021 +0000

- [PR #6191][marceloamaral] Addition of perfscale-load-generator to perform stress tests to evaluate the control plane
- [PR #6248][VirrageS] Reduced logging in hot paths
- [PR #6079][weihanglo] Hotplug volume can be unplugged at anytime and reattached after a VM restart.
- [PR #6101][rmohr] Make k8s client rate limits configurable
- [PR #6204][sradco] This PR adds to each alert the runbook url that points to a runbook that provides additional details on each alert and how to mitigate it.
- [PR #5974][vladikr] a list of desired mdev types can now be provided in KubeVirt CR to kubevirt to configure these devices on relevant nodes
- [PR #6147][rmohr] Fix rbac permissions for freeze/unfreeze, addvolume/removevolume, guestosinfo, filesystemlist and userlist
- [PR #6161][ashleyschuett] Remove HostDevice validation on VMI creation
- [PR #6078][zcahana] Report ErrImagePull/ImagePullBackOff VM status when image pull errors occur
- [PR #6176][kwiesmueller] Fix goroutine leak in virt-handler, potentially causing issues with a high turnover of VMIs.
- [PR #6047][ShellyKa13] Add phases to the vm snapshot api, specifically a failure phase
- [PR #6138][ansijain] NA

## v0.44.3

Released on: Tue Oct 19 15:38:22 2021 +0000

- [PR #6518][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #6532][kubevirt-bot] mutate migration PDBs instead of creating an additional one for the duration of the migration.
- [PR #6536][kubevirt-bot] Fix corrupted DHCP Gateway Option from local DHCP server, leading to rejected IP configuration on Windows VMs.

## v0.44.2

Released on: Thu Oct 7 12:55:34 2021 +0000

- [PR #6479][kubevirt-bot] BugFix: Fixed hotplug race between kubelet and virt-handler when virt-launcher dies unexpectedly.
- [PR #6392][rmohr] Better place vcpu threads on host cpus to form more efficient passthrough architectures
- [PR #6251][rmohr] Better place vcpu threads on host cpus to form more efficient passthrough architectures
- [PR #6344][kubevirt-bot] BugFix: hotplug was broken when using it with a hostpath volume that was on a separate device.
- [PR #6263][rmohr] Make k8s client rate limits configurable
- [PR #6207][kubevirt-bot] Fix goroutine leak in virt-handler, potentially causing issues with a high turnover of VMIs.
- [PR #6101][rmohr] Make k8s client rate limits configurable
- [PR #6249][kubevirt-bot] Fix rbac permissions for freeze/unfreeze, addvolume/removevolume, guestosinfo, filesystemlist and userlist

## v0.44.1

Released on: Thu Aug 12 12:28:02 2021 +0000

- [PR #6219][kubevirt-bot] Add phases to the vm snapshot api, specifically a failure phase

## v0.44.0

Released on: Mon Aug 9 14:20:14 2021 +0000

- [PR #6058][acardace] Fix virt-launcher exit pod race condition
- [PR #6035][davidvossel] Addition of perfscale-audit tool for auditing performance of control plane during stress tests
- [PR #6145][acardace] virt-launcher: disable unencrypted TCP socket for libvirtd.
- [PR #6163][davidvossel] Handle qemu processes in defunc (zombie) state
- [PR #6105][ashleyschuett] Add VirtualMachineInstancesPerNode to KubeVirt CR under Spec.Configuration
- [PR #6104][zcahana] Report FailedUnschedulable VM status when scheduling errors occur
- [PR #5905][davidvossel] VM CrashLoop detection and Exponential Backoff
- [PR #6070][acardace] Initiate Live-Migration using a unix socket (exposed by virt-handler) instead of an additional TCP<->Unix migration proxy started by virt-launcher
- [PR #5728][vasiliy-ul] Live migration of VMs with hotplug volumes is now enabled
- [PR #6109][rmohr] Fix virt-controller SCC: Reflect the need for NET_BIND_SERVICE in the virt-controller SCC.
- [PR #5942][ShellyKa13] Integrate guest agent to online VM snapshot
- [PR #6034][ashleyschuett] Go version updated to version 1.16.6
- [PR #6040][yuhaohaoyu] Improved debuggability by keeping the environment of a failed VMI alive.
- [PR #6068][dhiller] Add check that not all tests have been skipped
- [PR #6041][xpivarc] [Experimental] Virt-launcher can run as non-root user
- [PR #6062][iholder-redhat] replace dead "stress" binary with new, maintained, "stress-ng" binary
- [PR #6029][mhenriks] CDI to 1.36.0 with DataSource support
- [PR #4089][victortoso] Add support to USB Redirection with usbredir
- [PR #5946][vatsalparekh] Add guest-agent based ping probe
- [PR #6005][acardace] make containerDisk validation memory usage limit configurable
- [PR #5791][zcahana] Added a READY column to the tabular output of "kubectl get vm/vmi"
- [PR #6006][awels] DataVolumes created by DataVolumeTemplates will follow the associated VMs priority class.
- [PR #5982][davidvossel] Reduce vmi Update collisions (http code 409) during startup
- [PR #5891][akalenyu] BugFix: Pending VMIs when creating concurrent bulk of VMs backed by WFFC DVs
- [PR #5925][rhrazdil] Fix issue with Windows VMs not being assigned IP address configured in network-attachment-definition IPAM.
- [PR #6007][rmohr] Fix: The bandwidth limitation on migrations is no longer ignored. Caution: The default bandwidth limitation of 64Mi is changed to "unlimited" to not break existing installations.
- [PR #4944][kwiesmueller] Add `/portforward` subresource to `VirtualMachine` and `VirtualMachineInstance` that can tunnel TCP traffic through the API Server using a websocket stream.
- [PR #5402][alicefr] Integration of libguestfs-tools and added new command `guestfs` to virtctl
- [PR #5953][ashleyschuett] Allow Failed VMs to be stopped when using `--force --gracePeriod 0`
- [PR #5876][mlsorensen] KubeVirt CR supports specifying a runtime class for virt-launcher pods via 'launcherRuntimeClass'.

## v0.43.1

Released on: Tue Oct 19 15:36:32 2021 +0000

- [PR #6555][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #6052][kubevirt-bot] make containerDisk validation memory usage limit configurable

## v0.43.0

Released on: Fri Jul 9 15:46:22 2021 +0000

- [PR #5952][mhenriks] Use CDI beta API. CDI v1.20.0 is now the minimum requirement for kubevirt.
- [PR #5846][rmohr] Add "spec.cpu.numaTopologyPassthrough" which allows emulating a host-alligned virtual numa topology for high performance
- [PR #5894][rmohr] Add `spec.migrations.disableTLS` to the KubeVirt CR to allow disabling encrypted migrations. They stay secure by default.
- [PR #5649][awels] Enhancement: remove one attachment pod per disk limit (behavior on upgrade with running VM with hotplugged disks is undefined)
- [PR #5742][rmohr] VMIs which choose evictionStrategy `LifeMigrate` and request the `invtsc` cpuflag are now live-migrateable
- [PR #5911][dhiller] Bumps kubevirtci, also suppresses kubectl.sh output to avoid confusing checks
- [PR #5863][xpivarc] Fix: ioerrors don't cause crash-looping of notify server
- [PR #5867][mlsorensen] New build target added to export virt-* images as a tar archive.
- [PR #5766][davidvossel] Addition of kubevirt_vmi_phase_transition_seconds_since_creation to monitor how long it takes to transition a VMI to a specific phase from creation time.
- [PR #5823][dhiller] Change default branch to `main` for `kubevirt/kubevirt` repository
- [PR #5763][nunnatsa] Fix bug 1945589: Prevent migration of VMIs that uses virtiofs
- [PR #5827][mlsorensen] Auto-provisioned disk images on empty PVCs now leave 128KiB unused to avoid edge cases that run the volume out of space.
- [PR #5849][davidvossel] Fixes event recording causing a segfault in virt-controller
- [PR #5797][rhrazdil] Add serviceAccountDisk automatically when Istio is enabled in VMI annotations
- [PR #5723][ashleyschuett] Allow virtctl to stop VM and ignore the graceful shutdown period
- [PR #5806][mlsorensen] configmap, secret, and cloud-init raw disks now work when underlying node storage has 4k blocks.
- [PR #5623][iholder-redhat] [bugfix]: Allow migration of VMs with host-model CPU to migrate only for compatible nodes
- [PR #5716][rhrazdil] Fix issue with virt-launcher becoming `NotReady` after migration when Istio is used.
- [PR #5778][ashleyschuett] Update ca-bundle if it is unable to be parsed
- [PR #5787][acardace] migrated references of authorization/v1beta1 to authorization/v1
- [PR #5461][rhrazdil] Add support for Istio proxy when no explicit ports are specified on masquerade interface
- [PR #5751][acardace] EFI VMIs with secureboot disabled can now be booted even when only OVMF_CODE.secboot.fd and OVMF_VARS.fd are present in the virt-launcher image
- [PR #5629][andreyod] Support starting Virtual Machine with its guest CPU paused using `virtctl start --paused`
- [PR #5725][dhiller] Generate REST API coverage report after functional tests
- [PR #5758][davidvossel] Fixes kubevirt_vmi_phase_count to include all phases, even those that occur before handler hand off.
- [PR #5745][ashleyschuett] Alert with resource usage exceeds resource requests
- [PR #5759][mhenriks] Update CDI to 1.34.1
- [PR #5038][kwiesmueller] Add exec command to VM liveness and readinessProbe executed through the qemu-guest-agent.
- [PR #5431][alonSadan] Add NFT and IPTables rules to allow port-forward to non-declared ports on the VMI. Declaring ports on VMI will limit

## v0.42.2

Released on: Tue Oct 19 15:34:37 2021 +0000

- [PR #6554][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #5887][ashleyschuett] Allow virtctl to stop VM and ignore the graceful shutdown period
- [PR #5907][kubevirt-bot] Fix: ioerrors don't cause crash-looping of notify server
- [PR #5871][maiqueb] Fix: do not override with the DHCP server advertising IP with the gateway info.
- [PR #5875][kubevirt-bot] Update ca-bundle if it is unable to be parsed

## v0.42.1

Released on: Thu Jun 10 01:31:52 2021 +0000

- [PR #5738][rmohr] Stop releasing jinja2 templates of our operator. Kustomize is the preferred way for customizations.
- [PR #5691][ashleyschuett] Allow multiple shutdown events to ensure the event is received by ACPI
- [PR #5558][ormergi] Drop virt-launcher SYS_RESOURCE capability
- [PR #5694][davidvossel] Fixes null pointer dereference in migration controller
- [PR #5416][iholder-redhat] [feature] support booting VMs from a custom kernel/initrd images with custom kernel arguments
- [PR #5495][iholder-redhat] Go version updated to version 1.16.1.
- [PR #5502][rmohr] Add downwardMetrics volume to expose a limited set of hots metrics to guests
- [PR #5601][maya-r] Update libvirt-go to 7.3.0
- [PR #5661][davidvossel] Validation/Mutation webhooks now explicitly define a 10 second timeout period
- [PR #5652][rmohr] Automatically discover kube-prometheus installations and configure kubevirt monitoring
- [PR #5631][davidvossel] Expand backport policy to include logging and debug fixes
- [PR #5528][zcahana] Introduced a "status.printableStatus" field in the VirtualMachine CRD. This field is now displayed in the tabular output of "kubectl get vm".
- [PR #5200][rhrazdil] Add support for Istio proxy traffic routing with masquerade interface. nftables is required for this feature.
- [PR #5560][oshoval] virt-launcher now populates domain's guestOS info and interfaces status according guest agent also when doing periodic resyncs.
- [PR #5514][rhrazdil] Fix live-migration failing when VM with masquarade iface has explicitly specified any of these ports: 22222, 49152, 49153
- [PR #5583][dhiller] Reenable coverage
- [PR #5129][davidvossel] Gracefully shutdown virt-api connections and ensure zero exit code under normal shutdown conditions
- [PR #5582][dhiller] Fix flaky unit tests
- [PR #5600][davidvossel] Improved logging around VM/VMI shutdown and restart
- [PR #5564][omeryahud] virtctl rename support is dropped
- [PR #5585][iholder-redhat] [bugfix] - reject VM defined with volume with no matching disk
- [PR #5595][zcahana] Fixes adoption of orphan DataVolumes
- [PR #5566][davidvossel] Release branches are now cut on the first _business day_ of the month rather than the first day.
- [PR #5108][Omar007] Fixes handling of /proc/<pid>/mountpoint by working on the device information instead of mount information
- [PR #5250][mlsorensen] Controller health checks will no longer actively test connectivity to the Kubernetes API. They will rely in health of their watches to determine if they have API connectivity.
- [PR #5563][ashleyschuett] Set KubeVirt resources flags in the KubeVirt CR
- [PR #5328][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 7.0.0 and QEMU 5.2.0.

## v0.42.0

Released on: Tue Jun 8 12:09:49 2021 +0000

- [PR #5738][rmohr] Stop releasing jinja2 templates of our operator. Kustomize is the preferred way for customizations.
- [PR #5691][ashleyschuett] Allow multiple shutdown events to ensure the event is received by ACPI
- [PR #5558][ormergi] Drop virt-launcher SYS_RESOURCE capability
- [PR #5694][davidvossel] Fixes null pointer dereference in migration controller
- [PR #5416][iholder-redhat] [feature] support booting VMs from a custom kernel/initrd images with custom kernel arguments
- [PR #5495][iholder-redhat] Go version updated to version 1.16.1.
- [PR #5502][rmohr] Add downwardMetrics volume to expose a limited set of hots metrics to guests
- [PR #5601][maya-r] Update libvirt-go to 7.3.0
- [PR #5661][davidvossel] Validation/Mutation webhooks now explicitly define a 10 second timeout period
- [PR #5652][rmohr] Automatically discover kube-prometheus installations and configure kubevirt monitoring
- [PR #5631][davidvossel] Expand backport policy to include logging and debug fixes
- [PR #5528][zcahana] Introduced a "status.printableStatus" field in the VirtualMachine CRD. This field is now displayed in the tabular output of "kubectl get vm".
- [PR #5200][rhrazdil] Add support for Istio proxy traffic routing with masquerade interface. nftables is required for this feature.
- [PR #5560][oshoval] virt-launcher now populates domain's guestOS info and interfaces status according guest agent also when doing periodic resyncs.
- [PR #5514][rhrazdil] Fix live-migration failing when VM with masquarade iface has explicitly specified any of these ports: 22222, 49152, 49153
- [PR #5583][dhiller] Reenable coverage
- [PR #5129][davidvossel] Gracefully shutdown virt-api connections and ensure zero exit code under normal shutdown conditions
- [PR #5582][dhiller] Fix flaky unit tests
- [PR #5600][davidvossel] Improved logging around VM/VMI shutdown and restart
- [PR #5564][omeryahud] virtctl rename support is dropped
- [PR #5585][iholder-redhat] [bugfix] - reject VM defined with volume with no matching disk
- [PR #5595][zcahana] Fixes adoption of orphan DataVolumes
- [PR #5566][davidvossel] Release branches are now cut on the first _business day_ of the month rather than the first day.
- [PR #5108][Omar007] Fixes handling of /proc/<pid>/mountpoint by working on the device information instead of mount information
- [PR #5250][mlsorensen] Controller health checks will no longer actively test connectivity to the Kubernetes API. They will rely in health of their watches to determine if they have API connectivity.
- [PR #5563][ashleyschuett] Set KubeVirt resources flags in the KubeVirt CR
- [PR #5328][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 7.0.0 and QEMU 5.2.0.

## v0.41.4

Released on: Tue Oct 19 15:31:59 2021 +0000

- [PR #6573][acardace] mutate migration PDBs instead of creating an additional one for the duration of the migration.
- [PR #6517][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #6333][acardace] Fix virt-launcher exit pod race condition
- [PR #6401][rmohr] Fix rbac permissions for freeze/unfreeze, addvolume/removevolume, guestosinfo, filesystemlist and userlist
- [PR #6147][rmohr] Fix rbac permissions for freeze/unfreeze, addvolume/removevolume, guestosinfo, filesystemlist and userlist
- [PR #5673][kubevirt-bot] Improved logging around VM/VMI shutdown and restart
- [PR #6227][kwiesmueller] Fix goroutine leak in virt-handler, potentially causing issues with a high turnover of VMIs.

## v0.41.3

Released on: Thu Aug 12 16:35:43 2021 +0000

- [PR #6196][ashleyschuett] Allow multiple shutdown events to ensure the event is received by ACPI
- [PR #6194][kubevirt-bot] Allow Failed VMs to be stopped when using `--force --gracePeriod 0`
- [PR #6039][akalenyu] BugFix: Pending VMIs when creating concurrent bulk of VMs backed by WFFC DVs
- [PR #5917][davidvossel] Fixes event recording causing a segfault in virt-controller
- [PR #5886][ashleyschuett] Allow virtctl to stop VM and ignore the graceful shutdown period
- [PR #5866][xpivarc] Fix: Kubevirt build with golang 1.14+ will not fail on validation of container disk with memory allocation error
- [PR #5873][kubevirt-bot] Update ca-bundle if it is unable to be parsed
- [PR #5822][kubevirt-bot] migrated references of authorization/v1beta1 to authorization/v1
- [PR #5704][davidvossel] Fix virt-controller clobbering in progress vmi migration state during virt handler handoff
- [PR #5707][kubevirt-bot] Fixes null pointer dereference in migration controller
- [PR #5685][stu-gott] [bugfix] - reject VM defined with volume with no matching disk
- [PR #5670][stu-gott] Validation/Mutation webhooks now explicitly define a 10 second timeout period
- [PR #5653][kubevirt-bot] virt-launcher now populates domain's guestOS info and interfaces status according guest agent also when doing periodic resyncs.
- [PR #5644][kubevirt-bot] Fix live-migration failing when VM with masquarade iface has explicitly specified any of these ports: 22222, 49152, 49153
- [PR #5646][kubevirt-bot] virtctl rename support is dropped

## v0.41.2

Released on: Wed Jul 28 12:13:19 2021 -0400

## v0.41.1

Released on: Wed Jul 28 12:08:42 2021 -0400

## v0.41.0

Released on: Wed May 12 14:30:49 2021 +0000

- [PR #5586][kubevirt-bot] This version of KubeVirt includes upgraded virtualization technology based on libvirt 7.0.0 and QEMU 5.2.0.
- [PR #5344][ashleyschuett] Reconcile PrometheusRules and ServiceMonitor resources
- [PR #5542][andreyod] Add startStrategy field to VMI spec to allow Virtual Machine start in paused state.
- [PR #5459][ashleyschuett] Reconcile service resource
- [PR #5520][ashleyschuett] Reconcile required labels and annotations on ConfigMap resources
- [PR #5533][rmohr] Fix `docker save` and `docker push` issues with released kubevirt images
- [PR #5428][oshoval] virt-launcher now populates domain's guestOS info and interfaces status according guest agent also when doing periodic resyncs.
- [PR #5410][ashleyschuett] Reconcile ServiceAccount resources
- [PR #5109][Omar007] Add support for specifying a logical and physical block size for disk devices
- [PR #5471][ashleyschuett] Reconcile APIService resources
- [PR #5513][ashleyschuett] Reconcile Secret resources
- [PR #5496][davidvossel] Improvements to migration proxy logging
- [PR #5376][ashleyschuett] Reconcile CustomResourceDefinition resources
- [PR #5435][AlonaKaplan] Support dual stack service on "virtctl expose"-
- [PR #5425][davidvossel] Fixes VM restart during eviction when EvictionStrategy=LiveMigrate
- [PR #5423][ashleyschuett] Add resource requests to virt-controller, virt-api, virt-operator and virt-handler
- [PR #5343][erkanerol] Some cleanups and small additions to the storage metrics
- [PR #4682][stu-gott] Updated Guest Agent Version compatibility check. The new approach is much more accurate.
- [PR #5485][rmohr] Fix fallback to iptables if nftables is not used on the host on arm64
- [PR #5426][rmohr] Fix fallback to iptables if nftables is not used on the host
- [PR #5403][tiraboschi] Added a kubevirt_ prefix to several recording rules and metrics
- [PR #5241][stu-gott] Introduced Duration and RenewBefore parameters for cert rotation. Previous values are now deprecated.
- [PR #5463][acardace] Fixes upgrades from KubeVirt v0.36
- [PR #5456][zhlhahaha] Enable arm64 cross-compilation
- [PR #3310][davidvossel] Doc outlines our Kubernetes version compatibility commitment
- [PR #3383][EdDev] Add `vmIPv6NetworkCIDR` under `NetworkSource.pod` to support custom IPv6 CIDR for the vm network when using masquerade binding.
- [PR #3415][zhlhahaha] Make kubevirt code fit for arm64 support. No testing is at this stage performed against arm64 at this point.
- [PR #5147][xpivarc] Remove CAP_NET_ADMIN from the virt-launcher pod(second take).
- [PR #5351][awels] Support hotplug with virtctl using addvolume and removevolume commands
- [PR #5050][ashleyschuett] Fire Prometheus Alert when a vmi is orphaned for more than an hour

## v0.40.1

Released on: Tue Oct 19 13:33:33 2021 +0000

- [PR #6598][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #6287][kubevirt-bot] Fix goroutine leak in virt-handler, potentially causing issues with a high turnover of VMIs.
- [PR #5559][kubevirt-bot] Fix `docker save` issues with kubevirt images
- [PR #5500][kubevirt-bot] Support hotplug with virtctl using addvolume and removevolume commands

## v0.40.0

Released on: Mon Apr 19 12:25:41 2021 +0000

- [PR #5467][rmohr] Fixes upgrades from KubeVirt v0.36
- [PR #5350][jean-edouard] Removal of entire `permittedHostDevices` section will now remove all user-defined host device plugins.
- [PR #5242][jean-edouard] Creating more than 1 migration at the same time for a given VMI will now fail
- [PR #4907][vasiliy-ul] Initial cgroupv2 support
- [PR #5324][jean-edouard] Default feature gates can now be defined in the provider configuration.
- [PR #5006][alicefr] Add discard=unmap option
- [PR #5022][davidvossel] Fixes race condition between operator adding service and webhooks that can result in installs/uninstalls failing
- [PR #5310][ashleyschuett] Reconcile CRD resources
- [PR #5102][iholder-redhat] Go version updated to 1.14.14
- [PR #4746][ashleyschuett] Reconcile Deployments, DaemonSets, MutatingWebhookConfigurations and ValidatingWebhookConfigurations
- [PR #5037][ormergi] Hot-plug SR-IOV VF interfaces to VM's post a successful migration.
- [PR #5269][mlsorensen] Prometheus metrics scraped from virt-handler are now served from the VMI informer cache, rather than calling back to the Kubernetes API for VMI information.
- [PR #5138][davidvossel] virt-handler now waits up to 5 minutes for all migrations on the node to complete before shutting down.
- [PR #5191][yuvalturg] Added a metric for monitoring CPU affinity
- [PR #5215][xphyr] Enable detection of Intel GVT-g vGPU.
- [PR #4760][rmohr] Make virt-handler heartbeat more efficient and robust: Only one combined PATCH and no need to detect different cluster types anymore.
- [PR #5091][iholder-redhat] QEMU SeaBios debug logs are being seen as part of virt-launcher log.
- [PR #5221][rmohr] Remove  workload placement validation webhook which blocks placement updates when VMIs are running
- [PR #5128][yuvalturg] Modified memory related metrics by adding several new metrics and splitting the swap traffic bytes metric
- [PR #5084][ashleyschuett] Add validation to CustomizeComponents object on the KubeVirt resource
- [PR #5182][davidvossel] New [release-blocker] functional test marker to signify tests that can never be disabled before making a release
- [PR #5137][davidvossel] Added our policy around release branch backporting in docs/release-branch-backporting.md
- [PR #5096][yuvalturg] Modified networking metrics by adding new metrics, splitting existing ones by rx/tx and using the device alias for the interface name when available
- [PR #5088][awels] Hotplug works with hostpath storage.
- [PR #4908][dhiller] Move travis tag and master builds to kubevirt prow.
- [PR #4741][EdDev] Allow live migration for SR-IOV VM/s without preserving the VF interfaces.

## v0.39.2

Released on: Tue Oct 19 13:29:33 2021 +0000

- [PR #6597][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #5854][rthallisey] Prometheus metrics scraped from virt-handler are now served from the VMI informer cache, rather than calling back to the Kubernetes API for VMI information.
- [PR #5561][kubevirt-bot] Fix `docker save` issues with kubevirt images

## v0.39.1

Released on: Tue Apr 13 12:10:13 2021 +0000
## v0.39.0

Released on: Wed Mar 10 14:51:58 2021 +0000

- [PR #5010][jean-edouard] Migrated VMs stay persistent and can therefore survive S3, among other things.
- [PR #4952][ashleyschuett] Create warning NodeUnresponsive event if a node is running a VMI pod but not a virt-handler pod
- [PR #4686][davidvossel] Automated workload updates via new KubeVirt WorkloadUpdateStrategy API
- [PR #4886][awels] Hotplug support for WFFC datavolumes.
- [PR #5026][AlonaKaplan] virt-launcher, masquerade binding - prefer nft over iptables.
- [PR #4921][borod108] Added support for Sysprep in the API. A user can now add a answer file through a ConfigMap or a Secret. The User Guide is updated accordingly. /kind feature
- [PR #4874][ormergi] Add new feature-gate SRIOVLiveMigration,
- [PR #4917][iholder-redhat] Now it is possible to enable QEMU SeaBios debug logs setting virt-launcher log verbosity to be greater than 5.
- [PR #4966][arnongilboa] Solve virtctl "Error when closing file ... file already closed" that shows after successful image upload
- [PR #4489][salanki] Fix a bug where a disk.img file was created on filesystems mounted via Virtio-FS
- [PR #4982][xpivarc] Fixing handling of transient domain
- [PR #4984][ashleyschuett] Change customizeComponents.patches such that '*' resourceName or resourceType matches all, all fields of a patch (type, patch, resourceName, resourceType) are now required.
- [PR #4972][vladikr] allow disabling pvspinlock to support older guest kernels
- [PR #4927][yuhaohaoyu] Fix of XML and JSON marshalling/unmarshalling for user defined device alias names which can make migrations fail.
- [PR #4552][rthallisey] VMs using bridged networking will survive a kubelet restart by having kubevirt create a dummy interface on the virt-launcher pods, so that some Kubernetes CNIs, that have implemented the `CHECK` RPC call, will not cause VMI pods to enter a failed state.
- [PR #4883][iholder-redhat] Bug fixed: Enabling libvirt debug logs only if debugLogs label value is "true", disabling otherwise.
- [PR #4840][alicefr] Generate k8s events on IO errors
- [PR #4940][vladikr] permittedHostDevices will support both upper and lowercase letters in the device ID

## v0.38.2

Released on: Tue Oct 19 13:24:57 2021 +0000

- [PR #6596][jean-edouard] VMs with cloud-init data should now properly migrate from older KubeVirt versions
- [PR #5853][rthallisey] Prometheus metrics scraped from virt-handler are now served from the VMI informer cache, rather than calling back to the Kubernetes API for VMI information.

## v0.38.1

Released on: Mon Feb 8 19:00:24 2021 +0000

- [PR #4870][qinqon] Bump k8s deps to 0.20.2
- [PR #4571][yuvalturg] Added os, workflow and flavor labels to the kubevirt_vmi_phase_count metric
- [PR #4659][salanki] Fixed an issue where non-root users inside a guest could not write to a Virtio-FS mount.
- [PR #4844][xpivarc] Fixed limits/requests to accept int again
- [PR #4850][rmohr] virtio-scsi now respects the useTransitionalVirtio flag instead of assigning a virtio version depending on the machine layout
- [PR #4672][vladikr] allow increasing logging verbosity of infra components in KubeVirt CR
- [PR #4838][rmohr] Fix an issue where it may not be able to update the KubeVirt CR after creation for up to minutes due to certificate propagation delays
- [PR #4806][rmohr] Make the mutating webhooks for VMIs and VMs  required to avoid letting entities into the cluster which are not properly defaulted
- [PR #4779][brybacki] Error message on virtctl image-upload to WaitForFirstConsumer DV
- [PR #4749][davidvossel] KUBEVIRT_CLIENT_GO_SCHEME_REGISTRATION_VERSION env var for specifying exactly what client-go scheme version is registered
- [PR #4772][jean-edouard] Faster VMI phase transitions thanks to an increased number of VMI watch threads in virt-controller
- [PR #4730][rmohr] Add spec.domain.devices.useVirtioTransitional boolean to support virtio-transitional for old guests

## v0.38.0

Released on: Mon Feb 8 13:15:32 2021 +0000

- [PR #4870][qinqon] Bump k8s deps to 0.20.2
- [PR #4571][yuvalturg] Added os, workflow and flavor labels to the kubevirt_vmi_phase_count metric
- [PR #4659][salanki] Fixed an issue where non-root users inside a guest could not write to a Virtio-FS mount.
- [PR #4844][xpivarc] Fixed limits/requests to accept int again
- [PR #4850][rmohr] virtio-scsi now respects the useTransitionalVirtio flag instead of assigning a virtio version depending on the machine layout
- [PR #4672][vladikr] allow increasing logging verbosity of infra components in KubeVirt CR
- [PR #4838][rmohr] Fix an issue where it may not be able to update the KubeVirt CR after creation for up to minutes due to certificate propagation delays
- [PR #4806][rmohr] Make the mutating webhooks for VMIs and VMs  required to avoid letting entities into the cluster which are not properly defaulted
- [PR #4779][brybacki] Error message on virtctl image-upload to WaitForFirstConsumer DV
- [PR #4749][davidvossel] KUBEVIRT_CLIENT_GO_SCHEME_REGISTRATION_VERSION env var for specifying exactly what client-go scheme version is registered
- [PR #4772][jean-edouard] Faster VMI phase transitions thanks to an increased number of VMI watch threads in virt-controller
- [PR #4730][rmohr] Add spec.domain.devices.useVirtioTransitional boolean to support virtio-transitional for old guests

## v0.37.2

Released on: Wed Jan 27 17:49:36 2021 +0000

- [PR #4872][kubevirt-bot] Add spec.domain.devices.useVirtioTransitional boolean to support virtio-transitional for old guests
- [PR #4855][kubevirt-bot] Fix an issue where it may not be able to update the KubeVirt CR after creation for up to minutes due to certificate propagation delays

## v0.37.1

Released on: Thu Jan 21 16:20:52 2021 +0000

- [PR #4842][kubevirt-bot] KUBEVIRT_CLIENT_GO_SCHEME_REGISTRATION_VERSION env var for specifying exactly what client-go scheme version is registered

## v0.37.0

Released on: Mon Jan 18 17:57:03 2021 +0000

- [PR #4654][AlonaKaplan] Introduce virt-launcher DHCPv6 server.
- [PR #4669][kwiesmueller] Add nodeSelector to kubevirt components restricting them to run on linux nodes only.
- [PR #4648][davidvossel] Update libvirt base container to be based of packages in rhel-av 8.3
- [PR #4653][qinqon] Allow configure cloud-init with networkData only.
- [PR #4644][ashleyschuett] Operator validation webhook will deny updates to the workloads object of the KubeVirt CR if there are running VMIs
- [PR #3349][davidvossel] KubeVirt v1 GA api
- [PR #4645][maiqueb] Re-introduce the CAP_NET_ADMIN, to allow migration of VMs already having it.
- [PR #4546][yuhaohaoyu] Failure detection and handling for VM with EFI Insecure Boot in KubeVirt environments where EFI Insecure Boot is not supported by design.
- [PR #4625][awels] virtctl upload now shows error when specifying access mode of ReadOnlyMany
- [PR #4396][xpivarc] KubeVirt is now explainable!
- [PR #4517][danielBelenky] Fix guest agent reporting.

## v0.36.2

Released on: Mon Feb 22 10:20:40 2021 -0500

## v0.36.1

Released on: Tue Jan 19 12:30:33 2021 +0100

## v0.36.0

Released on: Wed Dec 16 14:30:37 2020 +0000

- [PR #4667][kubevirt-bot] Update libvirt base container to be based of packages in rhel-av 8.3
- [PR #4634][kubevirt-bot] Failure detection and handling for VM with EFI Insecure Boot in KubeVirt environments where EFI Insecure Boot is not supported by design.
- [PR #4647][kubevirt-bot] Re-introduce the CAP_NET_ADMIN, to allow migration of VMs already having it.
- [PR #4627][kubevirt-bot] Fix guest agent reporting.
- [PR #4458][awels] It is now possible to hotplug DataVolume and PVC volumes into a running Virtual Machine.
- [PR #4025][brybacki] Adds a special handling for DataVolumes in WaitForFirstConsumer state to support CDI's delayed binding mode.
- [PR #4217][mfranczy] Set only an IP address for interfaces reported by qemu-guest-agent. Previously that was CIDR.
- [PR #4195][davidvossel] AccessCredentials API for dynamic user/password and ssh public key injection
- [PR #4335][oshoval] VMI status displays SRIOV interfaces with their network name only when they have originally
- [PR #4408][andreabolognani] This version of KubeVirt includes upgraded virtualization technology based on libvirt 6.6.0 and QEMU 5.1.0.
- [PR #4514][ArthurSens] `domain` label removed from metric `kubevirt_vmi_memory_unused_bytes`
- [PR #4542][danielBelenky] Fix double migration on node evacuation
- [PR #4506][maiqueb] Remove CAP_NET_ADMIN from the virt-launcher pod.
- [PR #4501][AlonaKaplan] CAP_NET_RAW removed from virt-launcher.
- [PR #4488][salanki] Disable Virtio-FS metadata cache to prevent OOM conditions on the host.
- [PR #3937][vladikr] Generalize host devices assignment. Provides an interface between kubevirt and external device plugins. Provides a mechanism for accesslisting host devices.
- [PR #4443][rmohr] All kubevirt webhooks support now dry-runs.

## v0.35.0

Released on: Mon Nov 9 13:08:27 2020 +0000

- [PR #4409][vladikr] Increase the static memory overhead by 10Mi
- [PR #4272][maiqueb] Add `ip-family` to the `virtctl expose` command.
- [PR #4398][rmohr] VMIs reflect deleted stuck virt-launcher pods with the "PodTerminating" reason in the ready condition. The VMIRs detects this reason and immediately creates replacement VMIs.
- [PR #4393][salanki] Disable legacy service links in `virt-launcher` Pods to speed up Pod instantiation and decrease Kubelet load in namespaces with many services.
- [PR #2935][maiqueb] Add the macvtap bind mechanism.
- [PR #4132][mstarostik] fixes a bug that prevented unique device name allocation when configuring both SCSI and SATA drives
- [PR #3257][xpivarc] Added support of `kubectl explain` for Kubevirt resources.
- [PR #4288][ezrasilvera] Adding DownwardAPI volumes type
- [PR #4233][maya-r] Update base image used for pods to Fedora 31.
- [PR #4192][xpivarc] We now run gosec in Kubevirt
- [PR #4328][stu-gott] Version 2.x QEMU guest agents are supported.
- [PR #4289][AlonaKaplan] Masquerade binding - set the virt-launcher pod interface MTU on the bridge.
- [PR #4300][maiqueb] Update the NetworkInterfaceMultiqueue openAPI documentation to better specify its semantics within KubeVirt.
- [PR #4277][awels] PVCs populated by DVs are now allowed as volumes.
- [PR #4265][dhiller] Fix virtctl help text when running as a plugin
- [PR #4273][dhiller] Only run Travis build for PRs against release branches

## v0.34.2

Released on: Tue Nov 17 08:13:22 2020 -0500

## v0.34.1

Released on: Mon Nov 16 08:22:56 2020 -0500

## v0.34.0

Released on: Wed Oct 7 13:59:50 2020 +0300

- [PR #4315][kubevirt-bot] PVCs populated by DVs are now allowed as volumes.
- [PR #3837][jean-edouard] VM interfaces with no `bootOrder` will no longer be candidates for boot when using the BIOS bootloader, as documented
- [PR #3879][ashleyschuett] KubeVirt should now be configured through the KubeVirt CR `configuration` key. The usage of the kubevirt-config configMap will be deprecated in the future.
- [PR #4074][stu-gott] Fixed bug preventing non-admin users from pausing/unpausing VMs
- [PR #4252][rhrazdil] Fixes https://bugzilla.redhat.com/show_bug.cgi?id=1853911
- [PR #4016][ashleyschuett] Allow for post copy VMI migrations
- [PR #4235][davidvossel] Fixes timeout failure that occurs when pulling large containerDisk images
- [PR #4263][rmohr] Add readiness and liveness probes to virt-handler, to clearly indicate readiness
- [PR #4248][maiqueb] always compile KubeVirt with selinux support on pure go builds.
- [PR #4012][danielBelenky] Added support for the eviction API for VMIs with eviction strategy. This enables VMIs to be live-migrated when the node is drained or when the descheduler wants to move a VMI to a different node.
- [PR #4075][ArthurSens] Metric kubevirt_vmi_vcpu_seconds' state label is now exposed as a human-readable state instead of an integer
- [PR #4162][vladikr] introduce a cpuAllocationRatio config parameter to normalize the number of CPUs requested for a pod, based on the number of vCPUs
- [PR #4177][maiqueb] Use vishvananda/netlink instead of songgao/water to create tap devices.
- [PR #4092][stu-gott] Allow specifying nodeSelectors, affinity and tolerations to control where KubeVirt components will run
- [PR #3927][ArthurSens] Adds new metric kubevirt_vmi_memory_unused_bytes
- [PR #3493][vladikr] virtio-fs is being added as experimental, protected by a feature-gate that needs to be enabled in the kubevirt config by the administrator
- [PR #4193][mhenriks] Add snapshot.kubevirt.io to admin/edit/view roles
- [PR #4149][qinqon] Bump kubevirtci to k8s-1.19
- [PR #3471][crobinso] Allow hiding that the VM is running on KVM, so that Nvidia graphics cards can be passed through
- [PR #4115][phoracek] Add conformance automation and manifest publishing
- [PR #3733][davidvossel] each PRs description.
- [PR #4082][mhenriks] VirtualMachineRestore API and implementation
- [PR #4154][davidvossel] Fixes issue with Service endpoints not being updated properly in place during KubeVirt updates.
- [PR #3289][vatsalparekh] Add option to run only VNC Proxy in virtctl
- [PR #4027][alicefr] Added memfd as default memory backend for hugepages. This introduces the new annotation kubevirt.io/memfd to disable memfd as default and fallback to the previous behavior.
- [PR #3612][ashleyschuett] Adds `customizeComponents` to the kubevirt api
- [PR #4029][cchengleo] Fix an issue which prevented virt-operator from installing monitoring resources in custom namespaces.
- [PR #4031][rmohr] Initial support for sonobuoy for conformance testing

## v0.33.0

Released on: Tue Sep 15 14:46:00 2020 +0000

- [PR #3226][vatsalparekh] Added tests to verify custom pciAddress slots and function
- [PR #4048][davidvossel] Improved reliability for failed migration retries
- [PR #3585][mhenriks] "virtctl image-upload pvc ..." will create the PVC if it does not exist
- [PR #3945][xpivarc] KubeVirt is now being built with Go1.13.14
- [PR #3845][ArthurSens] action required: The domain label from VMI metrics is being removed and may break dashboards that use the domain label to identify VMIs. Use name and namespace labels instead
- [PR #4011][dhiller] ppc64le arch has been disabled for the moment, see https://github.com/kubevirt/kubevirt/issues/4037
- [PR #3875][stu-gott] Resources created by KubeVirt are now labelled more clearly in terms of relationship and role.
- [PR #3791][ashleyschuett] make node as kubevirt.io/schedulable=false on virt-handler restart
- [PR #3998][vladikr] the local provider is usable again.
- [PR #3290][maiqueb] Have virt-handler (KubeVirt agent) create the tap devices on behalf of the virt-launchers.
- [PR #3957][AlonaKaplan] virt-launcher support Ipv6 on dual stack cluster.
- [PR #3952][davidvossel] Fixes rare situation where vmi may not properly terminate if failure occurs before domain starts.
- [PR #3973][xpivarc] Fixes VMs with clock.timezone set.
- [PR #3923][danielBelenky] Add support to configure QEMU I/O mode for VMIs
- [PR #3889][rmohr] The status fields for our CRDs are now protected on normal PATCH and PUT operations.The /status subresource is now used where possible for status updates.
- [PR #3568][xpivarc] Guest swap metrics available

## v0.32.0

Released on: Tue Aug 11 19:21:56 2020 +0000

- [PR #3921][vladikr] use correct memory units in libvirt xml
- [PR #3893][davidvossel] Adds recurring period that rsyncs virt-launcher domains with virt-handler
- [PR #3880][sgarbour] Better error message when input parameters are not the expected number of parameters for each argument. Help menu will popup in case the number of parameters is incorrect.
- [PR #3785][xpivarc] Vcpu wait metrics available
- [PR #3642][vatsalparekh] Add a way to update VMI Status with latest Pod IP for Masquerade bindings
- [PR #3636][ArthurSens] Adds kubernetes metadata.labels as VMI metrics' label
- [PR #3825][awels] Virtctl now prints error messages from the response body on upload errors.
- [PR #3830][davidvossel] Fixes re-establishing domain notify client connections when domain notify server restarts due to an error event.
- [PR #3778][danielBelenky] Do not emit a SyncFailed event if we fail to sync a VMI in a final state
- [PR #3803][andreabolognani] Not sure what to write here (see above)
- [PR #2694][rmohr] Use native go libraries for selinux to not rely on python-selinux tools like semanage, which are not always present.
- [PR #3692][victortoso] QEMU logs can now be fetched from outside the pod
- [PR #3738][enp0s3] Restrict creation of VMI if it has labels that are used internally by Kubevirt components.
- [PR #3725][danielBelenky] The tests binary is now part of the release and can be consumed from the GitHub release page.
- [PR #3684][rmohr] Log if critical devices, like kvm, which virt-handler wants to expose are not present on the node.
- [PR #3166][petrkotas] Introduce new virtctl commands:
- [PR #3708][andreabolognani] Make qemu work on GCE by pulling in a fix for https://bugzilla.redhat.com/show_bug.cgi?id=1822682

## v0.31.0

Released on: Thu Jul 9 16:08:18 2020 +0300

- [PR 3690][davidvossel] Update go-grpc dependency to v1.30.0 in order to improve stability
- [PR 3628][AlonaKaplan] Avoid virt-handler crash in case of virt-launcher network configuration error
- [PR 3635][jean-edouard] The "HostDisk" feature gate has to be enabled to use hostDisks
- [PR 3641][vatsalparekh] Reverts kubevirt/kubevirt#3488 because CI seems to have merged it without all tests passing
- [PR 3488][vatsalparekh] Add a way to update VMI Status with latest Pod IP for Masquerade bindings
- [PR 3406][tomob] If a PVC was created by a DataVolume, it cannot be used as a Volume Source for a VM. The owning DataVolume has to be used instead.
- [PR 3566][kraxel] added: TigerVNC support for linux & windows
- [PR 3529][jean-edouard] Enabling EFI will also enable Secure Boot, which requires SMM to be enabled.
- [PR 3455][ashleyschuett] Add KubevirtConfiguration, MigrationConfiguration, DeveloperConfiguration and NetworkConfiguration to API-types
- [PR 3520][rmohr] Fix hot-looping on the  VMI sync-condition if errors happen during the Scheduled phase of a VMI
- [PR 3220][mhenriks] API and controller/webhook for VirtualMachineSnapshots

## v0.30.7

Released on: Mon Oct 26 11:57:21 2020 -0400

## v0.30.6

Released on: Wed Aug 12 10:55:31 2020 +0200

## v0.30.5

Released on: Fri Jul 17 05:26:37 2020 -0400

## v0.30.4

Released on: Fri Jul 10 07:44:00 2020 -0400

## v0.30.3

Released on: Tue Jun 30 17:39:42 2020 -0400

## v0.30.2

Released on: Thu Jun 25 17:05:59 2020 -0400

## v0.30.1

Released on: Tue Jun 16 13:10:17 2020 -0400

## v0.30.0

Released on: Fri Jun 5 12:19:57 2020 +0200

- Tests: Many more test fixes
- Security: Introduce a custom SELinux policy for virt-launcher
- More user friendly IPv6 default CIDR for IPv6 addresses
- Fix OpenAPI compatibility issues by switching to openapi-gen
- Improved support for EFI boot (configurable OVMF path and test fixes)
- Improved VMI IP reporting
- Support propagation of annotations from VMI to pods
- Support for more fine grained (NET_RAW( capability granting to virt-launcher
- Support for eventual consistency with DataVolumes

## v0.29.2

Released on: Mon May 25 21:15:30 2020 +0200

## v0.29.1

Released on: Tue May 19 10:03:27 2020 +0200

## v0.29.0

Released on: Wed May 6 15:01:57 2020 +0200

- Tests: Many many test fixes
- Tests: Many more test fixes
- CI: Add lane with SELinux enabled
- CI: Drop PPC64 support for now
- Drop Genie support
- Drop the use of hostPaths in the virt-launcher for improved security
- Support priority classes for important components
- Support IPv6 over masquerade binding
- Support certificate rotations based on shared secrets
- Support for VM ready condition
- Support for advanced node labelling (supported CPU Families and machine types)

## v0.28.0

Released on: Thu Apr 9 23:01:29 2020 +0200

- CI: Try to discover flaky tests before merge
- Fix the use of priorityClasses
- Fix guest memory overhead calculation
- Fix SR-IOV device overhead requirements
- Fix loading of tun module during virt-handler initialization
- Fixes for several test cases
- Fixes to support running with container_t
- Support for renaming a VM
- Support ioEmulator thread pinning
- Support a couple of alerts for virt-handler
- Support for filesystem listing using the guest agent
- Support for retrieving data from the guest agent
- Support for device role tagging
- Support for assigning devices to the PCI root bus
- Support for guest overhead override
- Rewrite container-disk in C to in order to reduce it's memory footprint

## v0.27.0

Released on: Fri Mar 6 22:40:34 2020 +0100

- Support for more guest agent informations in the API
- Support setting priorityClasses on VMs
- Support for additional control plane alerts via prometheus
- Support for io and emulator thread pinning
- Support setting a custom SELinux type for the launcher
- Support to perform network configurations from handler instead of launcher
- Support to opt-out of auto attaching the serial console
- Support for different uninstall strategies for data protection
- Fix to let qemu run in the qemu group
- Fix guest agent connectivity check after i.e. live migrations

## v0.26.5

Released on: Tue Apr 14 15:07:04 2020 -0400

## v0.26.4

Released on: Mon Mar 30 03:43:48 2020 +0200

## v0.26.3

Released on: Tue Mar 10 08:57:27 2020 -0400

## v0.26.2

Released on: Tue Mar 3 12:31:56 2020 -0500

## v0.26.1

Released on: Fri Feb 14 20:42:46 2020 +0100

## v0.26.0

Released on: Fri Feb 7 09:40:07 2020 +0100

- Fix incorrect ownerReferences to avoid VMs getting GCed
- Fixes for several tests
- Fix greedy permissions around Secrets by delegating them to kubelet
- Fix OOM infra pod by increasing it's memory request
- Clarify device support around live migrations
- Support for an uninstall strategy to protect workloads during uninstallation
- Support for more prometheus metrics and alert rules
- Support for testing SRIOV connectivity in functional tests
- Update Kubernetes client-go to 1.16.4
- FOSSA fixes and status

## v0.25.0

Released on: Mon Jan 13 20:37:15 2020 +0100

- CI: Support for Kubernetes 1.17
- Support emulator thread pinning
- Support virtctl restart --force
- Support virtctl migrate to trigger live migrations from the CLI

## v0.24.0

Released on: Tue Dec 3 15:34:34 2019 +0100

- CI: Support for Kubernetes 1.15
- CI: Support for Kubernetes 1.16
- Add and fix a couple of test cases
- Support for pause and unpausing VMs
- Update of libvirt to 5.6.0
- Fix bug related to parallel scraping of Prometheus endpoints
- Fix to reliably test VNC

## v0.23.3

Released on: Tue Jan 21 13:17:20 2020 -0500

## v0.23.2

Released on: Fri Jan 10 10:36:36 2020 -0500

## v0.23.1

Released on: Thu Nov 28 09:36:41 2019 +0100

## v0.23.0

Released on: Mon Nov 4 16:42:54 2019 +0100

- Guest OS Information is available under the VMI status now
- Updated to Go 1.12.8 and latest bazel
- Updated go-yaml to v2.2.4, which has a ddos vulnerability fixed
- Cleaned up and fixed CRD scheme registration
- Several bug fixes
- Many CI improvements (e.g. more logs in case of test failures)

## v0.22.0

Released on: Thu Oct 10 18:55:08 2019 +0200

- Support for Nvidia GPUs and vGPUs exposed by Nvidia Kubevirt Device Plugin.
- VMIs now successfully start if they get a 0xfe prefixed MAC address assigned from the pod network
- Removed dependency on host semanage in SELinux Permissive mode
- Some changes as result of entering the CNCF sandbox (DCO check, FOSSA check, best practice badge)
- Many bug fixes and improvements in several areas
- CI: Introduced a OKD 4 test lane
- CI: Many improved tests resulting in less flakiness

## v0.21.0

Released on: Mon Sep 9 09:59:08 2019 +0200

- CI: Support for Kubernetes 1.14
- Many bug fixes in several areas
- Support for `virtctl migrate`
- Support configurable number of controller threads
- Support to opt-out of bridge binding for podNetwork
- Support for OpenShift Prometheus monitoring
- Support for setting more SMBIOS fields
- Improved containerDisk memory usage and speed
- Fix CRI-O memory limit
- Drop spc_t from launcher
- Add feature gates to security sensitive features

## v0.20.8

Released on: Thu Oct 3 12:03:40 2019 +0200

## v0.20.7

Released on: Fri Sep 27 15:21:56 2019 +0200

## v0.20.6

Released on: Wed Sep 11 06:09:47 2019 -0400

## v0.20.5

Released on: Thu Sep 5 17:48:59 2019 +0200

## v0.20.4

Released on: Mon Sep 2 18:55:35 2019 +0200

## v0.20.3

Released on: Tue Aug 27 16:58:15 2019 +0200

## v0.20.2

Released on: Tue Aug 20 15:51:07 2019 +0200

## v0.20.1

Released on: Fri Aug 9 19:48:17 2019 +0200

- Container disks are now secure and they are not copied anymore on every start.
Old container disks can still be used in the same secure way, but new
container disks can't be used on older kubevirt releases
- Create specific SecurityContextConstraints on OKD instead of using the
privileged SCC
- Added clone authorization check for DataVolumes with PVC source
- The sidecar feature is feature-gated now
- Use container image shasums instead of tags for KubeVirt deployments
- Protect control plane components against voluntary evictions with a
PodDisruptionBudget of MinAvailable=1
- Replaced hardcoded `virtctl` by using the basename of the call, this enables
nicer output when installed via krew plugin package manager
- Added RNG device to all Fedora VMs in tests and examples (newer kernels might
block bootimg while waiting for entropy)
- The virtual memory is now set to match the memory limit, if memory limit is
specified and guest memory is not
- Support nftable for CoreOS
- Added a block-volume flag to the virtctl image-upload command
- Improved virtctl console/vnc data flow
- Removed DataVolumes feature gate in favor of auto-detecting CDI support
- Removed SR-IOV feature gate, it is enabled by default now
- VMI-related metrics have been renamed from `kubevirt_vm_` to `kubevirt_vmi_`
to better reflect their purpose
- Added metric to report the VMI count
- Improved integration with HCO by adding a CSV generator tool and modified
KubeVirt CR conditions
- CI Improvements:
  - Added dedicated SR-IOV test lane
  - Improved log gathering
  - Reduced amount of flaky tests

## v0.20.0

Released on: Fri Aug 9 16:42:41 2019 +0200

- container Disks are now secure and they are not copied anymore on every start.
Old container Disks can still be used in the same secure way, but new
container Disks can't be used on older kubevirt releases
- Create specific SecurityContextConstraints on OKD instead of using the
privileged SCC
- Added clone authorization check for DataVolumes with PVC source
- The sidecar feature is feature-gated now
- Use container image shasum's instead of tags for KubeVirt deployments
- Protect control plane components against voluntary evictions with a
PodDisruptionBudget of MinAvailable=1
- Replaced hardcoded `virtctl` by using the basename of the call, this enables
nicer output when installed via krew plugin package manager
- Added RNG device to all Fedora VMs in tests and examples (newer kernels might
block boot img while waiting for entropy)
- The virtual memory is now set to match the memory limit, if memory limit is
specified and guest memory is not
- Support nftable for CoreOS
- Added a block-volume flag to the virtctl image-upload command
- Improved virtctl console/vnc data flow
- Removed DataVolumes feature gate in favor of auto-detecting CDI support
- Removed SR-IOV feature gate, it is enabled by default now
- VMI-related metrics have been renamed from `kubevirt_vm_` to `kubevirt_vmi_`
to better reflect their purpose
- Added metric to report the VMI count
- Improved integration with HCO by adding a CSV generator tool and modified
KubeVirt CR conditions
- CI Improvements:
  - Added dedicated SR-IOV test lane
  - Improved log gathering
  - Reduced amount of flaky tests

## v0.19.0

Released on: Fri Jul 5 12:52:16 2019 +0200

- Fixes when run on kind
- Fixes for sub-resource RBAC
- Limit pod network interface bindings
- Many additional bug fixes in many areas
- Additional test cases for updates, disk types, live migration with NFS
- Additional test cases for memory over-commit, block storage, cpu manager,
headless mode
- Improvements around HyperV
- Improved error handling for runStrategies
- Improved update procedure
- Improved network metrics reporting (packets and errors)
- Improved guest overhead calculation
- Improved SR-IOV test suite
- Support for live migration auto-converge
- Support for config-drive disks
- Support for setting a pullPolicy con container Disks
- Support for unprivileged VMs when using SR-IOV
- Introduction of a project security policy

## v0.18.1

Released on: Thu Jun 13 12:00:56 2019 +0200

## v0.18.0

Released on: Wed Jun 5 22:25:09 2019 +0200

- Build: Use of go modules
- CI: Support for Kubernetes 1.13
- Countless test cases fixes and additions
- Several smaller bug fixes
- Improved upgrade documentation

## v0.17.4

Released on: Tue Jun 25 07:49:12 2019 -0400

## v0.17.3

Released on: Wed Jun 19 12:00:45 2019 -0400

## v0.17.2

Released on: Wed Jun 5 08:12:04 2019 -0400

## v0.17.1

Released on: Tue Jun 4 14:41:10 2019 -0400

## v0.17.0

Released on: Mon May 6 16:18:01 2019 +0200

- Several test case additions
- Improved virt-controller node distribution
- Improved support between version migrations
- Support for a configurable MachineType default
- Support for live-migration of a VM on node taints
- Support for VM swap metrics
- Support for versioned virt-launcher / virt-handler communication
- Support for HyperV flags
- Support for different VM run strategies (i.e manual and rerunOnFailure)
- Several fixes for live-migration (TLS support, protected pods)

## v0.16.3

Released on: Thu May 2 23:51:08 2019 +0200

## v0.16.2

Released on: Fri Apr 26 12:24:33 2019 +0200

## v0.16.1

Released on: Tue Apr 23 19:31:19 2019 +0200

## v0.16.0

Released on: Fri Apr 5 23:18:22 2019 +0200

- Bazel fixes
- Initial work to support upgrades (not finalized)
- Initial support for HyperV features
- Support propagation of MAC addresses to multus
- Support live migration cancellation
- Support for table input devices
- Support for generating OLM metadata
- Support for triggering VM live migration on node taints

## v0.15.0

Released on: Tue Mar 5 10:35:08 2019 +0100

- CI: Several fixes
- Fix configurable number of KVM devices
- Narrow virt-handler permissions
- Use bazel for development builds
- Support for live migration with shared and non-shared disks
- Support for live migration progress tracking
- Support for EFI boot
- Support for libvirt 5.0
- Support for extra DHCP options
- Support for a hook to manipulate cloud-init metadata
- Support setting a VM serial number
- Support for exposing infra and VM metrics
- Support for a tablet input device
- Support for extra CPU flags
- Support for ignition metadata
- Support to set a default CPU model
- Update to go 1.11.5

## v0.14.0

Released on: Mon Feb 4 22:04:14 2019 +0100

- CI: Several stabilizing fixes
- docs: Document the KubeVirt Razor
- build: golang update
- Update to Kubernetes 1.12
- Update CDI
- Support for Ready and Created Operator conditions
- Support (basic) EFI
- Support for generating cloud-init network-config

## v0.13.7

Released on: Mon Oct 28 17:02:35 2019 -0400

## v0.13.6

Released on: Wed Sep 25 17:19:44 2019 +0200

## v0.13.5

Released on: Thu Aug 1 11:25:00 2019 -0400

## v0.13.4

Released on: Thu Aug 1 09:52:35 2019 -0400

## v0.13.3

Released on: Mon Feb 4 15:46:48 2019 -0500

## v0.13.2

Released on: Thu Jan 24 23:24:06 2019 +0100

## v0.13.1

Released on: Thu Jan 24 11:16:20 2019 +0100

## v0.13.0

Released on: Tue Jan 15 08:26:25 2019 +0100

- CI: Fix virt-api race
- API: Remove volumeName from disks

## v0.12.0

Released on: Fri Jan 11 22:22:02 2019 +0100

- Introduce a KubeVirt Operator for KubeVirt life-cycle management
- Introduce dedicated kubevirt namespace
- Support VMI ready conditions
- Support vCPU threads and sockets
- Support scale and HPA for VMIRs
- Support to pass NTP related DHCP options
- Support guest IP address reporting via qemu guest agent
- Support for live migration with shared storage
- Support scheduling of VMs based on CPU family
- Support masquerade network interface binding

## v0.11.1

Released on: Thu Dec 13 10:21:56 2018 +0200

## v0.11.0

Released on: Thu Dec 6 10:15:51 2018 +0100

- API: registryDisk got renamed to containerDisk
- CI: User OKD 3.11
- Fix: Tolerate if the PVC has less capacity than expected
- Aligned to use ownerReferences
- Update to libvirt-4.10.0
- Support for VNC on MAC OSX
- Support for network SR-IOV interfaces
- Support for custom DHCP options
- Support for VM restarts via a custom endpoint
- Support for liveness and readiness probes

## v0.10.0

Released on: Thu Nov 8 15:21:34 2018 +0100

- Support for vhost-net
- Support for block multi-queue
- Support for custom PCI addresses for virtio devices
- Support for deploying KubeVirt to a custom namespace
- Support for ServiceAccount token disks
- Support for multus backed networks
- Support for genie backed networks
- Support for kuryr backed networks
- Support for block PVs
- Support for configurable disk device caches
- Support for pinned IO threads
- Support for virtio net multi-queue
- Support for image upload (depending on CDI)
- Support for custom entity lists with more VM details (custom columns)
- Support for IP and MAC address reporting of all vNICs
- Basic support for guest agent status reporting
- More structured logging
- Better libvirt error reporting
- Stricter CR validation
- Better ownership references
- Several test improvements

## v0.9.6

Released on: Thu Nov 22 17:14:18 2018 +0100

## v0.9.5

Released on: Thu Nov 8 09:57:48 2018 +0100

## v0.9.4

Released on: Wed Nov 7 08:22:14 2018 -0500

## v0.9.3

Released on: Mon Oct 22 09:04:02 2018 -0400

## v0.9.2

Released on: Thu Oct 18 12:14:09 2018 +0200

## v0.9.1

Released on: Fri Oct 5 09:01:51 2018 +0200

## v0.9.0

Released on: Thu Oct 4 14:42:28 2018 +0200

- CI: NetworkPolicy tests
- CI: Support for an external provider (use a preconfigured cluster for tests)
- Fix virtctl console issues with CRI-O
- Support to initialize empty PVs
- Support for basic CPU pinning
- Support for setting IO Threads
- Support for block volumes
- Move preset logic to mutating webhook
- Introduce basic metrics reporting using prometheus metrics
- Many stabilizing fixes in many places

## v0.8.0

Released on: Thu Sep 6 14:25:22 2018 +0200

- Support for DataVolume
- Support for a subprotocol for web browser terminals
- Support for virtio-rng
- Support disconnected VMs
- Support for setting host model
- Support for host CPU passthrough
- Support setting a vNICs mac and PCI address
- Support for memory over-commit
- Support booting from network devices
- Use less devices by default, aka disable unused ones
- Improved VMI shutdown status
- More logging to improve debugability
- A lot of small fixes, including typos and documentation fixes
- Race detection in tests
- Hook improvements
- Update to use Fedora 28 (includes updates of dependencies like libvirt and
  qemu)
- Move CI to support Kubernetes 1.11

## v0.7.0

Released on: Wed Jul 4 17:41:33 2018 +0200

- CI: Move test storage to hostPath
- CI: Add support for Kubernetes 1.10.4
- CI: Improved network tests for multiple-interfaces
- CI: Drop Origin 3.9 support
- CI: Add test for testing templates on Origin
- VM to VMI rename
- VM affinity and anti-affinity
- Add awareness for multiple networks
- Add hugepage support
- Add device-plugin based kvm
- Add support for setting the network interface model
- Add (basic and initial) Kubernetes compatible networking approach (SLIRP)
- Add role aggregation for our roles
- Add support for setting a disks serial number
- Add support for specifying the CPU model
- Add support for setting an network interfaces MAC address
- Relocate binaries for FHS conformance
- Logging improvements
- Template fixes
- Fix OpenShift CRD validation
- virtctl: Improve vnc logging improvements
- virtctl: Add expose
- virtctl: Use PATCH instead of PUT

## v0.6.4

Released on: Tue Aug 21 17:29:28 2018 +0300

## v0.6.3

Released on: Mon Jul 30 16:14:22 2018 +0200

## v0.6.2

Released on: Wed Jul 4 17:49:37 2018 +0200

- Binary relocation for packaging
- QEMU Process detection
- Role aggregation
- CPU Model selection
- VM Rename fix

## v0.6.1

Released on: Mon Jun 18 17:07:48 2018 -0400

## v0.6.0

Released on: Mon Jun 11 09:30:28 2018 +0200

- A range of flakiness reducing test fixes
- Vagrant setup got deprecated
- Updated Docker and CentOS versions
- Add Kubernetes 1.10.3 to test matrix
- A couple of ginkgo concurrency fixes
- A couple of spelling fixes
- A range if infra updates
- Use /dev/kvm if possible, otherwise fallback to emulation
- Add default view/edit/admin RBAC Roles
- Network MTU fixes
- CD-ROM drives are now read-only
- Secrets can now be correctly referenced on VMs
- Add disk boot ordering
- Add virtctl version
- Add virtctl expose
- Fix virtual machine memory calculations
- Add basic virtual machine Network API

## v0.5.0

Released on: Fri May 4 18:25:32 2018 +0200

- Better controller health signaling
- Better virtctl error messages
- Improvements to enable CRI-O support
- Run CI on stable OpenShift
- Add test coverage for multiple PVCs
- Improved controller life-cycle guarantees
- Add Webhook validation
- Add tests coverage for node eviction
- OfflineVirtualMachine status improvements
- RegistryDisk API update

## v0.4.1

Released on: Thu Apr 12 11:46:09 2018 +0200

- VM shutdown fixes and tests
- Functional test for CRD validation
- Windows VM test
- DHCP link-local change

## v0.4.0

Released on: Fri Apr 6 16:40:31 2018 +0200

- Fix several networking issues
- Add and enable OpenShift support to CI
- Add conditional Windows tests (if an image is present)
- Add subresources for console access
- virtctl config alignment with kubectl
- Fix API reference generation
- Stable UUIDs for OfflineVirtualMachines
- Build virtctl for MacOS and Windows
- Set default architecture to x86_64
- Major improvement to the CI infrastructure (all containerized)
- virtctl convenience functions for starting and stopping a VM

## v0.3.0

Released on: Thu Mar 8 10:21:57 2018 +0100

- Kubernetes compatible networking
- Kubernetes compatible PV based storage
- VirtualMachinePresets support
- OfflineVirtualMachine support
- RBAC improvements
- Switch to q35 machine type by default
- A large number of test and CI fixes
- Ephemeral disk support

## v0.2.0

Released on: Fri Jan 5 16:30:45 2018 +0100

- VM launch and shutdown flow improvements
- VirtualMachine API redesign
- Removal of HAProxy
- Redesign of VNC/Console access
- Initial support for different vagrant providers

## v0.1.0

Released on: Fri Dec 8 20:43:06 2017 +0100

- Many API improvements for a proper OpenAPI reference
- Add watchdog support
- Drastically improve the deployment on non-vagrant setups
  - Dropped nodeSelectors
  - Separated inner component deployment from edge component deployment
  - Created separate manifests for developer, test, and release deployments
- Moved components to kube-system namespace
- Improved and unified flag parsing

## v0.0.4

Released on: Tue Nov 7 11:51:45 2017 +0100

- Add support for node affinity to VM.Spec
- Add OpenAPI specification
- Drop swagger 1.2 specification
- virt-launcher refactoring
- Leader election mechanism for virt-controller
- Move from glide to dep for dependency management
- Improve virt-handler synchronization loops
- Add support for running the functional tests on oVirt infrastructure
- Several tests fixes (spice, cleanup, ...)
- Add console test tool
- Improve libvirt event notification

## v0.0.3

Released on: Fri Oct 6 10:21:16 2017 +0200

- Containerized binary builds
- Socket based container detection
- cloud-init support
- Container based ephemeral disk support
- Basic RBAC profile
- client-go updates
- Rename of VM to VirtualMachine
- Introduction of VirtualMachineReplicaSet
- Improved migration events
- Improved API documentation

## v0.0.2

Released on: Mon Sep 4 21:12:46 2017 +0200

- Usage of CRDs
- Moved libvirt to a pod
- Introduction of `virtctl`
- Use glide instead of govendor
- Container based ephemeral disks
- Contributing guide improvements
- Support for Kubernetes Namespaces
