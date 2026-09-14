# Document format — the shape csync's documents have

`workspace.md` says what each directory is **for**; this file says what the
documents **look like**, so a program can read them without guessing.

**Copy the template, fill it in. Do not reconstruct it from this prose.**
`templates/document/` holds a real file for every shape below, and `init` scaffolds
both `notes/` files and `backlog.md`. A `cp` does not drift.

**The reader is `scripts/csync-ledger.sh`.** It lists plans, backlog, docs and
gauges from these shapes, resolves slugs, and reports what is out of shape. What
this file calls machine-read, that script reads.

⚠️ **`rationale.md` holds why these shapes are what they are.** Read it only when
changing one of them.

## The rules that apply to every document

The fields a tool reads live in **YAML frontmatter**; the prose stays prose.

⚠️ **The reader stays lenient.** A document with no frontmatter is **legacy**, not
an error: it is read by whatever heuristics the tool has and reported as legacy.
Existing workspaces are not migrated on sight — migration happens during `cleanup`,
which the user asks for by name.

**1. Frontmatter comes first, delimited by `---`, before the `#` title.**

**2. The first key is always `csync: <kind>/<version>`:**

| `csync:` | file |
|---|---|
| `plan/1` | `plans/*.md` |
| `note/2` | `notes/decisions.md`, `notes/knowledge.md` |
| `backlog/1` | `backlog.md` |
| `design/1` | `docs/design/**` — live |
| `archive/1` | `docs/archive/**` and `docs/closed-pipelines.md` — archive, **optional**, see below |

The skill updates at a different moment on every machine, so **a reader that meets
`plan/2` and only knows `plan/1` must say so** rather than parse it as best it can.

**Legacy kind names.** `doc/1` is the old name for `design/1`, `research/1` for
`archive/1`. `note/1` is the old notes format — `decisions` holding all three
authorities, and a separate `traps` file. `graph/1` is `GRAPH.md`, which is retired
(below). A reader **accepts all of them and reports them as legacy**; `cleanup`
migrates them, and nothing else does.

`CLAUDE.md` gets **no frontmatter** — it is instructions to Claude, not a document
in this sense, and it is excluded from conformance.

**3. Every prose value uses a literal block scalar (`|`).**

```yaml
next: |
  Fold §6.4 and §6.3 together.
```

A plain scalar breaks on a colon, a leading `#`, a quote or a `[`, and all four
occur constantly in this corpus. **Short values are no exception**; a rule with an
"unless it's simple" clause is one that gets guessed at.

**4. Nothing in frontmatter repeats what the filename already says** — a plan's
dates and slug are in `plans/<planned>-<advanced>-<slug>.md`. Restating them
creates a second authority, and the two drift.

**5. Frontmatter carries fields, never the document.** A value that is growing
paragraphs belongs in the body.

**6. A file read at every session start, or piling up between sessions, declares
its own `gauge`:**

```yaml
gauge: 300/      # max 300, no alarm
gauge: /200      # no max, alarm past 200
```

`<max>/<alarm>`, whole numbers, either side left empty for "none". The unit is
**lines of the whole file** — `wc -l`, frontmatter and header included, because
that is what a session reads. The value lives in the file it governs so it is in
context whenever that file is, and so a project can move it without touching a
copy anywhere else. What happens past each is `workspace.md`'s ("Gauges").

## `plan/1`

```yaml
---
csync: plan/1
status: active
status_note: |
  MVP shipped; the parser rebase is next
next: |
  One sentence, so the next session can start on it as written.
blocked: []
pairs: []
---
```

| key | |
|---|---|
| `status` | **`active` · `waiting` · `parked`.** A closed set, because this is the one field that gets counted — "how many pipelines are parked" is a question no prose status can answer |
| `status_note` | the status **as the session that did the work stated it**, in whatever words it used. Optional. ⚠️ **Never summarise it and never translate it** — reworded by a session that did not do the work, it is indistinguishable from the original, and every session after takes it as fact |
| `next` | one sentence. The next session starts on this, as written |
| `blocked` | `[]` when nothing, otherwise a list of block scalars |
| `pairs` | cross-repository pairs. `[]` when none |

