#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dist_dir="$repo_root/dist"

rm -rf "$dist_dir/claude" "$dist_dir/codex"

mkdir -p "$dist_dir/claude/resources"
mkdir -p "$dist_dir/codex/clone-site"

cp -R "$repo_root/adapters/claude/.claude-plugin" "$dist_dir/claude/"
cp -R "$repo_root/adapters/claude/skills" "$dist_dir/claude/"
cp -R "$repo_root/core/scripts/." "$dist_dir/claude/resources/scripts/"
cp -R "$repo_root/core/references/." "$dist_dir/claude/resources/references/"
cp -R "$repo_root/core/assets/." "$dist_dir/claude/resources/assets/"

cp -R "$repo_root/adapters/codex/clone-site/." "$dist_dir/codex/clone-site/"
cp -R "$repo_root/core/scripts/." "$dist_dir/codex/clone-site/scripts/"
cp -R "$repo_root/core/references/." "$dist_dir/codex/clone-site/references/"
cp -R "$repo_root/core/assets/." "$dist_dir/codex/clone-site/assets/"

echo "Built Claude bundle at $dist_dir/claude"
echo "Built Codex bundle at $dist_dir/codex/clone-site"
