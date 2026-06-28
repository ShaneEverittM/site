# AGENTS.md

Project-level guidance for AI coding agents working in this repo. This is the
tool-agnostic source of truth, read natively by agents that support the
`AGENTS.md` convention (Zed, Codex, Cursor, and others). `CLAUDE.md` is a symlink
to this file so Claude Code picks up the same guidance — edit `AGENTS.md`, never
the symlink. See ADR 0012 for the rationale.

## Stack

Zola static site generator. Content lives in `content/`, templates in `templates/`, styles in `sass/main.scss`, structured data in `data/`. No npm.

The toolchain is pinned by the Nix flake (ADR 0007), and config lives in `zola.toml` (a non-default name), so prefer the flake entrypoints over bare `zola`:

- `nix build` — renders the site into `./result` (the rendered `public/` contents).
- `nix run` (alias `nix run .#serve`) — starts the live-reloading dev server (`zola serve`) at `http://127.0.0.1:1111`.
- `nix develop` — a shell with the pinned Zola on `PATH` for ad-hoc commands (pass `--config zola.toml`).

## Design rules

### Data-derived UI, single source of truth

Any aggregate, summary, count, or breakdown shown in the UI must be **computed by the template** from the underlying records — never stored as a pre-computed sibling field that has to be kept in sync manually.

Hand-tallied summary fields drift the moment the data changes. If a stats panel, totals row, or category breakdown needs to appear, derive it in Tera by iterating the source data (e.g., `data.days[].exercises[]`) and aggregating in-template. External benchmarks (target ranges, thresholds) can still be stored — but the _current state_ of the data should always be computed.

If the in-template aggregation gets too gnarly, the next step is a Zola `load_data` shortcode or a build-time preprocessor — not pre-computed fields in the source data.

Reference implementation: `templates/workout-program.html` weekly volume block — each exercise carries `sets_n` and `volume = ["slug", ...]`, and the template sums per muscle group at render time.

### Architectural decisions are recorded as ADRs

Load-bearing design choices are committed as Architecture Decision Records under `docs/adr/`. Don't make a decision that would be confusing or annoying to reverse without writing an ADR for it. See `docs/adr/README.md` for the format and `docs/roadmap.md` for the in-flight roadmap.

When a decision changes, write a new ADR that supersedes the old one — never edit an Accepted ADR in place. The git log of `docs/adr/` is the architectural changelog.

## Git workflow

Merge-based, **never force-push**. The history is a truthful record of what happened — don't rewrite it.

- Integrate branches with `git merge` (let it make a merge commit when branches have diverged; don't fast-forward the topology away).
- Keep a feature branch current by **merging `main` in**, not by rebasing onto it. After a PR lands, merge `main` back into any still-open sibling branches.
- Never `git push --force` / `--force-with-lease`, and don't `git rebase` shared branches.

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues via the `gh` CLI. External PRs are _not_ a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
