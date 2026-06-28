# 0012. Agent guidance lives in AGENTS.md

- **Status:** Accepted
- **Date:** 2026-06-27

## Context

Project-wide guidance for AI coding agents (the stack notes, the data-derived-UI
rule, the ADR convention, the git workflow, the pointers into `docs/agents/`)
lived in `CLAUDE.md`. That filename is specific to one tool — Claude Code reads
`CLAUDE.md` by name — even though the guidance itself is tool-agnostic and the
`docs/agents/` material it references was already written for "engineering
skills" / "agents" generically.

In practice more than one agent touches this repo: it's edited from Zed (which
reads `AGENTS.md`), Codex and Cursor also follow the `AGENTS.md` convention, and
Claude Code reads `CLAUDE.md`. Keeping the canonical file named for one of them
either privileges that tool or invites a second hand-maintained copy — exactly
the kind of drift the repo's single-source-of-truth rule exists to prevent.

`AGENTS.md` has become the de facto cross-tool convention for this file, read
natively by Zed, Codex, Cursor, and others. Claude Code does not read `AGENTS.md`
automatically, but it follows symlinks, so a `CLAUDE.md` symlink keeps it working
without a duplicate file.

Alternatives considered:
- **Keep `CLAUDE.md` as canonical.** Zero churn, but names the shared file for
  one tool and leaves non-Claude agents to discover it by luck.
- **Two real files (`AGENTS.md` + `CLAUDE.md`), kept in sync by hand.** Re-creates
  the drift problem ADR 0007 and the data-derived-UI rule both push against.
- **`CLAUDE.md` as a one-line stub pointing at `AGENTS.md`.** Works, but a stub is
  still a second file that can rot; a symlink is unambiguously one source.

## Decision

**Make `AGENTS.md` the canonical agent-guidance file, and make `CLAUDE.md` a
symlink to it.**

- `AGENTS.md` holds the guidance, with a tool-agnostic title and intro. It is the
  only file to edit.
- `CLAUDE.md` is a relative symlink (`CLAUDE.md -> AGENTS.md`) so Claude Code
  picks up identical guidance. Editing the symlink target is editing `AGENTS.md`.
- The already-generic `docs/agents/` docs are unchanged.

Existing ADRs that mention `CLAUDE.md` in their bodies are **not** edited —
Accepted ADRs are immutable, and those references are accurate as historical
record. New writing refers to `AGENTS.md`.

## Consequences

**Good:**
- One source of truth for agent guidance, consistent with the repo's
  single-source-of-truth ethos. No hand-synced copies to drift.
- Tool-neutral by default: any agent following the `AGENTS.md` convention gets the
  guidance for free, and Claude Code still works via the symlink.
- Editing is unambiguous — there is exactly one real file to change.

**Bad:**
- Symlinks are a small bit of repo lore. Someone editing `CLAUDE.md` directly is
  really editing `AGENTS.md`; the `AGENTS.md` header calls this out to avoid
  surprise.
- A tool that neither reads `AGENTS.md` nor follows symlinks would miss the
  guidance. None of the agents in use here have that limitation.

**Foreclosed:**
- Nothing hard. Reverting means `git mv AGENTS.md CLAUDE.md` and dropping the
  symlink. This ADR records why the canonical name changed.
