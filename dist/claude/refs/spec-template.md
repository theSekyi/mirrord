# Component Spec Template

Use this template for every component specification file.

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
- maxWidth: ...
- (every relevant property with exact values)

### <Child element 1>
- fontSize: ...
- color: ...
- (every relevant property)

## States & Behaviors

### <Behavior name, e.g., "Scroll-triggered floating mode">
- **Trigger:** <exact mechanism — scroll position px, IntersectionObserver threshold, click on selector, hover>
- **State A (before):** <property values>
- **State B (after):** <property values>
- **Transition:** <CSS transition>
- **Implementation:** <CSS transition + scroll listener | IntersectionObserver | CSS animation-timeline | etc.>

### Hover states
- **<Element>:** <property>: <before> → <after>, transition: <value>

## Cross-Page Links
- "Learn more" button → routed link to /about
- "View all products" → routed link to /products
- "External partner" → external link

## Per-State Content (if applicable)

### State: "<Tab 1>"
- Title: "..."
- Content: [...]

### State: "<Tab 2>"
- Title: "..."
- Content: [...]

## Assets
- Background: `public/images/<page>/<file>.webp`
- Overlay: `public/images/<page>/<file>.png`
- Icons: <IconName> from icons.tsx

## Text Content (verbatim)
<All text, copy-pasted from the live site>

## Responsive Behavior
- **Desktop (1440px):** <layout description>
- **Tablet (768px):** <what changes>
- **Mobile (390px):** <what changes>
- **Breakpoint:** layout switches at ~<N>px
```

## Pre-Dispatch Checklist

Before dispatching ANY builder, verify ALL boxes:

- [ ] Spec file written with ALL sections filled
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

## What NOT to Do

- **Don't build click-based tabs when the original is scroll-driven.** Determine interaction model FIRST.
- **Don't extract only the default state.** Click every tab, scroll to every trigger.
- **Don't miss overlay/layered images.** Check every container's full DOM tree.
- **Don't approximate CSS classes.** Extract exact computed values.
- **Don't use placeholder links for links to real pages.** Use real routed links.
- **Don't forget mobile navigation.** The hamburger menu must work on every page.
- **Don't skip the route manifest.** Without it, navigation wiring is guesswork.
- **Don't build page components before shared components.** Navbar and Footer must exist first.
- **Don't hardcode the asset download script.** Generate it dynamically from browser asset discovery.
- **Don't put page-specific components in shared/.** Namespace under pages/<route>/.
- **Don't forget per-page metadata.** Every page needs its own title and description.
- **Don't dispatch builders without spec files.**
- **Don't give builders too much scope.** Under 150 lines of spec per agent.
- **Don't skip responsive extraction.** Test at 1440, 768, 390 during extraction.
- **Don't forget smooth scroll libraries.** Check for Lenis, Locomotive Scroll.
