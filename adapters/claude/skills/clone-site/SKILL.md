---
name: clone-site
description: Reverse-engineer and clone an entire public website into an independent multi-page Next.js project. Use this whenever the user wants a website cloned, rebuilt, replicated, or reverse-engineered from its live pages. Provide the target URL as an argument.
argument-hint: "<url>"
user-invocable: true
---

# Clone Site

Reverse-engineer **$ARGUMENTS** into a fully navigable Next.js clone.

This Claude bundle is self-contained. Use only the resources bundled with this installed plugin.

## Bundle Layout

- Scaffold: `${CLAUDE_SKILL_DIR}/../../resources/assets/scaffold/`
- Shared workflow: `${CLAUDE_SKILL_DIR}/../../resources/references/workflow.md`
- Output contract: `${CLAUDE_SKILL_DIR}/../../resources/references/output-contract.md`
- Shared helpers: `${CLAUDE_SKILL_DIR}/../../resources/scripts/`

## Preflight

1. Validate that browser automation is available before starting. If it is not, stop and tell the user the clone workflow requires browser automation.
2. Parse the target URL and derive the output directory name from the hostname.
3. Verify the bundled scaffold exists at `${CLAUDE_SKILL_DIR}/../../resources/assets/scaffold/`.
4. Read the shared workflow and output contract before planning the clone.

## Required Dependencies

- Chrome-compatible browser automation via MCP
- `node`
- `git`

## Operating Rules

- Treat the installed Claude bundle as the full runtime surface.
- Do not depend on repository-root paths.
- Do not read or reference Codex metadata, Codex packaging files, or any Codex-specific instructions.
- Copy the bundled scaffold into the user working directory before generating site-specific code.
- Keep the generated project fully independent from the plugin bundle.

## Validation Gates

- `npm install`
- `npx tsc --noEmit`
- `npm run build`

## Output Requirements

- clone every public page within the configured crawl limits
- extract shared layout pieces once
- build real App Router routes
- convert internal navigation to real links
- write auditable research artifacts into `docs/research/`
