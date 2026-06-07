# 0007. Nix flake as the build toolchain

- **Status:** Accepted
- **Date:** 2026-06-06

## Context

The site is built with Zola, a single static binary. Until now the toolchain lived in two unrelated places:

- **Locally**, Zola was installed via Homebrew (`/opt/homebrew/bin/zola`, currently 0.22.1).
- **In CI**, `deploy.yml` installed Zola with `taiki-e/install-action`, pinned to `zola@0.22.1`.

Two pins for the same tool, kept in sync by hand. They agree today; nothing enforces it. A `brew upgrade` bumps the local version silently, and the CI pin only changes when someone remembers to edit the workflow. For a static site this rarely bites, but the project is heading toward a tracker SPA (see `docs/roadmap.md`) with its own toolchain (Vite, a Cloudflare Worker), where reproducibility matters more and "works on my machine" failures get expensive.

Determinate Nix is now installed on the dev machine, which makes a flake the natural single source of truth: one pinned toolchain that the local shell, local builds, and CI all draw from.

Alternatives considered:
- **Status quo (Homebrew + `taiki-e` pin).** Zero new concepts, but keeps the two-pin drift problem.
- **Devbox / mise / asdf.** Lighter than Nix, but another tool to install everywhere and weaker reproducibility guarantees than a locked flake.
- **Docker dev image.** Heavier, slower inner loop, and overkill for a single static binary.

## Decision

**Adopt a Nix flake (`flake.nix` + `flake.lock`) as the canonical build toolchain, and drive CI from it.**

The flake exposes three outputs, all sharing one `pkgs.zola`:

- `packages.default` — renders the site into `$out` (the `public/` tree). Because the config file is `zola.toml` rather than the default `config.toml`, every invocation passes `--config zola.toml`.
- `devShells.default` — `nix develop` drops into a shell with that same Zola on `PATH`.
- `apps.serve` (the default app) — `nix run` runs `zola serve` for live-reload local development.

`flake.lock` pins `nixpkgs` (currently the `nixos-unstable` revision shipping Zola 0.22.1, matching the previous CI pin). The Zola version now changes only by `nix flake update` plus a committed lockfile bump — one place, reviewable in a diff.

CI switches from `taiki-e/install-action` to `DeterminateSystems/determinate-nix-action` + `nix build`. The build output is a store symlink, so the workflow dereferences it (`cp -rL result public`) before handing it to `upload-pages-artifact`.

## Consequences

**Good:**
- One pinned toolchain for local dev and CI. No more hand-synced version pins; drift is structurally impossible.
- Reproducible builds: the lockfile makes "the bytes CI produces" a function of committed state, not of whatever Homebrew last installed.
- A natural home for future tooling. When the tracker SPA arrives, its Node/Bun/Worker tools join the same flake, and `nix develop` becomes the one onboarding command.

**Bad:**
- Requires Nix to use the canonical build path. Anyone without Nix can still run a Homebrew/`cargo install` Zola directly, but they're then off the pinned toolchain.
- CI cold builds pay a Nix install + store fetch (~tens of seconds) that the lightweight `taiki-e` action avoided. Acceptable for a once-per-push Pages deploy; revisit with a Nix cache (e.g. Magic Nix Cache / Cachix) if it becomes annoying.
- Adds Nix as a concept to the repo. Mitigated by keeping `flake.nix` small and commented.

**Foreclosed:**
- Nothing hard. The flake is additive; reverting means restoring the `taiki-e` step and deleting two files. This ADR documents the rationale so a future reverter knows what they'd be giving up.
