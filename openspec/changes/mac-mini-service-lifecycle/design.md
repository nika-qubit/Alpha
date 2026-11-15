# Design

## Context

Alpha is the current canonical repository for the Mac Immich deployment and its recovery notes. The other existing repositories do not fit this host lifecycle: `Psi` is a C++ NAS project, and the Open App Hub / MarketProfile repositories are application development projects. Keeping this change in Alpha puts the proposed lifecycle contract next to the existing Immich Compose and safe-start templates.

Alpha is public. The change therefore contains only generic paths and policy. Live credentials, `.env`, API keys, actual disk UUIDs, personal network details, OpenTofu state, and saved plans remain outside Git.

## Goals

- Make Immich release status and safe update readiness visible.
- Track support and compatibility across the entire host-to-container dependency chain.
- Preserve Motion Photo relationships and playback across scans and upgrades.
- Recover safely after power loss and Docker Desktop delays.
- Fail closed when the media or backup disk is missing, replaced, or disconnected.
- Keep ChatGPT Desktop on OpenAI's official update path without treating it as an Immich or OpenTofu-managed container.
- Preserve a single owner for each managed resource and a human-readable rollback path.

## Non-goals

- Applying any production changes as part of this OpenSpec change.
- Running Immich on a floating image tag or applying updates without qualification.
- Storing production secrets or machine-specific volume identifiers in the public repo.
- Claiming that a database backup protects original media.
- Promising headless recovery before determining the actual macOS login and FileVault behavior.

## Proposed ownership model

- **OpenTofu:** declarative host-level configuration and lifecycle policy that can be represented safely in state; provider selection is deferred until a small non-production proof confirms support for macOS files, LaunchAgents, and the required checks.
- **Docker Compose:** remains the sole owner of the Immich containers and their bind mounts while the current stack is Compose-based. OpenTofu SHALL NOT also manage those containers through a second provider.
- **Release workflow:** a scheduled checker reads official Immich release information and prepares a reviewable version-and-digest change. CI validates Compose and produces a speculative OpenTofu plan. Production rollout happens only through the approved safe-start/upgrade procedure after all gates pass.
- **ChatGPT Desktop:** remains owned by OpenAI's supported app update channel. A local status check may report version drift, but it SHALL NOT install from a third-party package source or manipulate user session data.

OpenTofu provisioners are not the default bridge for running `docker compose up`; the official OpenTofu documentation describes provisioners as a last resort. Prefer a clear, separately reviewable deployment command or a provider with lifecycle behavior that passes acceptance checks.

## Dependency chain and update ownership

The declared chain is: Mac mini hardware/Apple silicon → macOS and its login, FileVault, and APFS behavior → Docker Desktop → the Docker Engine and Compose versions shipped with that Desktop release → the Compose-managed Immich server and machine-learning images, PostgreSQL with its required extensions, and Valkey → mounted media, external-library, and backup volumes. The management chain also includes the OpenTofu CLI, its pinned providers, the OpenTofu state, and the CI runner that creates speculative plans.

Maintain a version and compatibility matrix rather than setting every component to “latest.” Record the official source, installed and proposed versions, architecture support, compatibility notes, support window, and recovery path. Immich server/ML image digests and the PostgreSQL/Valkey versions remain explicit in the deployment. Docker Engine and Compose are recorded as the versions bundled with Docker Desktop; they are not independently replaced behind Desktop's back.

Update in layers: (1) macOS through Apple's supported updater after checking Docker Desktop support; (2) Docker Desktop through Docker's official updater and record its bundled Engine/Compose versions; (3) OpenTofu CLI/providers through pinned, reviewed dependency changes; (4) Immich and its companion images through the qualified service-upgrade workflow. Do not combine a macOS major upgrade, Docker Desktop update, and Immich schema migration in one maintenance window. Re-run mount, sentinel, Docker readiness, bind-mount, Compose, container-health, and Motion Photo checks after each applicable layer before moving on.

Docker documents a rolling support window for macOS and publishes per-release Desktop, Engine, and Compose changes. These are inputs to the compatibility matrix, not permanent hard-coded version assumptions. Apple OS updates use Apple's update path; Docker Desktop updates use Docker's official path; OpenTofu describes desired configuration and reviewable plans, not a replacement updater for either vendor application.

## Update policy recommendation

Recommended starting policy: check for official releases daily and raise a review item within 24 hours. Permit routine production updates only after the backup, storage, migration, and health gates pass. A patch release with no schema change may be eligible for automatic rollout after an isolated canary proves the path; major releases, schema changes, required intermediate upgrades, and any failed gate require explicit operator review. Do not report “current” when a gate blocks deployment.

The exact update service-level objective and whether qualified patch releases may apply without a person are Open Questions. The specification must be adjusted after the owner chooses these policies.

## Storage and failure model

