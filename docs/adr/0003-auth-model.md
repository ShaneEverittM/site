# 0003. Auth model for the tracker write path

- **Status:** Accepted
- **Date:** 2026-05-07

## Context

The tracker SPA needs to authenticate to the Worker, which performs the actual `git commit` against the repo via a GitHub PAT held server-side. Two distinct credentials are at play:

1. A **GitHub PAT** (fine-grained, scoped to this repo + Contents read/write) lives as a Cloudflare Worker secret. This is what does the commit. It is never exposed to the browser.
2. A **tracker auth token** that the SPA presents to the Worker, proving "this request is from Shane."

This ADR is about #2.

Options weighed:

- **Shared secret (Bearer token).** Worker holds a long random `TRACKER_TOKEN` in its env. Tracker SPA stores the same value in localStorage. Every Worker request carries `Authorization: Bearer <TRACKER_TOKEN>`; Worker compares constant-time.
- **OAuth with GitHub.** SPA does the GitHub OAuth dance, gets an access token, Worker validates. Standard, well-understood, but introduces callback handling, token storage, refresh, and an entire identity flow for a single-user app. The Worker still uses its own PAT to commit (the user's GitHub token wouldn't have scoped repo write where it needs it without further configuration). Net: extra ceremony with no real gain.
- **WebAuthn / passkey.** Modern and biometric-friendly, but overkill for a personal tool.
- **No auth (URL obscurity).** Unacceptable; the Worker writes to the repo.
- **Static token + IP allowlist.** Brittle on cellular and on the road.

For a single user, the simplest credential that adequately protects a low-blast-radius write surface is a shared secret. The Worker's blast radius is *already* tightly scoped — it accepts only `POST /sessions`, validates the JSON shape, and writes to a fixed path in one repo. A leaked tracker token gives an attacker the ability to commit garbage session JSON; not a serious harm, easy to revoke (rotate the Worker env).

## Decision

**Single-user shared secret, Bearer-token style.**

- A long random `TRACKER_TOKEN` (≥32 bytes hex) is held as a Cloudflare Worker secret.
- The same value is stored in tracker localStorage. A Settings screen in the SPA lets the user paste/replace it.
- Every Worker request requires `Authorization: Bearer <TRACKER_TOKEN>`. The Worker performs a constant-time comparison.
- The Worker's endpoints are narrow by construction: a single `POST /sessions` accepting validated JSON, writing to a fixed path in a fixed repo via the GitHub PAT. No general "execute commit" surface.
- Token rotation: regenerate the value, update the Worker secret, refresh localStorage on next tracker visit. Not automated; this is a manual operation done rarely.

## Consequences

**Good:**
- Trivial to implement on both sides. Single env var on the Worker; single localStorage key on the SPA.
- No third-party auth dependency. No OAuth callbacks, no flow handling.
- Token persists in localStorage indefinitely; no re-auth friction in normal use.
- Constant-time comparison prevents timing-based extraction.

**Bad:**
- Static long-lived token. If localStorage is exfiltrated (e.g., XSS in the tracker SPA), the token leaks. Mitigated by:
  - The Worker accepts only narrow operations (one endpoint, validated payloads, fixed write path).
  - The PAT held server-side has fine-grained scope (this repo, contents only).
  - Rotation is manual but easy.
- Manual rotation is a vigilance tax. Acceptable for personal use; the rotation cadence can be "when something feels off" rather than scheduled.

**Foreclosed:**
- Multi-user. If the tracker ever needs to support more than one person, this ADR is superseded by an OAuth-based one.
- Per-device tokens. Possible to issue distinct tokens per device by storing a list in the Worker, but unnecessary at one user.
