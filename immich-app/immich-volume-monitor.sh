#!/bin/bash
set -u

APP_HOME="${HOME}/immich-app"
HOST_ENV_FILE="${APP_HOME}/.immich-host.env"
DB_ENV_FILE="${APP_HOME}/.env"
STORAGE_CHECK="${APP_HOME}/immich-storage-check.sh"
SAFE_START="${APP_HOME}/immich-safe-start.sh"
STORAGE_CHECK="${IMMICH_STORAGE_CHECK_BIN:-$STORAGE_CHECK}"
SAFE_START="${IMMICH_SAFE_START_BIN:-$SAFE_START}"
DOCKER_BIN="${IMMICH_DOCKER_BIN:-docker}"
SLEEP_BIN="${IMMICH_SLEEP_BIN:-sleep}"
OSASCRIPT_BIN="${IMMICH_OSASCRIPT_BIN:-/usr/bin/osascript}"
last_state="unknown"

compose() {
    "$DOCKER_BIN" compose --env-file "$DB_ENV_FILE" --env-file "$HOST_ENV_FILE" "$@"
}

notify_transition() {
    local state="$1"
    if [[ "$state" != "$last_state" ]]; then
        if [[ "$state" == "healthy" ]]; then
            echo "Required volumes and Docker are ready; Immich is available."
            "$OSASCRIPT_BIN" -e 'display notification "Required storage is ready; Immich is available." with title "Immich storage monitor"' >/dev/null 2>&1 || true
        else
            echo "Required storage or Docker is unavailable; Immich is stopped or held offline."
            "$OSASCRIPT_BIN" -e 'display notification "Required storage or Docker is unavailable; Immich is held offline." with title "Immich storage monitor"' >/dev/null 2>&1 || true
        fi
        last_state="$state"
    fi
}

while true; do
    if [[ -f "$HOST_ENV_FILE" && -f "$DB_ENV_FILE" && -x "$STORAGE_CHECK" \
        && -x "$SAFE_START" ]] && "$STORAGE_CHECK" && "$DOCKER_BIN" info >/dev/null 2>&1; then
        services="$(compose ps --status running --services 2>/dev/null || true)"
        all_running=1
        for service in database redis immich-machine-learning immich-server; do
            /usr/bin/grep -Fxq "$service" <<<"$services" || all_running=0
        done
        if [[ "$all_running" -eq 0 ]]; then
            if "$SAFE_START"; then
                notify_transition "healthy"
            else
                notify_transition "blocked"
            fi
        else
            notify_transition "healthy"
        fi
    else
        if [[ -f "$HOST_ENV_FILE" && -f "$DB_ENV_FILE" ]] && "$DOCKER_BIN" info >/dev/null 2>&1; then
            if ! compose stop; then
                echo "Unable to stop Immich after a required storage check failed; retrying."
            fi
        fi
        notify_transition "blocked"
    fi
    "$SLEEP_BIN" 60
done
