---
name: rip
description: Rip any website into a pixel-perfect, multi-page Next.js clone. Discovers all public pages, extracts shared layouts, builds real routes with navigation. Provide the target URL as an argument.
argument-hint: "<url>"
user-invocable: true
---

# Rip Site

Reverse-engineer **$ARGUMENTS** into a pixel-perfect, multi-page, fully navigable Next.js clone.

You are a **foreman walking a construction site** — extraction and construction happen in parallel, but extraction is meticulous and produces auditable artifacts. You dispatch specialist builder agents, each working in an isolated worktree, and merge their work at carefully defined gates.

## Bundle Layout

This Claude bundle is self-contained. All paths are relative to the skill directory:

- Scaffold: `${CLAUDE_SKILL_DIR}/../../resources/assets/scaffold/`
- Guiding principles: `${CLAUDE_SKILL_DIR}/../../resources/references/guiding-principles.md`
- Extraction scripts: `${CLAUDE_SKILL_DIR}/../../resources/references/extraction-scripts.md`
- Spec template: `${CLAUDE_SKILL_DIR}/../../resources/references/spec-template.md`
- Workflow: `${CLAUDE_SKILL_DIR}/../../resources/references/workflow.md`
- Output contract: `${CLAUDE_SKILL_DIR}/../../resources/references/output-contract.md`

## Preflight

1. **Chrome MCP is required.** Test it immediately. If it's not available, stop and tell the user to enable Chrome MCP (`/chrome` or `claude --chrome`). This skill cannot work without browser automation.
2. Parse the target URL from `$ARGUMENTS`. Extract the domain name.
3. Verify the bundled scaffold exists at `${CLAUDE_SKILL_DIR}/../../resources/assets/scaffold/`.
4. Read the bundled references: guiding-principles.md, extraction-scripts.md, spec-template.md, workflow.md, output-contract.md. These are your operational manual — internalize them before proceeding.

## Operating Rules

- Do not depend on repository-root paths. Use only the bundled resources.
- Do not read or reference Codex metadata, Codex packaging files, or any Codex-specific instructions.
- Keep the generated project fully independent from the plugin bundle.

---

## Phase 0: Project Initialization

### Step 1: Derive Project Name
Extract the domain from the target URL and sanitize it:
- `https://arzana.ai/` → `arzana-ai-clone`
- `https://www.example.com/` → `example-com-clone`

Rules: lowercase, replace dots/special chars with hyphens, append `-clone`, strip `www.`.

### Step 2: Create Output Project
```bash
SCAFFOLD_DIR="${CLAUDE_SKILL_DIR}/../../resources/assets/scaffold"
OUTPUT_DIR="<project-name>"
cp -r "$SCAFFOLD_DIR/" "$OUTPUT_DIR"
```

Replace `{{PROJECT_NAME}}` in `package.json` with the sanitized project name. The output project is created in the current working directory.

### Step 3: Initialize
```bash
cd "$OUTPUT_DIR"
git init
npm install
npm run build    # Must pass on empty scaffold
git add -A
git commit -m "Initial scaffold"
```

### Step 4: Create Research Directories
```bash
mkdir -p docs/research/pages docs/design-references scripts
mkdir -p src/components/shared src/components/pages src/data
mkdir -p public/branding public/seo public/images/shared
```

**From this point forward, all work happens in the output project directory.**

---

## Phase 1: Site Crawl & Page Discovery

Navigate to the target URL homepage with Chrome MCP.

### Step 1: Extract Internal Links
Use the **Internal Link Discovery** script from the bundled `extraction-scripts.md`. Run it via Chrome MCP on the homepage.

### Step 2: BFS Crawl
For each discovered path (breadth-first, starting from homepage links):

1. Navigate to the page via Chrome MCP.
2. Check if it loads successfully (not a 404, not a redirect to external/login).
3. If valid:
   - Take a full-page screenshot at 1440px width. Save to `docs/design-references/<slug>-desktop.png`.
   - Extract the page's `<title>`, `<meta name="description">`, and OG tags.
   - Extract that page's internal links (for next BFS level).
