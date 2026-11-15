# Tasks

## 1. Resolve policy decisions

- [x] 1.1 Set the Immich release check target: check daily and raise a review change within 24 hours; every production update remains operator-reviewed.
- [ ] 1.2 Choose the independent media-backup target, retention, recovery point objective, and recovery time objective.
- [x] 1.3 Record current recovery constraints: FileVault is enabled and startup uses a logged-in user's LaunchAgent; verify cold-boot behavior before promising unattended recovery.
- [x] 1.4 Keep ChatGPT Desktop on OpenAI's official app update path; report version status only when it can be verified from official information.
- [x] 1.5 Keep local OpenTofu state on the internal FileVault-protected disk, excluded from Git and public CI artifacts; prove state recovery before production use.
- [x] 1.6 Set the proposed runtime response to missing required storage: fail closed, stop the Immich Compose stack, and restart only after Docker and volume identity/sentinel checks pass. Prove this in isolation before production.
- [x] 1.7 Track vendor support windows dynamically; do not hard-code a permanent macOS support count.
- [x] 1.8 Allow Docker Desktop to download updates automatically, while installation remains a reviewed maintenance action.

## 2. Prove the deployment boundaries

- [x] 2.1 Inventory which host files and policies OpenTofu will own and which remain owned by Docker Compose.
- [ ] 2.1a Reconcile the live Compose and safe-start files with the public repository templates before importing or applying OpenTofu; keep machine-specific values out of Git.
- [ ] 2.2 Evaluate candidate OpenTofu providers against macOS file, LaunchAgent, and state-recovery requirements in an isolated test environment.
- [ ] 2.3 Confirm a resource has exactly one owner; reject a design that manages Compose containers through both Compose and OpenTofu.
- [ ] 2.4 Confirm CI can validate a change without access to production credentials, state, media, or the Mac mini.
- [ ] 2.5 Build the dependency and compatibility inventory for macOS, Docker Desktop, bundled Engine/Compose, OpenTofu/providers, and every Immich service image.
- [ ] 2.6 Verify the planned layer order and recovery path for each host/runtime upgrade against current official vendor guidance.

## 3. Implement update visibility and qualification

- [x] 3.1 Add a daily official Immich stable-release check that produces a draft pull request with the exact server and machine-learning image digests; it never deploys to production.
- [ ] 3.2 Add compatibility and intermediate-upgrade checks from official release notes.
- [ ] 3.3 Add ChatGPT Desktop version reporting using only official OpenAI release/update sources.
- [ ] 3.4 Add CI validation for Compose configuration, OpenTofu formatting/validation/plan, secrets, and version pinning.

## 4. Implement and verify host recovery

- [ ] 4.1 Reconcile OpenTofu-managed host configuration with the existing safe-start LaunchAgent.
- [ ] 4.2 Verify cold boot, Docker-not-ready, missing-volume, wrong-volume, missing-sentinel, network-down, and runtime-disconnect scenarios without using production media for destructive tests.
- [ ] 4.3 Verify missing disks never create fallback media or backup directories.
- [ ] 4.4 Establish an independent original-media backup and verify representative restore before claiming protection from media-disk failure.
- [ ] 4.5 Verify host updates layer by layer, including macOS login/FileVault behavior, Docker Desktop startup, APFS bind mounts, and the safe-start LaunchAgent.

## 5. Roll out safely

- [ ] 5.1 Capture a known-good baseline and current backup before the first production OpenTofu apply.
- [ ] 5.2 Review the exact OpenTofu plan and service deployment diff before applying.
- [ ] 5.3 Verify containers, database, backups, external-library scan, Motion Photo playback, and asset invariants after rollout.
- [ ] 5.4 Record rollback steps and retain recovery sources until the owner accepts the verified result.
