# Mac mini dependency inventory

Observed read-only on 2026-11-15. These values describe the running host on that date; they are not a compatibility guarantee or an update authorization. Re-check versions and vendor guidance before each maintenance window.

| Layer | Observed version | Authority / source of truth | Qualification gate |
|---|---|---|---|
| Hardware | Mac mini, Apple M2 Pro | Apple system information | Confirm architecture and supported model before a macOS major upgrade |
| macOS | 26.6.1 | Apple Software Update | Check Docker Desktop's current macOS support window and backup status first |
| Docker Desktop | 4.93.0 | Docker Desktop official updater and [release notes](https://docs.docker.com/desktop/release-notes/) | Review bundled Engine/Compose changes; install as its own maintenance step |
| Docker Engine | 29.8.1 | Bundled with Docker Desktop; [Engine release notes](https://docs.docker.com/engine/release-notes/) | Do not independently replace the bundled engine |
| Docker Compose | 5.5.1 | Bundled with Docker Desktop; [Compose release notes](https://docs.docker.com/compose/release-notes/) | Validate the deployment Compose file before changing Desktop |
| OpenTofu | 1.13.9 | OpenTofu official release channel | Change the pinned CLI constraint in a reviewed repository change; preserve local state |
| OpenTofu provider | `hashicorp/local` 2.9.1 | Locked in `mac-mini/iac/.terraform.lock.hcl` | Review provider release notes and the plan; no production adoption until host-file ownership is reconciled |
| Immich server and ML | v3.3.5 | [Immich stable releases](https://github.com/immich-app/immich/releases) | Draft update PR pins both image digests; review intermediate migrations, backup, Motion Photo canary, and rollback |
| Immich PostgreSQL | `14-vectorchord0.4.3-pgvectors0.2.0` | Immich-supported image in Compose | Update only with an Immich compatibility review and a verified database restore path |
| Valkey | 9 | Pinned image and digest in Compose | Review data compatibility; preserve the existing named volume |
| ChatGPT Desktop | 26.1021.31345 installed | [OpenAI macOS app update guidance](https://help.openai.com/en/articles/9275200-downloading-the-chatgpt-macos-app) | OpenAI's supported app update path; the official update-status query returned `busy`, so newer-version availability was not established. No supported OpenTofu/CLI installer is documented |

## Service health observed with the version snapshot

The four Compose services were running and reported healthy: Immich server, Immich machine learning, Immich PostgreSQL, and Valkey. Docker reported them up for approximately two weeks. This read-only check did not inspect asset integrity, queues, backups, or Motion Photo scan behavior.

## Dependency chain and update order

`Mac mini / Apple silicon → macOS + FileVault/APFS/login behavior → Docker Desktop → bundled Docker Engine + Compose → Compose-managed Immich server + ML + PostgreSQL extensions + Valkey → media, external-library, and EnvoySSD mounts.`

The management chain also includes OpenTofu CLI, its locked provider, local state, and CI. Keep Compose as the only container owner. Update one layer at a time: verify macOS support and recovery first, then Docker Desktop and its bundled components, then the pinned OpenTofu/provider, and finally Immich after release-note and database-migration review. Re-run storage identity, sentinel, Compose, container-health, backup, and Motion Photo canary checks at the layer that can affect them.

The Immich release workflow checks the official stable release daily and raises a draft PR with server/ML digests. It does not deploy. Docker Desktop and macOS installation remain on their vendor update paths; this inventory is a dated snapshot, not a claim that those products have an automated update monitor. ChatGPT Desktop also remains on OpenAI's supported updater; this repository does not install or silently update the app.

## Sources

- [Docker Desktop for Mac system requirements](https://docs.docker.com/desktop/setup/install/mac-install/)
- [Docker Desktop release notes](https://docs.docker.com/desktop/release-notes/)
- [Docker Engine release notes](https://docs.docker.com/engine/release-notes/)
- [Docker Compose release notes](https://docs.docker.com/compose/release-notes/)
- [Immich releases](https://github.com/immich-app/immich/releases)
- [OpenTofu installation and releases](https://opentofu.org/docs/intro/install/)
- [OpenAI: Downloading the ChatGPT macOS app](https://help.openai.com/en/articles/9275200-downloading-the-chatgpt-macos-app)
