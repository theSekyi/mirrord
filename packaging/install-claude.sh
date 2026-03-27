#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest_dir="${MIRRORD_CLAUDE_PLUGIN_DIR:-$HOME/.claude/plugins/local/mirrord}"
browser_pattern="${MIRRORD_CLAUDE_BROWSER_MCP_PATTERN:-chrome|playwright|browser}"
force=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force]

Build and stage the Claude plugin bundle locally after validating dependencies.

This script installs a local bundle for use with:
  claude --plugin-dir $dest_dir

For marketplace or GitHub plugin installation, publish dist/claude as a standalone plugin bundle.

Options:
  --force  Replace an existing local bundle at $dest_dir
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
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

require_cmd claude
require_cmd node
require_cmd git

"$repo_root/packaging/build-bundles.sh" >/dev/null
"$repo_root/packaging/check-isolation.sh" >/dev/null

if ! claude plugin validate "$repo_root/dist/claude" >/dev/null; then
  echo "Claude plugin validation failed for dist/claude" >&2
  exit 1
fi

mcp_output="$(claude mcp list 2>&1 || true)"
if ! printf '%s\n' "$mcp_output" | grep -Eiq "$browser_pattern"; then
  echo "Claude browser MCP dependency not found." >&2
  echo "Expected a configured MCP server matching pattern: $browser_pattern" >&2
  echo "Current claude mcp list output:" >&2
  printf '%s\n' "$mcp_output" >&2
  exit 1
fi

mkdir -p "$(dirname "$dest_dir")"

if [[ -e "$dest_dir" ]]; then
  if [[ "$force" -ne 1 ]]; then
    echo "Destination already exists: $dest_dir" >&2
    echo "Re-run with --force to replace it." >&2
    exit 1
  fi
  rm -rf "$dest_dir"
fi

cp -R "$repo_root/dist/claude" "$dest_dir"

echo "Staged Claude plugin bundle at $dest_dir"
echo "Use it locally with:"
echo "  claude --plugin-dir $dest_dir"
echo "For native plugin installation, publish dist/claude as a standalone plugin repository and install that artifact."
