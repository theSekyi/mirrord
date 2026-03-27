# Output Contract

The generated clone must be a standalone project with no runtime dependency on the installed
skill or plugin bundle.

## Required Project Shape

```text
<site-name>-clone/
  src/
    app/
      layout.tsx
      page.tsx
      <route>/page.tsx
      <route>/[slug]/page.tsx
    components/
      shared/
      pages/
      ui/
      icons.tsx
    data/
    hooks/
    lib/
    types/
  public/
    branding/
    seo/
    images/
      shared/
      <route>/
  docs/
    research/
      SITE_MAP.md
      ROUTE_MANIFEST.json
      SHARED_COMPONENTS.md
      pages/
```

## Required Behaviors

- internal navigation uses real app routes
- shared navigation and footer live in shared layout code
- page content uses real text and locally stored assets
- dynamic route groups are used when repeated templates are confirmed
- the project compiles and builds cleanly

## Required Validation

- `npx tsc --noEmit`
- `npm run build`

## Forbidden Dependencies

- imports from the installed skill bundle
- imports from the plugin bundle
- runtime fetches to the original website for cloned assets
