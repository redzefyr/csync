# The workspace — `plans` · `notes` · `docs` · `GRAPH.md`

The three directories **have different lifetimes.** Mixed together, every
decision means reading all three, and once that is true for long enough nobody
reads any of them.

| | what lives there | lifetime |
|---|---|---|
| `plans/` | **one pipeline = one file.** Work in progress or deliberately parked | **deleted** when it closes |
| `notes/` | **decisions that must not be reversed** and **traps that are easy to step on**. Only what has to be in context no matter what you are doing | permanent, but **capped** |
| `docs/` | experiment results, measurements, evidence. The backing for a one-line note | permanent. It is a place you go looking, so it may grow |

`GRAPH.md` sits at the workspace root, one per project. It is **the entry point,
read at the start of every session together with `notes/`**.

**This file says what each directory is for and how long its contents live.**
What the documents *look like* — the frontmatter keys, the `## findings` block,
the emoji vocabulary, and what a tool may and may not read — is
`document-format.md`. Read that one before creating or editing a document, and
**copy the template from `templates/document/` rather than reconstructing a
header from prose.**

## Reference documents by slug, not by filename

In document bodies, point at other documents with **`[[slug]]`**. Filenames carry
dates and therefore change, so a filename reference breaks every time a pipeline
advances. Resolving slug → file is `GRAPH.md`'s job. (Same convention Claude's
memory directories already use.)

**Files inside the project repo may be referenced by path** — `PROTOCOL.md`,
`README.md` and the like move with the code, so the reader already has them.

## `plans/` — the filename states the progress

```
plans/<planned>-<advanced>-<slug>.md     e.g. 20260820-20260824-search-index-rebuild.md
```

**The advanced-date is the day that pipeline actually moved.** Fixing a banner,
correcting a typo, touching it during cleanup — **none of those are progress**.
If the date rises for those, the signal "how long has this been parked" dies, and
that signal is the only reason this name exists.

Every plan opens with **YAML frontmatter** carrying `status`, `next` and
`blocked`, so the file can be judged without opening it. The exact keys are in
`document-format.md`; copy `templates/document/plan.md` rather than rebuilding
the header from memory.

`status` is a closed set — `active` · `waiting` · `parked` — because it is the
one field that gets counted. The prose version of the status rides alongside it
in `status_note`, **in the words of the session that did the work.**

- **Do not leave finished sections in a plan.** Keep a one-line conclusion and
  push the evidence into `docs/`. This is the only thing stopping a plan from
  swelling into a decision archive
- **Advance one pipeline per project per session.** Cleanup, sync and simple
  lookups do not count. A session that has opened several projects may advance
  one pipeline **in each** — cross-repo pairs exist (the two ends of the same
  work, split across repos because the repos are split), and forcing them into
  separate sessions means the side that goes second starts without the context
  the first one just built.
  ⚠️ **This is not licence to open more projects in order to get more
  pipelines.** The limit is there so each plan's hand-off gets written while its
  context is still loaded. Opening a second project to dodge it produces two
  half-written hand-offs instead of one good one — and the hand-off is the only
  thing the next session has.
- **A session ends by updating that plan's "next step" and its advanced-date.**
  Skip it and the unfinished part accumulates exactly as it was — and a stale
  "next step" is worse than none, because it reads as one that someone checked

### `## findings` — carried over from other work

While running one pipeline you often find **something another pipeline needs to
know**. The one-per-session rule means you cannot go and fix it there, and not
handing it over means the finding disappears. **Put it in the other plan as a
`## findings` block.**

Copy `templates/document/findings-entry.md`. **The position is exact** — `##`
at column zero, entries at `###`, never inside a blockquote — and
`document-format.md` says why: this block has been written in another shape
before, and a reader that does not recognise it reports **zero pending
findings**, which is read as "nothing waiting".

⚠️ **The finder does not re-prioritise the other pipeline.** Do not add sections
to its body and do not rewrite its "next step" banner — **what comes first is
decided by the session that runs that pipeline.** `findings` is a quarantine
area, and that is the whole reason the block exists. (Crossed for real on
2026-08-27: a finding was written straight into the body and the banner rewritten
on top of it.)

- **Do not raise the advanced-date.** The other pipeline did not move. Raising it
  kills the "how long parked" signal
