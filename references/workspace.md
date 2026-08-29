# The workspace — `plans` · `notes` · `docs` · `GRAPH.md`

The directories **have different lifetimes**, and that is what the split is for.

| | what lives there | lifetime |
|---|---|---|
| `plans/` | **one pipeline = one file.** Work in progress or deliberately parked | **deleted** when it closes |
| `notes/` | **decisions that must not be reversed** and **traps that are easy to step on**. Only what has to be in context no matter what you are doing | permanent, but **capped** |
| `docs/design/` | **live** — design decisions and the criteria behind them | permanent, **revised** with the code |
| `docs/archive/` | **archive** — experiment results, measurements, feasibility reviews, the judgment of that day | permanent, **never revised** |

`GRAPH.md` sits at the workspace root, one per project, and is **the entry point,
read at the start of every session together with `notes/`**.

This file says what each directory is **for**. What the documents **look like** —
frontmatter keys, the `## findings` shape, the emoji vocabulary, what a tool may
read — is `document-format.md`; read it before creating or editing a document, and
**copy the template from `templates/document/` rather than rebuilding a header
from prose.**

⚠️ **`rationale.md` is not part of this.** It holds the incidents these rules came
out of, and is read **only when a rule is being changed** — never to do work.

## What survives — the grounds, not the route

**Keep the grounds a judgment stands on. Overwrite the route to it.** Grounds are
what a later session needs in order to keep or overturn the judgment. The route —
what was tried first, what was searched, who noticed it, what the text said before
it was corrected — moves nobody's next step, and unlike grounds it has no end.

**The test runs forward.** "Would it be a shame to lose this?" answers yes to
everything. Ask instead **"does the next session read this line and do something
different?"** No → it is not moved somewhere else, it is deleted. This holds for a
whole document, for a `GRAPH.md` entry, and **for each sentence inside one that is
otherwise staying.**

⚠️ **This is not licence to trim.** Folding *moves* a thing to its own home and
never drops it; the two are told apart by one question — **can you name the
destination?** If you can, it is folding, and it moves. Overwriting is only for
text no session needs anywhere. When both readings fit, fold.

## The budget for what every session reads

`GRAPH.md` **and** `notes/` are both read at every session start, so the limit is
on **their sum** — a capped file beside an uncapped one is an uncapped read.
`notes/` is held under it by its entry test, `GRAPH.md` by a structural cap.

**Gauge: 500 lines, `GRAPH.md` + `notes/` together.** Derived, not decreed:
`notes/`'s own gauge was 400, and a `GRAPH.md` at its cap holding a handful of
pipelines comes to about a hundred. **When the number and the principle behind it
disagree, the principle wins**; the number may be moved, but **write down why that
value, here, at the same time.**

⚠️ **Over the gauge, fold — never trim.** Running over costs less than losing
something while trimming.

## Reference documents by slug, not by filename

In document bodies, point at other documents with **`[[slug]]`** — filenames carry
dates and change, and resolving slug → file is `GRAPH.md`'s job. **Files inside
the project repo may be referenced by path** (`PROTOCOL.md` and the like): they
move with the code, so the reader already has them.

## `plans/` — the filename states the progress

```
plans/<planned>-<advanced>-<slug>.md     e.g. 20260820-20260824-search-index-rebuild.md
```

**The advanced-date is the day that pipeline actually moved.** Fixing a banner,
correcting a typo, touching it during cleanup — **none of those are progress.**

Every plan opens with **YAML frontmatter** carrying `status`, `next` and
`blocked`, so it can be judged without being opened; `status_note` carries the
prose version **in the words of the session that did the work.** Copy
`templates/document/plan.md`.

- **A plan holds no finished sections** — a one-line conclusion, evidence pushed
  into `docs/archive/`. Folding them is a "Session end" step
- **Advance one pipeline per project per session.** Cleanup, sync and simple
  lookups do not count. A session that has opened several projects may advance one
  pipeline **in each** — cross-repo pairs exist, and the side that goes second
  would otherwise start without the context the first just built.
  ⚠️ **Not licence to open more projects in order to get more pipelines.**