4. If invalid: skip and note in the site map.

**Crawl boundaries:**
- Same-origin only
- Max depth: 3 levels from homepage
- Max pages: 50
- Deduplicate paths (trailing slashes, case)

### Step 3: Detect Page Templates
Look for URL patterns with 3+ pages sharing the same structure:
- `/blog/post-1`, `/blog/post-2`, `/blog/post-3` → dynamic route `blog/[slug]`

Visit 2-3 representative pages and compare DOM structure. If structurally similar, confirm as template.

### Step 4: Build Site Map
Create `docs/research/SITE_MAP.md`:

```markdown
# Site Map: <domain>

## Pages Discovered
| Path | Title | Template Group | Depth | Status |
|------|-------|---------------|-------|--------|
| / | Home | — | 0 | clone |
| /about | About Us | — | 1 | clone |

## Template Groups
- **blog-post**: /blog/[slug] — N pages, structurally identical

## Page Hierarchy
- / (Home)
  - /about
  - /blog
    - /blog/post-1

## Skipped
| Path | Reason |
|------|--------|
| /login | Auth-gated |
```

---

## Phase 2: Shared Component Identification

### Step 1: Extract Header and Footer
Use the **Header and Footer Structure** script from `extraction-scripts.md`. Run on the homepage and at least 3 other pages via Chrome MCP.

### Step 2: Compare Across Pages
If header/footer structure is consistent across 80%+ of visited pages, mark as shared components.

### Step 3: Build Route Manifest
Create `docs/research/ROUTE_MANIFEST.json`:

```json
{
  "navLinks": [
    { "label": "Solutions", "href": "/solutions", "hasDropdown": true,
      "children": [
        { "label": "Quoting", "href": "/solutions/quoting" }
      ]
    },
    { "label": "Pricing", "href": "/pricing" },
    { "label": "Blog", "href": "/blog" }
  ],
  "footerGroups": [
    { "heading": "Company", "links": [
      { "label": "About Us", "href": "/about" }
    ]}
  ],
  "ctaButton": { "label": "Book a Demo", "href": "/contact" },
  "routes": [
    { "path": "/", "title": "Home", "template": null },
    { "path": "/about", "title": "About Us", "template": null },
    { "path": "/blog/[slug]", "title": "Blog Post", "template": "blog-post" }
  ]
}
```

### Step 4: Identify Nested Layouts
If a subset of pages share a sidebar (e.g., all `/docs/*` pages), note it for a nested `layout.tsx`.

Document in `docs/research/SHARED_COMPONENTS.md`.

---

## Phase 3: Global Reconnaissance

### Global Extraction
From the homepage, extract:

**Fonts** — Inspect `<link>` tags for Google Fonts or self-hosted fonts. Check computed `font-family` on headings, body, code, labels. Configure in `layout.tsx` using `next/font/google`.

**Colors** — Extract the site's color palette from computed styles. Update `globals.css` with the target's actual colors.

**Favicons & Meta** — Download to `public/seo/`. Update `layout.tsx` metadata.

**Global UI patterns** — Custom scrollbar, scroll-snap, global keyframes, smooth scroll libraries (Lenis, Locomotive Scroll). Add to `globals.css`.

### Mandatory Interaction Sweep (Homepage)

**Scroll sweep:** Scroll slowly top to bottom via Chrome MCP. Observe header changes, element animations, auto-switching sidebars, scroll-snap, smooth scroll libraries.

**Click sweep:** Click every interactive element via Chrome MCP. Record what happens.

**Hover sweep:** Hover over buttons, cards, links, nav items. Record changes.

**Responsive sweep:** Test at 1440px, 768px, 390px via Chrome MCP. Note layout shifts.

Save findings to `docs/research/BEHAVIORS.md`.

### Per-Page Topology
For each page, create `docs/research/pages/<slug>/TOPOLOGY.md`:

