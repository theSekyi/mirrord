---
name: clone-site
description: Reverse-engineer and clone an entire website — discovers all public pages, extracts shared layouts, builds real routes with navigation, and outputs an independent Next.js project. Use this whenever the user wants to clone, replicate, rebuild, or reverse-engineer any website. Provide the target URL as an argument.
argument-hint: "<url>"
user-invocable: true
---

# Clone Entire Website

You are about to reverse-engineer and rebuild **$ARGUMENTS** as a pixel-perfect, multi-page, fully navigable clone.

This is not a single-page tool. You will discover EVERY public page on the target site, identify shared components (Navbar, Footer), build real Next.js App Router routes, and wire navigation with `next/link` so the clone is fully browsable. The output is an independent git repository.

You are a **foreman walking a construction site** — extraction and construction happen in parallel, but extraction is meticulous and produces auditable artifacts. You dispatch specialist builder agents, each working in an isolated worktree, and merge their work at carefully defined gates.

## Pre-Flight

1. **Chrome MCP is required.** Test it immediately. If it's not available, stop and tell the user to enable it — this skill cannot work without browser automation.
2. Parse the target URL from `$ARGUMENTS`. Extract the domain name.
3. Verify the mirrord scaffold exists. The scaffold template lives at `${CLAUDE_SKILL_DIR}/../../templates/scaffold/`. If it doesn't exist, stop — the plugin is not installed correctly.

## Guiding Principles

These separate a successful multi-page clone from a "close enough" mess. Internalize them.

### 1. Completeness Beats Speed

Every builder agent must receive **everything** it needs: screenshot, exact CSS values, downloaded assets with local paths, real text content, component structure. If a builder has to guess anything — a color, a font size, a padding value — you have failed at extraction. Take the extra minute to extract one more property.

### 2. Small Tasks, Perfect Results

When an agent gets "build the entire features section," it glosses over details. When it gets a single focused component with exact CSS values, it nails it every time. **Complexity budget rule:** If a builder prompt exceeds ~150 lines of spec content, break it into smaller pieces.

### 3. Real Content, Real Assets

Extract actual text, images, videos, and SVGs from the live site. This is a clone, not a mockup. **Layered assets matter** — a section that looks like one image is often multiple layers (background, foreground, overlay). Inspect each container's full DOM tree.

### 4. Foundation First

Nothing can be built until the foundation exists: design tokens, fonts, shared layout, route scaffolding. This is sequential and non-negotiable. Everything after can be parallel.

### 5. Extract Appearance AND Behavior

A website is not a screenshot — elements move, change, appear, and disappear. For every element, extract its **appearance** (exact computed CSS via `getComputedStyle()`) AND its **behavior** (what changes, what triggers the change, and how the transition happens).

Behaviors to watch for:
- Navbar that shrinks/changes background/gains shadow after scrolling
- Elements animating into view (fade-up, slide-in, stagger delays)
- Scroll-snap sections
- Parallax layers
- Hover state transitions (duration and easing matter)
- Dropdowns, modals, accordions with enter/exit animations
- Auto-playing carousels or cycling content
- Tabbed/pill content that cycles with transitions
- Scroll-driven tab/accordion switching (IntersectionObserver, NOT click handlers)
- Smooth scroll libraries (Lenis, Locomotive Scroll — check for `.lenis` class)

### 6. Identify the Interaction Model Before Building

The single most expensive mistake: building a click-based UI when the original is scroll-driven. Before writing any builder prompt for an interactive section, definitively answer: **Is this section driven by clicks, scrolls, hovers, time, or some combination?**

1. **Don't click first.** Scroll through the section slowly and observe.
2. If things change on scroll, it's scroll-driven. Extract the mechanism.
3. If nothing changes on scroll, THEN test for click/hover-driven interactivity.
4. Document the interaction model explicitly in the component spec.

### 7. Extract Every State, Not Just the Default

Many components have multiple visual states. You must extract ALL states.

For tabbed/stateful content:
- Click each tab/button via Chrome MCP
- Extract content, images, and data for EACH state
- Record the transition animation between states

For scroll-dependent elements:
- Capture computed styles at scroll position 0
- Scroll past trigger, capture again
- Diff to identify exactly which CSS properties change
- Record transition CSS and trigger threshold

### 8. Spec Files Are the Source of Truth

Every component gets a specification file BEFORE any builder is dispatched. The spec file is the contract between extraction and building. The builder receives spec contents inline — no external references.