- **A session ends by updating that plan** — the three steps under "Session end"

### `## findings` — carried over from other work

While running one pipeline you often find **something another pipeline needs to
know**, and the one-per-session rule means you cannot go and fix it there. **Put
it in the other plan as a `## findings` block**, copied from
`templates/document/findings-entry.md`. ⚠️ **The position is exact** — a block in
any other shape reports **zero pending findings**, which is read as "nothing
waiting"; `document-format.md` has the shape.

⚠️ **The finder does not re-prioritise the other pipeline.** Do not add sections to
its body and do not rewrite its "next step" — **what comes first is decided by the
session that runs that pipeline.**

- **Do not raise the advanced-date.** The other pipeline did not move
- **Leave a marker on that entry in `GRAPH.md`** — `⚠️ findings x2 (08-27)` is
  enough; what is not visible from the entry point does not get found
- **The bar is "does it change the other side's premise, next step, or cost?"**
  "Good to know" fails, and "good to know" is what inflates plans
- **If the other side does not exist yet**, put it in the `GRAPH.md` backlog
- **In another repository, write the substance rather than a path** (the
  stand-alone rule in `SKILL.md`)

**Folding them in is the first job of the session that starts that pipeline.**
Each finding ends one of three ways — **promoted into the body** (only then does it
become a section and change the banner) · **moved to the backlog** · **rejected**
(one line saying so, then delete). Once folded, the entry is gone; **a finding
still sitting there is one that has not been judged.**

#### When the outlet will not open — **recommend it to the user**

A long-parked pipeline never opens the route that folds its findings in. **Say so
in the session report** when findings have **accumulated** far enough that the
plan's "next step" already looks stale, or when one **invalidates the other side's
premise** — that one is immediate, regardless of count.

> "**I'd open a separate session to tidy up `<slug>`.** It has N findings
>  waiting, and one of them touches that plan's premise."

**Do not handle it in this session**; whether to open it is the user's call.
⚠️ **Do not invent a numeric threshold** — those two conditions are the test.

## `notes/` — what goes into context every session

> **Principle (this is the source of truth)**: `notes/` holds **what any session
> must have in context, whatever it is working on**. Which is exactly why it is
> **kept small — so no session is made to read a large amount of context.**

Only two things survive:

1. **Decisions that must not be reversed** — write **why**: the ground that still
   holds, not the route that reached it
2. **Traps that are easy to step on** — prefer the ones that fail silently

**One test decides entry — "would starting work without knowing this make you
wrong?"** Yes → `notes`. No → somewhere else. **"Good to know" fails**, and that
category is most of the bulk.

Over the budget, fold during that session. What overflows usually has a home
already: the list of plans → `GRAPH.md`, conventions and procedures → the project
repo's `PROTOCOL.md`/`README.md`, machines and environments → memory, build steps
→ the workspace `CLAUDE.md`, measured numbers → `docs/archive/`.

⚠️ **Folding means moving, not discarding.** Deleting a trap or its reasoning to
hit a number turns this rule into a loss machine.

Session notes, scratch and logs do not belong in `notes/`. Use a scratchpad.

## `docs/` — **location is lifetime**

**`docs/` itself holds no documents**; everything sits in `design/` or `archive/`,
and which one it is decides whether it is ever revised again.

**`design/` is design, not documentation in general.** The test is *"does this
state how something is built, or the criterion something was built against?"* —
written down as `revise_when` in the frontmatter. Deployment procedures, structural
surveys, analysis guides and setup notes are **not** design: they belong to the
code, so they go in the project repo. A document that has to argue its way into
`design/` is one the workspace does not need.

**Archive is not "the stuff you can skip".** The reasoning behind an abandoned
track, and the grounds it was rejected on, live there — and when they cannot be
found, the same experiment gets run again.

