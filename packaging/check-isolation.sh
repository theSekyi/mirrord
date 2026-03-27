#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
claude_dir="$repo_root/dist/claude"
codex_dir="$repo_root/dist/codex/rip"

if [[ ! -d "$claude_dir" || ! -d "$codex_dir" ]]; then
  echo "Build dist bundles first with ./packaging/build-bundles.sh" >&2
  exit 1
fi

if find "$claude_dir" -path "*/agents/openai.yaml" | grep -q .; then
  echo "Claude bundle contains Codex agents metadata" >&2
  exit 1
fi

if find "$codex_dir" -path "*/.claude-plugin/*" | grep -q .; then
  echo "Codex bundle contains Claude plugin metadata" >&2
  exit 1
fi

if rg -n "CLAUDE_SKILL_DIR|\\.claude-plugin|plugin\\.json" "$codex_dir" >/dev/null; then
  echo "Codex bundle contains Claude-specific references" >&2
  exit 1
fi

echo "Bundle isolation checks passed"