### 9. Build Must Always Compile

Every builder: `npx tsc --noEmit` before finishing. After merges: `npm run build`. A broken build is never acceptable.

### 10. Every Page, Every Link

This is a multi-page clone. Every internal `<a href>` becomes a `<Link href>`. Every discovered page gets a real route. The Navbar shows which page is active. The user can browse the clone just like the original site.

---

## Phase 0: Project Initialization

### Step 1: Derive Project Name
Extract the domain from the target URL and sanitize it:
- `https://arzana.ai/` → `arzana-ai-clone`
- `https://www.example.com/` → `example-com-clone`
- `https://app.stripe.com/` → `app-stripe-com-clone`

Rules: lowercase, replace dots/special chars with hyphens, append `-clone`, strip `www.`.

### Step 2: Create Output Project
```bash
# The scaffold template lives relative to the skill file
SCAFFOLD_DIR="${CLAUDE_SKILL_DIR}/../../templates/scaffold"
OUTPUT_DIR="<project-name>"
cp -r "$SCAFFOLD_DIR/" "$OUTPUT_DIR"

# Replace placeholder in package.json
cd "$OUTPUT_DIR"
# Replace {{PROJECT_NAME}} with the actual project name in package.json
```

Use `sed` or write the file to replace `{{PROJECT_NAME}}` in `package.json` with the sanitized project name. The output project is created in the current working directory (wherever the user invoked the skill from).

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
mkdir -p docs/research/pages
mkdir -p docs/design-references
mkdir -p scripts
mkdir -p src/components/shared
mkdir -p src/components/pages
mkdir -p src/components/ui
mkdir -p src/data
mkdir -p public/branding
mkdir -p public/seo
mkdir -p public/images/shared
```

**From this point forward, all work happens in the output project directory.**

---

## Phase 1: Site Crawl & Page Discovery

Navigate to the target URL homepage with Chrome MCP.

### Step 1: Extract All Internal Links from Homepage
```javascript
JSON.stringify([...new Set(
  [...document.querySelectorAll('a[href]')]
    .map(a => {
      try { return new URL(a.href, location.origin); } catch { return null; }
    })
    .filter(u => u && u.origin === location.origin)
    .map(u => u.pathname.replace(/\/$/, '') || '/')
    .filter(p => !p.match(/\.(pdf|png|jpg|jpeg|gif|svg|webp|avif|zip|xml|json|css|js|ico|woff|woff2|ttf|eot)$/i))
    .filter(p => !p.match(/^\/(api|admin|login|auth|signin|signup|register|dashboard|account|checkout|cart)\b/i))
)].sort());
```

### Step 2: BFS Crawl
For each discovered path (breadth-first, starting from homepage links):

1. Navigate to the page via Chrome MCP.
2. Check if it loads successfully (not a 404, not a redirect to an external site or login page).
3. If valid:
   - Take a full-page screenshot at 1440px width. Save to `docs/design-references/<slug>-desktop.png`.
   - Extract the page's `<title>`, `<meta name="description">`, and OG tags.
   - Extract that page's internal links (for next BFS level).
4. If invalid (404, redirect, auth-gated): skip and note in the site map.

**Crawl boundaries:**
- Same-origin only
- Max depth: 3 levels from homepage
- Max pages: 50 (stop crawling after 50 valid pages)
- Deduplicate paths (trailing slashes, case)

### Step 3: Detect Page Templates
Look for URL patterns with 3+ pages sharing the same structure:
- `/blog/post-1`, `/blog/post-2`, `/blog/post-3` → dynamic route `blog/[slug]`
- `/products/widget-a`, `/products/widget-b` → dynamic route `products/[slug]`

For each template group, visit 2-3 representative pages and compare their DOM structure. If structurally similar (same number of major sections, same section types), confirm it as a template.

### Step 4: Build Site Map
Create `docs/research/SITE_MAP.md`:

```markdown
# Site Map: <domain>

## Pages Discovered
| Path | Title | Template Group | Depth | Status |
|------|-------|---------------|-------|--------|
| / | Home | — | 0 | clone |
| /about | About Us | — | 1 | clone |
| /solutions | Solutions | — | 1 | clone |
| /blog | Blog | — | 1 | clone |
| /blog/post-1 | First Post | blog-post | 2 | clone |
| /blog/post-2 | Second Post | blog-post | 2 | clone |
| /pricing | Pricing | — | 1 | clone |

