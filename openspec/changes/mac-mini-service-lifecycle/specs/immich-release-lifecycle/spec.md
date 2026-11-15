## ADDED Requirements

### Requirement: Official stable release visibility

The deployment SHALL compare the running Immich version with the latest official stable Immich release at least once per day. It SHALL identify prereleases separately and SHALL NOT treat a prerelease as the production target.

#### Scenario: A new stable release is published

- **WHEN** Immich publishes a stable release newer than the pinned production version
- **THEN** the system records the current and proposed versions, the official release notes, and whether an intermediate upgrade is required
- **AND** it reports the deployment as behind until the approved target version is running

#### Scenario: No network is available during a release check

- **WHEN** the release source cannot be reached
- **THEN** the check reports its last successful check time and an unknown update status
- **AND** it does not infer that production is current

### Requirement: Reproducible production version selection

Each production Immich image SHALL use an explicit stable version and immutable image digest. The deployment SHALL NOT use a floating `latest` tag or silently change an image because an upstream tag moved.

#### Scenario: A candidate release is selected

- **WHEN** an update proposal is prepared
- **THEN** the proposal records the exact version, image digest, official release notes, database compatibility, and required migration path
- **AND** the current production version remains available as the rollback reference

### Requirement: Upgrade safety gates

The system SHALL NOT deploy an Immich update unless the required storage volumes pass identity and sentinel checks, the destination has sufficient free space, and a fresh database backup has completed and passed an integrity check. Database-changing updates SHALL also have a documented recovery path that accounts for the database and the media files together.

#### Scenario: A preflight check fails

- **WHEN** a required disk is absent, its identity differs, the backup is invalid, or free space is below the configured threshold
- **THEN** the update is blocked
- **AND** the report identifies the failed check without changing production

#### Scenario: A release requires an intermediate version

- **WHEN** official release guidance requires one or more intermediate upgrades
- **THEN** the update plan lists and validates each required step in order
- **AND** the system does not skip directly to the final version

### Requirement: Deployment verification and rollback readiness

After an approved update, the system SHALL verify container health, Immich readiness, database health, storage reporting, scheduled backup completion, and asset invariants before declaring the update complete. Rollback instructions SHALL distinguish image rollback from database rollback; restoring a compatible database backup SHALL be required when the newer version has changed the schema.

#### Scenario: Post-upgrade verification fails

- **WHEN** a required health or data-invariant check fails
- **THEN** the deployment is marked unsuccessful and the recovery plan is surfaced
- **AND** the system SHALL NOT delete pre-upgrade backups or the previous supported images

#### Scenario: A future release is not yet safe to deploy

- **WHEN** release notes, a required migration, or a failed rehearsal makes a candidate unsafe
- **THEN** the deployment remains on its known-good version
- **AND** the update status includes the blocker and next review condition
