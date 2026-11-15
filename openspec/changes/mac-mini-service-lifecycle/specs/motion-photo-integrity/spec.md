## ADDED Requirements

### Requirement: Motion Photo relationship preservation

The deployment SHALL preserve the database relationship between a Motion Photo's parent image and its video component during release upgrades, metadata work, and external-library scans. An `encoded-video` path SHALL NOT be treated as disposable cache solely because it is generated or derived by Immich.

#### Scenario: A supported external-library scan completes

- **GIVEN** the parent photo and linked video component are present on their expected mounted volumes
- **WHEN** an external-library scan completes
- **THEN** the parent-photo/video-component relationship remains intact
- **AND** neither asset is marked Offline or moved to Trash because of a transient scan or mount-order error

#### Scenario: A parent photo has an associated video component

- **WHEN** a canary Motion Photo is checked after a scan or upgrade
- **THEN** the photo and its motion video play as a Motion Photo in the supported Immich web and mobile clients
- **AND** the verification records the scan time and asset relationship without exposing private filenames in public logs

### Requirement: Missing-component protection

When a linked Motion Photo component is absent, the system SHALL preserve the parent relationship and SHALL NOT create an empty placeholder or rewrite the database path to an unverified file. The component SHALL remain recoverable through the normal retention policy while its source and cause are investigated.

#### Scenario: A component is missing but its parent original exists

- **WHEN** the component path is absent and the parent photo original is present
- **THEN** the item is classified as recoverable from the parent source for a separately reviewed repair
- **AND** the component is not permanently deleted or replaced with a fabricated file during the scan

#### Scenario: A component is Offline or in Trash after scanning

- **WHEN** a post-scan check finds a Motion Photo component marked Offline or in Trash
- **THEN** the rollout is not declared data-integrity verified
- **AND** the report includes parent availability, component file existence, mount identity, and retention status before repair is proposed

### Requirement: Bounded Motion Photo verification

Every production Immich release that changes media handling SHALL pass a bounded canary containing internal-library and external-library Motion Photos before broader scans or recovery jobs are run. Verification SHALL include file presence, database linkage, Offline/Trash state, and actual playback.

#### Scenario: The canary detects a regression

- **WHEN** any canary Motion Photo loses its relationship, becomes Offline despite present source files, or fails playback
- **THEN** broader scans and batch recovery are blocked
- **AND** the previous known-good application and recovery sources are retained pending investigation