## Template Groups
- **blog-post**: /blog/[slug] — 5 pages, structurally identical

## Page Hierarchy
- / (Home)
  - /about
  - /solutions
  - /blog
    - /blog/post-1
    - /blog/post-2
  - /pricing

## Skipped
| Path | Reason |
|------|--------|
| /login | Auth-gated |
| /dashboard | Auth-gated |
```

---

## Phase 2: Shared Component Identification

### Step 1: Extract Header and Footer from Each Page
For the homepage and at least 3 other pages, extract:

```javascript
// Extract header/nav structure
JSON.stringify({
  header: (() => {
    const h = document.querySelector('header') || document.querySelector('nav');
    if (!h) return null;
    return {
      tag: h.tagName,
      html: h.outerHTML.slice(0, 5000),
      links: [...h.querySelectorAll('a[href]')].map(a => ({
        text: a.textContent.trim(),
        href: new URL(a.href, location.origin).pathname,
        isExternal: new URL(a.href, location.origin).origin !== location.origin
      })),
      hasDropdowns: h.querySelectorAll('[data-dropdown], details, [aria-haspopup]').length > 0,
      hasMobileToggle: h.querySelectorAll('[aria-label*="menu"], [aria-label*="Menu"], .hamburger, .mobile-toggle, button[aria-expanded]').length > 0
    };
  })(),
  footer: (() => {
    const f = document.querySelector('footer');
    if (!f) return null;
    return {
      html: f.outerHTML.slice(0, 5000),
      linkGroups: [...f.querySelectorAll('div, section, nav')].filter(el =>
        el.querySelectorAll('a').length >= 2 && el.children.length <= 15
      ).map(group => ({
        heading: group.querySelector('h2, h3, h4, h5, p, span')?.textContent?.trim(),
        links: [...group.querySelectorAll('a')].map(a => ({
          text: a.textContent.trim(),
          href: a.href,
          isExternal: new URL(a.href, location.origin).origin !== location.origin
        }))
      }))
    };
  })()
});
```

### Step 2: Compare Across Pages
If the header/footer structure is consistent across 80%+ of visited pages, mark them as shared components.

### Step 3: Build Route Manifest
Create `docs/research/ROUTE_MANIFEST.json`:

```json
{
  "navLinks": [
    { "label": "Solutions", "href": "/solutions", "hasDropdown": true,
      "children": [
        { "label": "Quoting", "href": "/solutions/quoting" },
        { "label": "Estimating", "href": "/solutions/estimating" }
      ]
    },
    { "label": "Pricing", "href": "/pricing" },
    { "label": "Company", "href": "/about" },
    { "label": "Blog", "href": "/blog" }
  ],
  "footerGroups": [
    { "heading": "Solutions", "links": [
      { "label": "Quoting", "href": "/solutions/quoting" },
      { "label": "Estimating", "href": "/solutions/estimating" }
    ]},
    { "heading": "Company", "links": [
      { "label": "About Us", "href": "/about" },
      { "label": "Careers", "href": "/careers" }
    ]},
    { "heading": "Resources", "links": [
      { "label": "Blog", "href": "/blog" },
      { "label": "Documentation", "href": "https://docs.example.com", "external": true }
    ]}
  ],
  "ctaButton": { "label": "Book a Demo", "href": "/contact" },
  "routes": [
    { "path": "/", "title": "Home", "template": null },
    { "path": "/about", "title": "About Us", "template": null },
    { "path": "/solutions", "title": "Solutions", "template": null },
    { "path": "/blog", "title": "Blog", "template": null },
    { "path": "/blog/[slug]", "title": "Blog Post", "template": "blog-post" }
  ]
}
```

### Step 4: Identify Nested Layouts
If a subset of pages share a sidebar or secondary navigation (e.g., all `/docs/*` pages have a left sidebar), note this. These pages will get a nested `layout.tsx`.

Document findings in `docs/research/SHARED_COMPONENTS.md`:
```markdown
# Shared Components Analysis

## Navbar
- **Status:** Shared across all pages
- **Type:** Sticky header
- **Links:** [list from ROUTE_MANIFEST]
- **Has dropdowns:** Yes/No
- **Has mobile toggle:** Yes/No
- **Scroll behavior:** [changes on scroll? describe]

## Footer
- **Status:** Shared across all pages
- **Link groups:** [count] groups with [count] total links
- **Has social icons:** Yes/No
- **Has CTA:** Yes/No

## Nested Layouts
- **/docs/**: Sidebar navigation (appears on all /docs/* pages)
```

---

## Phase 3: Global Reconnaissance

### Screenshots
Full-page screenshots were already captured during Phase 1 crawl. For the homepage, also capture at mobile (390px) viewport.

### Global Extraction
Extract these from the homepage:

**Fonts** — Inspect `<link>` tags for Google Fonts or self-hosted fonts. Check computed `font-family` on headings, body, code, labels. Configure in `layout.tsx` using `next/font/google` or `next/font/local`.

**Colors** — Extract the site's color palette from computed styles. Update `globals.css` with the target's actual colors. Map to shadcn tokens where they fit. Add custom properties for extras.

**Favicons & Meta** — Download favicons, apple-touch-icons, OG images, webmanifest to `public/seo/`. Update `layout.tsx` metadata.

**Global UI patterns** — Custom scrollbar, scroll-snap, global keyframes, backdrop filters, gradients, smooth scroll libraries (Lenis, Locomotive Scroll). Add to `globals.css`.

### Mandatory Interaction Sweep (Homepage)
**Scroll sweep:** Scroll slowly top to bottom. Observe header changes, element animations, auto-switching sidebars, scroll-snap, smooth scroll libraries.

**Click sweep:** Click every interactive element. Record what happens.

**Hover sweep:** Hover over buttons, cards, links, nav items. Record changes.

**Responsive sweep:** Test at 1440px, 768px, 390px. Note layout shifts.

Save findings to `docs/research/BEHAVIORS.md`.

### Per-Page Abbreviated Sweep
For each non-homepage page, perform a quick interaction sweep:
1. Scroll top to bottom — note any unique behaviors.
2. Click any tabs/interactive elements unique to that page.
3. Note responsive differences.

Save per-page topology: `docs/research/pages/<slug>/TOPOLOGY.md` with sections mapped, interaction models identified.

### Page Topology Format
For each page, map every section:
```markdown
# Page Topology: /about

| # | Section | Interaction | Height | Notes |
|---|---------|-------------|--------|-------|
| 0 | Navbar | static (sticky) | 66px | Shared — in layout.tsx |
| 1 | Hero Banner | static | ~500px | Full-width image + overlay text |
| 2 | Our Story | static | ~600px | Two-column: text + image |
| 3 | Team Grid | static | ~800px | 3-column card grid |
| 4 | Values | scroll-driven | ~400px | Cards animate in on scroll |
| 5 | CTA | static | ~200px | Centered CTA button |
| 6 | Footer | static | ~300px | Shared — in layout.tsx |
```

---

## Phase 4: Foundation Build

This is sequential. Do it yourself — do not delegate:

### Step 1: Update Fonts
Update `src/app/layout.tsx` with the target site's fonts:
```tsx
import { Inter, Roboto } from "next/font/google";

const inter = Inter({ variable: "--font-inter", subsets: ["latin"], display: "swap" });
```

### Step 2: Update Design Tokens
Update `src/app/globals.css` with extracted colors, spacing, animations, utility classes. Preserve the shadcn theme structure. Add site-specific custom properties.

### Step 3: Create TypeScript Interfaces
Create `src/types/` interfaces for content structures observed across the site.

### Step 4: Extract SVG Icons
Find all inline `<svg>` elements across the site. Deduplicate and save as React components in `src/components/icons.tsx`.

### Step 5: Download All Assets
Write and run `scripts/download-assets.mjs` that downloads ALL images, videos, and binary assets from ALL pages. Use Chrome MCP on each page to discover assets:

```javascript
// Run on EACH page to discover assets
JSON.stringify({
  images: [...document.querySelectorAll('img')].map(img => ({
    src: img.src || img.currentSrc,
    alt: img.alt,
    width: img.naturalWidth,
    height: img.naturalHeight,
    parentClasses: img.parentElement?.className,
    siblings: img.parentElement ? [...img.parentElement.querySelectorAll('img')].length : 0,
    position: getComputedStyle(img).position,
    zIndex: getComputedStyle(img).zIndex
  })),
  videos: [...document.querySelectorAll('video')].map(v => ({
    src: v.src || v.querySelector('source')?.src,
    poster: v.poster,
    autoplay: v.autoplay,
    loop: v.loop,
    muted: v.muted
  })),
  backgroundImages: [...document.querySelectorAll('*')].filter(el => {
    const bg = getComputedStyle(el).backgroundImage;
    return bg && bg !== 'none';
  }).map(el => ({
    url: getComputedStyle(el).backgroundImage,
    element: el.tagName + '.' + (el.className?.toString().split(' ')[0] || '')
  })),
  svgCount: document.querySelectorAll('svg').length,
  fonts: [...new Set([...document.querySelectorAll('*')].slice(0, 200).map(el => getComputedStyle(el).fontFamily))],
  favicons: [...document.querySelectorAll('link[rel*="icon"]')].map(l => ({ href: l.href, sizes: l.sizes?.toString() }))
});
```

Organize assets by page:
- Assets on 2+ pages → `public/images/shared/`
- Assets on 1 page → `public/images/<page-slug>/`
- Branding (logo, favicon) → `public/branding/`
- SEO (OG images, webmanifest) → `public/seo/`

Use batched parallel downloads (4 at a time) with error handling.

### Step 6: Build Shared Layout
Update `src/app/layout.tsx` to include the structure for shared components:
```tsx
import type { Metadata } from "next";
import { FontFamily } from "next/font/google";
import "./globals.css";

// Fonts configured from extraction

export const metadata: Metadata = {
  title: { default: "Site Name", template: "%s | Site Name" },
  description: "Site description",
  icons: { icon: "/seo/favicon.png" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${font.variable} antialiased`}>
      <body className="min-h-screen flex flex-col">
        {/* Navbar will be imported here after Phase 5 */}
        <main className="flex-1">{children}</main>
        {/* Footer will be imported here after Phase 5 */}
      </body>
    </html>
  );
}
```

### Step 7: Create Route Directories and Placeholders
For every page in the site map, create the route directory and a placeholder `page.tsx`:

```bash
# For each route: /about, /solutions, /blog, /blog/[slug], etc.
mkdir -p src/app/about
echo 'export default function AboutPage() { return <main>About</main>; }' > src/app/about/page.tsx
```

For dynamic routes:
```tsx
// src/app/blog/[slug]/page.tsx
export default function BlogPost({ params }: { params: Promise<{ slug: string }> }) {
  return <main>Blog Post</main>;
}
```

### Step 8: Verify and Commit
```bash
npm run build    # Must pass
git add -A
git commit -m "Foundation: design tokens, fonts, assets, route scaffolding"
```

---

## Phase 5: Shared Component Build

Shared components MUST be built before any page-specific components because every page imports them via `layout.tsx`.

### Navbar Agent

Dispatch a builder agent in a worktree with:

**Spec requirements for the Navbar:**
- Full CSS extraction from the homepage header
- The complete nav link structure from `ROUTE_MANIFEST.json`
- Active route logic using `usePathname()` from `next/navigation`
- All links as `<Link href="/route">` (from `next/link`) for internal routes
- External links as `<a href target="_blank">`
- Dropdown menu behavior (if applicable) — click/hover trigger, animation
- Scroll behavior (if navbar changes on scroll)
- CTA button with correct link

**Pattern for the Navbar:**
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

  return (
    <header className="sticky top-0 z-50 ...">
      {/* Logo as Link to "/" */}
      {/* Desktop nav with Link components and isActive styling */}
      {/* Mobile hamburger button */}
      {/* Mobile drawer/dropdown with Link components */}
    </header>
  );
}
```

