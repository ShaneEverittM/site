# Architecture Decision Records

This directory holds the load-bearing design decisions for the project. Each decision is one numbered markdown file. The history of these files is the project's architectural memory — readable by Shane, by AI agents in future sessions, and by anyone else who needs to understand _why_ something is the way it is.

## Convention

- **Format:** Nygard-style. Five sections: **Title · Status · Context · Decision · Consequences**.
- **Length:** One page or less. ADRs are decision artifacts, not design documents.
- **Numbering:** Zero-padded sequential — `0001-...`, `0002-...`. Never reused.
- **File name:** `NNNN-short-kebab-slug.md`, e.g. `0001-hosting-target.md`.
- **Status lifecycle:** `Proposed` → `Accepted` → (later, if revised) `Superseded by NNNN`. Once an ADR is `Accepted`, its content does not change. Decisions evolve by writing a _new_ ADR that supersedes the old one. The old ADR's status changes to `Superseded by NNNN` and gains a one-line note pointing forward; otherwise it stays as it was. The git log of `docs/adr/` is the architectural changelog.
- **Scope:** Write an ADR for any decision that would be confusing or annoying to reverse, or where the _next_ person (including future Shane) would benefit from knowing why this path was chosen over the alternatives. Skip for trivial choices.

## Template

A starter template is at `0000-template.md`. Copy it, renumber, fill it in.

## Index

| #                                         | Title                                          | Status   |
| ----------------------------------------- | ---------------------------------------------- | -------- |
| 0000                                      | Template                                       | n/a      |
| [0001](0001-hosting-target.md)            | Hosting target                                 | Accepted |
| [0002](0002-domain-strategy.md)           | Domain strategy                                | Accepted |
| [0003](0003-auth-model.md)                | Auth model for the tracker write path          | Accepted |
| [0004](0004-ci-rebuild-filtering.md)      | CI rebuild filtering for session-only commits  | Accepted |
| [0005](0005-progression-rule-encoding.md) | Encoding progression rules in the program TOML | Accepted |
| [0006](0006-session-json-schema.md)       | Session JSON schema                            | Accepted |
| [0007](0007-nix-build-tooling.md)         | Nix flake as the build toolchain               | Accepted |
| [0008](0008-theming-and-dark-mode.md)     | Theming and dark mode                          | Accepted |
| [0009](0009-apex-domain-migration.md)     | Apex domain migration to semurphy.com          | Accepted |
| [0012](0012-agent-guidance-file.md)       | Agent guidance lives in AGENTS.md              | Accepted |