- **Leave a marker on that entry in `GRAPH.md`** — what is not visible from the
  entry point does not get found. `⚠️ findings x2 (08-27)` is enough
- **The bar for entry is "does it change the other side's premise, next step, or
  cost?"** "Good to know" fails, and "good to know" is what inflates plans
- **If the other side does not exist yet**, put it in the `GRAPH.md` backlog. Grow
  it into a plan when it earns one
- **In another repository, write the substance rather than a path** (the
  stand-alone rule in `SKILL.md`)

**Folding them in is the first job of the session that starts that pipeline.**
Each finding ends one of three ways — **promoted into the body** (only then does
it become a section and change the banner) · **moved to the backlog** ·
**rejected** (one line saying so, then delete). Once folded, the entry is gone.
**A finding still sitting there is one that has not been judged.**

#### When the outlet will not open — **recommend it to the user**

The only route to folding findings in is "when that pipeline is started", and
**a long-parked pipeline never opens that route** (waiting on an external spec,
say). Findings then pile up, inflate the plan, and worse, **sit unjudged**.

**Say something to the user when either of these is true** — one line in the
session report:

- findings have **accumulated** far enough that the plan's "next step" already
  looks stale
- one finding **invalidates the other side's premise** — this one is **immediate,
  regardless of count**. A plan whose premise is broken will have the next
  session **start from a false premise**

> "**I'd open a separate session to tidy up `<slug>`.** It has N findings
>  waiting, and one of them touches that plan's premise."

