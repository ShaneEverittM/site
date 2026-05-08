# 0005. Encoding progression rules in the program TOML

- **Status:** Accepted
- **Date:** 2026-05-07

## Context

The program TOML currently encodes progression rules as free-text in each exercise's `notes` field — e.g., `"Add 5lbs per session."` Humans can read and apply these. The tracker cannot.

For the tracker to auto-suggest the next session's working weight (the killer feature of this whole project), each progressing exercise needs structured progression metadata. Three patterns appear in the existing program:

1. **Linear** — fixed increment per session. Squat, Bench, OHP, Deadlift, Pendlay Row.
2. **Double progression** — fixed weight until all sets are completed at the top of the rep range, then bump weight and reset to the bottom. The Wednesday hypertrophy DB lifts, Friday DB Row, Hammer Curls.
3. **AMRAP** — log reps achieved; "progression" is just "more next time." Assisted Pullups, Dips.

Many exercises don't progress at all — Face Pulls, mobility, conditioning. Those simply omit the field.

The schema must be:

- **Self-explanatory enough that I (Claude) can read and reason about it without external documentation.** Following the same principle as ADR 0001 / the data-derived UI rule.
- **Extensible.** New `kind` values (e.g., wave loading, RPE-based, percent-of-1RM) can be added later without breaking existing entries.
- **Minimal up front.** Don't pre-specify deload rules, plateau detection, or anything else the tracker doesn't implement yet. Add fields when the tracker grows behaviors that need them.

## Decision

A `progression` table is added to each exercise that progresses. Three `kind` values are defined now; more can be added later.

**Linear:**
```toml
progression = { kind = "linear", increment_lbs = 5, cadence = "session" }
```
Bump the working weight by `increment_lbs` after every successful session.

**Double progression:**
```toml
progression = { kind = "double", rep_range = [8, 12], increment_lbs = 5 }
```
Stay at the current weight until all sets are completed at `rep_range[1]`. Then bump weight by `increment_lbs` and reset target reps to `rep_range[0]`.

**AMRAP:**
```toml
progression = { kind = "amrap", rep_range = [8, 12] }
```
No automatic weight progression. Tracker logs reps achieved and surfaces the trend. Optionally a target band can be encoded for context.

**No field** = no auto-progression. Tracker shows the prescribed `sets` string and lets the user log completion as a checkbox without weight tracking.

**Cadence default.** All linear lifts in the current program are performed once per week (stable IDs distinguish e.g. BB Squat from Front Squat), so `cadence = "session"` and `cadence = "week"` are operationally identical. We default to `"session"` everywhere as the simpler model, and revisit per-exercise if any lift starts being performed multiple times per week with the same ID.

**Deferred fields:**

- **Deload rules** (after N failed sessions, drop X%). Will be added when the tracker implements deload handling — likely Phase 3.
- **Stall detection.** Same.
- **RPE / RIR-aware progression.** Not in the current program; add when introduced.
- **Plate-rounding precision.** Increments are in lbs; assume the user has 2.5lb plates. If micro-loading becomes relevant, add `min_increment_lbs`.

## Consequences

**Good:**
- The tracker has everything it needs to compute next session's target weight from the program + last session log.
- Schema is small (≤4 keys per record) and easy to read in the TOML.
- Free-text `notes` stay alongside as human prose; the structured field doesn't replace the human-readable rationale.
- Adding new `kind` values later is non-breaking: tracker handles unknown kinds with a fallback ("show prescribed, no auto-progression"), and exercises retain the same `id` so history continues across schema additions.
- Claude can read both the TOML and a few weeks of session logs and propose `progression` edits the same way it proposes any other TOML edit.

**Bad:**
- The structured rule and the free-text `notes` can drift. Discipline: when editing one, eyeball the other.
- "Successful session" needs a clear definition somewhere — currently "all prescribed sets completed at prescribed reps." That definition lives in the tracker's progression engine code, not the schema. If it ever needs configuring, it becomes a new field here.

**Foreclosed:**
- Encoding deload, plateau, or RPE rules right now. (Intentional. Add when needed.)
- Per-set progression schemes (e.g., "first set 3×5, back-off sets 2×8"). The current program doesn't have these; if introduced, the schema needs a `sets` array with per-set progression metadata.