**Critical:** The Navbar must NOT use `href="#"` for any link that maps to a discovered page. Every internal link is a real `<Link>`.

### Footer Agent

Dispatch a builder agent with:
- Full CSS extraction from the homepage footer
- Footer link groups from `ROUTE_MANIFEST.json`
- Internal links as `<Link>`, external as `<a target="_blank">`
- Social media icons as external links

### MobileNav Agent (if needed)

If the mobile navigation is complex (slide-out drawer, separate component), dispatch a separate agent. Otherwise, include mobile nav logic in the Navbar component.

### Merge Gate
After all shared component agents complete:
1. Merge their worktree branches into main.
2. Update `src/app/layout.tsx` to import the real Navbar and Footer:
   ```tsx
   import { Navbar } from "@/components/shared/Navbar";
   import { Footer } from "@/components/shared/Footer";

   // In the return:
   <body>
     <Navbar />
     <main className="flex-1">{children}</main>
     <Footer />
   </body>
   ```
3. Verify: `npm run build` passes.
4. Commit: `git commit -m "Shared components: Navbar, Footer"`

---

## Phase 6: Per-Page Component Build

This is the core extraction-to-build loop, applied to every page in the site map.

### Execution Strategy

**Across pages:** Process up to 3 pages in parallel after shared components are done.

