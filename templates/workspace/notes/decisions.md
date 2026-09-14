---
csync: note/2
kind: decisions
gauge: /200
why_marker: |
  Why.
authority_markers:
  mandate: |
    mandate
  held: |
    held
---

# Decisions — the standing rules the user set

**Only the user's rules go here.** An entry is written when the user states a
rule meant to hold beyond the task at hand — calling it a rule, a convention, a
design, a spec are the usual signs, but the words are examples and not the test —
and **after the wording and the why have been read back and confirmed.** If the
user gave no reason, ask; do not supply one. What Claude concluded by working
goes in [[knowledge]].

**Every entry carries an authority marker**, declared as `authority_markers`
above in this file's language:

- **`mandate`** — the user decided it, explicitly. Work within it. When the work
  argues against it, **raise it and let the user decide**; never revise it
  yourself and never quietly route around it. ⚠️ **Inferred intent is not a
  mandate** — "they would want this" is a `judgment`, and it goes in [[knowledge]]
- **`held`** — authority not settled yet, which is also how an **unmarked** entry
  reads. Treat it as a `mandate`, and settle it with the user **the first time it
  actually gets in the way** — not as a pass through the file. Settled as
  Claude's, it moves to [[knowledge]] as a `judgment`

⚠️ **`gauge` is `<max>/<alarm>`, and this file has no max** — nothing in it is
Claude's to fold. After writing here, run
`~/.claude/skills/csync/scripts/csync-ledger.sh gauges`; past the alarm and not yet
reported this session, tell the user and leave the choice to them.

One flat list of `##` entries. Copy
`~/.claude/skills/csync/templates/document/note-decision-entry.md`.