**Do not handle it in this session** (one pipeline per project per session, and
that project's one is already spoken for). Recommending is
the whole job; whether to open it is the user's call. ⚠️ **Do not invent a
numeric threshold for this** — that just adds another unfounded number. The two
conditions above are the test.

## `notes/` — what goes into context every session

> **Principle (this is the source of truth)**: `notes/` holds **what any session
> must have in context, whatever it is working on**. Which is exactly why it is
> **kept small — so no session is made to read a large amount of context.**

The line count below is **a gauge derived from that principle, not a separate
instruction.** When the number and the principle disagree, **the principle wins.**

Only two things survive:

1. **Decisions that must not be reversed** — write **why** it was decided, not
   what was decided
2. **Traps that are easy to step on** — prefer the ones that fail silently, the
   ones that raise no exception

**One test decides entry — "would starting work without knowing this make you
wrong?"** Yes → `notes`. No → somewhere else. **"Good to know" fails**, and that
category is most of the bulk.

**Gauge: 400 lines.** Over it, fold during that session. What overflows usually
has a home already: the list of plans belongs in `GRAPH.md`, conventions in the
project repo's `PROTOCOL.md`/`README.md`, machines and environments in memory,
build steps in the workspace `CLAUDE.md`, measured numbers in `docs/`.

⚠️ **Folding means moving, not discarding.** Deleting a trap or its reasoning to
hit a number turns this rule into a loss machine — **better to run over than to
lose something while trimming** (2026-08-27, the reason the gauge went 300 → 400).

⚠️ **Do not read the gauge as a user instruction.** The original 300 was a
Claude's translation of the principle into a number, written without its
reasoning, and **a session mistook it for a ceiling the user had set**
(2026-08-27). The gauge may be adjusted when the principle calls for it — **but
write down why that value, here, at the same time.**

**One flat list of `##` entries per file**, and a decision entry carries its
reason as a marked paragraph — `document-format.md` has the shape, and
`templates/document/` has both entry snippets. Marking the reason is what lets a
reader see which decisions have none, instead of that surfacing years later when
someone reverses one.

Session notes, scratch and logs do not belong in `notes/`. Use a scratchpad.

## `docs/` — **location is lifetime**

When two opposite lifetimes share a directory, you end up reading a snapshot as
if it were the standard, and working from a stale premise. Labels are not enough
— **split by directory.**

| | what | when the conventions change |
|---|---|---|
| `docs/*.md` | **live** — analysis procedures, structural surveys, constant tables, setup docs | **revise them along with it** |
| `docs/research/**` | **archive** — experiment results, feasibility reviews, the judgment of that day | leave them alone |

One test: **"does this have to be corrected when code or conventions change?"**
Yes → live, no → archive. It is usually settled **at creation time**, so moving
things later is rare.

A live document writes that answer down as `revise_when` in its frontmatter, so
cleanup's "refresh `docs/`" step has something to check against instead of
re-deriving it per file. Archive documents are ordinary markdown; frontmatter
there is optional and carries at most `superseded_by`.

**Archive is not "the stuff you can skip".** The reasoning behind an abandoned
track, and the grounds on which it was rejected, live there — and when they
cannot be found, the same experiment gets run again. That is why the directory is
not called `archive/`.

When an archive document is overturned, do not delete it: mark the passage **"as
of then"** and add what changed. Internal documents are where reversals are
supposed to be recorded — the opposite of the rule for anything shipped to users.

⚠️ **Change a convention, revise the live docs in the same session.** Miss it and
the next analysis runs on the old premise — there is precedent: an archive schema
changed while the analysis guide still told readers to look up the old keys.

## `GRAPH.md` — the entry point

The skeleton — which h2 sections exist, how a plan entry opens — is in
`document-format.md`, and `init` scaffolds it. Two things about it belong here,
because they are about what the file is *for* rather than what it looks like:

**Everything under an entry is free prose, and that is deliberate.** Real entries
carry a dozen emoji-led lines. Only the skeleton is structure; the rest is shown
as written. A line that cannot be classified is displayed, never dropped —
dropping raises no error, and the reader concludes it was never written.

**A path written next to a slug is for the reader, not for a tool.** Slugs
resolve from filenames, so a tool reading paths here would be consulting a second
authority that nothing keeps in step.

**When to update it**: when a document is created or deleted, when a pipeline's
status changes, and when a session closes. If `GRAPH.md` is wrong, nothing else
being accurate helps, because it cannot be reached — **never keep the index in two
places.**

**Always record cross-repository pairs.** Close one side alone and the other is
orphaned. Paths cannot be used (the stand-alone rule), so write **repository name
plus document name** as text.

⚠️ **When recording a pair, do not write the slug alone — write a fragment of what
it does.** If the slug changes in the other repository this side quietly points at
the old name (a validation script only ever sees its own repo), but a reader can
still find it when the description is there. On the day five plans were merged
into two, five cross-repository references died at once.

**When one side merges or renames a document, sweep the other in the same
session** — `grep -rn '<old-slug>'` over the other workspace and the memory
directory is the whole job.

## Session start

1. Read `notes/` and `GRAPH.md`
2. Work out which pipeline the user's request belongs to. With no instruction,
   **ask which one to continue** — do not pick one yourself
3. **If that plan has a `## findings` block, fold it in first** — promote, backlog,
   or reject. Another session handed those over, and until they are folded the
   "next step" may be stale
4. Run that one, and only that one

`/csync open <slug>` is steps 2 and 3 as one command, and the only thing that
renames the session — `SKILL.md` has it. These four steps stand on their own
where it is not used; the command is a shorter way to walk them, not a
precondition.

## During a session — finding something that belongs to another pipeline

Do not touch it where you found it. **Put it in the other plan's `## findings` and
leave a marker in `GRAPH.md`** (the `## findings` section above). The pipeline you
are running continues unchanged.

## Closing a pipeline — four steps before deleting

**The order matters.** Delete without this and the rule becomes a loss machine.

1. **Verify completion in the code.** Do not believe what the document says about
   itself — grep for the symbols, read the commits. There is precedent for a plan
   marked "shipped" describing an abandoned branch with no code behind it at all
2. **Extract the unstarted follow-ups first.** This is where things die most
   often. Even a plan whose main work shipped almost always still holds "if we
   ever need X, start here" items. Split them into a new plan or raise them to the
   `GRAPH.md` backlog
3. **Grep the slug and the filename across the whole tree and the memory
   directory.** Memory files often say "the plan for this is X" and go silently
   wrong
4. **If it is paired with another repository, handle both together**

Then distribute the contents:

| what is in the finished plan | where it goes |
|---|---|
| a decision that must not be reversed, plus **why** | `notes/` |
| a trap that is easy to step on | `notes/` |
| the **verdict** on a rejected option ("do not try this again") | one line in `notes/` |
| the **numbers and experiments** behind that verdict | `docs/` |
| measurements, instrumentation, comparison tables | `docs/` |
| unstarted follow-ups | a new plan, or the backlog (step 2) |
| checklists, status tables, step-by-step records | discard |

A rejection **splits into verdict and evidence.** The verdict has to be known
whatever you are working on, so it goes in `notes`; the evidence is what you go
looking for when you do not want to recompute it, so it goes in `docs`.

Finally **delete the plan file and leave one line under "closed pipelines" in
`GRAPH.md`.** The workspace is a git clone, so the full text stays in the
`prj/<name>` history.

## Cleanup

Pruning a workspace so a new session can trust it. There is nothing to run: read
the files, decide, edit, delete, then `sync`.

Deletion is safe here — the workspace is a git clone, so anything removed stays in
`prj/<name>` history. Say so when you report, and give the branch name.

⚠️ **"Safe to delete" is not "free to read back."** Recovering something from that
history needs the user's approval twice — once to read, once to apply (**Two
repos** in `SKILL.md`). Retired judgments sit in history stated with their original
confidence and nothing marks them as retired, so a session that digs one up can
quietly revive a rule the user has already changed.

