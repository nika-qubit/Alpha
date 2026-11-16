# Immich on macOS with Docker Desktop

This is the canonical Mac mini deployment template; the previous Raspberry Pi Compose setup is retired. It contains no production credentials, database dumps, or media.

## Deployment topology

| Role | Host location | Container location | Notes |
|---|---|---|---|
| Immich originals and generated files | `/Volumes/$MEDIA_VOLUME/<media-library-path>` | `/data` | External APFS volume; UUID and sentinel checked before startup |
| External library | `/Volumes/$MEDIA_VOLUME/<external-library-path>` | `/ext-archive` | Read-only bind mount |
| Automatic database backups | `/Volumes/$BACKUP_VOLUME/ImmichBackups` | `/data/backups` | Daily 02:00, keep 14 database dumps |
| Live PostgreSQL data | `~/immich-data/postgres` | `/var/lib/postgresql/data` | Mac internal SSD; not the backup destination |
| Immich config | `~/immich-data/config` | `/config` | `config/immich.json` is a credential-scrubbed baseline |
| Immich cache | `~/immich-data/cache` | `/cache` | Re-creatable application cache |

Production is pinned to Immich v3.3.5, Valkey 9, and Immich PostgreSQL 14 / VectorChord. PostgreSQL uses `max_connections=50`. Do not use `latest` or change an image tag without checking release notes and updating its matching digest.

## First setup on a replacement Mac

1. Install Docker Desktop, allow it to open at login, and permit Docker Desktop to share the mounted external volumes.
2. Clone Alpha. The live Compose project and safe-start files live under `~/immich-app`.
3. Copy `.env.example` to `~/immich-app/.env` and set a newly generated database secret from your password manager. This file contains database credentials only and is ignored by Git.
4. Create `~/immich-data/config`, `cache`, `guard`, and `postgres` on the Mac internal SSD. Copy `~/immich-app/config/immich.json` to `~/immich-data/config/immich.json`. Do not initialize a replacement database until you have identified the recovery source.
5. Connect the existing media and backup volumes; do not initialize or format them. Record actual paths, UUIDs, and sentinel contents in a private OpenTofu variable file (`*.tfvars`, mode `0600`); never copy those values into Git.
6. Run OpenTofu `fmt`, `validate`, and `plan` from `mac-mini/iac`. Its current resources generate private candidate files under the ignored `.generated/` directory; they do not install files, load launchd, or start containers.
7. Compare the staged safe-start and LaunchAgent against the live versions. The current live files are not yet adopted; the Local provider cannot import them. Do not apply a deployment until the old files are backed up and the exact deployment diff is reviewed.
8. The candidate monitor is intended to check both APFS volume identities, sentinels, and required directories before starting or stopping Compose. An isolated mocked missing-storage test confirmed it requests only Docker readiness and `compose stop`, never `compose up`; cold boot, wrong-volume, sentinel, Docker-not-ready, and real runtime-disconnect scenarios remain unverified. The monitor is not active in production and must not be installed yet.
9. After an approved installation, verify container health, Web UI, external-library paths, and Motion Photo playback before accepting the rollout.

The current LaunchAgent runs at user login and the existing safe-start script checks external storage before starting Immich. The generated candidate adds runtime volume monitoring, but it remains staged and is not yet installed.

## Backup and recovery boundaries

Immich's built-in scheduled database dump is written to EnvoySSD, not to the internal PostgreSQL directory or the 5 TB media volume. The 14-file retention applies only to database dumps. It does not back up originals, videos, sidecars, or the external library; protect those media sources separately. Keep recovery sources until the new host and its scheduled backups have been confirmed stable.

The tracked JSON is a baseline, not a credential store. Immich may persist some settings in its database; verify effective settings in the admin UI after restoring.
