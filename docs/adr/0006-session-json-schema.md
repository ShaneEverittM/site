# 0006. Session JSON schema

- **Status:** Accepted
- **Date:** 2026-05-07

## Context

Each gym session produces one JSON file written to the repo via the Worker. This ADR fixes its shape — what each file contains, where it lives, and how it relates to the program TOML.

Constraints:

- **AI-readable.** Same principle as the program TOML: Claude must be able to glance at a session file and reason about it without external schema docs.
- **Self-contained per file.** A session file is the unit of commit. Reconstructing what happened that day shouldn't require fetching N other files.
- **Forward-compatible.** Additions over time (per-set RPE, video links, body-weight, sleep score, whatever) shouldn't break existing files. Tracker treats unknown fields as ignorable.
- **Minimum viable.** Phase 3 is "did the set" UX. Don't pre-design fields the tracker won't write.

A subtlety: the program changes over time. A session logged on 2026-05-08 might have been performed against a program that no longer exists in `data/workout_program.toml`. To preserve that context, each session records the git SHA of the program revision active at log time. Anyone (including future Claude) can `git show <sha>:data/workout_program.toml` to reconstruct exactly what the day's program was.

A second subtlety: the user may override the prescribed weight at log time ("didn't feel like 145, did 140 instead"). The session must record what was *actually* done, not what was prescribed. The prescribed value can be looked up via the program revision; the actual value cannot be reconstructed without being captured.

## Decision

**File location:** `data/sessions/<date>-<day_slug>.json`, e.g. `data/sessions/2026-05-08-monday.json`. One file per session. Sorted lexically by date for `git log` readability.

**Shape:**

```json
{
  "date": "2026-05-08",
  "day_id": "monday",
  "program_revision": "abc1234",
  "started_at": "2026-05-08T17:32:00Z",
  "ended_at": "2026-05-08T18:45:00Z",
  "exercises": [
    {
      "id": "barbell_squat",
      "completed": true,
      "weight_lbs": 145,
      "reps": [5, 5, 5]
    },
    {
      "id": "barbell_bench",
      "completed": false,
      "weight_lbs": 160,
      "reps": [5, 5, 4],
      "notes": "missed last rep"
    },
    {
      "id": "face_pulls_mon",
      "completed": true
    }
  ],
  "notes": ""
}
```

**Field semantics:**

- `date` — ISO date the session was performed. Required.
- `day_id` — slug matching the day in the program (e.g. `"monday"`, `"wednesday"`). Required. Used to resolve which program day this session was logged against.
- `program_revision` — git SHA (short, 7+ chars) of the commit holding the program TOML when the session was started. Required. Enables time-travel reconstruction of prescribed work.
- `started_at`, `ended_at` — ISO timestamps. Optional. Useful for session-length analysis later; not load-bearing.
- `exercises[]` — required. Order matches the program's exercise order at log time, but consumers should not rely on order; key off `id`.
  - `id` — stable exercise ID from the program TOML. Required.
  - `completed` — boolean. Required. Whether all prescribed sets were completed at prescribed reps/weight (or better). Drives progression: `true` allows the next-session weight bump per ADR 0005's rules; `false` holds or eventually deloads.
  - `weight_lbs` — optional. The actual weight used. Required for any exercise with a `progression` rule that uses weight. Omit for bodyweight or unweighted exercises.
  - `reps` — optional array of integers, one per set. Required for `kind = "double"` and `kind = "amrap"` exercises (so the tracker can decide rep-range progression). Optional for linear (the `completed` boolean is sufficient there).
  - `notes` — optional string. Free-form per-exercise comment.
- `notes` — optional string. Free-form session-level comment.

**Unknown fields** are preserved on read (tracker passes them through if rewriting a session), but the schema-of-record is what's documented above. Additions land via this ADR being superseded.

## Consequences

**Good:**
- Self-contained: one file fully describes one session.
- Time-travel: `program_revision` plus git history makes "what was prescribed that day?" answerable forever.
- Progression engine has exactly what it needs: `completed` for linear, `reps` for double/amrap, `weight_lbs` for the running working-weight.
- AI-readable: the structure is obvious from skimming a few fields. Field names are not abbreviated.
- File-per-session means `git log data/sessions/` is a chronological training journal, and any tool (cli, ripgrep, jq) can analyze the corpus trivially.

**Bad:**
- Many small files. After 12 months of training that's ~250 files. Not a real performance concern, but lists in the tracker need pagination or filtering by date.
- The `program_revision` field requires the Worker to know the current HEAD SHA at write time. The Worker does the commit, so it has access — but it must record the SHA *before* the session commit (i.e., the parent SHA), not the SHA of the session commit itself.
- Double-progression "did all sets at top of range" decision requires `reps[]`, which adds a small UX wrinkle for the user (they tap done, but did they hit 12 reps or 11 on each set?). v1 may default to "if you tap completed, assume you hit the top of the range; if you didn't, manually edit `reps`." Refine as needed.

**Foreclosed:**
- Per-rep RPE/RIR tracking. Possible additive field; not now.
- Per-set weight variation (drop sets, ascending sets). Not in the current program.
- Photos/video. Not relevant to this tool's purpose.
