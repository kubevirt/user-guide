\# Changelog

\#\# v0.26.0

Released on: Fri Feb 7 09:40:07 2020 +0100

-   Fix incorrect ownerReferences to avoid VMs getting GCed

-   Fixes for several tests

-   Fix greedy permissions around Secrets by delegating them to kubelet

-   Fix OOM infra pod by increasing it’s memory request

-   Clarify device support around live migrations

-   Support for an uninstall strategy to protect workloads during
    uninstallation

-   Support for more prometheus metrics and alert rules

-   Support for testing SRIOV connectivity in functional tests

-   Update Kubernetes client-go to 1.16.4

-   FOSSA fixes and status

\#\# v0.25.0

Released on: Mon Jan 13 20:37:15 2020 +0100

-   CI: Support for Kubernetes 1.17

-   Support emulator thread pinning

-   Support virtctl restart --force

-   Support virtctl migrate to trigger live migrations from the CLI

\#\# v0.24.0

Released on: Tue Dec 3 15:34:34 2019 +0100

-   CI: Support for Kubernetes 1.15

-   CI: Support for Kubernetes 1.16

-   Add and fix a couple of test cases

-   Support for pause and unpausing VMs

-   Update of libvirt to 5.6.0

-   Fix bug related to parallel scraping of Prometheus endpoints

-   Fix to reliably test VNC

\#\# v0.23.0

Released on: Mon Nov 4 16:42:54 2019 +0100

-   Guest OS Information is available under the VMI status now

-   Updated to Go 1.12.8 and latest bazel

-   Updated go-yaml to v2.2.4, which has a ddos vulnerability fixed

-   Cleaned up and fixed CRD scheme registration

-   Several bugfixes

-   Many CI improvements (e.g. more logs in case of test failures)

\#\# v0.22.0

Released on: Thu Oct 10 18:55:08 2019 +0200

-   Support for Nvidia GPUs and vGPUs exposed by Nvidia Kubevirt Device
    Plugin.

-   VMIs now successfully start if they get a 0xfe prefixed MAC address
    assigned from the pod network

-   Removed dependency on host semanage in SELinux Permissive mode

-   Some changes as result of entering the CNCF sandbox (DCO check,
    FOSSA check, best practice badge)

-   Many bug fixes and improvements in several areas

-   CI: Introduced a OKD 4 test lane

-   CI: Many improved tests, resulting in less flakyness

\#\# v0.21.0

Released on: Mon Sep 9 09:59:08 2019 +0200

-   CI: Support for Kubernetes 1.14

-   Many bug fixes in several areas

-   Support for `virtctl migrate`

-   Support configurable number of controller threads

-   Support to opt-out of bridge binding for podnetwork

-   Support for OpenShift Prometheus monitoring

-   Support for setting more SMBIOS fields

-   Improved containerDisk memory usage and speed

-   Fix CRI-O memory limit

-   Drop spc\_t from launcher

-   Add feature gates to security sensitive features

\#\# v0.20.0

Released on: Fri Aug 9 16:42:41 2019 +0200

-   Containerdisks are now secure and they are not copied anymore on
    every start. Old containerdisks can still be used in the same secure
    way, but new containerdisks can’t be used on older kubevirt releases

-   Create specific SecurityContextConstraints on OKD instead of using
    the privileged SCC

-   Added clone authorization check for DataVolumes with PVC source

-   The sidecar feature is feature-gated now

-   Use container image shasums instead of tags for KubeVirt deployments

-   Protect control plane components against voluntary evictions with a
    PodDisruptionBudget of MinAvailable=1

-   Replaced hardcoded `virtctl` by using the basename of the call, this
    enables nicer output when installed via krew plugin package manager

-   Added RNG device to all Fedora VMs in tests and examples (newer
    kernels might block bootimg while waiting for entropy)

-   The virtual memory is now set to match the memory limit, if memory
    limit is specified and guest memory is not

-   Support nftable for CoreOS

-   Added a block-volume flag to the virtctl image-upload command

-   Improved virtctl console/vnc data flow

-   Removed DataVolumes feature gate in favor of auto-detecting CDI
    support

-   Removed SR-IOV feature gate, it is enabled by default now

-   VMI-related metrics have been renamed from `kubevirt_vm_` to
    `kubevirt_vmi_` to better reflect their purpose

-   Added metric to report the VMI count

-   Improved integration with HCO by adding a CSV generator tool and
    modified KubeVirt CR conditions

-   CI Improvements:

-   Added dedicated SR-IOV test lane

-   Improved log gathering

-   Reduced amount of flaky tests

\#\# v0.19.0

Released on: Fri Jul 5 12:52:16 2019 +0200

-   Fixes when run on kind

-   Fixes for sub-resource RBAC

-   Limit pod network interface bindings

-   Many additional bug fixes in many areas

-   Additional testcases for updates, disk types, live migration with
    NFS

-   Additional testcases for memory over-commit, block storage, cpu
    manager, headless mode

