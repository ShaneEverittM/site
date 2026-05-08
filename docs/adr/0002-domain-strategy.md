# 0002. Domain strategy

- **Status:** Accepted
- **Date:** 2026-05-07

## Context

The tracker needs a URL. Two patterns:

- **Subpath** — `shanemurphy.space/tracker`. SEO-friendly (one domain), single set of cookies. Requires either path-based routing on a single host or a reverse proxy in front. Both contradict the hybrid hosting model (ADR 0001), which has the site and the tracker on different providers (GitHub Pages and Cloudflare Pages). Making subpath work would essentially force collapsing the two deploys back to one provider, undoing ADR 0001's reasoning.
- **Subdomain** — `tracker.shanemurphy.space`. Independent DNS, independent deploy, standard pattern for multi-app domains. No reverse proxy. Clean separation between the static site and the app. Trivial to set up (CNAME the subdomain to Cloudflare Pages).

For a single-user personal tracker, SEO consolidation is a non-goal. Cookie scope and shared-auth concerns don't apply (auth is a Bearer token in localStorage; cookies aren't load-bearing).

The subdomain name itself: `tracker.` is descriptive, brief, and unambiguous. Alternatives considered (`gym.`, `lift.`, `app.`) trade descriptiveness for brevity or playfulness; not a meaningful improvement.

## Decision

The tracker lives at **`tracker.shanemurphy.space`**, served by Cloudflare Pages. The main site stays at the apex (and `www.`) on GitHub Pages.

DNS: a CNAME record for `tracker` pointed at the Cloudflare Pages target, set in the Squarespace DNS panel where the rest of the domain's records live.

## Consequences

**Good:**
- Falls out of ADR 0001 cleanly — each deploy owns its origin, no path-based plumbing required.
- Independent deploys, independent CI failures, independent caching layers. Either side can break without taking the other down.
- Easy to add more apps later under sibling subdomains (`projectN.shanemurphy.space`) without touching the main site.

**Bad:**
- Three DNS records to maintain (apex, `www.`, `tracker.`) instead of one.
- Cross-link from the site's workout-program page to the tracker is a bare `https://tracker.shanemurphy.space` link — no chance of accidental in-app navigation between site and tracker. (Arguably a feature: the tracker is a different mode of use.)

**Foreclosed:**
- Anything that relies on the site and tracker sharing cookies or session state automatically. Not relevant here.
