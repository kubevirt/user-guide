# Latest release notes

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

## v0.20.0

Released on: Fri Aug 9 16:42:41 2019 +0200

- containerDisks are now secure and they are not copied anymore on every start.
Old containerDisks can still be used in the same secure way, but new
containerDisks can't be used on older kubevirt releases
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
- Support for setting a pullPolicy con containerDisks
- Support for unprivileged VMs when using SR-IOV
- Introduction of a project security policy

## v0.18.0

Released on: Wed Jun 5 22:25:09 2019 +0200

- Build: Use of go modules
- CI: Support for Kubernetes 1.13
- Countless test cases fixes and additions
- Several smaller bug fixes
- Improved upgrade documentation

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
