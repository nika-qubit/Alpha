#!/usr/bin/env python3
"""Update the repository's Immich version/digests for a review-only PR."""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


USER_AGENT = "nika-qubit-alpha-immich-release-check"
REGISTRY_ACCEPT = ", ".join(
    [
        "application/vnd.oci.image.index.v1+json",
        "application/vnd.docker.distribution.manifest.list.v2+json",
        "application/vnd.oci.image.manifest.v1+json",
        "application/vnd.docker.distribution.manifest.v2+json",
    ]
)


def get_json(url: str) -> dict:
    request = urllib.request.Request(
        url, headers={"Accept": "application/vnd.github+json", "User-Agent": USER_AGENT}
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def image_digest(image: str, tag: str) -> str:
    repository = f"immich-app/{image}"
    url = f"https://ghcr.io/v2/{repository}/manifests/{urllib.parse.quote(tag, safe='.') }"

    def head(token: str | None = None):
        headers = {"Accept": REGISTRY_ACCEPT, "User-Agent": USER_AGENT}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        request = urllib.request.Request(url, headers=headers, method="HEAD")
        try:
            return urllib.request.urlopen(request, timeout=30)
        except urllib.error.HTTPError as error:
            if error.code != 401:
                raise
            challenge = error.headers.get("Www-Authenticate", "")
            match = re.search(r'realm="([^"]+)"', challenge)
            if not match:
                raise RuntimeError(f"GHCR did not provide an authorization realm for {image}")
            realm = match.group(1)
            query = urllib.parse.urlencode(
                {"service": "ghcr.io", "scope": f"repository:{repository}:pull"}
            )
            token_data = get_json(f"{realm}?{query}")
            bearer = token_data.get("token") or token_data.get("access_token")
            if not bearer:
                raise RuntimeError(f"GHCR did not return a read token for {image}")
            request = urllib.request.Request(
                url,
                headers={**headers, "Authorization": f"Bearer {bearer}"},
                method="HEAD",
            )
            return urllib.request.urlopen(request, timeout=30)

    with head() as response:
        digest = response.headers.get("Docker-Content-Digest", "")
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise RuntimeError(f"GHCR returned no valid manifest digest for {image}:{tag}")
    return digest


def set_output(name: str, value: str) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a", encoding="utf-8") as output:
            output.write(f"{name}={value}\n")


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    env_path = root / "immich-app/.env.example"
    compose_path = root / "immich-app/docker-compose.yml"
    env_text = env_path.read_text(encoding="utf-8")
    compose_text = compose_path.read_text(encoding="utf-8")

    current_match = re.search(r"(?m)^IMMICH_VERSION=(v\d+\.\d+\.\d+)\s*$", env_text)
    if not current_match:
        raise RuntimeError("Could not read a pinned stable IMMICH_VERSION from .env.example")
    current = current_match.group(1)

    release = get_json("https://api.github.com/repos/immich-app/immich/releases/latest")
    latest = release.get("tag_name", "")
    if release.get("draft") or release.get("prerelease") or not re.fullmatch(
        r"v\d+\.\d+\.\d+", latest
    ):
        raise RuntimeError("GitHub's latest release endpoint did not return a stable semver tag")

    current_tuple = tuple(map(int, current[1:].split(".")))
    latest_tuple = tuple(map(int, latest[1:].split(".")))
    set_output("current", current)
    set_output("latest", latest)
    if latest_tuple < current_tuple:
        set_output("changed", "false")
        print(f"Repository target {current} is current against latest stable {latest}.")
        return 0

    digests = {
        "immich-server": image_digest("immich-server", latest),
        "immich-machine-learning": image_digest("immich-machine-learning", latest),
    }
    current_digests = {}
    for image in digests:
        match = re.search(
            rf"(?m)^\s*image:\s*ghcr\.io/immich-app/{re.escape(image)}:[^@]+@(sha256:[0-9a-f]{{64}})\s*$",
            compose_text,
        )
        if not match:
            raise RuntimeError(f"Could not read the pinned {image} digest from Compose")
        current_digests[image] = match.group(1)

    needs_update = latest_tuple > current_tuple or current_digests != digests
    set_output("changed", "true" if needs_update else "false")
    if not needs_update:
        print(f"Repository target {current} and its image digests match latest stable {latest}.")
        return 0

    for image, digest in digests.items():
        pattern = re.compile(
            rf"(?m)^(\s*image:\s*ghcr\.io/immich-app/{re.escape(image)}:)[^@]+@sha256:[0-9a-f]{{64}}(\s*)$"
        )
        compose_text, count = pattern.subn(rf"\g<1>${{IMMICH_VERSION:?Set IMMICH_VERSION}}@{digest}\g<2>", compose_text)
        if count != 1:
            raise RuntimeError(f"Expected one pinned {image} image in Compose, found {count}")

    env_text, count = re.subn(
        r"(?m)^IMMICH_VERSION=v\d+\.\d+\.\d+\s*$", f"IMMICH_VERSION={latest}", env_text
    )
    if count != 1:
        raise RuntimeError("Expected exactly one IMMICH_VERSION in .env.example")

    compose_path.write_text(compose_text, encoding="utf-8")
    env_path.write_text(env_text, encoding="utf-8")
    print(f"Proposed {current} -> {latest}; pinned both image manifest digests.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # Fail the scheduled workflow closed.
        print(f"Release check failed: {error}", file=sys.stderr)
        raise SystemExit(1)
