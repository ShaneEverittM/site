# Workout Tracker — Roadmap

Living document. Updated as phases complete or assumptions change. The original planning artifact is in
`.claude/plans/`; this is the durable record committed to the repo.

## Context

The site is a Zola SSG at shanemurphy.space (GitHub Pages, GitHub Actions deploy). It includes a workout program in
`data/workout_program.toml` with auto-derived volume targets per muscle group.

The goal is a workout tracker that:

- **Solves progressive overload** — shows today's prescribed weight (per program rules), takes a "did the set" tap,
  increments next session's target.
- **Treats the program as mutable** — Shane revises it frequently with AI assistance, so the program file stays plain
  text in git.
- **Treats logs as owned data** — sessions live in the same repo as JSON files, in a format both Claude and Shane can
  read.
- **Stays on free hosting.**
- **Lives in the same monorepo as the static site.**

This roadmap enumerates the discrete plans, decisions, and implementations needed. Each phase below will get its own
dedicated plan when it's reached.

---

## Project documentation strategy

Design rationale persists in the repo, not in per-user/per-session scratch files. Future Claude sessions, future Shane,
and anyone else reading should be able to understand *why* the architecture is what it is from `git log` alone.

Two artifacts are committed:

1. **This roadmap** at `docs/roadmap.md`. Living document — every phase completion updates it (mark phase done, add
   lessons learned, revise downstream phases).
2. **Architecture Decision Records (ADRs)** at `docs/adr/`. Every meaningful design decision gets a short, numbered ADR.
   See `docs/adr/README.md` for the format and convention.

The principle: **single source of truth, in the repo, AI-readable** — extending the same rule CLAUDE.md captured for UI
data to design rationale.

---

## Cross-cutting open decisions (Phase 0)

These touch every later phase, so resolving them first is load-bearing. Each will be settled with an ADR.

1. **Hosting target.** Currently on GitHub Pages. The tracker write path needs a serverless function that can commit to
   the repo via the GitHub API.
2. **Domain strategy.** Subdomain (`tracker.shanemurphy.space`) vs subpath (`/tracker`).
3. **Auth between phone and Worker.** Single-user shared secret vs OAuth-with-GitHub vs nothing-but-obscurity.
4. **CI rebuild filtering.** Whether session-only commits should skip the tracker SPA rebuild.
5. **Structured progression rules in TOML.** Whether to encode `progression = { kind, increment, cadence, deload }` now
   or defer.

---

## Phases

Each phase ends in a commit. Each will get its own plan when it starts.

### Phase 0 — Decisions & schema preparation

**Goal:** Resolve the cross-cutting decisions above and prep the TOML so the tracker can consume it cleanly.

**Plans/work:**