When an archive document is overturned, do not delete it: mark the passage **"as of
then"** and add what changed. ⚠️ **This rule is `docs/archive/`'s alone.** A live
document, a plan and `GRAPH.md` are read as the present, so a superseded line in
one of them is corrected, not annotated.

⚠️ **Change a convention, revise the live docs in the same session.** Miss it and
the next analysis runs on the old premise.

## `GRAPH.md` — the entry point

The skeleton is in `document-format.md` and `init` scaffolds it. What belongs here
is what the file is *for*:

**One pipeline, five to eight lines** — the slug line, status, next step, any
markers. This is where you decide *which* pipeline to open, and that decision does
not need the pipeline's contents; what will not fit is plan body.

**A plan entry states the present, and only the present.** A rename, a corrected
status, where a section went when it closed — all of that lives inside the plan.
An index that also records how it came to say what it says stops being scannable.

**When to update it**: a document created or deleted, a pipeline's status changed,
a session closed. **Never keep the index in two places** — if `GRAPH.md` is wrong,
nothing else being accurate helps, because it cannot be reached.

**Always record cross-repository pairs**, or closing one side orphans the other.
Paths cannot be used, so write **the repository name plus a fragment of what the
document does** — ⚠️ never the slug alone, because a slug that changes over there
leaves this side pointing at a name that no longer exists, silently.

**When one side merges or renames a document, sweep the other in the same
session** — `grep -rn '<old-slug>'` over that workspace and the memory directory is
the whole job.

## Session start

1. Read `notes/` and `GRAPH.md`
2. Work out which pipeline the user's request belongs to. With no instruction,
   **ask which one to continue** — do not pick one yourself
3. **If that plan has a `## findings` block, fold it in first** — promote, backlog
   or reject. Until they are folded the "next step" may be stale
4. Run that one, and only that one

`/csync open <slug>` is steps 2 and 3 as one command, and the only thing that
renames the session (`SKILL.md`). The four steps stand on their own without it.

## During a session — finding something that belongs to another pipeline

Do not touch it where you found it. **Put it in the other plan's `## findings` and
leave a marker in `GRAPH.md`.** The pipeline you are running continues unchanged.

## Session end

1. **Update the plan's "next step."** A stale one is worse than none, because it
   reads as a step someone checked
2. **Raise the advanced-date** — only if the pipeline actually moved
3. **Fold every section this session closed into one line each.** This is the
   moment that rule fires; left to "eventually", nothing checks it, and a closed
   section left standing reads as work still on the table. ⚠️ **Striking a heading
   through is not folding** — the heading, the strike and the body all go, and the
   one-line conclusion stays

## Closing a pipeline — four steps before deleting

**The order matters.** Delete without this and the rule becomes a loss machine.

1. **Verify completion in the code** — grep the symbols, read the commits. Do not
   believe what the document says about itself
2. **Extract the unstarted follow-ups first.** This is where things die most often.
   Split them into a new plan or raise them to the `GRAPH.md` backlog
3. **Grep the slug and the filename across the whole tree and the memory
   directory.** Memory files say "the plan for this is X" and go silently wrong
4. **If it is paired with another repository, handle both together**

Then distribute the contents:

| what is in the finished plan | where it goes |
|---|---|
| a decision that must not be reversed, plus **why** | `notes/` |
| a trap that is easy to step on | `notes/` |
| the **verdict** on a rejected option ("do not try this again") | one line in `notes/` |
| the **numbers and experiments** behind that verdict | `docs/archive/` |
| measurements, instrumentation, comparison tables | `docs/archive/` |
| a design criterion that outlives the pipeline | `docs/design/` |
| unstarted follow-ups | a new plan, or the backlog (step 2) |
| checklists, status tables, step-by-step records | discard |

Finally **delete the plan file and leave one line under "closed pipelines" in
`GRAPH.md`.** The workspace is a git clone, so the full text stays in the
`prj/<name>` history.

## Cleanup

Pruning a workspace so a new session can trust it. There is nothing to run: read
the files, decide, edit, delete, then `sync`.

