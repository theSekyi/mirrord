# Packaging

`packaging/build-bundles.sh` generates the install artifacts under `dist/`.

## Generated Claude Bundle

```text
dist/claude/
  .claude-plugin/
  skills/
    rip/
      SKILL.md
  resources/
    scripts/
    references/
    assets/
```

Claude should only consume this tree.

## Generated Codex Bundle

```text
dist/codex/
  rip/
    SKILL.md
    agents/
      openai.yaml
    scripts/
    references/
    assets/
```

Codex should only consume this tree.

## Verification

Run `./packaging/check-isolation.sh` after building bundles. It fails if:

- the Codex bundle contains Claude plugin metadata
- the Codex bundle contains Claude-specific environment variables
- the Claude bundle contains Codex `agents/openai.yaml`

## Local Installers

- `./packaging/install-codex.sh` builds, validates, and installs the Codex skill into `~/.codex/skills/rip/`
- `./packaging/install-claude.sh` builds, validates, checks for browser MCP in Claude, and stages a local Claude bundle for `--plugin-dir`

Claude's native `plugin install` flow is marketplace-oriented. The release artifact for that flow is `dist/claude/` published as its own plugin bundle.
