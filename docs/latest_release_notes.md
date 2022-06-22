# Latest release notes

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