**Cleanup is a reduction, and it is measured.** Count the session-start reading
before and after — `wc -l GRAPH.md notes/*.md` — and report both numbers. **Ending
larger than it started is a failed cleanup**, whatever else was tidied, and it is
reported as one: "what was deleted and what survived" is satisfied by a run that
dropped three checklists and added four traps, and two numbers are not.

⚠️ **A defect found during cleanup is not itself something to write down.** Fix it
and move on. It earns a `notes/` entry only when **the condition that produced it is
still standing** — a trap in the original sense — and that entry says what to
avoid, never how this session came to find it.

Deletion is safe here: the workspace is a git clone, so anything removed stays in
`prj/<name>` history. Say so when you report, and give the branch name.
⚠️ **"Safe to delete" is not "free to read back"** — recovering something from that
history needs the user's approval twice, once to read and once to apply (**Two
repos** in `SKILL.md`).

**0. If the structure is the old shape, reorganise first**, or what you tidy just
piles up in the old place again. The old shapes: no `GRAPH.md` · `plans/` filenames
that are not `<planned>-<advanced>-<slug>` · hand-off notes and session logs in
`notes/` · **documents directly under `docs/`** · **a `docs/research/` directory**.

`docs/research/` → `docs/archive/`, wholesale. Documents at the root of `docs/` go
one of three ways: **design** → `docs/design/` · **the judgment of a day** →
`docs/archive/` · **procedures, surveys and guides that belong to the code** → the
project repo, the workspace copy deleted once the move is verified.

**Migrating documents to the frontmatter format belongs here and nowhere else.** A
document without frontmatter is legacy, not broken; converting one is an edit to
the user's own record, so it happens when they ask for cleanup — never
opportunistically, while a session is doing something else. Convert by **moving**
what is already there: a plan's leading blockquote becomes `status` /
`status_note` / `next` / `blocked`, keeping the original wording. ⚠️ **Do not
restate a status in your own words** — that is the one way this migration loses
something, and it loses it invisibly.

**1. Split live from finished.** A plan is live if *any* item in it is unstarted,
not if it is mostly done. Check the actual state — grep the code, read the git log
— rather than trusting what the document claims.

**2. A finished plan goes with the file. Four things are the exception — take those
out first.** In order of how often the loss bites:

- **Unstarted follow-ups buried in a finished plan.** The commonest loss
- **Why an option was rejected**, or the next session re-derives the dead end
- **Why a decision was reversed** — both the old reasoning and what broke it
- **Traps that cost real time** — silent failure modes, dead code that looked like
  defence

**Everything else goes with the file** — task checklists, status tables,
step-by-step records of work that shipped, and the account of how any of the four
above came to be known.

**3. Distribute, then delete — and record the closure in `GRAPH.md`.** Follow the
four steps and the distribution table above. **The index lives in one place only.**

**4. If a document's content moved elsewhere, verify the move before deleting.**
Compare section lists, not file sizes. When the destination is another repo, name it
explicitly as the source of truth.

**5. Repair dangling references — this is the step that gets skipped.** After
deleting, grep the whole tree *and the memory directory* for the removed filenames.

**6. Refresh `docs/design/`** against each document's own `revise_when`; they go
stale untouched, because they encode assumptions the conventions have since
changed. `docs/archive/` is not touched — an outdated passage there is marked "as
of then", not corrected.

**7. Notes — hold the principle** (in context every session). Only **decisions that must not be reversed** and
**traps that are easy to step on** survive; over the budget, move things to their
real homes. Session notes recording only what happened get discarded; anything
recording a trap does not.

**8. Check `GRAPH.md` against the actual tree** — the number of live pipelines,
whether each slug resolves to a file that exists, whether the advanced-dates match
the document banners, and whether any entry has outgrown five to eight lines or
started carrying its own history.

Run cleanup over each of the session's project roots, not only the one you are
sitting in — a second project's workspace is exactly where stale notes hide.

Finish with `sync`. Report the session-start reading before and after, then what was
deleted and what survived — not a file-by-file diff.
