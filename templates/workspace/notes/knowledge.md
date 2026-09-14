---
csync: note/2
kind: knowledge
gauge: 300/
why_marker: |
  Why.
entry_markers:
  judgment: |
    judgment
  trap: |
    trap
---

# Knowledge — what Claude concluded, and what is easy to step on

**Claude keeps this file.** Two kinds of entry, named at the end of the heading
by the values declared as `entry_markers` above:

- **`judgment`** — a standing choice Claude reached by working. It carries a
  reason paragraph opening with the bold `why_marker`: the **ground** it stands
  on, not how it was found. Revise it without asking once that ground stops
  holding, and say so in the session report. When the user affirms one, it moves
  to [[decisions]] as a `mandate`
- **`trap`** — something easy to step on. Prefer the ones that fail silently

**Two tests decide entry, and an entry needs both**: would starting work without
knowing this make you wrong? · where is the reader standing when it fires?
⚠️ **Inside one routine, type or interface, the home is a comment at that code
site, not here** — this file is read at session start, before anyone knows which
files the session touches.

⚠️ **`gauge` is `<max>/<alarm>`.** After writing here, run
`~/.claude/skills/csync/scripts/csync-ledger.sh gauges`; past the max, tell the
user if not yet told this session, and **fold before finishing** either way —
a single-site entry to a comment at that site, a convention to the project repo,
a criterion to `docs/design/`, numbers to `docs/archive/`; a `judgment` whose
ground is gone and a `trap` whose condition is gone are deleted, and reported.
Only when nothing can move, ask the user to raise the max, with the current line
count and the value proposed. **Never trim to fit.**

One flat list of `##` entries. Copy
`~/.claude/skills/csync/templates/document/note-judgment-entry.md` or
`note-trap-entry.md` beside it.
