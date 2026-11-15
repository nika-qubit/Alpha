## ADDED Requirements

### Requirement: Official ChatGPT Desktop update channel

ChatGPT Desktop SHALL be updated through an official OpenAI distribution or in-app update mechanism. The system SHALL NOT replace it with an unverified package source or claim it is current without comparing the installed app version with the latest version information available from OpenAI.

#### Scenario: The official updater offers an update

- **WHEN** the official ChatGPT Desktop updater reports a compatible update
- **THEN** the update status identifies the available version and directs installation through that official mechanism
- **AND** Immich or OpenTofu SHALL NOT modify the user's ChatGPT session data

#### Scenario: No machine-readable official version is available

- **WHEN** OpenAI does not publish a machine-readable version feed or supported command-line update interface
- **THEN** the system reports that version verification is incomplete and points to the official release notes or download page
- **AND** it does not infer automatic update capability from the presence of an installed app

### Requirement: Visible update status

The system SHALL report the installed ChatGPT Desktop version, the latest verified official release information, the last successful check time, and any action required from the operator.

#### Scenario: A newer official release is available

- **WHEN** the verified official version is newer than the installed application
- **THEN** the system reports ChatGPT Desktop as behind
- **AND** it continues to report behind until the installed version is re-read and verified after updating

#### Scenario: The Mac is offline

- **WHEN** the official release information cannot be checked
- **THEN** the last verified version and check time are retained
- **AND** the app is marked unknown rather than current
