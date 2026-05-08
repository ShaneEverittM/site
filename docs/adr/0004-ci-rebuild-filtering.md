# 0004. CI rebuild filtering for session-only commits

- **Status:** Accepted
- **Date:** 2026-05-07

## Context

Once Phase 4 lands, every gym session results in a commit to the repo (a new `data/sessions/<date>.json` written by the Worker). On a typical training week, that's 4–5 commits — a few hundred per year.

Two CI pipelines watch the repo:

- **GitHub Actions** rebuilds the Zola site on every push to `main`. The site's workout-program page reads `data/workout_program.toml` but currently does not surface session data. So a session-only commit produces a byte-identical site.
- **Cloudflare Pages** (Phase 2 onward) rebuilds the tracker SPA on every push to `main`. The SPA reads its own input (the TOML at build time, plus runtime fetches of session JSON). A session-only commit doesn't change the SPA bundle either.

Without filtering, every session commit triggers two rebuilds that produce no visible change — pure waste, and slow cache invalidation on the CDN side. With filtering, both pipelines skip when the change is "session JSON only."

The filtering mechanisms differ:

- GitHub Actions supports `paths-ignore` and `paths` filters on the workflow `on:` trigger.
- Cloudflare Pages supports `[skip ci]` in commit messages and a build-watching path config.

## Decision

**Filter both pipelines so session-only commits do not rebuild.**

- The site workflow uses `paths-ignore: ['data/sessions/**']` on the `push` trigger, so commits touching only those files don't run the build.
- The tracker Pages project is configured to skip builds when no monitored paths change. As an additional safety net, the Worker writes session commits with `[skip ci]` in the commit message — Cloudflare Pages honors that convention.

A future ADR will supersede this one if/when the site or tracker grows a feature that *does* depend on session data being visible (e.g., a "last logged" indicator on the workout-program page). At that point, filtering needs to be revisited.

## Consequences

**Good:**
- ~30 fewer site builds and ~30 fewer SPA builds per month, all of which would have been no-ops.
- Faster perceived sync from a logged session: the Worker commit lands; nothing else needs to happen.
- CDN cache stays warm; user-facing TTFB is unaffected by background logging activity.

**Bad:**
- Adds a "what changed?" question every time the site or tracker behavior depends on something. Future ADR-superseding-this-one needs a clear trigger condition so the filter doesn't silently drop a needed rebuild.
- The skip-condition lives in two places (workflow file and Pages config). Keep them in sync.

**Foreclosed:**
- Site features that read session JSON at build time. Possible later, but requires this ADR to be superseded.
