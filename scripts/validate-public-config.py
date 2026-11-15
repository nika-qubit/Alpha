#!/usr/bin/env python3
"""Reject machine-specific Immich identifiers in tracked public templates."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UUID_PATTERN = re.compile(
    r"(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b"
)


def main() -> int:
    env_example = ROOT / "immich-app/.env.example"
    text = env_example.read_text(encoding="utf-8")
    failures = []

    if UUID_PATTERN.search(text):
        failures.append(".env.example contains a concrete volume UUID")

    password_lines = [line for line in text.splitlines() if line.startswith("DB_PASSWORD=")]
    if len(password_lines) != 1 or not any(
        marker in password_lines[0].split("=", 1)[1].lower()
        for marker in ("replace", "placeholder", "change_me", "<")
    ):
        failures.append(".env.example must contain one obvious non-secret DB password placeholder")

    for line in text.splitlines():
        if not line or line.lstrip().startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.endswith(("_VOLUME", "_LOCATION", "_SENTINEL")) and value.startswith(
            ("/Volumes/", "/Users/")
        ) and "REPLACE_WITH" not in value:
            failures.append(f"{key} contains a machine-specific absolute path")

    result = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, check=True, capture_output=True
    )
    tracked = [Path(name.decode()) for name in result.stdout.split(b"\0") if name]
    forbidden = re.compile(
        r"(^|/)(\.env|terraform\.tfstate(\..*)?|terraform\.tfvars|[^/]+\.auto\.tfvars|.*\.tfplan)$"
    )
    for path in tracked:
        if forbidden.search(path.as_posix()):
            failures.append(f"machine-local state/input is tracked: {path.as_posix()}")

    if failures:
        print("Public configuration validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print("Public configuration contains no concrete disk identities or tracked local state.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