-   Improvements around HyperV

-   Improved error handling for runStartegies

-   Improved update procedure

-   Improved network metrics reporting (packets and errors)

-   Improved guest overhead calculation

-   Improved SR-IOV testsuite

-   Support for live migration auto-converge

-   Support for config-drive disks

-   Support for setting a pullPolicy con containerDisks

-   Support for unprivileged VMs when using SR-IOV

-   Introduction of a project security policy

\#\# v0.18.0

Released on: Wed Jun 5 22:25:09 2019 +0200

-   Build: Use of go modules

-   CI: Support for Kubernetes 1.13

-   Countless testcase fixes and additions

-   Several smaller bug fixes

-   Improved upgrade documentation

\#\# v0.17.0

Released on: Mon May 6 16:18:01 2019 +0200

-   Several testcase additions

-   Improved virt-controller node distribution

-   Improved support between version migrations

-   Support for a configurable MachineType default

-   Support for live-migration of a VM on node taints

-   Support for VM swap metrics

-   Support for versioned virt-launcher / virt-handler communication

-   Support for HyperV flags

-   Support for different VM run strategies (i.e manual and
    rerunOnFailure)

-   Several fixes for live-migration (TLS support, protected pods)

\#\# v0.16.0

Released on: Fri Apr 5 23:18:22 2019 +0200

-   Bazel fixes

-   Initial work to support upgrades (not finalized)

-   Initial support for HyperV features

-   Support propagation of MAC addresses to multus

-   Support live migration cancellation

-   Support for table input devices

-   Support for generating OLM metadata

-   Support for triggering VM live migration on node taints

\#\# v0.15.0

Released on: Tue Mar 5 10:35:08 2019 +0100

-   CI: Several fixes

-   Fix configurable number of KVM devices

-   Narrow virt-handler permissions

-   Use bazel for development builds

-   Support for live migration with shared and non-shared disks

-   Support for live migration progress tracking

-   Support for EFI boot

-   Support for libvirt 5.0

-   Support for extra DHCP options

-   Support for a hook to manipualte cloud-init metadata

-   Support setting a VM serial number

-   Support for exposing infra and VM metrics

-   Support for a tablet input device

-   Support for extra CPU flags

-   Support for ignition metadata

-   Support to set a default CPU model

-   Update to go 1.11.5

\#\# v0.14.0

Released on: Mon Feb 4 22:04:14 2019 +0100

-   CI: Several stabilizing fixes

-   docs: Document the KubeVirt Razor

-   build: golang update

-   Update to Kubernetes 1.12

-   Update CDI

-   Support for Ready and Created Operator conditions

-   Support (basic) EFI

-   Support for generating cloud-init network-config

\#\# v0.13.0

Released on: Tue Jan 15 08:26:25 2019 +0100

-   CI: Fix virt-api race

-   API: Remove volumeName from disks

\#\# v0.12.0

Released on: Fri Jan 11 22:22:02 2019 +0100

-   Introduce a KubeVirt Operator for KubeVirt life-cycle management

-   Introduce dedicated kubevirt namespace

-   Support VMI ready conditions

-   Support vCPU threads and sockets

-   Support scale and HPA for VMIRS

-   Support to pass NTP related DHCP options

-   Support guest IP address reporting via qemu guest agent

-   Support for live migration with shared storage

-   Support scheduling of VMs based on CPU family

-   Support masquerade network interface binding

\#\# v0.11.0

Released on: Thu Dec 6 10:15:51 2018 +0100

-   API: registryDisk got renamed to containreDisk

-   CI: User OKD 3.11

-   Fix: Tolerate if the PVC has less capacity than expected

-   Aligned to use ownerReferences

-   Update to libvirt-4.10.0

-   Support for VNC on MAC OSX

-   Support for network SR-IOV interfaces

-   Support for custom DHCP options

-   Support for VM restarts via a custom endpoint

-   Support for liveness and readiness probes

\#\# v0.10.0

Released on: Thu Nov 8 15:21:34 2018 +0100

-   Support for vhost-net

-   Support for block multi-queue

-   Support for custom PCI addresses for virtio devices

-   Support for deploying KubeVirt to a custom namespace

-   Support for ServiceAccount token disks

-   Support for multus backed networks

-   Support for genie backed networks

-   Support for kuryr backed networks

-   Support for block PVs

-   Support for configurable disk device caches

-   Support for pinned IO threads

-   Support for virtio net multi-queue

-   Support for image upload (depending on CDI)

-   Support for custom entity lists with more VM details (cusomt
    columns)

-   Support for IP and MAC address reporting of all vNICs

-   Basic support for guest agent status reporting

-   More structured logging

-   Better libvirt error reporting

-   Stricter CR validation

-   Better ownership references

-   Several test improvements

\#\# v0.9.0

Released on: Thu Oct 4 14:42:28 2018 +0200

-   CI: NetworkPolicy tests

-   CI: Support for an external provider (use a preconfigured cluster
    for tests)

