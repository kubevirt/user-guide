# Arm64 Operations

This page summarizes all operations that are not supported on Arm64.

## Hotplug Network Interfaces

Hotplug Network Interfaces are not supported on Arm64, because the image ghcr.io/k8snetworkplumbingwg/multus-cni:snapshot-thick does not support for the Arm64 platform. For more information please refer to https://github.com/k8snetworkplumbingwg/multus-cni/pull/1027.

## Hugepages support

Hugepages feature is not supported on Arm64. The hugepage mechanism differs between X86_64 and Arm64. Now we only verify KubeVirt on 4k pagesize systems.

## Export API

Export API is partially supported on the Arm64 platform. As CDI is not supported yet, the export of DataVolumes and MemoryDump are not supported on Arm64.

## Virtual machine memory dump

As explained above, MemoryDump requires CDI, and is not yet supported on Arm64.

## Mediated devices and virtual GPUs

This is not verified on Arm64 platform.