```yaml
pairs:
  - repo: some-protocol-lib
    what: |
      the Entry renumbering, server side
```

⚠️ **`what` is a description, never a bare slug.** Slugs change in the other
repository and this side then points at a name that no longer exists — silently,
because a check only ever sees its own repo.

**The body carries no header.** `status`, `next` and `blocked` are frontmatter and
appear once. A body sentence that happens to read like a status is just a sentence.

### `## findings` — exact in position

```markdown
## findings — carried over from other work (judge each, then delete it)

Each entry gets one of three verdicts before this session's own work:
**promote** into the body · **backlog** in `backlog.md` · **reject** in one line.
Then the entry goes. An entry still sitting here reads as *not yet judged*.

### YYYY-MM-DD · found while working on <what>
**Touches**: premise | next step | cost — one line
A few lines of body.
```

- the heading is **`## findings`**, at h2, at column zero. **Not inside a
  blockquote**, not h3, not decorated before the word
- every entry is **`### YYYY-MM-DD · <what>`**, at h3. Not a numbered list
- the block ends at the next h1 or h2
- **the prose between the heading and the first entry travels with the block**,
  and so does the `KEEP THIS COMMENT` comment in the template. They are the only
  instruction that reaches the session doing the folding — the block arrives in a
  plan whose session may never load these rules

⚠️ **A block in any other shape is read as zero pending findings**, and zero reads
as "nothing waiting" — the ledger shows a block with no `###` entries as `?` for
that reason. Copy `~/.claude/skills/csync/templates/document/findings-entry.md`.

⚠️ **Older blocks say `backlog in GRAPH.md`.** The prose travels with the block, so
copies written before `GRAPH.md` was retired are still sitting in plans. Read it as
`backlog.md`; `cleanup` rewrites the line.

## `note/2`

The two files split by **whose** entries they hold, because that decides who may
revise one: `decisions` is the user's, `knowledge` is Claude's.

```yaml
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
```

```yaml
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
```

| key | |
|---|---|
| `kind` | **`decisions` · `knowledge`** |
| `gauge` | rule 6. The template values are defaults, not the user's ceiling |
| `why_marker` | the bold run that opens the reason paragraph, in this file's language — declared per file because the corpus is not written in English. Defaults to `Why.` |
| `authority_markers` | `decisions` only. The keys are fixed — **`mandate` · `held`** — and the values are the tokens that appear in an entry, in this file's language |
| `entry_markers` | `knowledge` only. The keys are fixed — **`judgment` · `trap`** — declared for the same reason |

**The body is a flat list of `##` entries.** No nesting: an entry that needs
subsections is a `docs/` document with a one-line note pointing at it.

**Every heading ends in a token in parentheses.** In `decisions`,
`(<YYYY-MM-DD> · <authority>)`. In `knowledge`, `(<YYYY-MM-DD> · <kind>)` — or
`(<kind>)` alone for a trap migrated from `note/1`, which carried no date:
⚠️ **a date is never invented to fill the slot.**

**A `decisions` entry, and a `knowledge` entry marked `judgment`, must contain a
paragraph opening with `why_marker` in bold.** That is what makes "a decision
records why" checkable.

⚠️ **An entry in `decisions` with no authority token is `held`, never Claude's.**
Reading an unmarked entry as Claude's own is how a user's decision gets revised
without anyone choosing that, and it fails silently. An entry in `knowledge` with
no kind token is reported as deviating, and `cleanup` marks it: `judgment` when
it carries a `why_marker` paragraph, `trap` otherwise.

**`note/1`**, the legacy shape: `decisions` declared a third authority,
`judgment`, and traps lived in `kind: traps`. `cleanup` moves every entry marked
`judgment` into `knowledge` unchanged — its heading already ends in
`(<date> · <judgment>)` — appends `(<trap>)` to each trap's heading, and leaves
`held` entries where they are. That holds only because the new file's
`entry_markers.judgment` and `why_marker` are first set to the old `decisions.md`
values, and `trap` to a word in the same language (`cleanup.md`, step 0).

## `backlog/1`

```yaml
---
csync: backlog/1
gauge: 50/
---
```

