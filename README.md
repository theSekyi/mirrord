# mirrord

Clone any website — all pages, real navigation, pixel-perfect.

## Install

### Claude Code

```
/plugin install github:theSekyi/mirrord --path dist/claude
```

Requires Chrome MCP. Enable it once with `/chrome` in Claude Code.

### Codex

```bash
git clone https://github.com/theSekyi/mirrord.git
cp -r mirrord/dist/codex/clone-site ~/.codex/skills/clone-site
```

Requires a browser automation backend.

## Use

```
/clone-site https://example.com
```

This will:
1. Create `example-com-clone/` in your current directory
2. Crawl all public pages (max 50, depth 3)
3. Extract shared Navbar/Footer and design tokens
4. Build every page with real Next.js App Router routes
5. Wire navigation with real links — no `href="#"`

## What You Get

A standalone Next.js 16 project. Run it with:

```bash
cd example-com-clone
npm run dev
```

## Requirements

- Node.js 18+
- Git
- Browser automation (Chrome MCP for Claude, browser backend for Codex)

---

## For Contributors

The repo has three layers:

- `core/` — shared scaffold, extraction scripts, spec templates (agent-agnostic)
- `adapters/claude/` and `adapters/codex/` — platform-specific skill files
- `dist/` — generated install bundles (built by `./packaging/build-bundles.sh`)

Do not install the repo root into either product. Only `dist/claude/` and `dist/codex/clone-site/` are runtime artifacts.

## License

MIT
