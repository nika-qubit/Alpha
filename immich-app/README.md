# Immich on macOS with Docker Desktop

This is the canonical Mac mini deployment template; the previous Raspberry Pi Compose setup is retired. It contains no production credentials, database dumps, or media.

## Current topology

| Role | Host location | Container location | Notes |
|---|---|---|---|
| Immich originals and generated files | `/Volumes/ImmichMedia/nas/public/immich` | `/data` | APFS external volume; UUID and sentinel checked before startup |
| External library | `/Volumes/ImmichMedia/nas/public/archive` | `/ext-archive` | Read-only bind mount |
| Automatic database backups | `/Volumes/EnvoySSD/ImmichBackups` | `/data/backups` | Daily 02:00, keep 14 database dumps |
| Live PostgreSQL data | `~/immich-data/postgres` | `/var/lib/postgresql/data` | Mac internal SSD; not the backup destination |
| Immich config | `~/immich-data/config` | `/config` | `config/immich.json` is a credential-scrubbed baseline |
| Immich cache | `~/immich-data/cache` | `/cache` | Re-creatable application cache |

Production is pinned to Immich v3.3.5, Valkey 9, and Immich PostgreSQL 14 / VectorChord. PostgreSQL uses `max_connections=50`. Do not use `latest` or change an image tag without checking release notes and updating its matching digest.

## First setup on a replacement Mac

1. Install Docker Desktop, allow it to open at login, and permit Docker Desktop to share the mounted external volumes.
2. Clone Alpha. Copy the repository's `immich-app` template directory to `~/immich-app` (the active Compose and safe-start paths are under this directory).
3. Copy `~/immich-app/.env.example` to `~/immich-app/.env`. Replace `REPLACE_WITH_MAC_USERNAME` in every host path and enter a newly generated database secret from your password manager. `.env` is ignored by Git; never add it to the repository.
4. Create `~/immich-data/config`, `cache`, `guard`, and `postgres` on the Mac internal SSD. Copy `~/immich-app/config/immich.json` to `~/immich-data/config/immich.json`. Do not initialize a replacement database until you have identified the recovery source.
5. Connect the existing `ImmichMedia` and `EnvoySSD` APFS drives; do not initialize or format them. Verify their volume names and UUIDs with `diskutil info`. The `.env.example` records the current UUIDs as reference values; update UUIDs only if a disk was replaced or reformatted.
6. Verify the media and backup sentinels and all Immich `.immich` directory markers. Create the internal media guard sentinel with the exact content in `.env.example`. Do not create missing external paths while a drive is absent.
7. Validate locally with `docker compose config --quiet`. Copy the plist example to `~/Library/LaunchAgents/com.ningk.immich-safe-start.plist`, replace the username paths, run `plutil -lint`, create `~/Library/Logs/Immich`, then bootstrap the LaunchAgent for the logged-in user.
8. Start only through `~/immich-app/immich-safe-start.sh`. It checks both APFS UUIDs, sentinels, and required directories before Compose starts. If either external drive is unavailable, Immich does not start. The Compose binds also use `create_host_path: false` to prevent accidental fallback directories.
9. Confirm all containers are healthy, the Web UI is reachable, and external-library paths remain read-only. Restore the database and verify user, album, asset, original-photo/video, Motion Photo, search, and queue state before accepting uploads.

The LaunchAgent runs at user login, after Docker Desktop becomes ready. Both external volumes must be mounted before the safe-start check; this deployment does not start without either drive.

## Backup and recovery boundaries

Immich's built-in scheduled database dump is written to EnvoySSD, not to the internal PostgreSQL directory or the 5 TB media volume. The 14-file retention applies only to database dumps. It does not back up originals, videos, sidecars, or the external library; protect those media sources separately. Keep recovery sources until the new host and its scheduled backups have been confirmed stable.

The tracked JSON is a baseline, not a credential store. Immich may persist some settings in its database; verify effective settings in the admin UI after restoring.