**Every line opening with `- ` is an item, and nothing else in the file uses one.**
An item is `- YYYYMMDD <what>`, dated the day it was listed — the date is what lets
"untouched through several cleanups" be read off the file rather than remembered.
A legacy item with no date gets the date of the cleanup that migrates it: that
reads as "listed since at least", which is true, where any earlier date would be a
guess.

## `design/1` — live

```yaml
---
csync: design/1
revise_when: |
  the interface this document specifies changes
---
```

`revise_when` is what makes a document live rather than archive, stated by the
document itself, and it is what `cleanup`'s "refresh `docs/design/`" step checks
against instead of re-deriving the answer per file. ⚠️ **If you cannot fill it in,
the document is not design** — it is either the judgment of a day, which is
`docs/archive/`, or it belongs to the code, which is the project repo.

## `archive/1` — archive, and **optional**

Archive documents are ordinary markdown: the judgment of a day, revised by nothing,
with nothing for a tool to track. Frontmatter is optional and carries at most one
key. The title line **`# <title> — YYYY-MM-DD`** is what the ledger lists the
document by, so the template's shape is worth keeping even where frontmatter is
left out.

```yaml
---
csync: archive/1
superseded_by: some-later-slug
---
```

An overturned archive document is marked *"as of then"* rather than deleted
(`workspace.md`); that mark is a sentence somewhere in the body and gets missed, so
`superseded_by` puts it where a reader sees it first. Archive documents are
**excluded from conformance reporting** — plain markdown is correct here, and
flagging it would train people to ignore the report.

## `GRAPH.md` — retired

There is no index file. `csync-ledger.sh` derives what `GRAPH.md` used to hold —
plans with status, next step, findings count and pairs; the backlog; docs with
their titles and `revise_when`; slug resolution — from the documents themselves,
each time it runs, and writes nothing.

📌 **Slugs resolve from filenames** — `plans/<planned>-<advanced>-<slug>.md`, the
basename everywhere else — and a closed slug from its line in
`docs/closed-pipelines.md`. There is no second authority to keep in step.

A `GRAPH.md` still in a workspace is the legacy shape, reported by the ledger. Its
backlog goes to `backlog.md`, prose under a plan's entry goes into that plan if it
still holds, and the file is deleted — by `cleanup`, when the user asks for it.

**Dates in filenames and in backlog items are `YYYYMMDD`**, compared and sorted by
a program. ⚠️ A dashed date in a filename is **legacy, not deviating**: read it, say
so, and leave the rename to `cleanup`. `workspace.md` has the reason for the fixed
width.

⚠️ **This does not reach into document bodies.** The `## findings` heading stays
`### YYYY-MM-DD · <what>`, and so do dates in note headings and archive titles —
they are read, not compared against a filename. Changing the findings shape would
be the worst kind of edit: a block in any other shape counts as **zero** pending
findings, so every existing hand-off would go silently missing.

## Emoji markers — a closed vocabulary

| | means |
|---|---|
| 📌 | **settled** — a decision or premise that holds, with its reason |
| ⚠️ | **warning** — easy to get wrong; prefer the ones that fail silently |
| ✅ | **done** — completed and verified, not merely claimed |
| 🔁 | **carried over** — the substance moved to another document or pipeline |
| 🗑️ | **dropped** — abandoned; do not revive without new grounds |
| ★ | **read this first** — the one line that survives if nothing else is read |
| 🔓 | **correction** — supersedes something written above it. **`docs/archive/` only**; everywhere else the superseded line is corrected, not annotated |
| 🔗 | **pair** — a cross-repository link |

- a marker sits at the **start of a paragraph or list item** and applies to that
  paragraph. Mid-sentence it is just an emoji
- **the set is closed.** Any other emoji is decoration and carries no meaning a
  tool may act on

## Conformance

A tool reading these documents reports three states, and **only reports**:

| | |
|---|---|
| **conforming** | frontmatter present, `csync:` known, required keys present |
| **legacy** | no frontmatter, or a legacy kind name. Read by heuristics, shown as legacy |
| **deviating** | frontmatter present but wrong — unknown kind, unknown version, missing key, unparseable YAML |

⚠️ **Reporting is the whole job.** Repairing a workspace is `cleanup`, which the
user runs by name. A tool that quietly fixed a document would erase the judgment
that `cleanup` exists to make.
