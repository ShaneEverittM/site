# 0008. Theming and dark mode

- **Status:** Accepted
- **Date:** 2026-06-20

## Context

The site shipped with a single light palette ("Birch & Cream") defined once in `sass/_palette.scss` and exposed to every component as `--color-*` custom properties. No dark mode existed.

Adding a dark mode raises three questions:

1. **How is a palette represented?** The CSS-custom-property indirection already in place means a theme is nothing more than a re-binding of the six `--color-*` tokens. No component CSS needs to change. This is the single-source-of-truth principle from CLAUDE.md applied to color.
2. **How does a visitor select a theme, and does an OS preference participate?** Options: manual toggle only; OS preference only (`prefers-color-scheme`); or both, with manual choice overriding the OS default.
3. **How is a flash of the wrong palette on load avoided?** A purely CSS/`prefers-color-scheme` solution flashes nothing, but a stored manual choice that contradicts the OS will flash unless applied before first paint.

A dark palette was chosen by comparing three candidates in-browser ("Espresso" warm, "Slate" cool-neutral, "Ink" near-black). Slate was selected.

## Decision

**Palette = token re-binding.** Light stays the `:root` default. The dark palette ("Slate") is defined once as a Sass mixin (`slate-tokens`) and applied in two places: under `[data-theme="dark"]` (explicit choice) and under `:root:not([data-theme="light"])` inside a `@media (prefers-color-scheme: dark)` block (OS default). `color-scheme` is set alongside so native form controls and scrollbars match.

**Resolution order:** explicit `[data-theme]` (set by the toggle) → OS `prefers-color-scheme` → light. A stored `"light"` choice opts back out of the OS default via the `:not([data-theme="light"])` guard.

**Persistence and no-flash:** the chosen theme is stored in `localStorage` under `theme`. A tiny inline script in `<head>` applies an explicit stored choice to `<html>` before first paint. With no stored choice, nothing is applied and CSS `prefers-color-scheme` governs — so first-time visitors get their OS preference with zero flash. A second script wires the nav toggle button and keeps its label in sync when the OS preference changes and no explicit choice is set.

Rejected: OS-preference-only (no way to override per-device); manual-only (ignores a preference the visitor already expressed at the OS level); a build-time or server-rendered theme (static host, no per-request state).

## Consequences

**Good:**
- Adding or swapping a palette is editing six values in one mixin; no component CSS changes.
- First-time visitors get their OS preference automatically; returning visitors get their explicit choice; neither flashes.
- The only JavaScript on the site is two small inline scripts — no framework, no build step, consistent with the no-npm constraint.

**Bad / costs:**
- Two inline scripts in `base.html` are now load-bearing for correct first-paint behavior. They must stay inline (an external file would defeat the no-flash goal).
- Syntax highlighting is baked in at build time via `zola.toml`'s `catppuccin-latte` (a light theme). In dark mode, highlighted code blocks look out of place. Fixing this requires switching Zola to CSS-class highlighting and shipping per-theme highlight CSS — deferred until a writing post with code actually needs it.

**Foreclosed:**
- A third user-selectable theme would reintroduce the cycle-style toggle the evaluation phase used; the current toggle is deliberately binary.
