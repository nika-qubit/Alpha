#!/bin/bash
set -euo pipefail

APP_HOME="${HOME}/immich-app"
HOST_ENV_FILE="${APP_HOME}/.immich-host.env"
DB_ENV_FILE="${APP_HOME}/.env"
DOCKER_BIN="${IMMICH_DOCKER_BIN:-docker}"

fail() {
    echo "ERROR: $1"
    echo "Immich was not started."
    exit 1
}

read_env() {
    local key="$1" file="$2"
    /usr/bin/awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$file"
}

compose() {
    "$DOCKER_BIN" compose --env-file "$DB_ENV_FILE" --env-file "$HOST_ENV_FILE" "$@"
}

[[ -f "$HOST_ENV_FILE" ]] || fail "Private host configuration is missing."
[[ -f "$DB_ENV_FILE" ]] || fail "Immich database environment file is missing."

APP_HOME="$(read_env IMMICH_APP_HOME "$HOST_ENV_FILE")"
HOST_ENV_FILE="${APP_HOME}/.immich-host.env"
DB_ENV_FILE="${APP_HOME}/.env"

MEDIA_VOLUME="$(read_env IMMICH_MEDIA_VOLUME "$HOST_ENV_FILE")"
MEDIA_UUID="$(read_env IMMICH_MEDIA_UUID "$HOST_ENV_FILE")"
MEDIA_SENTINEL="$(read_env IMMICH_MEDIA_SENTINEL "$HOST_ENV_FILE")"
MEDIA_SENTINEL_CONTENT="$(read_env IMMICH_MEDIA_SENTINEL_CONTENT "$HOST_ENV_FILE")"
BACKUP_VOLUME="$(read_env IMMICH_BACKUP_VOLUME "$HOST_ENV_FILE")"
BACKUP_UUID="$(read_env IMMICH_BACKUP_UUID "$HOST_ENV_FILE")"
BACKUP_SENTINEL="$(read_env IMMICH_BACKUP_SENTINEL "$HOST_ENV_FILE")"
BACKUP_SENTINEL_CONTENT="$(read_env IMMICH_BACKUP_SENTINEL_CONTENT "$HOST_ENV_FILE")"
UPLOAD_LOCATION="$(read_env UPLOAD_LOCATION "$HOST_ENV_FILE")"
EXTERNAL_LOCATION="$(read_env EXTERNAL_LOCATION "$HOST_ENV_FILE")"
BACKUP_LOCATION="$(read_env BACKUP_LOCATION "$HOST_ENV_FILE")"
DB_DATA_LOCATION="$(read_env DB_DATA_LOCATION "$HOST_ENV_FILE")"
IMMICH_CACHE_LOCATION="$(read_env IMMICH_CACHE_LOCATION "$HOST_ENV_FILE")"
IMMICH_CONFIG_LOCATION="$(read_env IMMICH_CONFIG_LOCATION "$HOST_ENV_FILE")"

for key in MEDIA_VOLUME MEDIA_UUID MEDIA_SENTINEL MEDIA_SENTINEL_CONTENT \
    BACKUP_VOLUME BACKUP_UUID BACKUP_SENTINEL BACKUP_SENTINEL_CONTENT \
    UPLOAD_LOCATION EXTERNAL_LOCATION BACKUP_LOCATION DB_DATA_LOCATION \
    IMMICH_CACHE_LOCATION IMMICH_CONFIG_LOCATION; do
    [[ -n "${!key}" ]] || fail "Private host configuration is incomplete (${key})."
done

for i in {1..60}; do
    if "$DOCKER_BIN" info >/dev/null 2>&1; then
        break
    fi
    [[ "$i" -lt 60 ]] || fail "Docker Desktop did not become ready within five minutes."
    sleep 5
done

check_volume() {
    local mount="$1" expected_uuid="$2" label="$3"
    [[ -d "$mount" ]] || fail "$label mount is unavailable."
    local info uuid filesystem
    info="$(/usr/sbin/diskutil info "$mount" 2>/dev/null)" || fail "$label is not mounted."
    uuid="$(printf '%s\n' "$info" | /usr/bin/awk -F: '/Volume UUID/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
    filesystem="$(printf '%s\n' "$info" | /usr/bin/awk -F: '/File System Personality/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
    [[ "$uuid" == "$expected_uuid" ]] || fail "$label volume identity does not match."
    [[ "$filesystem" == "APFS" ]] || fail "$label is not APFS."
}

check_volume "$MEDIA_VOLUME" "$MEDIA_UUID" "Media"
[[ -f "$MEDIA_SENTINEL" ]] || fail "Media sentinel is missing."
[[ "$(/bin/cat "$MEDIA_SENTINEL")" == "$MEDIA_SENTINEL_CONTENT" ]] || fail "Media sentinel does not match."
check_volume "$BACKUP_VOLUME" "$BACKUP_UUID" "Backup"
[[ -f "$BACKUP_SENTINEL" ]] || fail "Backup sentinel is missing."
[[ "$(/bin/cat "$BACKUP_SENTINEL")" == "$BACKUP_SENTINEL_CONTENT" ]] || fail "Backup sentinel does not match."

for directory in "$UPLOAD_LOCATION" "$EXTERNAL_LOCATION" "$BACKUP_LOCATION" \
    "$DB_DATA_LOCATION" "$IMMICH_CACHE_LOCATION" "$IMMICH_CONFIG_LOCATION"; do
    [[ -d "$directory" ]] || fail "A required Immich data directory is missing."
done
[[ -f "$BACKUP_LOCATION/.immich" ]] || fail "Backup destination marker is missing."
[[ -f "$IMMICH_CONFIG_LOCATION/immich.json" ]] || fail "Immich configuration file is missing."
for folder in upload library profile thumbs encoded-video; do
    [[ -d "$UPLOAD_LOCATION/$folder" ]] || fail "A required Immich storage directory is missing."
    [[ -f "$UPLOAD_LOCATION/$folder/.immich" ]] || fail "An Immich storage marker is missing."
done

echo "Storage identity, APFS, sentinel, and directory checks passed. Starting Immich."
cd "$APP_HOME"
compose up -d database redis immich-machine-learning
compose up -d immich-server
compose ps