-   Fix virtctl console issues with CRI-O

-   Support to initialize empty PVs

-   Support for basic CPU pinning

-   Support for setting IO Threads

-   Support for block volumes

-   Move preset logic to mutating webhook

-   Introduce basic metrics reporting using prometheus metrics

-   Many stabilizing fixes in many places

\#\# v0.8.0

Released on: Thu Sep 6 14:25:22 2018 +0200

-   Support for DataVolume

-   Support for a subprotocol for webbrowser terminals

-   Support for virtio-rng

-   Support disconnected VMs

-   Support for setting host model

-   Support for host CPU passthrough

-   Support setting a vNICs mac and PCI address

-   Support for memory over-commit

-   Support booting from network devices

-   Use less devices by default, aka disable unused ones

-   Improved VMI shutdown status

-   More logging to improve debugability

-   A lot of small fixes, including typos and documentation fixes

-   Race detection in tests

-   Hook improvements

-   Update to use Fedora 28 (includes updates of dependencies like
    libvirt and qemu)

-   Move CI to support Kubernetes 1.11

\#\# v0.7.0

Released on: Wed Jul 4 17:41:33 2018 +0200

-   CI: Move test storage to hostPath

-   CI: Add support for Kubernetes 1.10.4

-   CI: Improved network tests for multiple-interfaces

-   CI: Drop Origin 3.9 support

-   CI: Add test for testing templates on Origin

-   VM to VMI rename

-   VM affinity and anti-affinity

-   Add awareness for multiple networks

-   Add hugepage support

-   Add device-plugin based kvm

-   Add support for setting the network interface model

-   Add (basic and inital) Kubernetes compatible networking approach
    (SLIRP)

-   Add role aggregation for our roles

-   Add support for setting a disks serial number

-   Add support for specyfing the CPU model

-   Add support for setting an network intefraces MAC address

-   Relocate binaries for FHS conformance

-   Logging improvements

-   Template fixes

-   Fix OpenShift CRD validation

-   virtctl: Improve vnc logging improvements

-   virtctl: Add expose

-   virtctl: Use PATCH instead of PUT

\#\# v0.6.0

Released on: Mon Jun 11 09:30:28 2018 +0200

-   A range of flakyness reducing test fixes

-   Vagrant setup got deprectated

-   Updated Docker and CentOS versions

-   Add Kubernetes 1.10.3 to test matrix

-   A couple of ginkgo concurrency fixes

-   A couple of spelling fixes

-   A range if infra updates

-   Use /dev/kvm if possible, otherwise fallback to emulation

-   Add default view/edit/admin RBAC Roles

-   Network MTU fixes

-   CDRom drives are now read-only

-   Secrets can now be correctly referenced on VMs

-   Add disk boot ordering

-   Add virtctl version

-   Add virtctl expose

-   Fix virtual machine memory calculations

-   Add basic virtual machine Network API

\#\# v0.5.0

Released on: Fri May 4 18:25:32 2018 +0200

-   Better controller health signaling

-   Better virtctl error messages

-   Improvements to enable CRI-O support

-   Run CI on stable OpenShift

-   Add test coverage for multiple PVCs

-   Improved controller life-cycle guarantees

-   Add Webhook validation

-   Add tests coverage for node eviction

-   OfflineVirtualMachine status improvements

-   RegistryDisk API update

\#\# v0.4.0

Released on: Fri Apr 6 16:40:31 2018 +0200

-   Fix several networking issues

-   Add and enable OpenShift support to CI

-   Add conditional Windows tests (if an image is present)

-   Add subresources for console access

-   virtctl config alignmnet with kubectl

-   Fix API reference generation

-   Stable UUIDs for OfflineVirtualMachines

-   Build virtctl for MacOS and Windows

-   Set default architecture to x86\_64

-   Major improvement to the CI infrastructure (all containerized)

-   virtctl convenience functions for starting and stopping a VM

\#\# v0.3.0

Released on: Thu Mar 8 10:21:57 2018 +0100

-   Kubernetes compatible networking

-   Kubernetes compatible PV based storage

-   VirtualMachinePresets support

-   OfflineVirtualMachine support

-   RBAC improvements

-   Switch to q35 machien type by default

-   A large number of test and CI fixes

-   Ephemeral disk support

\#\# v0.2.0

Released on: Fri Jan 5 16:30:45 2018 +0100

-   VM launch and shutdown flow improvements

-   VirtualMachine API redesign

-   Removal of HAProxy

-   Redesign of VNC/Console access

-   Initial support for different vagrant providers

\#\# v0.1.0

Released on: Fri Dec 8 20:43:06 2017 +0100

-   Many API improvements for a proper OpenAPI reference

-   Add watchdog support

-   Drastically improve the deployment on non-vagrant setups

-   Dropped nodeSelectors

-   Separated inner component deployment from edge component deployment

-   Created separate manifests for developer, test, and release
    deployments

-   Moved komponents to kube-system namespace

-   Improved and unified flag parsing
