# CLAUDE.md

Project-level guidance for Claude Code working in this repo.

## Stack

Zola static site generator. Content lives in `content/`, templates in `templates/`, styles in `sass/main.scss`, structured data in `data/`. No npm.

The toolchain is pinned by the Nix flake (ADR 0007), and config lives in `zola.toml` (a non-default name), so prefer the flake entrypoints over bare `zola`:

- `nix build` — renders the site into `./result` (the rendered `public/` contents).
- `nix run` (alias `nix run .#serve`) — starts the live-reloading dev server (`zola serve`) at `http://127.0.0.1:1111`.
- `nix develop` — a shell with the pinned Zola on `PATH` for ad-hoc commands (pass `--config zola.toml`).

## Design rules

### Data-derived UI, single source of truth

Any aggregate, summary, count, or breakdown shown in the UI must be **computed by the template** from the underlying records — never stored as a pre-computed sibling field that has to be kept in sync manually.

Hand-tallied summary fields drift the moment the data changes. If a stats panel, totals row, or category breakdown needs to appear, derive it in Tera by iterating the source data (e.g., `data.days[].exercises[]`) and aggregating in-template. External benchmarks (target ranges, thresholds) can still be stored — but the *current state* of the data should always be computed.

If the in-template aggregation gets too gnarly, the next step is a Zola `load_data` shortcode or a build-time preprocessor — not pre-computed fields in the source data.

Reference implementation: `templates/workout-program.html` weekly volume block — each exercise carries `sets_n` and `volume = ["slug", ...]`, and the template sums per muscle group at render time.

### Architectural decisions are recorded as ADRs

Load-bearing design choices are committed as Architecture Decision Records under `docs/adr/`. Don't make a decision that would be confusing or annoying to reverse without writing an ADR for it. See `docs/adr/README.md` for the format and `docs/roadmap.md` for the in-flight roadmap.

When a decision changes, write a new ADR that supersedes the old one — never edit an Accepted ADR in place. The git log of `docs/adr/` is the architectural changelog.
