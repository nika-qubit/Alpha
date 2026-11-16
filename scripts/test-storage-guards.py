#!/usr/bin/env python3
"""Exercise fail-closed host scripts with disposable files and a fake Docker CLI."""

from __future__ import annotations

import os
import signal
import subprocess
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def write_executable(path: Path, body: str) -> None:
    path.write_text(body, encoding="utf-8")
    path.chmod(0o700)


def base_environment(home: Path, docker: Path, log: Path) -> dict[str, str]:
    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "PATH": "/usr/bin:/bin",
            "IMMICH_DOCKER_BIN": str(docker),
            "IMMICH_TEST_DOCKER_LOG": str(log),
            "IMMICH_OSASCRIPT_BIN": "/usr/bin/true",
        }
    )
    return env


def test_safe_start_blocks_missing_volume(root: Path) -> None:
    home = root / "safe-start-home"
    app = home / "immich-app"
    app.mkdir(parents=True)
    docker_log = root / "safe-start-docker.log"
    docker = root / "fake-docker"
    write_executable(
        docker,
        '#!/bin/sh\nprintf "%s\\n" "$*" >> "$IMMICH_TEST_DOCKER_LOG"\nexit 0\n',
    )
    media_root = f"/tmp/immich-test-missing-media-{os.getpid()}"
    backup_root = f"/tmp/immich-test-missing-backup-{os.getpid()}"
    host_env = {
        "IMMICH_APP_HOME": str(app),
        "IMMICH_MEDIA_VOLUME": media_root,
        "IMMICH_MEDIA_UUID": "11111111-2222-3333-4444-555555555555",
        "IMMICH_MEDIA_SENTINEL": f"{media_root}/sentinel",
        "IMMICH_MEDIA_SENTINEL_CONTENT": "test",
        "IMMICH_BACKUP_VOLUME": backup_root,
        "IMMICH_BACKUP_UUID": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
        "IMMICH_BACKUP_SENTINEL": f"{backup_root}/sentinel",
        "IMMICH_BACKUP_SENTINEL_CONTENT": "test",
        "UPLOAD_LOCATION": f"{media_root}/immich",
        "EXTERNAL_LOCATION": f"{media_root}/archive",
        "BACKUP_LOCATION": f"{backup_root}/ImmichBackups",
        "DB_DATA_LOCATION": str(home / "immich-data/postgres"),
        "IMMICH_CACHE_LOCATION": str(home / "immich-data/cache"),
        "IMMICH_CONFIG_LOCATION": str(home / "immich-data/config"),
    }
    (app / ".immich-host.env").write_text(
        "".join(f"{key}={value}\n" for key, value in host_env.items()), encoding="utf-8"
    )
    (app / ".env").write_text("DB_USERNAME=test\n", encoding="utf-8")
    env = base_environment(home, docker, docker_log)
    result = subprocess.run(
        ["/bin/bash", str(ROOT / "immich-app/immich-safe-start.sh")],
        env=env,
        capture_output=True,
        text=True,
        timeout=5,
        check=False,
    )
    calls = docker_log.read_text(encoding="utf-8") if docker_log.exists() else ""
    if result.returncode == 0 or "Immich was not started." not in result.stdout:
        raise AssertionError(f"safe-start did not fail closed: {result.stdout} {result.stderr}")
    if any(call.startswith("compose ") for call in calls.splitlines()):
        raise AssertionError(f"safe-start invoked Compose before storage passed: {calls}")
    if any(call != "info" for call in calls.splitlines()):
        raise AssertionError(f"safe-start invoked a mutating Docker command: {calls}")


def test_monitor_stops_without_starting(root: Path) -> None:
    home = root / "monitor-home"
    app = home / "immich-app"
    app.mkdir(parents=True)
    (app / ".immich-host.env").write_text("test=1\n", encoding="utf-8")
    (app / ".env").write_text("test=1\n", encoding="utf-8")
    docker_log = root / "monitor-docker.log"
    docker = root / "fake-docker-monitor"
    write_executable(
        docker,
        '#!/bin/sh\nprintf "%s\\n" "$*" >> "$IMMICH_TEST_DOCKER_LOG"\nexit 0\n',
    )
    storage_check = root / "fake-storage-check"
    write_executable(storage_check, "#!/bin/sh\nexit 1\n")
    safe_start = root / "fake-safe-start"
    write_executable(safe_start, "#!/bin/sh\nexit 99\n")
    sleep = root / "fake-sleep"
    write_executable(sleep, "#!/bin/sh\nexec /bin/sleep 60\n")
    env = base_environment(home, docker, docker_log)
    env.update(
        {
            "IMMICH_STORAGE_CHECK_BIN": str(storage_check),
            "IMMICH_SAFE_START_BIN": str(safe_start),
            "IMMICH_SLEEP_BIN": str(sleep),
        }
    )
    process = subprocess.Popen(
        ["/bin/bash", str(ROOT / "immich-app/immich-volume-monitor.sh")],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    deadline = time.monotonic() + 5
    try:
        while time.monotonic() < deadline:
            if docker_log.exists() and " stop\n" in docker_log.read_text(encoding="utf-8"):
                break
            if process.poll() is not None:
                raise AssertionError("monitor exited before the mocked stop command")
            time.sleep(0.05)
        else:
            raise AssertionError("monitor did not request compose stop after storage failure")
    finally:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        process.wait(timeout=5)
    calls = docker_log.read_text(encoding="utf-8").splitlines()
    if "info" not in calls:
        raise AssertionError(f"monitor did not check Docker readiness: {calls}")
    if not any(line.startswith("compose ") and line.endswith(" stop") for line in calls):
        raise AssertionError(f"monitor did not request Compose stop: {calls}")
    if any(line.endswith(" up") or " up " in line for line in calls):
        raise AssertionError(f"monitor attempted to start services with failed storage: {calls}")


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="immich-storage-guards-") as directory:
        root = Path(directory)
        test_safe_start_blocks_missing_volume(root)
        test_monitor_stops_without_starting(root)
    print("Storage guard checks passed using temporary paths and a fake Docker CLI.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
