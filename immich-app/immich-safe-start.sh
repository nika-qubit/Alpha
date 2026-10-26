#!/bin/bash
set -euo pipefail

ENV_FILE="${HOME}/immich-app/.env"

read_env() {
    local key="$1"
    /usr/bin/awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$ENV_FILE"
}

fail() {
    echo "ERROR: $1"
    echo "Immich was not started."
    exit 1
}

[ -f "$ENV_FILE" ] || fail "Missing $ENV_FILE."
APP_HOME="$(read_env IMMICH_APP_HOME)"
[ -n "$APP_HOME" ] || fail "IMMICH_APP_HOME is not set in .env."

# Wait for Docker Desktop without starting any Immich container.
for i in {1..60}; do
    if docker info >/dev/null 2>&1; then
        break
    fi
    [ "$i" -lt 60 ] || fail "Docker Desktop did not become ready within five minutes."
    sleep 5
done

check_volume() {
    local mount="$1" expected_uuid="$2" label="$3"
    [ -d "$mount" ] || fail "$label mount path is absent: $mount"
    local info uuid filesystem
    info="$(/usr/sbin/diskutil info "$mount" 2>/dev/null)" || fail "$label is not mounted."
    uuid="$(printf '%s\n' "$info" | /usr/bin/awk -F: '/Volume UUID/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
    filesystem="$(printf '%s\n' "$info" | /usr/bin/awk -F: '/File System Personality/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
    [ "$uuid" = "$expected_uuid" ] || fail "$label UUID mismatch (expected $expected_uuid; found ${uuid:-unknown})."
    [ "$filesystem" = "APFS" ] || fail "$label is not APFS."
}

MEDIA_VOLUME="$(read_env IMMICH_MEDIA_VOLUME)"
MEDIA_UUID="$(read_env IMMICH_MEDIA_UUID)"
MEDIA_SENTINEL="$(read_env IMMICH_MEDIA_SENTINEL)"
MEDIA_SENTINEL_CONTENT="$(read_env IMMICH_MEDIA_SENTINEL_CONTENT)"
BACKUP_VOLUME="$(read_env IMMICH_BACKUP_VOLUME)"
BACKUP_UUID="$(read_env IMMICH_BACKUP_UUID)"
BACKUP_SENTINEL="$(read_env IMMICH_BACKUP_SENTINEL)"
BACKUP_SENTINEL_CONTENT="$(read_env IMMICH_BACKUP_SENTINEL_CONTENT)"
UPLOAD_LOCATION="$(read_env UPLOAD_LOCATION)"
EXTERNAL_LOCATION="$(read_env EXTERNAL_LOCATION)"
BACKUP_LOCATION="$(read_env BACKUP_LOCATION)"
DB_DATA_LOCATION="$(read_env DB_DATA_LOCATION)"
IMMICH_CONFIG_LOCATION="$(read_env IMMICH_CONFIG_LOCATION)"
IMMICH_CACHE_LOCATION="$(read_env IMMICH_CACHE_LOCATION)"

check_volume "$MEDIA_VOLUME" "$MEDIA_UUID" "Immich media volume"
[ -f "$MEDIA_SENTINEL" ] || fail "Media sentinel is missing."
[ "$(/bin/cat "$MEDIA_SENTINEL")" = "$MEDIA_SENTINEL_CONTENT" ] || fail "Media sentinel content mismatch."
check_volume "$BACKUP_VOLUME" "$BACKUP_UUID" "Immich backup volume"
[ -f "$BACKUP_SENTINEL" ] || fail "Backup volume sentinel is missing."
[ "$(/bin/cat "$BACKUP_SENTINEL")" = "$BACKUP_SENTINEL_CONTENT" ] || fail "Backup volume sentinel content mismatch."

[ -d "$UPLOAD_LOCATION" ] || fail "Immich media root is missing."
[ -d "$EXTERNAL_LOCATION" ] || fail "External library root is missing."
[ -d "$BACKUP_LOCATION" ] || fail "SSD backup destination is missing."
[ -f "$BACKUP_LOCATION/.immich" ] || fail "SSD backup destination marker is missing."
[ -d "$DB_DATA_LOCATION" ] || fail "PostgreSQL data directory is missing; refusing to create an empty database path."
[ -f "$IMMICH_CONFIG_LOCATION/immich.json" ] || fail "Immich configuration file is missing."
[ -d "$IMMICH_CACHE_LOCATION" ] || fail "Immich cache directory is missing."
for folder in upload library profile thumbs encoded-video; do
    [ -d "$UPLOAD_LOCATION/$folder" ] || fail "Immich storage folder is missing: $folder"
    [ -f "$UPLOAD_LOCATION/$folder/.immich" ] || fail "Immich storage marker is missing: $folder/.immich"
done

# Ensure the shell-safe variables are not accidentally printed; Compose reads .env itself.
echo "Storage UUID, APFS, sentinel, and directory checks passed. Starting Immich."
cd "$APP_HOME"
docker compose up -d database redis immich-machine-learning
docker compose up -d immich-server
docker compose ps
