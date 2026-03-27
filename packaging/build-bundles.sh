#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dist_dir="$repo_root/dist"

rm -rf "$dist_dir/claude" "$dist_dir/codex"

# Claude bundle — flat structure to avoid ENAMETOOLONG in plugin cache
mkdir -p "$dist_dir/claude"
cp -R "$repo_root/adapters/claude/.claude-plugin" "$dist_dir/claude/"
cp -R "$repo_root/adapters/claude/skills" "$dist_dir/claude/"
cp -R "$repo_root/core/assets/scaffold" "$dist_dir/claude/scaffold"
cp -R "$repo_root/core/references" "$dist_dir/claude/refs"
cp -R "$repo_root/core/scripts/." "$dist_dir/claude/scripts/"

# Codex bundle
mkdir -p "$dist_dir/codex/rip"
cp -R "$repo_root/adapters/codex/rip/." "$dist_dir/codex/rip/"
cp -R "$repo_root/core/scripts/." "$dist_dir/codex/rip/scripts/"
cp -R "$repo_root/core/references/." "$dist_dir/codex/rip/refs/"
cp -R "$repo_root/core/assets/." "$dist_dir/codex/rip/assets/"

echo "Built Claude bundle at $dist_dir/claude"
echo "Built Codex bundle at $dist_dir/codex/rip"