```markdown
# Page Topology: /about

| # | Section | Interaction | Height | Notes |
|---|---------|-------------|--------|-------|
| 0 | Navbar | static (sticky) | 66px | Shared — in layout.tsx |
| 1 | Hero Banner | static | ~500px | Full-width image + overlay text |
| 2 | Team Grid | static | ~800px | 3-column card grid |
| 3 | Footer | static | ~300px | Shared — in layout.tsx |
```

---

## Phase 4: Foundation Build

Sequential. Do it yourself — do not delegate:

1. **Update fonts** in `src/app/layout.tsx` using `next/font/google`.
2. **Update `globals.css`** with extracted design tokens, animations, utility classes.
3. **Create TypeScript interfaces** in `src/types/`.
4. **Extract SVG icons** — deduplicate inline `<svg>` elements, save as React components in `src/components/icons.tsx`.
5. **Download all assets** — write and run `scripts/download-assets.mjs`. Use the **Asset Discovery** script from `extraction-scripts.md` on each page via Chrome MCP. Organize:
   - Assets on 2+ pages → `public/images/shared/`
   - Assets on 1 page → `public/images/<page-slug>/`
   - Branding → `public/branding/`
   - SEO → `public/seo/`
   - Batch downloads 4 at a time.
6. **Build shared layout** — update `src/app/layout.tsx`:
   ```tsx
   export default function RootLayout({ children }: { children: React.ReactNode }) {
     return (
       <html lang="en" className={`${font.variable} antialiased`}>
         <body className="min-h-screen flex flex-col">
           {/* Navbar imported after Phase 5 */}
           <main className="flex-1">{children}</main>
           {/* Footer imported after Phase 5 */}
         </body>
       </html>
     );
   }
   ```
7. **Create route directories** — for every page in site map, `mkdir -p` and create placeholder `page.tsx`.
8. **Verify and commit:** `npm run build` → `git commit -m "Foundation: design tokens, fonts, assets, route scaffolding"`

---

## Phase 5: Shared Component Build

Shared components MUST be built before page-specific components.

### Navbar Agent
Dispatch a builder agent in a worktree with:
- Full CSS extraction from the homepage header (use **Per-Component CSS Extraction** script via Chrome MCP)
- Nav link structure from `ROUTE_MANIFEST.json`
- Active route logic using `usePathname()` from `next/navigation`
- All links as `<Link href="/route">` from `next/link`
- External links as `<a href target="_blank">`
- Dropdown behavior (if applicable)
- Scroll behavior (if navbar changes on scroll)
- Mobile hamburger menu

**Pattern:**
```tsx
"use client";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { cn } from "@/lib/utils";

export function Navbar() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  const isActive = (href: string) =>
    pathname === href || (href !== "/" && pathname.startsWith(href));
  // ...
}
```

**Critical:** NO `href="#"` for any link that maps to a discovered page.

### Footer Agent
Dispatch with full CSS extraction, footer link groups from `ROUTE_MANIFEST.json`, `<Link>` for internal, `<a target="_blank">` for external.

### Merge Gate
1. Merge worktree branches into main.
2. Update `layout.tsx` to import Navbar and Footer.
3. `npm run build` must pass.
4. Commit: `"Shared components: Navbar, Footer"`

---

## Phase 6: Per-Page Component Build

### Execution Strategy
- **Across pages:** Up to 3 pages in parallel after shared components done.
- **Within a page:** Sections in parallel.
- **Order:** Homepage first, then main nav links, then deep pages.
- **Template groups:** Extract from 1-2 pages, build template component once, create data file.

### Per-Page Loop

For each page:

#### Step 1: Extract
Navigate via Chrome MCP. For each section (excluding Navbar/Footer):
1. Screenshot the section. Save to `docs/design-references/`.
2. Use the **Per-Component CSS Extraction** script from `extraction-scripts.md` via Chrome MCP.
3. Extract multi-state styles — capture both states, record diff.
4. Extract real content — all text, alt attributes, aria labels.
5. Identify assets and layered images.
6. Assess complexity.
7. Wire cross-page links — map `<a href>` to route manifest.

#### Step 2: Write Spec Files
Use the **Spec Template** from `spec-template.md`. Create at `docs/research/pages/<slug>/components/<name>.spec.md`. Review the **Pre-Dispatch Checklist** in the spec template before proceeding.