- Decide hosting model (cross-cutting #1) → ADR 0001.
- Decide domain strategy (cross-cutting #2) → ADR 0002.
- Decide auth model (cross-cutting #3) → ADR 0003.
- Decide CI rebuild filtering (cross-cutting #4) → ADR 0004.
- Decide structured-progression-now-or-later (cross-cutting #5) → ADR 0005.
- Add stable `id = "barbell_bench"`-style fields to every exercise in `data/workout_program.toml`.
- Encode structured `progression = { ... }` metadata on linearly-progressing exercises (Squat, Bench, OHP, Deadlift,
  Row).
- Define the JSON shape for emitted program data (`program.json`) and session logs (`sessions/<date>.json`).

**Deliverable:**

- Updated `workout_program.toml` with `id` + `progression` per exercise.
- ADRs 0001–0005 committed to `docs/adr/`.
- This roadmap committed to `docs/roadmap.md`.
- CLAUDE.md updated to reference the ADR convention.
- No tracker code yet.

**Ready when:** All five cross-cutting decisions have an Accepted ADR; TOML has stable IDs; session JSON shape is
sketched; `docs/roadmap.md` and `docs/adr/` exist in the repo.

---

### Phase 1 — Build pipeline & data exposure

**Goal:** Make the program (and later, sessions) available to a runtime fetcher at a stable URL on the deployed site,
without bundling them into a SPA build.

**Plans/work:**

- Add a Zola build step that emits `static/program.json` from the TOML on each build.
- Decide where session JSON lives: `data/sessions/*.json` (Zola consumes & passes through) vs `static/sessions/*.json` (
  untouched passthrough).
- Update `deploy.yml` if needed; add CI path filter so session-only commits skip SPA rebuilds (relevant once Phase 2
  adds one).
- Verify program.json is fetchable from a deployed page.

**Deliverable:** A live URL like `shanemurphy.space/program.json` that returns the compiled program.

**Ready when:** `curl https://shanemurphy.space/program.json` returns valid JSON matching the schema agreed in Phase 0.

---

### Phase 2 — Tracker SPA scaffold

**Goal:** A deployable Vite + React + TS app at the chosen URL, reading the program and rendering "Today" with no
logging behavior yet.

**Plans/work:**

- Decide monorepo layout: `tracker/` directory alongside Zola's `content/`, `templates/`, etc.
- Initialize Vite + React + TypeScript in `tracker/`.
- Routing (React Router or TanStack Router): Today / History / Settings.
- Today screen: fetch `program.json`, identify today's day-of-week, render the prescribed exercises read-only.
- Add CI to build and deploy the tracker SPA to the chosen URL.
- Cross-link from the main site's workout-program page.

**Deliverable:** A deployed tracker URL that renders today's program in a phone-friendly layout. No state, no checkboxes
yet.

**Ready when:** On a phone in the gym, you can open the URL and read what to do today.

---

### Phase 3 — Tracker v1 (offline-only logging)

**Goal:** The actual app — checkbox UX, progressive overload calculation, local session history. localStorage
persistence only; no sync yet.

**Plans/work:**

- "Did the set" UX: per-exercise checkbox with current target weight rendered prominently. One-tap completion. Optional
  weight override field.
- Progression engine: read `progression` rule from program, look up last completed session for that exercise ID, compute
  today's target weight. Handle deload after N consecutive incomplete sessions.
- localStorage schema mirroring the future session JSON shape, so Phase 4 sync is a serialization swap, not a rewrite.
- "End session" flow: mark complete, update progression state.
- History view: list past sessions, basic table.
- PWA manifest + install prompt. Service worker for shell caching only (defer offline-first reads to Phase 6 if it's a
  lift).

**Deliverable:** A functional tracker on the phone. Loses data if browser storage is cleared. Sufficient for a 2-week
trial.

**Ready when:** Used in the gym for 1–2 weeks with feedback on in-gym UX.

---

### Phase 4 — Sync (Worker + repo writes)

**Goal:** Sessions persist durably as JSON files in the repo. Multi-device read works.

**Plans/work:**

- Cloudflare Worker (or chosen alternative) accepting authenticated session POST and committing to the repo via GitHub
  API.
- Auth: Bearer token in tracker localStorage, validated against a Worker secret. Single-user model.
- Tracker sync flow: localStorage immediate write on "End session," POST in background, retry on failure. UI shows sync
  status.
- Tracker reads sessions from `/sessions/*.json` (or an index file) on launch, reconciles with localStorage.
- CI path filter so session-only commits skip the SPA rebuild.
- Backfill: import any sessions logged in Phase 3 from localStorage on first sync.

**Deliverable:** Logging on phone → JSON file in repo within ~60s. History queryable from any device.

**Ready when:** A session logged on phone is visible in `git log` and renders correctly on a second device after
refresh.

---

### Phase 5 — Research-mode loop

**Goal:** Close the cycle that motivates this whole project: log → review → revise program with AI assistance.

**Plans/work:**

- Document the workflow in `docs/program-iteration.md`.
- Optional: a small "stats" view in the tracker (or a static page on the main site) summarizing adherence and trend per
  lift.
- Optional: a `scripts/analyze.ts` (Bun) that emits a markdown summary of the last N weeks for paste-into-conversation.

**Deliverable:** A documented, repeatable loop where every 4–8 weeks Shane asks Claude to review and propose program
changes; Shane commits; tracker picks up the new program; history continues seamlessly via stable IDs.

**Ready when:** One full review cycle has happened end-to-end and the program has been updated based on logged data.

---

### Phase 6 — PWA polish (deferred until needed)

**Goal:** Make it gym-grade — installable, offline-resilient, fast on a mid-tier phone.

**Plans/work:**

- Service worker offline-first reads.
- Install prompt UX, app icon, splash screen.
- Performance pass: bundle size, time-to-interactive on phone, tap responsiveness.
- Robust error handling for sync failures.

**Deliverable:** App-quality experience indistinguishable from a native gym app.

**Ready when:** A workout in airplane mode syncs cleanly on reconnect with no data loss.

---

## What this roadmap is NOT

- Not a commitment to all phases. Phases 5 and 6 may turn out unnecessary; re-evaluate after Phase 4.
- Not a fixed timeline. Each phase is planned and executed when ready.
- Not a substitute for per-phase plans.

## Critical files (current state)

- `data/workout_program.toml` — the program. Will gain `id` and `progression` fields in Phase 0.
- `templates/workout-program.html` — already consumes the TOML at build time.
- `.github/workflows/deploy.yml` — will gain steps in Phases 1, 2, 4.
- `CLAUDE.md` — records project-wide rules. Will gain the ADR convention in Phase 0.
- `docs/roadmap.md` (this file) — committed roadmap, revised as phases complete.
- `docs/adr/000N-*.md` — one ADR per architectural decision.
- (Future) `tracker/` — the SPA, scaffolded in Phase 2.
- (Future) `data/sessions/*.json` (or `static/sessions/*.json`) — log files, written by the Worker in Phase 4.

## Verification approach

Each phase has its own "Ready when" criterion above. The overall verification is a 4-week real-world trial: log every
gym session, review logs with Claude, revise the program once, see continuity preserved.
