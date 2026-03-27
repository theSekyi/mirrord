# Packaging

`packaging/build-bundles.sh` generates the install artifacts under `dist/`.

## Generated Claude Bundle

```text
dist/claude/
  .claude-plugin/
  skills/rip/SKILL.md
  scaffold/              # Next.js template (flat, not nested)
  refs/                  # Guiding principles, extraction scripts, etc.
  scripts/
```

## Generated Codex Bundle

```text
dist/codex/rip/
  SKILL.md
  agents/openai.yaml
  assets/scaffold/
  refs/
  scripts/
```

## Verification

Run `./packaging/check-isolation.sh` after building. It fails if adapters leak into each other.

## Local Installers

- `./packaging/install-codex.sh` builds, validates, and installs into `~/.codex/skills/rip/`
- `./packaging/install-claude.sh` builds, validates, and stages for `--plugin-dir`