#### Step 3: Dispatch Builders
**Simple section** (1-2 sub-components): One agent in one worktree.
**Complex section** (3+ sub-components): One agent per sub-component, plus wrapper.

Every builder receives inline:
- Full spec file contents
- Screenshot path
- Target file path: `src/components/pages/<page-slug>/<Component>.tsx`
- Cross-page link instructions (which links become `<Link>`)
- Instruction to verify `npx tsc --noEmit`

**Critical for multi-page:** Tell builders explicitly:
- Import `Link` from `next/link` for internal links
- Never use `href="#"` for links pointing to real routes
- Reference images from correct page path in `public/images/<page>/`

**Don't wait.** Dispatch for Section A while extracting Section B.

#### Step 4: Merge Per-Page
Merge worktree branches → resolve conflicts → `npm run build`.

### Dynamic Route Handling
For template groups (e.g., blog posts):
1. Extract content from each page.
2. Create data file: `src/data/<template-name>.ts`
3. Build template component: `src/components/pages/<route>/`
4. Wire dynamic route with `generateStaticParams()` and `generateMetadata()`:
   ```tsx
   // src/app/blog/[slug]/page.tsx
   import { blogPosts } from "@/data/blog-posts";
   import { notFound } from "next/navigation";

   export function generateStaticParams() {
     return blogPosts.map(post => ({ slug: post.slug }));
   }

   export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
     const { slug } = await params;
     const post = blogPosts.find(p => p.slug === slug);
     if (!post) return {};
     return { title: post.title, description: post.description };
   }

   export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
     const { slug } = await params;
     const post = blogPosts.find(p => p.slug === slug);
     if (!post) notFound();
     return <BlogPostContent post={post} />;
   }
   ```

---

## Phase 7: Page Assembly

For each page, wire sections in `src/app/<route>/page.tsx`:

```tsx
import { HeroSection } from "@/components/pages/about/HeroSection";
import { TeamSection } from "@/components/pages/about/TeamSection";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "About Us",
  description: "Learn about our team.",
};

export default function AboutPage() {
  return (
    <>
      <HeroSection />
      <TeamSection />
    </>
  );
}
```

Every page gets `metadata` from the crawl-extracted title/description.

Assembly checklist:
- [ ] All sections in correct visual order
- [ ] Page-level layout matches topology
- [ ] Page-level behaviors implemented
- [ ] Metadata set
- [ ] `npm run build` passes

Commit: `"Assemble all pages with metadata"`

---

## Phase 8: Visual QA + Navigation QA

### Per-Page Visual QA
For EACH page via Chrome MCP:
1. Open original and clone side-by-side at 1440px.
2. Compare section by section.
3. Repeat at 390px (mobile).
4. Fix discrepancies (re-extract if spec was wrong, fix component if spec was right).

### Navigation QA
1. **Navbar links:** Click each via Chrome MCP. Verify correct routing.
2. **Active state:** On each page, verify correct Navbar item highlighted.
3. **Footer links:** Click each internal link. Verify routing.
4. **In-page cross-links:** Click "Learn more", "View all" links. Verify routing.
5. **Back/forward:** Navigate forward 3 pages, then back.
6. **Direct URL:** Navigate to each route by URL.

### Mobile Navigation QA
1. At 390px, verify hamburger menu appears.
2. Open menu, verify all links present.
3. Click a link — verify it navigates AND closes the menu.

### Zero `href="#"` Audit
```bash
grep -r 'href="#"' src/ --include="*.tsx" --include="*.ts"
```
Every result must be an intentional anchor (`#section-id`) or a bug to fix.

### Final Build
```bash
npm run build
git add -A
git commit -m "Visual QA and navigation fixes"
```

---

## Completion

Report:
- Total pages cloned (with routes)
- Total components created (shared + per-page)
- Total spec files written
- Total assets downloaded
- Route manifest summary
- Navigation QA results
- Build status (`npm run build`)
- Visual QA results per page
- Known gaps
- Output path and run command (`cd <name>-clone && npm run dev`)
