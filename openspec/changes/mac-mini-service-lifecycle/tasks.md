# Tasks

## 1. Resolve policy decisions

- [ ] 1.1 Set the Immich release lag target and decide whether qualified patch releases may deploy automatically.
- [ ] 1.2 Choose the independent media-backup target, retention, recovery point objective, and recovery time objective.
- [ ] 1.3 Confirm expected reboot recovery behavior, macOS login requirements, and FileVault constraints.
- [ ] 1.4 Confirm ChatGPT Desktop's target Mac, official update behavior, and desired notification path.
- [ ] 1.5 Choose OpenTofu state storage, encryption, locking, and recovery procedure.
- [ ] 1.6 Decide the runtime action when either external volume disconnects while Immich is running.

## 2. Prove the deployment boundaries

- [ ] 2.1 Inventory which host files and policies OpenTofu will own and which remain owned by Docker Compose.
- [ ] 2.2 Evaluate candidate OpenTofu providers against macOS file, LaunchAgent, and state-recovery requirements in an isolated test environment.
- [ ] 2.3 Confirm a resource has exactly one owner; reject a design that manages Compose containers through both Compose and OpenTofu.
- [ ] 2.4 Confirm CI can validate a change without access to production credentials, state, media, or the Mac mini.

## 3. Implement update visibility and qualification

- [ ] 3.1 Add a daily official Immich stable-release check that produces a version-and-digest review change.
- [ ] 3.2 Add compatibility and intermediate-upgrade checks from official release notes.
- [ ] 3.3 Add ChatGPT Desktop version reporting using only official OpenAI release/update sources.
- [ ] 3.4 Add CI validation for Compose configuration, OpenTofu formatting/validation/plan, secrets, and version pinning.

## 4. Implement and verify host recovery

- [ ] 4.1 Reconcile OpenTofu-managed host configuration with the existing safe-start LaunchAgent.
- [ ] 4.2 Verify cold boot, Docker-not-ready, missing-volume, wrong-volume, missing-sentinel, network-down, and runtime-disconnect scenarios without using production media for destructive tests.
- [ ] 4.3 Verify missing disks never create fallback media or backup directories.
- [ ] 4.4 Establish an independent original-media backup and verify representative restore before claiming protection from media-disk failure.

## 5. Roll out safely

- [ ] 5.1 Capture a known-good baseline and current backup before the first production OpenTofu apply.
- [ ] 5.2 Review the exact OpenTofu plan and service deployment diff before applying.
- [ ] 5.3 Verify containers, database, backups, external-library scan, Motion Photo playback, and asset invariants after rollout.
- [ ] 5.4 Record rollback steps and retain recovery sources until the owner accepts the verified result.
