# Mac replacement / disaster recovery

This guide restores the documented Immich v3.3.5 deployment. Do not initialize or format the media or backup drives during recovery.

1. Reinstall macOS and Docker Desktop. Clone Alpha and copy the `immich-app` template directory to `~/immich-app`.
2. Create a private `~/immich-app/.env` from `.env.example`; replace the Mac username and obtain the database credential from the password manager. Never use the removed legacy `.env` or commit a replacement `.env`.
3. Connect the existing `ImmichMedia` and `EnvoySSD` drives. Confirm APFS, volume names, UUIDs, free space, and sentinels. If a UUID differs, stop and confirm which disk is mounted before changing local `.env` values.
4. Recreate internal `~/immich-data` directories. PostgreSQL's live data belongs on the internal SSD. Restore a compatible PostgreSQL data directory or initialize a new database and use Immich's database-backup restore flow with a validated SSD `.sql.gz` backup. Do not feed a dump to a database that already contains user data.
5. Restore `immich.json` to `~/immich-data/config/immich.json` if needed. Keep `/config` and `/cache` on the internal SSD.
6. Install the safe-start LaunchAgent with the local username. It must pass both volume UUID and sentinel checks before starting Compose.
7. Start Immich, wait for database migrations, and verify users, albums, asset counts, originals, thumbnails, Motion Photo playback, external-library Offline state, jobs, and backup path before resuming uploads.

Database dumps cover PostgreSQL only. The media volume and external archive remain separate required data sources. This repository intentionally contains no `.env`, database dump, password, API key, or media file.
