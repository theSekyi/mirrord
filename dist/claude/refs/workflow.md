# Clone Workflow

Use this workflow for public, content-driven websites that should be rebuilt as independent
Next.js projects.

## Phase 1: Preflight

- Validate browser automation.
- Validate Node.js and Git.
- Normalize the target URL.
- Derive the output directory name from the hostname.
- Copy the shared scaffold into the output directory.

## Phase 2: Crawl

- Crawl same-origin public pages only.
- Default crawl bounds:
  - max depth: 3
  - max valid pages: 50
- Skip auth-gated, admin, and asset-only paths.
- Record page title, metadata, discovered links, and screenshots.

## Phase 3: Analyze

- Detect shared navigation and footer structures.
- Detect repeated page templates suitable for dynamic routes.
- Extract design tokens, typography, spacing, and reusable assets.
- Produce auditable artifacts in `docs/research/`.

## Phase 4: Materialize

- Generate App Router routes from the discovered site map.
- Promote shared UI into shared components and layout files.
- Keep page-specific code isolated by route.
- Download assets into `public/` with stable local paths.

## Phase 5: Validate

- Run `npm install`.
- Run `npx tsc --noEmit`.
- Run `npm run build`.
- Confirm internal links point to real routes.

## Source of Truth

- live site behavior and DOM extraction
- shared scaffold assets
- generated research artifacts
- the output contract
