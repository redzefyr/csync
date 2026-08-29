# Document format — the shape csync's documents have

`workspace.md` says what each directory is **for** and how long its contents
live. This file says what the documents **look like**, so a program can read them
without guessing. When you want to know whether something belongs in `notes/`,
read `workspace.md`; when you want to know how to write the file, read this.

**Copy the template, fill it in. Do not reconstruct it from this prose.**
`templates/document/` holds a real file for every shape below, and `init`
scaffolds `GRAPH.md` and both `notes/` files. A `cp` does not drift.

⚠️ **`rationale.md` holds why these shapes are what they are.** Read it only when
changing one of them.

## Why there is a machine-readable part at all

The fields a tool reads live in **YAML frontmatter**, and the prose stays prose.
Frontmatter costs the raw-text reader nothing — it sits at the top of the file in
plain sight — and it buys the parser an unambiguous carrier that no sentence in
the body can collide with.

⚠️ **The reader stays lenient.** A document with no frontmatter is **legacy**,
not an error: it is read by whatever heuristics the tool has and reported as
legacy. Existing workspaces are not migrated on sight — migration happens during
`cleanup`, which the user asks for by name.

## The rules that apply to every document

**1. Frontmatter comes first, delimited by `---`, before the `#` title.**

**2. The first key is always `csync: <kind>/<version>`.** It says which shape
this is and which revision of that shape:

| `csync:` | file |
|---|---|
| `graph/1` | `GRAPH.md` |
| `plan/1` | `plans/*.md` |
| `note/1` | `notes/*.md` |
| `design/1` | `docs/design/**` — live |
| `archive/1` | `docs/archive/**` — archive, **optional**, see below |

The version is there because the skill updates at a different moment on every
machine. A reader that meets `plan/2` and only knows `plan/1` must say so rather
than parse it as best it can.

**Legacy kind names.** `doc/1` is the old name for `design/1` and `research/1`
the old name for `archive/1`, from when the directories were `docs/*.md` and
`docs/research/`. A reader **accepts both and reports the old ones as legacy**;
`cleanup` renames them along with the directories, and nothing else does.

`CLAUDE.md` gets **no frontmatter.** It is instructions to Claude, not a document
in this sense, and it is excluded from conformance.

**3. Every prose value uses a literal block scalar (`|`).**

```yaml
next: |
  Fold §6.4 and §6.3 together.
```

Not `next: Fold §6.4 and §6.3 together.` — a plain YAML scalar breaks on a colon,
a leading `#`, a quote, or a `[`, and all four occur constantly in this corpus.
Short values are no exception; a rule with an "unless it's simple" clause is a
rule that gets guessed at.

**4. Nothing in frontmatter repeats what the filename already says.** A plan's
dates and slug are in `plans/<planned>-<advanced>-<slug>.md`, which is already
unambiguous. Restating them creates a second authority and the two drift.

**5. Frontmatter carries fields, never the document.** If a value is growing
paragraphs, it belongs in the body.

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
| `status_note` | the status **as the session that did the work stated it**, in whatever words it used. Optional. ⚠️ **Never summarise it and never translate it** — a status reworded by a session that did not do the work is indistinguishable from one written by the session that did, and every session after takes it as fact |
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
because a check only ever sees its own repo. A reader can still find the document
from a description.

**The body carries no header.** `status`, `next` and `blocked` are frontmatter and
appear once. A body sentence that happens to read like a status is just a
sentence.

### `## findings` — exact in position

The block stays in the body: its entries have prose bodies, and frontmatter is
for fields.

```markdown
## findings — carried over from other work (fold these in when you start)

### YYYY-MM-DD · found while working on <what>
**Touches**: premise | next step | cost — one line
A few lines of body.
```

- the heading is **`## findings`**, at h2, at column zero. **Not inside a
  blockquote**, not h3, not decorated before the word
- every entry is **`### YYYY-MM-DD · <what>`**, at h3. Not a numbered list
- the block ends at the next h1 or h2

⚠️ **A block in any other shape is read as zero pending findings**, and zero
reads as "nothing waiting". Copy `templates/document/findings-entry.md`.

## `note/1`

```yaml
---
csync: note/1
kind: decisions
why_marker: |
  Why.
---
```

| key | |
|---|---|
| `kind` | **`decisions` · `traps`** |
| `why_marker` | the bold run that opens the reason paragraph in this file's language. Defaults to `Why.` |

**The body is a flat list of `##` entries, one entry per decision or trap.** No
nesting: an entry that needs subsections is a `docs/` document with a one-line
note pointing at it.

**A `decisions` entry must contain a paragraph opening with `why_marker` in
bold.** That is what makes "a decision records why" checkable, so a tool can show
which decisions have none.

`why_marker` is declared per file because the corpus is written in the user's
language, and declaring the marker once is cheaper than a parser that knows how
to say "why" in every language.

## `design/1` — live

```yaml
---
csync: design/1
revise_when: |
  the interface this document specifies changes
---
```

`revise_when` is what makes a document live rather than archive, stated by the
document itself. `workspace.md` gives the test — *"does this state how something
is built, or the criterion something was built against?"* — and `revise_when` is
the answer written down, so `cleanup`'s "refresh `docs/design/`" step has
something to check against instead of re-deriving it per file.

⚠️ **If you cannot fill `revise_when` in, the document is not design.** It is
either the judgment of a day, which is `docs/archive/`, or it belongs to the code,
which is the project repo.

## `archive/1` — archive, and **optional**

Archive documents are ordinary markdown. They are the judgment of a day and
nothing revises them, so there is nothing for a tool to track. Frontmatter here
is optional and carries at most one key:

```yaml
---
csync: archive/1
superseded_by: some-later-slug
---
```

`workspace.md` says an overturned archive document is marked *"as of then"*
rather than deleted. That mark is a sentence somewhere in the body, and it gets
missed. `superseded_by` puts it where a reader sees it first.

Archive documents are **excluded from conformance reporting.** Plain markdown is
correct here, so flagging it would train people to ignore the report.

## `graph/1`

```yaml
---
csync: graph/1
---
```

`GRAPH.md` is the index, and an index must live in exactly one place — so its
content stays in the body where a reader sees it. The frontmatter only says what
the file is.

What is exact is the **skeleton**:

```markdown
## plans — <free prose subtitle>
### [[slug]] · planned MM-DD → advanced MM-DD · **status**
<free prose, any number of lines, emoji markers and all>

## docs — <free prose subtitle>
### design
- [[slug]] `docs/design/<path>` — one line
### archive
- [[slug]] MM-DD — one line

## notes — <free prose subtitle>
- [[slug]] — one line

## backlog — <free prose subtitle>
- one line

## closed pipelines
- ~~[[slug]]~~ closed MM-DD `<commit>` — one-line conclusion
```

- **section headings are h2 and begin with a key from a closed set** —
  `plans` · `docs` · `notes` · `backlog` · `closed`. Anything after the key,
  usually ` — ` and a sentence, is free
- **plan entries are h3 and open with `[[slug]]`**
- **everything under an entry is free prose and is rendered as written**

📌 **A path written next to a slug is for the reader. A tool must not read it.**
Slugs resolve from filenames (`plans/<planned>-<advanced>-<slug>.md`, basename
elsewhere), so a tool that also looked in `GRAPH.md` would be consulting a second
authority that nothing keeps in step.

⚠️ **The body under an entry stays free, deliberately.** Only the skeleton above
is structure; everything else is shown verbatim. A line a tool cannot classify is
**displayed, never dropped** — dropping raises no error, and the reader concludes
it was never written.

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
