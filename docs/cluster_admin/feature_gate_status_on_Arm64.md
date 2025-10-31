# Feature Gate Status on arm64

This document tracks the status of KubeVirt feature gates on the arm64 architecture.

## Status Definitions

 **SUPPORTED**: The feature gate is supported on arm64 and verified by CI
 **PENDING**: Support for this feature gate is pending
 **UNSUPPORTED**: The feature gate is not supported on arm64
 **UNVERIFIED**: The feature gate is expected to work on arm64 but is not verified by CI

## CI Test Coverage

The arm64 CI lanes run tests labeled with `wg-arm64`. Tests are excluded if they:

- Require AMD64-specific features (ACPI, specific CPU models, SEV/TDX)
- Require multiple schedulable nodes (limited by CI infrastructure)
- Require specialized hardware (GPU, SR-IOV)

Current test lane:

1. **wg-arm64**: Basic functional tests (serial execution)

**Note**: The **sig-compute-migrations-wg-arm64** lane for live migration tests is defined in `automation/test.sh` but is not yet configured to run in CI. This lane would test migration features with storage and networking support.

FEATURE GATE | GRADUATION | STATUS
-- | -- | --
AlignCPUsGate | Alpha | UNVERIFIED
AutoResourceLimitsGate | GA | UNVERIFIED
BochsDisplayForEFIGuests | GA | UNVERIFIED
ClusterProfiler | GA | UNVERIFIED
CommonInstancetypesDeploymentGate | GA | UNVERIFIED
CPUManager | Alpha | UNVERIFIED
CPUNodeDiscoveryGate | GA | UNVERIFIED
DecentralizedLiveMigration | Alpha | UNVERIFIED
DeclarativeHotplugVolumesGate | Alpha | UNVERIFIED
DisableCustomSELinuxPolicy | GA | UNVERIFIED
DisableMediatedDevicesHandling | Alpha | UNVERIFIED
DockerSELinuxMCSWorkaround | Deprecated | UNVERIFIED
DownwardMetricsFeatureGate | Alpha | UNVERIFIED
DynamicPodInterfaceNamingGate | GA | UNVERIFIED
ExpandDisksGate | Alpha | UNVERIFIED
GPUGate | GA | UNVERIFIED
GPUsWithDRAGate | Alpha | UNVERIFIED
HostDevicesGate | Alpha | UNVERIFIED
HostDevicesWithDRAGate | Alpha | UNVERIFIED
HostDiskGate | Alpha | SUPPORTED
HotplugNetworkIfacesGate | GA | UNVERIFIED
HotplugVolumesGate | Alpha | UNVERIFIED
HypervStrictCheckGate | Alpha | UNSUPPORTED
IgnitionGate | Alpha | UNVERIFIED
ImageVolume | Beta | SUPPORTED
IncrementalBackupGate | Alpha | UNVERIFIED
InstancetypeReferencePolicy | GA | UNVERIFIED
KubevirtSeccompProfile | Beta | UNVERIFIED
LiveMigrationGate | GA | UNVERIFIED
MacvtapGate | Discontinued | PENDING
MigrationPriorityQueue | Alpha | UNVERIFIED
MultiArchitecture | Deprecated | UNVERIFIED
NetworkBindingPlugingsGate | GA | UNVERIFIED
NodeRestrictionGate | Beta | UNVERIFIED
NonRoot | GA | UNVERIFIED
NUMAFeatureGate | GA | PENDING
ObjectGraph | Alpha | UNVERIFIED
PanicDevicesGate | Beta | SUPPORTED
PasstGate | Discontinued | UNVERIFIED
PasstIPStackMigration | Alpha | UNVERIFIED
PersistentReservation | Alpha | UNVERIFIED
PSA | GA | UNVERIFIED
Root | Alpha | UNVERIFIED
SecureExecution | Beta | UNVERIFIED
SidecarGate | Alpha | UNVERIFIED
SnapshotGate | Beta | UNVERIFIED
SRIOVLiveMigrationGate | GA | UNVERIFIED
VideoConfig | Beta | UNVERIFIED
VirtIOFSConfigVolumesGate | Alpha | UNVERIFIED
VirtIOFSGate | Deprecated | UNVERIFIED
VirtIOFSStorageVolumeGate | Alpha | UNVERIFIED
VMLiveUpdateFeaturesGate | GA | UNVERIFIED
VMExportGate | Beta | UNVERIFIED
VMPersistentState | GA | UNVERIFIED
VolumeMigration | GA | UNVERIFIED
VolumesUpdateStrategy | GA | UNVERIFIED
VSOCKGate | Alpha | UNVERIFIED
WorkloadEncryptionSEV | Alpha | UNSUPPORTED
WorkloadEncryptionTDX | Alpha | UNVERIFIED

## Notes

### Features with CI Verification (SUPPORTED)

The following features have dedicated test coverage in the active arm64 CI lane:

- **HostDiskGate**: Tested in storage tests with wg-arm64 label
- **ImageVolume**: Tested with enable/disable scenarios in container disk tests
- **PanicDevicesGate**: Explicitly enabled and tested in VMI lifecycle tests

### Features Planned for CI Verification

The following features have tests defined but are not currently running in CI:

- **LiveMigrationGate**: Tests defined for sig-compute-migrations-wg-arm64 lane (not yet active)
- **VolumeMigration**: Tests defined in storage migration (requires sig-compute-migrations-wg-arm64 lane)

### Architecture-Specific Limitations

The following features are marked UNSUPPORTED due to architecture-specific requirements:

- **HypervStrictCheckGate**: Hyper-V enlightenments are x86_64-only
- **WorkloadEncryptionSEV**: AMD SEV is x86_64-only

### CI Infrastructure Limitations

Some tests are excluded from arm64 CI due to infrastructure constraints:

- Tests requiring multiple schedulable nodes (limited by CI resources)
- Tests requiring specialized hardware (GPU, SR-IOV, vGPU)
- Tests requiring specific CPU models or ACPI features
- Tests marked as requiring AMD64 architecture

### Pending Features

- **MacvtapGate**: Requires macvtap-cni support for arm64
- **NUMAFeatureGate**: Requires hugepages support verification on arm64

### Contributing

To improve arm64 test coverage, add the `decorators.WgArm64` label to tests in:

- `tests/` directory for the wg-arm64 lane
- Ensure tests don't require excluded features (ACPI, multiple nodes, AMD64-specific)