- Startup checks verify mounted volume identity and sentinel content before Compose is invoked; Compose bind mounts disallow host path creation.
- A runtime monitor checks required mounts. On storage loss, it must protect the library from fallback writes and alert. The implementation proof must determine whether it can safely stop only ingestion or must stop the server stack.
- A network outage does not trigger container recreation or version changes. Local LAN service remains independent of external release checks where feasible.
- Power recovery depends on Docker Desktop and the logged-in macOS user's LaunchAgent. Confirm whether FileVault or login requirements prevent unattended restart; do not enable automatic login as an implicit workaround.
- Daily database dumps on EnvoySSD cover the database only. A separate independent copy of originals and sidecars is required before claiming recovery from ImmichMedia failure. The available EnvoySSD is much smaller than the active media library, so it cannot be assumed to hold a full media copy.

## OpenTofu state and Git safety

- Keep the state file and saved plans out of Git and out of public CI artifacts.
- Keep credentials outside OpenTofu inputs where possible; never put the live Immich `.env` into Terraform state.
- Decide whether the single-operator state lives encrypted on the internal SSD with a protected copy on EnvoySSD, or in an encrypted remote backend with locking. Test recovery of state before adopting a backend.
- Pin provider versions and commit the dependency lock file.
- Require plan review before production changes. Do not use unattended `-auto-approve` for database, mount, or service restart changes.

## Update and rollback flow

1. Detect official stable releases and review release notes, compatibility, and intermediate upgrade requirements.
2. Propose exact versions and image digests in a repository change; validate Compose, OpenTofu syntax/plan, secret scanning, and policy checks in CI.
3. On the Mac mini, verify disk identities, sentinels, free space, current health, and a fresh EnvoySSD database backup.
4. For schema-changing updates, restore the backup in an isolated rehearsal and compare required database and asset invariants before production.
5. Apply the reviewed change using the established deployment path and verify health, backup, storage, external-library state, Motion Photo playback, and asset invariants.
6. If verification fails, follow the recorded rollback choice. For schema changes, restore the pre-upgrade database and the corresponding media state; reverting an image alone is not sufficient.
7. Retain recovery sources until the new version and data integrity have been accepted. Cleanup is a separate reviewed change.

An external-library scan is a data-integrity gate, not just an operational smoke test. A canary set must include internal-library and external-library Motion Photos. The scan result must preserve the parent-photo/video-component relation, keep both available when their source files and volumes are present, and confirm actual playback in the supported clients. Any Offline or Trash transition must be explained against source-file and mount evidence before the rollout is accepted.

## ChatGPT Desktop update source

OpenAI's current macOS download guidance points to the official ChatGPT download page, and its desktop migration guidance says existing users should update through the app's normal flow. The available official help pages do not document a supported OpenTofu provider or stable CLI for app-version management. Therefore the design prefers the vendor updater and a version/status monitor; it does not assume OpenTofu can force a silent app update.

References:

- [OpenAI: Downloading the ChatGPT macOS app](https://help.openai.com/en/articles/9275200-downloading-the-chatgpt-macos-app)
- [OpenAI: Moving to the new ChatGPT desktop app](https://help.openai.com/en/articles/20001276-moving-to-the-new-chatgpt-desktop-app)
- [OpenAI: ChatGPT macOS app release notes](https://help.openai.com/en/articles/9703738-desktop-app-release-notes)
- [OpenTofu: Provisioners](https://opentofu.org/docs/language/resources/provisioners/syntax/)
- [OpenTofu: Plan command](https://opentofu.org/docs/cli/commands/plan/)
- [OpenSpec: spec-driven schema](https://github.com/Fission-AI/OpenSpec/blob/main/schemas/spec-driven/schema.yaml)
- [Docker: Docker Desktop system requirements for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
- [Docker: Docker Desktop release notes](https://docs.docker.com/desktop/release-notes/)
- [Docker: Docker Desktop release FAQ](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/releases/)
- [Docker: Docker Compose release notes](https://docs.docker.com/compose/release-notes/)
- [Apple: Update macOS on Mac](https://support.apple.com/en-mide/108382)

## Open Questions

1. What update lag is acceptable for Immich stable patch releases, and may qualified patch releases deploy automatically after all gates pass? Recommendation: detect within 24 hours; allow patch deployment within 7 days only after a passing canary; require review for schema changes and major releases.
2. What independent media-backup target is available, and what recovery point and recovery time objectives should apply? The current 120 GB EnvoySSD cannot hold a second copy of the active media library.
3. Is the Mac mini expected to recover without a person logging in after power loss? Confirm the FileVault and Docker Desktop login behavior before promising unattended recovery.
4. Is ChatGPT Desktop installed on this Mac mini and expected to update automatically, or should this system only report its version and notify the operator to use OpenAI's updater?
5. Which state backend and recovery copy are acceptable for a single-operator OpenTofu deployment?
6. If ImmichMedia disconnects while the service is live, should the monitor stop the entire Immich stack or only block writes/ingestion? The implementation must prove there is no fallback write path before choosing.
7. Which exact macOS, Docker Desktop, bundled Engine/Compose, OpenTofu, and provider support windows should trigger warning and upgrade deadlines? Recommendation: track the vendors' current support policy rather than pinning a fixed number of supported macOS releases in code.
8. Should Docker Desktop be configured to download updates automatically while deferring installation to a reviewed maintenance window?
