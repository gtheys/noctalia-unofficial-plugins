#!/usr/bin/env python3
"""Generate registry.json from all plugin manifests in the repo root."""

import json
import os
import sys
from datetime import datetime, timezone

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY_FILE = os.path.join(REPO_ROOT, "registry.json")
BASE_URL = "https://github.com/gtheys/noctalia-unofficial-plugins"
EXCLUDE_DIRS = {"scripts", ".git", ".github"}


def load_plugins() -> list[dict]:
    plugins = []
    for entry in sorted(os.listdir(REPO_ROOT)):
        if entry.startswith(".") or entry in EXCLUDE_DIRS:
            continue
        plugin_dir = os.path.join(REPO_ROOT, entry)
        if not os.path.isdir(plugin_dir):
            continue
        manifest_path = os.path.join(plugin_dir, "manifest.json")
        if not os.path.isfile(manifest_path):
            print(f"  [skip] {entry}: no manifest.json", file=sys.stderr)
            continue

        with open(manifest_path) as f:
            manifest = json.load(f)

        # Validate id matches folder name
        if manifest.get("id") != entry:
            print(
                f"  [warn] {entry}: manifest id '{manifest.get('id')}' != folder name",
                file=sys.stderr,
            )

        # Inject registry-specific fields
        manifest["sourceUrl"] = f"{BASE_URL}/tree/main/{entry}"
        manifest["downloadUrl"] = f"{BASE_URL}/archive/refs/heads/main.zip"
        manifest["pluginPath"] = entry

        plugins.append(manifest)
        print(f"  [ok]   {entry} ({manifest.get('version', '?')})", file=sys.stderr)

    return plugins


def main() -> None:
    print("Generating registry.json ...", file=sys.stderr)
    plugins = load_plugins()

    registry = {
        "version": "1.0.0",
        "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "repositoryUrl": BASE_URL,
        "plugins": plugins,
    }

    with open(REGISTRY_FILE, "w") as f:
        json.dump(registry, f, indent=2)
        f.write("\n")

    print(f"Done. {len(plugins)} plugin(s) written to registry.json", file=sys.stderr)


if __name__ == "__main__":
    main()
