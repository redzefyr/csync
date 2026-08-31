---
csync: note/1
kind: decisions
why_marker: |
  Why.
authority_markers:
  mandate: |
    mandate
  judgment: |
    judgment
  held: |
    held
---

# Decisions — the standing choices, and who may change them

**Record why it was decided, not just what was decided.** Without the reason the
next session reverses it. Write the **ground** — what makes the decision right —
not how it came to be found. Traps go in [[traps]]; live work and where to start
is `../GRAPH.md`.

**Every entry carries an authority marker, and it decides who may revise that
entry.** The three are declared as `authority_markers` above — write them in this
file's language and keep them matching.

- **`mandate`** — the user decided it, explicitly. Work within it. When the work
  argues against it, **raise it and let the user decide**; never revise it
  yourself and never quietly route around it. ⚠️ **Inferred intent is not a
  mandate** — "they would want this" is a `judgment`, and marking it `mandate`
  inflates the protected tier until the whole file is frozen
- **`judgment`** — Claude concluded it. Consult it the same way, and **revise it
  without asking once the ground it stands on stops holding** — that is what the
  ground is written down for. Say in the session report that you did, and what
  changed
- **`held`** — authority not settled yet, which is also how an **unmarked** entry
  reads. Treat it as a `mandate` for now, and settle it **the first time it
  actually gets in the way**: say it is `held`, say which way you read it, and
  agree the marker with the user. Not a migration to run through the file — an
  entry nobody has bumped into costs nothing sitting there

Markers are settled, not fixed: a `judgment` the user affirms becomes a
`mandate`, and a `held` becomes whichever it turns out to be.

One flat list of `##` entries. Every entry carries a paragraph opening with the
bold run declared as `why_marker` above. Copy
`~/.claude/skills/csync/templates/document/note-decision-entry.md` — read it
there rather than rebuilding the heading from memory.
