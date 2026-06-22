# 0009. Apex domain migration to semurphy.com

- **Status:** Accepted
- **Date:** 2026-06-20

## Context

The site originally launched on `shanemurphy.space` (ADR 0001 hosting, ADR 0002 domain strategy). In practice the `.space` TLD caused friction: several services (form providers, some email validators, link unfurlers, and account-signup allowlists) treat newer/non-`.com` TLDs as suspicious or reject them outright. A shorter, conventional `.com` avoids this class of papercut.

`semurphy.com` was acquired and the apex was migrated (CNAME + `base_url` already point at it; HTTPS live). This ADR records the decision so the architectural changelog stays coherent — `docs/roadmap.md` and `README.md` now say `semurphy.com`, which would otherwise silently contradict ADRs 0001–0002.

## Decision

The canonical apex domain is **`semurphy.com`**, registered through Squarespace Domains, served by GitHub Pages with the same A records and `www` CNAME (`shaneeverittm.github.io`) documented in `README.md`. `static/CNAME` and `zola.toml`'s `base_url` reflect this.

This **amends the naming** used in ADRs 0001 and 0002; it does **not reverse their decisions**:

- ADR 0001 (GitHub Pages hosting) stands unchanged.
- ADR 0002 (tracker on a subdomain, not a subpath) stands — the subdomain is now `tracker.semurphy.com`.

The old `shanemurphy.space` continues to resolve and redirects to the canonical apex, so existing links don't break.

## Consequences

**Good:**
- Conventional `.com` removes TLD-based rejection from third-party services.
- No structural change: same host, same DNS shape, same deploy pipeline.

**Bad / costs:**
- Two registrations to keep renewed for as long as the `.space` redirect is maintained.
- Any hard-coded `shanemurphy.space` strings (e.g. the contact email `mail@shanemurphy.space` in `zola.toml`) must be migrated deliberately — email in particular depends on where the mailbox actually lives and is intentionally left for a separate decision.

**Foreclosed:**
- Nothing. The redirect preserves the old domain's inbound links indefinitely if desired.
