# Guiding Principles

These separate a successful multi-page clone from a "close enough" mess.

## 1. Completeness Beats Speed

Every builder must receive **everything** it needs: screenshot, exact CSS values, downloaded assets with local paths, real text content, component structure. If a builder has to guess anything — a color, a font size, a padding value — extraction has failed.

## 2. Small Tasks, Perfect Results

When a builder gets "build the entire features section," it glosses over details. When it gets a single focused component with exact CSS values, it nails it every time. **Complexity budget rule:** If a builder prompt exceeds ~150 lines of spec content, break it into smaller pieces.

## 3. Real Content, Real Assets

Extract actual text, images, videos, and SVGs from the live site. This is a clone, not a mockup. **Layered assets matter** — a section that looks like one image is often multiple layers (background, foreground, overlay). Inspect each container's full DOM tree.

## 4. Foundation First

Nothing can be built until the foundation exists: design tokens, fonts, shared layout, route scaffolding. This is sequential and non-negotiable. Everything after can be parallel.

## 5. Extract Appearance AND Behavior

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

## 6. Identify the Interaction Model Before Building

The single most expensive mistake: building a click-based UI when the original is scroll-driven. Before building any interactive section, definitively answer: **Is this section driven by clicks, scrolls, hovers, time, or some combination?**

1. **Don't click first.** Scroll through the section slowly and observe.
2. If things change on scroll, it's scroll-driven. Extract the mechanism.
3. If nothing changes on scroll, THEN test for click/hover-driven interactivity.
4. Document the interaction model explicitly in the component spec.

## 7. Extract Every State, Not Just the Default

Many components have multiple visual states. Extract ALL states.

For tabbed/stateful content:
- Click each tab/button
- Extract content, images, and data for EACH state
- Record the transition animation between states

For scroll-dependent elements:
- Capture computed styles at scroll position 0
- Scroll past trigger, capture again
- Diff to identify exactly which CSS properties change
- Record transition CSS and trigger threshold

## 8. Spec Files Are the Source of Truth

Every component gets a specification file BEFORE any builder is dispatched. The spec file is the contract between extraction and building. Builders receive spec contents inline — no external references.

## 9. Build Must Always Compile

Every builder verifies `npx tsc --noEmit` before finishing. After merges: `npm run build`. A broken build is never acceptable.

## 10. Every Page, Every Link

Every internal `<a href>` becomes a real routed link. Every discovered page gets a real route. The navbar shows which page is active. The user can browse the clone just like the original site.

## 11. Visual Check Per Section, Not Per Page

After building and merging each section, immediately render it in the browser and compare against the original. Do NOT wait until the end for visual QA. Extracted CSS can be technically correct but visually wrong — a class like `min-h-screen` might create dead space in the clone even though the original uses the same class. The only way to catch this is to look at the rendered output. Catching layout issues per-section is a 10-second fix; catching them at the end is a debugging session.
