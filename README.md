# mirrord

Clone any website — all pages, real navigation, pixel-perfect.

A Claude Code plugin that reverse-engineers websites and rebuilds them as fully navigable Next.js clones.

## Install

```
/plugin install github:theSekyi/mirrord
```

## Usage

```
/clone-site https://example.com
```

mirrord will:
1. Create `example-com-clone/` in your current directory
2. Crawl all public pages (max 50, depth 3)
3. Extract shared components (Navbar, Footer) and design tokens
4. Build every page with real App Router routes
5. Wire all navigation with `next/link`
6. Run visual QA on each page

## Requirements

- [Claude Code](https://claude.ai/code) with Chrome MCP enabled
- Node.js 18+
- Git

## What You Get

A self-contained Next.js 16 project with:
- Every public page cloned with pixel-perfect fidelity
- Real routing — click any nav link and it navigates
- Active route indicators in the navbar
- Mobile-responsive navigation (hamburger menu)
- All assets downloaded (images, videos, fonts, favicons)
- Component specs as auditable artifacts

## Output Structure

```
example-com-clone/
  src/app/
    layout.tsx          # Shared Navbar + Footer
    page.tsx            # Homepage
    about/page.tsx      # /about
    blog/page.tsx       # /blog
    blog/[slug]/page.tsx # Dynamic blog posts
  src/components/
    shared/             # Navbar, Footer, MobileNav
    pages/home/         # Homepage sections
    pages/about/        # About page sections
  public/images/        # Downloaded assets
  docs/research/        # Extraction artifacts
```

## Tech Stack (Output)

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Language | TypeScript (strict) |
| UI | React 19 + shadcn/ui |
| Styling | Tailwind CSS v4 |
| Deployment | Vercel-ready |

## License

MIT
