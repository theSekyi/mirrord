# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.

# mirrord — Multi-Page Website Cloning Engine

## What This Is
A Claude Code plugin that reverse-engineers any website and rebuilds ALL its public pages as a faithful, fully navigable clone. It discovers every page, extracts shared layouts, builds real routes, and wires navigation — producing an independent Next.js project.

## Tech Stack (Output Projects)
- **Framework:** Next.js 16 (App Router, React 19, TypeScript strict)
- **UI:** shadcn/ui (Radix primitives, Tailwind CSS v4, `cn()` utility)
- **Icons:** Lucide React (default — replaced by extracted SVGs during cloning)
- **Styling:** Tailwind CSS v4 with oklch design tokens
- **Deployment:** Vercel

## Code Style (Enforced in Output)
- TypeScript strict mode, no `any`
- Named exports, PascalCase components, camelCase utils
- Tailwind utility classes, no inline styles
- 2-space indentation
- Responsive: mobile-first

## Output Project Structure
```
<site-name>-clone/
  src/
    app/                    # Next.js App Router routes
      layout.tsx            # Shared layout: Navbar + Footer + {children}
      page.tsx              # Homepage
      <route>/page.tsx      # Each discovered page gets its own route
      <route>/[slug]/page.tsx  # Dynamic routes for template pages
    components/
      shared/               # Cross-page components (Navbar, Footer, MobileNav)
      pages/                # Page-specific components, namespaced by route
      ui/                   # shadcn/ui primitives
      icons.tsx             # Extracted SVG icons
    data/                   # Content data for dynamic routes
    lib/utils.ts            # cn() utility
  public/
    branding/               # Logo, favicon
    seo/                    # OG images, webmanifest
    images/
      shared/               # Multi-page assets
      <route>/              # Page-specific assets
  docs/research/            # Extraction artifacts
```

## Design Principles
- **Pixel-perfect emulation** — match the target's spacing, colors, typography exactly
- **Every page, not just the homepage** — discover and clone all public pages
- **Real navigation** — `next/link` with real hrefs, `usePathname()` for active states
- **Shared components extracted once** — Navbar and Footer live in `layout.tsx`
- **No `href="#"` for internal links** — every internal link points to a real route
- **Real content** — actual text and assets, not placeholders
- **Foundation first** — global tokens and shared components before per-page builds

## Agent Conventions

### Worktree Branch Naming
```
shared/navbar
shared/footer
page/home/hero
page/about/team
```

### Merge Order
1. Shared components merge first (Navbar, Footer)
2. Page-specific components merge per-page
3. `npm run build` must pass after every merge gate

### Navigation Rules
- Internal links → `<Link href="/route">` (from `next/link`)
- External links → `<a href="https://..." target="_blank" rel="noopener noreferrer">`
- Anchor links → `<a href="#section-id">`
- Active route detection → `usePathname()` from `next/navigation`

## MOST IMPORTANT NOTES
- When launching Claude Code agent teams, ALWAYS have each teammate work in their own worktree branch and merge everyone's work at the end.
- The output project MUST be fully independent — no imports from the plugin directory.
- Every builder agent MUST verify `npx tsc --noEmit` before finishing.
- After every merge gate, `npm run build` must pass.
