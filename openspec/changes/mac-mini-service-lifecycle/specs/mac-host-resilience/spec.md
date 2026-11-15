## ADDED Requirements

### Requirement: Fail-closed storage startup

Immich SHALL start only when every required external volume is mounted at the expected mount point and passes a stable identity check and sentinel check. Missing mount paths SHALL NOT be created as substitute directories.

#### Scenario: The Mac reboots while a required disk is unavailable

- **WHEN** Docker Desktop becomes ready before a required volume is mounted
- **THEN** Immich remains stopped and the startup check records which volume is unavailable
- **AND** Immich starts only after a later check confirms the expected volume and sentinel

#### Scenario: A disk with the wrong identity is mounted at the expected name

- **WHEN** a volume name matches but its identity does not match the configured value
- **THEN** startup is blocked and no Immich bind mount is created against that volume

### Requirement: Runtime response to storage loss

The deployment SHALL detect loss of a required media or backup volume while Immich is running. It SHALL prevent writes from falling through to an empty host directory and SHALL alert the operator with the affected mount and service state.

#### Scenario: The media volume disconnects during service

- **WHEN** the media volume is no longer mounted or its sentinel becomes unavailable
- **THEN** the deployment enters a protected degraded state within the configured detection interval
- **AND** it does not create replacement media directories or continue ingesting into a fallback path
- **AND** it reports the action needed to restore the volume and service

### Requirement: Reboot recovery

After power loss or an operating-system restart, Immich SHALL recover only after Docker Desktop is responsive and all required storage checks pass. The recovery procedure SHALL state any macOS login or FileVault unlock dependency and SHALL distinguish automatic recovery from steps requiring a person at the Mac.

#### Scenario: Power returns without a usable user session

- **WHEN** Docker Desktop or the user LaunchAgent cannot start because macOS has not established the required user session
- **THEN** the deployment remains stopped safely
- **AND** the runbook explains the minimum manual action needed to continue recovery

### Requirement: Network outage behavior

Loss of internet access SHALL NOT cause a healthy LAN-local Immich deployment to restart or change versions. Release checks and remote integrations SHALL report degraded connectivity and resume when the network returns.

#### Scenario: Internet access is unavailable but LAN and disks remain available

- **WHEN** the Mac mini can reach local clients but cannot reach external services
- **THEN** local Immich access remains available to the extent supported by the running services
- **AND** no update or remote-dependent action is attempted with incomplete release data

### Requirement: Backup scope and recovery claims

The deployment SHALL state which data each backup covers. A database dump SHALL NOT be described as a media backup. The deployment SHALL NOT claim protection against media-disk failure until an independent copy of original media and required sidecars has been identified and verified.

#### Scenario: Only the database backup is available

- **WHEN** the media volume is lost and only a database dump can be reached
- **THEN** the recovery status explicitly reports that original media recovery is incomplete
- **AND** it does not report the library as fully recoverable

#### Scenario: A risky database migration is planned

- **WHEN** a release can alter the database schema
- **THEN** a current database backup is integrity-checked and restored in an isolated rehearsal before production deployment
- **AND** routine restore drills are not required between risky changes unless the recovery design changes or a failure occurs