**Within a page:** Build sections in parallel (same as single-page cloning).

**Order:** Start with the homepage (most important), then remaining pages by priority (main nav links first, deep pages last).

**For template groups** (e.g., blog posts): Extract fully from 1-2 representative pages, build the template component once, create a data file with all content.

### Per-Page Loop

For each page:

#### Step 1: Extract Page Sections

Navigate to the page via Chrome MCP. For each section in its topology (excluding Navbar and Footer — they're in `layout.tsx`):

1. **Screenshot** the section. Save to `docs/design-references/`.

2. **Extract CSS** for every element using the extraction script:
```javascript
(function(selector) {
  const el = document.querySelector(selector);
  if (!el) return JSON.stringify({ error: 'Element not found: ' + selector });
  const props = [
    'fontSize','fontWeight','fontFamily','lineHeight','letterSpacing','color',
    'textTransform','textDecoration','backgroundColor','background',
    'padding','paddingTop','paddingRight','paddingBottom','paddingLeft',
    'margin','marginTop','marginRight','marginBottom','marginLeft',
    'width','height','maxWidth','minWidth','maxHeight','minHeight',
    'display','flexDirection','justifyContent','alignItems','gap',
    'gridTemplateColumns','gridTemplateRows',
    'borderRadius','border','borderTop','borderBottom','borderLeft','borderRight',
    'boxShadow','overflow','overflowX','overflowY',
    'position','top','right','bottom','left','zIndex',
    'opacity','transform','transition','cursor',
    'objectFit','objectPosition','mixBlendMode','filter','backdropFilter',
    'whiteSpace','textOverflow','WebkitLineClamp'
  ];
  function extractStyles(element) {
    const cs = getComputedStyle(element);
    const styles = {};
    props.forEach(p => { const v = cs[p]; if (v && v !== 'none' && v !== 'normal' && v !== 'auto' && v !== '0px' && v !== 'rgba(0, 0, 0, 0)') styles[p] = v; });
    return styles;
  }
  function walk(element, depth) {
    if (depth > 4) return null;
    const children = [...element.children];
    return {
      tag: element.tagName.toLowerCase(),
      classes: element.className?.toString().split(' ').slice(0, 5).join(' '),
      text: element.childNodes.length === 1 && element.childNodes[0].nodeType === 3 ? element.textContent.trim().slice(0, 200) : null,
      styles: extractStyles(element),
      images: element.tagName === 'IMG' ? { src: element.src, alt: element.alt, naturalWidth: element.naturalWidth, naturalHeight: element.naturalHeight } : null,
      childCount: children.length,
      children: children.slice(0, 20).map(c => walk(c, depth + 1)).filter(Boolean)
    };
  }
  return JSON.stringify(walk(el, 0), null, 2);
})('SELECTOR');
```

3. **Extract multi-state styles** — for stateful elements, capture both states. Record the diff.

4. **Extract real content** — all text, alt attributes, aria labels. For tabbed content, click each tab and extract per state.

5. **Identify assets** — which images/videos from `public/`, which icons from `icons.tsx`. Check for layered images.

6. **Assess complexity** — how many distinct sub-components?

7. **Wire cross-page links** — for every `<a>` in this section:
   - If href matches a route in the site map → note it for `<Link>` conversion
   - If href is external → stays as `<a>`
   - If href is an anchor → stays as `#id`

#### Step 2: Write Component Spec Files

For each section, create a spec at `docs/research/pages/<page-slug>/components/<component-name>.spec.md`:

```markdown
# <ComponentName> Specification

## Overview
- **Target file:** `src/components/pages/<page-slug>/<ComponentName>.tsx`
- **Screenshot:** `docs/design-references/<screenshot-name>.png`
- **Interaction model:** <static | click-driven | scroll-driven | time-driven>

## DOM Structure
<Element hierarchy>

## Computed Styles (exact values from getComputedStyle)

### Container
- display: ...
- padding: ...
- (every relevant property with exact values)

### <Child element 1>
- fontSize: ...
- color: ...

## States & Behaviors

### <Behavior name>
- **Trigger:** <exact mechanism>
- **State A (before):** <property values>
- **State B (after):** <property values>
- **Transition:** <CSS transition>
- **Implementation:** <approach>

### Hover states
- **<Element>:** <property>: <before> → <after>, transition: <value>

## Cross-Page Links
- "Learn more" button → `<Link href="/about">`
- "View all products" → `<Link href="/products">`
- "External partner" → `<a href="https://..." target="_blank">`

## Per-State Content (if applicable)

### State: "<Tab 1>"
- Title: "..."
- Content: [...]

## Assets
- Background: `public/images/<page>/<file>.webp`
- Icons: <IconName> from icons.tsx

## Text Content (verbatim)
<All text, copy-pasted from the live site>

## Responsive Behavior
- **Desktop (1440px):** <layout>
- **Tablet (768px):** <changes>
- **Mobile (390px):** <changes>
```

#### Step 3: Dispatch Builders

Based on complexity, dispatch builder agent(s) in worktree(s).

**Simple section** (1-2 sub-components): One agent.
**Complex section** (3+ sub-components): One agent per sub-component, plus wrapper.

**What every builder receives (inline in prompt):**
- Full spec file contents
- Section screenshot path
- Shared component imports (`icons.tsx`, `cn()`, shadcn primitives)
- Target file path: `src/components/pages/<page-slug>/<Component>.tsx`
- Cross-page link instructions (which links become `<Link>`)
- Instruction to verify `npx tsc --noEmit`
- Responsive breakpoint values

**Critical for multi-page:** Tell builders explicitly:
- Import `Link` from `next/link` for any internal links
- Never use `href="#"` for links that point to real routes
- Reference images from the correct page-specific path in `public/images/<page>/`

**Don't wait.** Dispatch builders for Section A while extracting Section B.

#### Step 4: Merge Per-Page
As builder agents complete:
1. Merge worktree branches into main.
2. Resolve conflicts (you have full context).
3. Verify build: `npm run build`.

### Dynamic Route Handling

For template groups (e.g., blog posts):

1. Extract content from each page in the group.
2. Create a data file: `src/data/<template-name>.ts`:
   ```tsx
   export interface BlogPost {
     slug: string;
     title: string;
     description: string;
     content: React.ReactNode; // or structured sections
   }

   export const blogPosts: BlogPost[] = [
     { slug: "first-post", title: "First Post", ... },
     { slug: "second-post", title: "Second Post", ... },
   ];
   ```

3. Build the template component: `src/components/pages/blog/BlogPostContent.tsx`.

4. Wire the dynamic route page:
   ```tsx
   // src/app/blog/[slug]/page.tsx
   import { blogPosts } from "@/data/blog-posts";
   import { BlogPostContent } from "@/components/pages/blog/BlogPostContent";
   import { notFound } from "next/navigation";
   import type { Metadata } from "next";

   export function generateStaticParams() {
     return blogPosts.map(post => ({ slug: post.slug }));
   }

   export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
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

After all sections for a page are built and merged, wire them together in `src/app/<route>/page.tsx`:

### For Static Pages
```tsx
import { HeroSection } from "@/components/pages/about/HeroSection";
import { TeamSection } from "@/components/pages/about/TeamSection";
import { ValuesSection } from "@/components/pages/about/ValuesSection";
import { CTASection } from "@/components/pages/about/CTASection";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "About Us",
  description: "Learn about our team and mission.",
};

