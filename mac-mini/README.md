# Mac mini service lifecycle

This directory records the operating policy for the Mac mini host. The OpenSpec change under `openspec/changes/mac-mini-service-lifecycle/` is the behavior contract; this file records conservative defaults selected for the first implementation batches.

## Ownership

- OpenTofu will render host configuration using a pinned local provider and local state protected by FileVault. Docker Compose remains the sole owner of Immich containers.
- Docker Compose remains the only owner of the Immich containers and bind mounts.
- macOS and Docker Desktop are updated through Apple and Docker's official channels. OpenTofu does not install either application.
- ChatGPT Desktop remains on OpenAI's official update path. OpenTofu does not update it; a future status check must rely on verifiable official information and must not use a third-party package source or manipulate session data.

## Update defaults

- Check official stable releases daily and raise a reviewable change with exact versions and image digests.
- Do not automatically apply production updates. A reviewed pull request, a fresh verified database backup, storage checks, compatibility review, and post-update verification are required.
- macOS major upgrades, Docker Desktop installation, and Immich database migrations are separate maintenance changes. Verify the lower layer before proceeding to the next one.
- Docker Desktop may download an update automatically, but installation remains a reviewed maintenance action.
- Track Docker Desktop's current official macOS support window dynamically; do not hard-code a permanent count of supported OS releases.

## State and privacy

The local OpenTofu state is stored on the internal FileVault-protected disk and excluded from Git. It contains no database credentials, but it does contain private volume identities and paths. Use `umask 077` before local OpenTofu initialization/apply, keep the state file at mode `0600`, and keep the generated staging directory at mode `0700`. Saved plans, `.tfvars`, production `.env`, sentinels, and host-specific paths are excluded from Git and CI artifacts. Keep the state on this FileVault-protected host. The Local provider cannot import the existing safe-start script or LaunchAgent, so the root currently renders ignored staging files only; it does not overwrite or adopt active production files. A first production installation needs a separate reviewed backup-and-activation procedure.

## Startup and failure policy

- The active LaunchAgent is user-scoped. FileVault is enabled, so unattended startup before unlock is not promised; automatic login will not be enabled as a workaround.
- The active safe-start checks required volumes before startup. The candidate monitor adds runtime fail-closed behavior, but is staged and inactive until separately installed.
- Missing or incorrect storage must block startup and must never create fallback media or backup directories.
- An internet outage does not trigger a version change or prevent LAN-local operation when the host and required disks remain healthy.

## Production adoption prerequisite

The repository Compose and safe-start templates differ from the live files on the Mac mini. OpenTofu currently stages generated files under `mac-mini/iac/.generated/`; it does not install them. Before production adoption, reconcile the Compose and safe-start behavior, snapshot the current LaunchAgent and scripts to EnvoySSD, validate the staged plist/scripts/Compose config, and review the exact launchd activation plan. Applying the staging root does not modify production services.

The 120 GB EnvoySSD holds database backups, not a second copy of the roughly 1 TB media library. An independent media-backup destination and recovery objectives remain unresolved; until then, the system can fail closed when the media disk disappears but cannot claim complete recovery from permanent media-disk failure.
