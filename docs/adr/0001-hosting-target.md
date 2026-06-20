# 0001. Hosting target

- **Status:** Accepted
- **Date:** 2026-05-07

## Context

The existing site is a Zola static site deployed to GitHub Pages via GitHub Actions. Adding a workout tracker introduces two requirements GitHub Pages alone can't satisfy:

- **Authenticated server-side writes.** The tracker logs sessions as JSON files in the repo. The browser can't safely hold a write-scoped GitHub token, so a server-side function (validating the request and performing the commit) is required.
- **Co-located function + static delivery for the tracker SPA.** A small "API" surface (one endpoint) needs to live next to or near the SPA, ideally on the same provider for simplicity.

GitHub Pages is static-only and has no native serverless function story. Three options were weighed:

1. **All-GitHub, with a webhook-triggered GitHub Actions workflow as the "Worker."** Free, single-provider, but cycle time is ~30–60 seconds *per request* (Actions queues, runners spin up). Unacceptable for an interactive tap.
2. **Full migration to Cloudflare Pages.** Site, tracker, Worker all on Cloudflare. One provider, native Worker integration. But the existing site already works on GitHub Pages with DNS, custom domain, and a tested CI pipeline; migration is real cost for marginal gain on the static-content side.
3. **Hybrid.** Site stays on GitHub Pages. Tracker SPA + Worker live on Cloudflare. Two providers, but each does what it's good at, and migration cost is zero.

A subtlety: it would be tempting to have the main site serve `program.json` to the tracker (since both read the same TOML). That makes the static site quietly responsible for being a data source for an external app, coupling two deploys at runtime. The cleaner alternative is for both the site and the tracker to *independently* consume the source TOML at build time — the site renders its workout-program page; the tracker emits its own `program.json` to its own deploy. The TOML is the shared input; the deploys don't talk to each other.

## Decision

**Hybrid hosting (option 3), with each deploy self-contained:**

- **Main site** — GitHub Pages, status quo. Zola, deployed via GitHub Actions. Zero API responsibilities. Pure content.
- **Tracker SPA** — Cloudflare Pages, separate deploy. Vite/React/TS bundle, reads `data/workout_program.toml` at build time and emits its own `program.json` to its `dist/`. SPA fetches `program.json` from same-origin at runtime.
- **Worker** — Cloudflare Workers, paired with the tracker. Single endpoint accepting authenticated session POST; performs the git commit via the GitHub API.
- **Repo as the database.** Both deploys read the same monorepo's TOML at build time. The Worker is the only writer. All reads are static (CDN-served).

## Consequences

**Good:**
- The static site keeps doing what it's good at, with no migration cost.
- The tracker gets the right tool (Workers) for its single dynamic responsibility, on the same provider as its SPA — clean operational unit.
- No "site as backend" anti-pattern. Each deploy is self-contained; the TOML is the only shared coupling, resolved at build time.
- All free-tier. Cloudflare Workers free tier (100k req/day) and Pages free tier are far beyond a single-user load.
- Portability: if Cloudflare's terms ever change, the Worker is small and the SPA is portable. The main site is unaffected.

**Bad:**
- Two providers (GitHub + Cloudflare) to manage credentials, billing settings, and DNS records on. Mitigated by the fact that each provider hosts a self-contained piece.
- Two CI pipelines — one per host. Negligible operational burden but worth acknowledging.
- The TOML being read by two independent build pipelines means a program edit triggers two rebuilds. Both are fast (~60s) and parallel; the user experiences this as "edit, push, both are live in about a minute."

**Foreclosed:**
- Tightly-coupled SSR-style architectures where the main site dynamically serves data to the tracker. (Intentional — keeps the site pure.)
- Single-provider operational simplicity. (Considered but rejected; the migration cost outweighs the simplification for this scope.)