export default function AboutPage() {
  return (
    <>
      <HeroSection />
      <TeamSection />
      <ValuesSection />
      <CTASection />
    </>
  );
}
```

### For the Homepage
```tsx
import { HeroSection } from "@/components/pages/home/HeroSection";
import { LogoBar } from "@/components/pages/home/LogoBar";
// ... all homepage sections

export default function Home() {
  return (
    <>
      <HeroSection />
      <LogoBar />
      {/* ... all sections in visual order */}
    </>
  );
}
```

### Per-Page Metadata
Every page gets metadata extracted during the crawl:
```tsx
export const metadata: Metadata = {
  title: "Page Title",  // From <title> tag
  description: "Page description", // From <meta name="description">
  openGraph: {
    title: "OG Title",
    description: "OG Description",
    // images if applicable
  },
};
```

### Assembly Checklist
- [ ] All sections imported in correct visual order
- [ ] Page-level layout matches topology (scroll containers, z-index)
- [ ] Page-level behaviors implemented (scroll-snap, intersection observers)
- [ ] Metadata set from extracted title/description
- [ ] `npm run build` passes

After assembling all pages, commit:
```bash
git add -A
git commit -m "Assemble all pages with metadata"
```

---

## Phase 8: Visual QA + Navigation QA

### Per-Page Visual QA
For EACH page:
1. Open original and clone side-by-side at 1440px.
2. Compare section by section, top to bottom.
3. Repeat at 390px (mobile).
4. For discrepancies:
   - Check the spec file — was the value extracted correctly?
   - If spec wrong: re-extract, update spec, fix component
   - If spec right but builder wrong: fix component

### Navigation QA
Test every navigable path:

1. **Navbar links:** Click each link. Verify it routes to the correct page.
2. **Active state:** On each page, verify the correct Navbar item is highlighted.
3. **Footer links:** Click each internal link. Verify routing.
4. **In-page cross-links:** Click "Learn more", "View all", "Read more" links. Verify they route correctly.
5. **Back/forward:** Navigate forward 3 pages, then back. Verify correct pages render.
6. **Direct URL:** Navigate directly to each route by URL. Verify it renders correctly.

### Mobile Navigation QA
1. At 390px viewport, verify hamburger menu appears.
2. Open the mobile menu. Verify all links are present.
3. Click a link. Verify it navigates AND closes the menu.
4. On the new page, verify the hamburger menu works again.

### Zero `href="#"` Audit
```bash
grep -r 'href="#"' src/ --include="*.tsx" --include="*.ts"
```
Every result must be either:
- An intentional anchor link (`href="#section-id"` with a corresponding `id`)
- A button that should use `<button>` instead of `<a>` (fix it)
- NOT a link that should point to a real route (fix it with `<Link>`)

### Interaction QA
Test all interactive behaviors on every page:
- Scroll through — animations trigger correctly
- Click tabs/pills — content switches
- Hover buttons/cards — states apply
- Carousels auto-play and controls work

### Final Build and Commit
```bash
npm run build
git add -A
git commit -m "Visual QA and navigation fixes"
```

---

## Pre-Dispatch Checklist

Before dispatching ANY builder agent, verify ALL boxes:

- [ ] Spec file written to `docs/research/pages/<slug>/components/<name>.spec.md`
- [ ] Every CSS value is from `getComputedStyle()`, not estimated
- [ ] Interaction model identified (static / click / scroll / time)
- [ ] For stateful components: every state's content and styles captured
- [ ] For scroll-driven: trigger threshold, before/after styles, transition recorded
- [ ] For hover states: before/after values and transition timing recorded
- [ ] All images identified (including overlays and layered compositions)
- [ ] Cross-page links identified and mapped to routes
- [ ] Responsive behavior documented for desktop and mobile
- [ ] Text content verbatim from the site
- [ ] Builder prompt under ~150 lines of spec; if over, split

---

## What NOT to Do

Each of these cost hours of rework in previous clones:

- **Don't build click-based tabs when the original is scroll-driven.** Determine interaction model FIRST by scrolling before clicking.
- **Don't extract only the default state.** Click every tab, scroll to every trigger.
- **Don't miss overlay/layered images.** Check every container's full DOM tree.
- **Don't approximate CSS classes.** Extract exact computed values.
- **Don't use `href="#"` for links to real pages.** Use `<Link href="/route">`.
- **Don't forget mobile navigation.** The hamburger menu must work on every page.
- **Don't skip the route manifest.** Without it, navigation wiring is guesswork.
- **Don't build page components before shared components.** Navbar and Footer must exist first.
- **Don't hardcode the asset download script.** Generate it dynamically from Chrome MCP discovery.
- **Don't put page-specific components in `shared/`.** Namespace under `pages/<route>/`.
- **Don't forget per-page metadata.** Every page needs its own title and description.
- **Don't dispatch builders without spec files.** The spec forces exhaustive extraction.
- **Don't give builders too much scope.** Under 150 lines of spec per agent.
- **Don't bundle unrelated sections into one agent.**
- **Don't skip responsive extraction.** Test at 1440, 768, 390 during extraction.
- **Don't forget smooth scroll libraries.** Check for Lenis, Locomotive Scroll.

---

## Completion

When done, report:
- Total pages cloned (with routes)
- Total components created (shared + per-page)
- Total spec files written
- Total assets downloaded
- Route manifest summary (how many nav links, footer links)
- Navigation QA results (any broken links)
- Build status (`npm run build` result)
- Visual QA results per page
- Any known gaps or limitations
- The output project path and how to run it (`cd ../<name>-clone && npm run dev`)
