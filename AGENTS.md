# mirrord Source Repository

This repository produces two separate runtime artifacts from one shared source tree.

## Architecture

- `core/` is shared engine source. Keep it agent-agnostic.
- `adapters/claude/` is Claude-only.
- `adapters/codex/` is Codex-only.
- `dist/` is generated and must remain platform-pure.

## Non-Negotiable Boundaries

- Never install the repository root into Claude or Codex.
- Never make the Claude adapter reference Codex metadata or packaging.
- Never make the Codex adapter reference Claude metadata or packaging.
- Never put Claude- or Codex-specific instructions into `core/`.
- Shared logic belongs in scripts, references, schemas, and assets under `core/`.

## Runtime Contract

- Claude consumes `dist/claude/` only.
- Codex consumes `dist/codex/rip/` only.
- `packaging/build-bundles.sh` is the only supported way to assemble runtime bundles.
- `packaging/check-isolation.sh` must pass before release.

## Output Stack

- Framework: Next.js 16
- Language: TypeScript strict
- UI: React 19 + shadcn/ui
- Styling: Tailwind CSS v4

## Editing Guidance

- If you change shared workflow or output contracts, update both adapters only when their
  orchestration text must change.
- Prefer adding or updating shared helpers in `core/scripts/` over duplicating prompt logic.
- If a change is needed for one platform only, keep it inside that adapter.
