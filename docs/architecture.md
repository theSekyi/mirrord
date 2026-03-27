# Architecture

mirrord now uses a shared-core, multi-adapter layout.

## Layers

- `core/`: shared engine assets, shared contracts, and shared helpers
- `adapters/claude/`: Claude-only metadata and prompts
- `adapters/codex/`: Codex-only metadata and prompts
- `dist/`: generated runtime bundles

## Dependency Rules

- `core/` must not mention Claude or Codex.
- `adapters/claude/` may depend on `core/` only.
- `adapters/codex/` may depend on `core/` only.
- adapters must never reference each other.

## Why This Boundary Exists

- Claude and Codex have different packaging and metadata expectations.
- Shared source is useful.
- Shared runtime surfaces are risky and invite prompt drift.
- Bundle generation creates clean install targets without duplicating the source of truth.