**0. If the structure is the old shape, reorganise first.** No `GRAPH.md`, or
`plans/` filenames that are not `<planned>-<advanced>-<slug>`, or hand-off notes
and session logs sitting in `notes/` — move to the structure above before doing
anything else. Otherwise what you tidy just piles up in the old place again.

**Migrating documents to the frontmatter format belongs here too, and nowhere
else.** A document without frontmatter is legacy, not broken: it reads fine, and
tools report it as legacy rather than failing on it. Converting one is an edit to
the user's own record, so it happens when they ask for cleanup — never
opportunistically, in passing, while a session is doing something else.

Convert by **moving** what is already there — a plan's leading blockquote becomes
`status` / `status_note` / `next` / `blocked`, and `status_note` keeps the
original wording. ⚠️ **Do not restate a status in your own words while
converting.** That is the one way this migration can lose something, and it loses
it invisibly: the reworded version is indistinguishable from what the session
that did the work wrote.

**1. Split live from finished.** A plan is live if *any* item in it is unstarted —
not if it is mostly done. Check the actual state (grep the code, read the git log)
rather than trusting what the document claims; a plan that says "implemented" may
describe code that was later reverted.

**2. Before deleting a finished plan, harvest what would otherwise be
recomputed.** In order of how often it bites:

- **Unstarted follow-ups buried in a finished plan.** The commonest loss
- **Why an option was rejected.** Without it the next session re-derives the same
  dead end
- **Why a decision was reversed.** Both the old reasoning and what broke it
- **Traps that cost real time** — silent failure modes, dead code that looked like
  defence

Drop the rest: task checklists, status tables, step-by-step records of work that
shipped.

**3. Distribute, then delete — and record the closure in `GRAPH.md`.** Follow the
four steps and the distribution table above. **The index lives in one place only**
— a second copy is how the live list ends up wrong.

**4. If a document's content moved elsewhere, verify the move before deleting.**
Compare section lists, not file sizes. When the destination is another repo, name
it explicitly as the source of truth — a relative path that no longer resolves is
worse than no pointer.

**5. Repair dangling references — this is the step that gets skipped.** After
deleting, grep the whole tree *and the memory directory* for the removed
filenames. Memory files often say "the plan for handling this is `<plan>.md`" and
silently become wrong; a stale pointer also leaves a finished item looking
unfinished.

**6. Refresh `docs/`.** Research and analysis documents go stale without anyone
touching them, because they encode assumptions the conventions have since
changed. Check each one still matches the current schema, constants and open
questions.

**Do not erase history inside documents that stay.** Mark the outdated passage "as
of then" and add what changed.

**7. Notes — hold the principle (in context every session). Gauge 400 lines.**
Only **decisions that must not be reversed** and **traps that are easy to step on**
survive. Over the gauge, move things to their real homes. Session notes recording
only what happened get discarded; anything recording a trap does not.

**8. Check `GRAPH.md` against the actual tree.** The number of live pipelines,
whether each slug resolves to a file that exists, whether the advanced-dates match
the document banners. **Get this wrong and the next session loses its starting
point.**

Run cleanup over each of the session's project roots, not only the one you are
sitting in — a second project's workspace is exactly where stale notes hide.

Finish with `sync`, and report what was deleted and what survived — not a
file-by-file diff.
