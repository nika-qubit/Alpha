# Proposal

## Why

Immich now runs on the Mac mini, but its release checks, Docker deployment, external-disk safeguards, backups, and restart behavior are documented across separate files and manual steps. ChatGPT Desktop has a separate vendor-managed update path, so a single host lifecycle plan is needed to make update status visible without putting the photo library or database at risk.

## What Changes

- Define an OpenTofu-based, reviewable source of truth for Mac mini host configuration and service lifecycle policy.
- Track compatibility and supported update paths across macOS, Docker Desktop, its bundled Docker Engine and Compose, OpenTofu/providers, and the Immich service images.
- Specify how Immich stable releases are detected, pinned, qualified, deployed, and rolled back.
- Specify safe behavior for power loss, network loss, missing or disconnected storage, and Docker Desktop startup delays.
- Specify how ChatGPT Desktop stays on an official update channel and how stale or blocked updates are reported.
- Keep secrets, live state, and machine-specific disk identifiers out of the public repository.

This change is a planning package only. It does not create OpenTofu resources, update the production Compose stack, change the ChatGPT app, or apply anything to the Mac mini.

## Capabilities

### New Capabilities

- `immich-release-lifecycle`: Track and safely adopt official stable Immich releases.
- `motion-photo-integrity`: Preserve Motion Photo relationships and verify playback through library scans and upgrades.
- `mac-host-resilience`: Start and recover Immich safely across host, network, and storage failures.
- `host-platform-lifecycle`: Track the complete host-to-container dependency chain and update it in compatible, reversible layers.
- `desktop-app-updates`: Track ChatGPT Desktop through its official update channel and surface stale versions.

### Modified Capabilities

None.

## Impact

- Planning artifacts under `openspec/` in the Alpha repository.
- Future implementation may touch `immich-app/docker-compose.yml`, the safe-start LaunchAgent, host monitoring, and update automation.
- No production files, credentials, database, media, or running services change in this proposal.
