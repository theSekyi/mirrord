# mirrord

Website cloning engine with separate Claude and Codex runtime bundles.

## Model

- `core/` holds shared scaffold, references, and helpers.
- `adapters/claude/` is Claude-only.
- `adapters/codex/` is Codex-only.
- `dist/` contains generated install artifacts.

Do not install the repository root into either product.

## Build

```bash
./packaging/build-bundles.sh
./packaging/check-isolation.sh
```

## Install

Claude:
- local checked install: `./packaging/install-claude.sh`
- published install target: release [`dist/claude`](/Users/emmanuel/mirrord/dist/claude) as a standalone Claude plugin bundle
- requires a browser MCP server such as Chrome DevTools MCP to already be configured in Claude

Codex:
- checked local install: `./packaging/install-codex.sh`
- installs [`dist/codex/clone-site`](/Users/emmanuel/mirrord/dist/codex/clone-site) into `~/.codex/skills/clone-site/`
- requires `codex`, `node`, `git`, and a browser automation backend

## Rules

- keep `core/` agent-agnostic
- keep adapters isolated from each other
- treat `dist/` as generated output only
