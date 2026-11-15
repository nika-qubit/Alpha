# Mac mini service lifecycle

This directory records the operating policy for the Mac mini host. The OpenSpec change under `openspec/changes/mac-mini-service-lifecycle/` is the behavior contract; this file records conservative defaults selected for the first implementation batches.

## Ownership

- OpenTofu will manage host-level files and policy artifacts only, using pinned providers and local state protected by FileVault.
- Docker Compose remains the only owner of the Immich containers and bind mounts.
- macOS and Docker Desktop are updated through Apple and Docker's official channels. OpenTofu does not install either application.
- ChatGPT Desktop remains on OpenAI's official update path. The monitor reports its installed version and whether an official update can be verified; it will not use a third-party package source or manipulate session data.

## Update defaults

- Check official stable releases daily and raise a reviewable change with exact versions and image digests.
- Do not automatically apply production updates. A reviewed pull request, a fresh verified database backup, storage checks, compatibility review, and post-update verification are required.
- macOS major upgrades, Docker Desktop installation, and Immich database migrations are separate maintenance changes. Verify the lower layer before proceeding to the next one.
- Docker Desktop may download an update automatically, but installation remains a reviewed maintenance action.
- Track Docker Desktop's current official macOS support window dynamically; do not hard-code a permanent count of supported OS releases.

## State and privacy

The local OpenTofu state is stored on the internal FileVault-protected disk and excluded from Git. It contains no credentials. Saved plans, `.tfvars`, production `.env`, disk UUIDs, sentinels, and host-specific paths are also excluded from Git and CI artifacts. If local state is lost, reconstruct it by importing the existing host files and reviewing the resulting plan; do not apply an empty-state plan to production.

## Startup and failure policy

- The existing LaunchAgent starts Immich only after a user session exists, Docker Desktop is ready, and both expected volumes pass private UUID and sentinel checks. FileVault is enabled, so unattended startup before unlock is not promised; automatic login will not be enabled as a workaround.
- Missing or incorrect storage blocks startup and must never create fallback media or backup directories.
- A runtime volume monitor will stop the Immich Compose stack and alert if a required disk disappears. It may restart the stack only after Docker and both volume checks pass again.
- An internet outage does not trigger a version change or prevent LAN-local operation when the host and required disks remain healthy.

## Known prerequisite before first OpenTofu apply

The repository Compose and safe-start templates currently differ from the live files on the Mac mini. Reconcile that drift, preserve current production behavior, import the existing files into OpenTofu state, and review a no-surprise plan before applying. No OpenTofu apply is authorized by this policy file alone.

The 120 GB EnvoySSD holds database backups, not a second copy of the roughly 1 TB media library. An independent media-backup destination and recovery objectives remain unresolved; until then, the system can fail closed when the media disk disappears but cannot claim complete recovery from permanent media-disk failure.
