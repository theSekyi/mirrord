---
name: clone-site
description: Reverse-engineer and clone public multi-page websites into independent Next.js projects. Use when Codex needs to crawl public pages, extract shared layouts and design tokens, build real routes and navigation, and output a standalone clone from a live website.
---

# Clone Site

Use this skill to clone a public website into a standalone Next.js project.

This installed skill is self-contained. Use only the files packaged inside the skill folder.

## Package Layout

- `assets/scaffold/` contains the shared Next.js scaffold.
- `references/workflow.md` defines the shared cloning workflow.
- `references/output-contract.md` defines the required output project shape.
- `scripts/` contains shared helpers. Prefer them when the skill evolves to include deterministic automation.

## Quick Start

1. Validate browser automation, Node.js, and Git before starting.
2. Read `references/workflow.md`.
3. Read `references/output-contract.md`.
4. Copy `assets/scaffold/` into the output directory and build from there.

## Required Dependencies

- a browser automation backend
- `node`
- `git`

Prefer an MCP-backed browser integration for deterministic live-site inspection.

## Operating Rules

- Treat this skill folder as the entire runtime surface.
- Do not assume Claude plugin files or Claude-specific environment variables exist.
- Do not reference repository-root paths during normal skill execution.
- Keep reusable logic in bundled helpers and artifacts, not in repeated prompt text.
- Keep the generated clone fully independent from the installed skill.

## Validation Gates

- `npm install`
- `npx tsc --noEmit`
- `npm run build`
