## ADDED Requirements

### Requirement: Complete dependency inventory

The deployment SHALL maintain one reviewable inventory of the versions and update owners for the Mac hardware architecture, macOS, Docker Desktop, its bundled Docker Engine and Docker Compose, OpenTofu CLI and providers, Immich server and machine-learning images, PostgreSQL image/extensions, and Valkey. The inventory SHALL identify each component's official release source, compatibility constraints, support status, and rollback or recovery method.

#### Scenario: A dependency is added or replaced

- **WHEN** a runtime or deployment dependency changes
- **THEN** its version source, compatibility relationship, owner, and recovery path are added to the inventory before production rollout
- **AND** no second tool is allowed to own the same resource

#### Scenario: A component version cannot be verified

- **WHEN** the installed version or official support status of a dependency is unknown
- **THEN** the system reports that part of the chain as unverified
- **AND** it does not report the complete deployment as current or supported

### Requirement: Compatibility-gated host updates

macOS, Docker Desktop, Docker Engine, Docker Compose, OpenTofu, and provider updates SHALL be checked against the official compatibility and support information for the exact Mac architecture and installed versions. The system SHALL NOT assume that the latest release of each component is mutually compatible.

#### Scenario: Docker Desktop support changes for macOS

- **WHEN** Docker changes the macOS versions it supports
- **THEN** the inventory identifies whether the installed macOS remains supported
- **AND** a required OS upgrade is proposed as a separate, reviewable change with a recovery plan

#### Scenario: An OpenTofu provider update is proposed

- **WHEN** a provider version changes
- **THEN** the dependency lock file and compatibility checks are updated
- **AND** a speculative plan is reviewed before the provider can change production state

### Requirement: Layered host and runtime upgrades

Host, container-runtime, and application-stack updates SHALL be isolated into reviewable layers. The system SHALL verify the lower layer before upgrading the next layer and SHALL NOT combine an operating-system major upgrade, Docker Desktop upgrade, and Immich database migration into one unverified operation.

#### Scenario: A macOS update is approved

- **WHEN** an Apple update is selected for the Mac mini
- **THEN** Docker Desktop support, external-volume access, file-sharing behavior, login/startup behavior, and recovery steps are checked first
- **AND** the update is installed through Apple's supported update mechanism rather than OpenTofu

#### Scenario: Docker Desktop is updated

- **WHEN** a Docker Desktop release is selected
- **THEN** the resulting Desktop, Engine, and Compose versions are recorded together
- **AND** Docker readiness, Compose validation, bind mounts, APFS access, safe-start, and container health are verified before an Immich image update begins

#### Scenario: A lower layer fails verification

- **WHEN** macOS, Docker Desktop, Engine, Compose, OpenTofu, or a provider fails its post-update checks
- **THEN** updates to dependent layers are blocked
- **AND** the failure and supported recovery path are reported without upgrading Immich

### Requirement: Supported release currency

The deployment SHALL monitor official release and support information for the full dependency chain. It SHALL distinguish security updates, routine updates, major platform upgrades, and unsupported versions, and SHALL not claim a component is current solely because an automatic updater downloaded an installer.

#### Scenario: A host dependency approaches end of support

- **WHEN** the installed macOS or Docker Desktop version is approaching or has passed the vendor-supported window
- **THEN** the system reports the deadline and proposes a compatibility-reviewed upgrade sequence
- **AND** it retains the current recovery sources until the new layer passes verification

#### Scenario: Docker Desktop automatically downloads an update

- **WHEN** Docker Desktop downloads an update in the background
- **THEN** the deployment reports the installed version separately from the downloaded version
- **AND** production recovery and service checks still run after the update is installed

### Requirement: Operator-reviewed production updates

Official stable releases SHALL be checked daily and a reviewable version change SHALL be prepared within 24 hours when a newer compatible release is available. Production updates for macOS, Docker Desktop, OpenTofu providers, or Immich SHALL require operator review and SHALL pass backup, compatibility, storage, and post-update verification gates.

#### Scenario: A new stable release is found

- **WHEN** an official stable release is newer than the installed version
- **THEN** the system prepares a reviewable change with exact versions and image digests where applicable
- **AND** it does not apply the change to production automatically

#### Scenario: Docker Desktop downloads an update

- **WHEN** Docker Desktop automatically downloads an update
- **THEN** the downloaded and installed versions are reported separately
- **AND** installation remains a reviewed maintenance action
