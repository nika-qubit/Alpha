#!/bin/bash
set -euo pipefail

APP_HOME="${HOME}/immich-app"
HOST_ENV_FILE="${APP_HOME}/.immich-host.env"

read_env() {
    local key="$1"
    /usr/bin/awk -F= -v key="$key" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$HOST_ENV_FILE"
}
check_volume() {
    local mount="$1" expected_uuid="$2" info uuid filesystem
    [[ -d "$mount" ]] || return 1
    info="$(/usr/sbin/diskutil info "$mount" 2>/dev/null)" || return 1
    uuid="$(printf '%s\n' "$info" | /usr/bin/awk -F: '/Volume UUID/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
    filesystem="$(printf '%s\n' "$info" | /usr/bin/awk -F: '/File System Personality/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
    [[ "$uuid" == "$expected_uuid" && "$filesystem" == "APFS" ]]
}

[[ -f "$HOST_ENV_FILE" ]] || exit 1
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
IMMICH_CACHE_LOCATION="$(read_env IMMICH_CACHE_LOCATION)"
IMMICH_CONFIG_LOCATION="$(read_env IMMICH_CONFIG_LOCATION)"

check_volume "$MEDIA_VOLUME" "$MEDIA_UUID" || exit 1
[[ -f "$MEDIA_SENTINEL" && "$(/bin/cat "$MEDIA_SENTINEL")" == "$MEDIA_SENTINEL_CONTENT" ]] || exit 1
check_volume "$BACKUP_VOLUME" "$BACKUP_UUID" || exit 1
[[ -f "$BACKUP_SENTINEL" && "$(/bin/cat "$BACKUP_SENTINEL")" == "$BACKUP_SENTINEL_CONTENT" ]] || exit 1
for directory in "$UPLOAD_LOCATION" "$EXTERNAL_LOCATION" "$BACKUP_LOCATION" \
    "$DB_DATA_LOCATION" "$IMMICH_CACHE_LOCATION" "$IMMICH_CONFIG_LOCATION"; do
    [[ -d "$directory" ]] || exit 1
done
[[ -f "$BACKUP_LOCATION/.immich" && -f "$IMMICH_CONFIG_LOCATION/immich.json" ]] || exit 1
for folder in upload library profile thumbs encoded-video; do
    [[ -d "$UPLOAD_LOCATION/$folder" && -f "$UPLOAD_LOCATION/$folder/.immich" ]] || exit 1
done
exit 0
