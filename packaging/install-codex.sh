#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_name="rip"
dest_root="${CODEX_HOME:-$HOME/.codex}/skills"
dest_dir="$dest_root/$skill_name"
browser_pattern="${MIRRORD_CODEX_BROWSER_MCP_PATTERN:-chrome|playwright|browser}"
force=0
skip_browser_check=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] [--skip-browser-check]

Build and install the Codex skill bundle locally.

Options:
  --force               Replace an existing install at $dest_dir
  --skip-browser-check  Skip Codex MCP browser backend detection
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      ;;
    --skip-browser-check)
      skip_browser_check=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 1
  fi
}

require_cmd codex
require_cmd node
require_cmd git

"$repo_root/packaging/build-bundles.sh" >/dev/null
"$repo_root/packaging/check-isolation.sh" >/dev/null

if [[ "$skip_browser_check" -eq 0 ]]; then
  mcp_output="$(codex mcp list 2>&1 || true)"
  if ! printf '%s\n' "$mcp_output" | grep -Eiq "$browser_pattern"; then
    echo "Codex browser MCP dependency not found." >&2
    echo "Expected a configured MCP server matching pattern: $browser_pattern" >&2
    echo "Current codex mcp list output:" >&2
    printf '%s\n' "$mcp_output" >&2
    echo "Use --skip-browser-check if you will provide browser automation another way." >&2
    exit 1
  fi
fi

mkdir -p "$dest_root"

if [[ -e "$dest_dir" ]]; then
  if [[ "$force" -ne 1 ]]; then
    echo "Destination already exists: $dest_dir" >&2
    echo "Re-run with --force to replace it." >&2
    exit 1
  fi
  rm -rf "$dest_dir"
fi

cp -R "$repo_root/dist/codex/$skill_name" "$dest_dir"

echo "Installed Codex skill to $dest_dir"
echo "Restart Codex to pick up the new skill."
