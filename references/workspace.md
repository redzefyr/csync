# The workspace — `plans` · `notes` · `docs` · `backlog.md`

The directories **have different lifetimes**, and that is what the split is for.

| | what lives there | lifetime |
|---|---|---|
| `plans/` | **one pipeline = one file.** Work in progress or deliberately parked | **deleted** when it closes |
| `notes/` | **`decisions.md`** — the user's standing rules · **`knowledge.md`** — Claude's standing choices and the traps that are easy to step on. Only what has to be in context no matter what you are doing | permanent, **gauged per file** |
| `backlog.md` | work with no plan yet, one dated line each | an item leaves when it is done, promoted or dropped |
| `docs/design/` | **live** — design decisions and the criteria behind them | permanent, **revised** with the code |
| `docs/archive/` | **archive** — experiment results, measurements, feasibility reviews, the judgment of that day | permanent, **never revised** |

**`notes/` is the only thing read at the start of every session.** There is no
index file to read beside it: `~/.claude/skills/csync/scripts/csync-ledger.sh`
lists what the workspace holds, derived from the documents each time it runs
("The ledger").

This file says what each directory is **for**. What the documents **look like** —
frontmatter keys, the `## findings` shape, the emoji vocabulary, what a tool may
read — is `document-format.md`; read it before creating or editing a document, and
**copy the template from `~/.claude/skills/csync/templates/document/` rather than
rebuilding a header from prose.** ⚠️ **Write that path wherever a workspace file
points at a template.** A bare `templates/document/` does not resolve from inside a
workspace, so a session without this skill loaded cannot obey the instruction — and
what it does instead is invent the frontmatter, which is machine-read and therefore
wrong in a way nothing reports.

⚠️ **`rationale.md` is not part of this.** It holds the incidents these rules came
out of, and is read **only when a rule is being changed** — never to do work.

## An old-shape workspace — `cleanup` first, and nothing written around it

A workspace written under earlier rules has some of: `GRAPH.md`,
`notes/traps.md`, a `notes/decisions.md` that is `note/1` or has no `csync:` key,
no `notes/knowledge.md`, no `backlog.md`. (A kind newer than `note/2` is not the
old shape: it is reported as unknown, and read by nothing.) The notes'
frontmatter shows it at session start, and the ledger prints `OLD SHAPE` above
everything else.

⚠️ **Until `/csync cleanup` has migrated it, write nothing to `notes/`,
`backlog.md` or `GRAPH.md` — neither the new files nor the old ones — and close no
pipeline.**
Every one of those writes lands in a file this skill no longer reads or in one
that does not exist yet, and a file improvised now is overwritten or duplicated
when the migration runs. When something needs recording, **say it in the session
report and tell the user the workspace needs `/csync cleanup`**; the finding waits
in the conversation, not on disk.

Reading is unaffected, and so is working a plan: its frontmatter and body did not
change shape, so a session may advance one and update its `next` as usual, and
write a `## findings` entry into another plan. **Folding findings is where this
bites**: an entry whose verdict is *backlog* has nowhere to go, so **leave that
entry in its block** and say it waits for cleanup — deleting it would lose it, and
writing it to `GRAPH.md` feeds the old shape. Promote and reject work as usual.

**Do not take up a backlog item there either.** Its line lives in `GRAPH.md`, so a
finished item cannot be deleted and would be migrated as unstarted. If the user
asks for one anyway, say so first; cleanup asks the user about every backlog line
before migrating, so a finished one is dropped then.

## What survives — the grounds, not the route

**Keep the grounds a judgment stands on. Overwrite the route to it.** Grounds are
what a later session needs in order to keep or overturn the judgment. The route —
what was tried first, what was searched, who noticed it, what the text said before
it was corrected — moves nobody's next step, and unlike grounds it has no end.

⚠️ **Who *decided* it is not route — it is the authority to overturn.** "Who
noticed it" is route and goes; **who the decision belongs to** passes the forward
test above, because it decides whether the next session may revise the entry at
all. That is which file an entry sits in — `decisions.md` or `knowledge.md` — and
the token at the end of its heading, and both survive every fold, every cleanup
and every rewrite of the entry around it.

**The test runs forward.** "Would it be a shame to lose this?" answers yes to
everything. Ask instead **"does the next session read this line and do something
different?"** No → it is not moved somewhere else, it is deleted. This holds for a
whole document, for a backlog line, and **for each sentence inside one that is
otherwise staying.**

⚠️ **This is not licence to trim.** Folding *moves* a thing to its own home and
never drops it; the two are told apart by one question — **can you name the
destination?** If you can, it is folding, and it moves. Overwriting is only for
text no session needs anywhere. When both readings fit, fold.

## Gauges — each file carries its own

A file that is read at every session start, or that piles up between sessions,
declares **`gauge: <max>/<alarm>`** in its own frontmatter (`document-format.md`,
rule 6). The unit is lines of the whole file. There is no shared budget across
files: what each one can do when it runs over differs by **whose entries it
holds**, so one number over several would make a file Claude cannot fold squeeze
the one it can.

| file | default | past it |
|---|---|---|
| `notes/decisions.md` | `/200` — alarm, no max | **tell the user**, and stop there. Nothing in it is Claude's to fold |
| `notes/knowledge.md` | `300/` — max | **fold first** (below); only when nothing can move, **ask to raise the max**, with the line count and the value proposed |
| `backlog.md` | `50/` — max | **propose** — the items that meet the plan test, the ones gone stale, or a higher max — and act only on a yes. The proposal does not hold up what the session was doing, `open` included |

**When the gauge is reported — once per file per session, and only at these two
points:**

1. **At `/csync open`**, for the project being opened — a file already past its
   max or alarm is reported before the plan's header
2. **After a write to a gauged file** — run `csync-ledger.sh gauges`; a file that
   shows past its max or alarm and has not yet been reported this session is
   reported now. The script cannot tell a file that just crossed from one that
   was already over, and does not need to: the first time this session sees it is
   the moment it is said

**Who folds `knowledge.md`.** Reporting and folding are separate. **A session that
writes to `knowledge.md` leaves it under its max** — folding before it finishes,
then asking to raise the max if nothing can move — whether the file was reported
at `open`, after an earlier write, or not at all this session. A session that only
opened a plan and never wrote there **reports and proposes, and does not fold**:
it goes on to the plan, and the fold is the user's to ask for, or `cleanup`'s.

⚠️ **A max never blocks a write, and it is never met by trimming.** Write the
entry, then fold. Running over costs less than losing something while trimming.

⚠️ **A default is not the user's ceiling.** The template values are a starting
point; a number the user raised is theirs. Raising one is always the user's call —
never write a new value without their yes.

## Reference documents by slug, not by filename

In document bodies, point at other documents with **`[[slug]]`** — filenames carry
dates and change, and `csync-ledger.sh resolve <slug>` finds the file, or the
closed-pipeline line once the file is gone. **Files inside
the project repo may be referenced by path** (`PROTOCOL.md` and the like): they
move with the code, so the reader already has them.

## `plans/` — the filename states the progress

```
plans/<planned>-<advanced>-<slug>.md     e.g. 20260820-20260824-search-index-rebuild.md
```

**Both dates are `YYYYMMDD`, no separators**, and so is a backlog item's date.
The slug is whatever follows the two date fields, so the fixed width is what lets a
name be split without guessing — and, more to the point, what makes a **malformed**
one visible: `20260820-search-index-rebuild.md` is missing a date and fails on
sight, while a dashed equivalent still consumes six fields and yields nonsense.

⚠️ **Dashed dates are the old shape.** Read them, report them as legacy, and leave
the rename to `cleanup` — the same treatment the old `csync:` kind names get.

**The advanced-date is the day that pipeline actually moved.** Fixing a banner,
correcting a typo, touching it during cleanup — **none of those are progress.**

Every plan opens with **YAML frontmatter** carrying `status`, `next` and
`blocked`, so it can be judged without being opened; `status_note` carries the
prose version **in the words of the session that did the work.** Copy
`~/.claude/skills/csync/templates/document/plan.md`.

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
`~/.claude/skills/csync/templates/document/findings-entry.md`.
⚠️ **The position is exact** — a block in
any other shape reports **zero pending findings**, which is read as "nothing
waiting"; `document-format.md` has the shape.

⚠️ **The finder does not re-prioritise the other pipeline.** Do not add sections to
its body and do not rewrite its "next step" — **what comes first is decided by the
session that runs that pipeline.**

- **Do not raise the advanced-date.** The other pipeline did not move
- **Nothing else to mark.** The ledger counts the entries from the block itself,
  so the count shown beside that plan cannot outlive the block
- **The bar is "does it change the other side's premise, next step, or cost?"**
  "Good to know" fails, and "good to know" is what inflates plans
- **If the other side does not exist yet**, put it in `backlog.md`
- **In another repository, write the substance rather than a path** ("Each
  workspace must stand alone", below)

**Folding them in is the first job of the session that starts that pipeline** —
before the plan's "next step", which a finding may already have made stale.
Each finding ends one of three ways — **promoted into the body** (only then does it
become a section and change the banner) · **moved to the backlog** · **rejected**
(one line saying so, then delete). Once folded, the entry is gone; **a finding
still sitting there is one that has not been judged.**

⚠️ **Weighing a finding is not folding it.** Letting it change what you do and
leaving the entry in place leaves no trace that it was judged, so the next session
meets it and decides it again.

**When the last entry goes, delete the block, heading and all** — a heading left
with no entries under it is counted as `?`, a hand-off in a shape nothing can
read. **The prose under the heading and the `KEEP THIS COMMENT` comment travel with
the block**, because it lands in a plan whose session may never load this file.
⚠️ Copies written before `GRAPH.md` was retired tell the folder to backlog into
`GRAPH.md`; that means `backlog.md`.

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

Two files, split by **whose** entries they hold — which is also who may revise
one:

| file | holds | entry | past its gauge |
|---|---|---|---|
| `decisions.md` | **the user's standing rules** — `mandate`, and `held` until settled | the user stated a rule meant to outlast the task, and confirmed its wording and why | alarm to the user only |
| `knowledge.md` | **Claude's standing choices** (`judgment`) and **traps that are easy to step on** (`trap`) | the two tests below | fold first, then ask to raise the max |

Both write **why** — the ground that still holds, not the route that reached it.

### `decisions.md` — the user's

**An entry is written when the user states a rule meant to hold beyond the task at
hand.** Calling it a rule, a convention, a design or a spec is the usual sign; the
words are examples, not the test — "never do X again" is a rule with none of them,
and "what do you think of this design?" is a question with one. **Read the wording
and the reason back and write it only once confirmed.** ⚠️ **If the user gave no
reason, ask.** A reason Claude supplies here is recorded as the user's, and the
next session defends it as theirs.

**Nothing in it is folded by Claude** — not into a comment, not into
`docs/design/`, not to meet a number. Past the alarm, the user is told
("Gauges"); retiring or merging a rule is theirs.

### `knowledge.md` — Claude's

**Two tests decide entry, and an entry needs both.**

1. **Necessity** — "would starting work without knowing this make you wrong?"
   No → it does not go here. **"Good to know" fails**, and that category is most
   of the bulk
2. **Reach** — **"where is the reader standing when it fires?"** Inside one
   routine, one type, one interface → **a comment at that code site, not here**

**The second test is what the first one lets through.** `notes/` is read at
session start, *before* anyone knows which files this session touches — so a
thing that fires only once one file is already open passes test 1 on its merits
and still has no business here. ⚠️ **This is an entry rule, not a fold.** It does
not wait for a gauge: an entry that fails test 2 was never `notes/` material, and
the session that writes it anyway has already charged every later session for it.
"Where the reader stands decides the home" below is the whole rule.

**A session that writes past its max folds during that session — before asking
for more room** ("Gauges"). What
overflows usually has a home already: a single-site entry → a comment there,
conventions, procedures and build steps → the project repo's
`PROTOCOL.md`/`README.md`, machines and environments → memory, a criterion →
`docs/design/`, measured numbers → `docs/archive/`. ⚠️ **Not the workspace
`CLAUDE.md`**: it is loaded with every note, so a fold into it clears the gauge and
charges every session the same lines. **A `judgment`
whose ground no longer holds and a `trap` whose condition is gone are deleted** —
that is revision, which this file is Claude's to do, and it is said in the session
report. Only when nothing is left that can move, **ask the user to raise the max**,
with the current line count and the value proposed.

⚠️ **Folding means moving, not discarding.** Deleting a live trap or its reasoning
to hit a number turns this rule into a loss machine.

Session notes, scratch and logs do not belong in `notes/`. Use a scratchpad.

### Authority — which file, and which token

A decision reached by working and a decision the user handed down read identically
once written, and they are not the same thing. **The file says whose it is, and
the token at the end of the heading says it again** — declared per file as
`authority_markers` and `entry_markers` (`document-format.md`), because the corpus
is not written in English.

- **`mandate`** (`decisions.md`) — the user decided it, explicitly. **Raise it and
  let them decide** when the work argues against it; never revise it yourself, and
  never quietly route around it, which is the same reversal with the objection
  left unsaid. ⚠️ **Inferred intent is not a mandate.** "They would want this" is a
  `judgment`, and writing it into `decisions.md` inflates the protected file until
  nothing in it can move and the distinction stops meaning anything
- **`held`** (`decisions.md`) — not settled, and how an **unmarked** entry there
  reads. Treat it as a `mandate`, and settle it **the first time it is actually in
  the way**: say it is `held`, say which way you read it and why, and agree it with
  the user — settled as Claude's, it moves to `knowledge.md` as a `judgment`.
  ⚠️ **Not a migration to run through the file** — a bulk pass would have you
  guessing at exactly the thing the marker exists to stop you guessing at
- **`judgment`** (`knowledge.md`) — Claude concluded it. **Revise it without asking
  once its ground stops holding** — that is what writing the ground down is *for* —
  and say in the session report that you did, and what changed
- **`trap`** (`knowledge.md`) — easy to step on; prefer the ones that fail silently

**Authority is not the writer's to choose.** A decision that came out of doing the
work — including everything the closing table routes into `notes/` — is a
`judgment` in `knowledge.md`. It becomes a `mandate` only when the user affirms it,
and moving it to `decisions.md` then is the one change of authority that needs no
further discussion.

### Where the reader stands decides the home

**Ask where the reader is standing when they step on it.** A trap you can only
meet by editing one routine, one type, one interface — or by calling it wrong
from a site its signature already leads to — is caught by a comment there and
missed by `notes/`. Nobody reads `notes/` *because* they opened that file; they
read it at session start, before they know which files this session touches. The
comment reaches the reader who is about to be wrong. The note charges every
session in the project for the same context and reaches them by luck. **And it
expires correctly**: a `notes/` entry about a routine that no longer exists sits
there forever, because nothing checks — the comment goes when the routine goes.

The same holds for a `judgment` when the choice is settled inside one
implementation and nothing outside it can be wrong about it.

It stays in `notes/` when there is no single site to hang it on:

- it fires from **callers that never open the file** — a class of call sites, an
  ordering constraint between two subsystems
- it is about **code that is not there** — an approach not to try again, a
  defence deliberately left out
- it holds **across the project**, so a comment at one site would need a copy at
  every other

⚠️ **Write the comment and read it back before deleting the entry.** This fold
crosses a repo boundary — a different clone, a different history — and run
halfway it leaves nothing anywhere.

⚠️ **Write it for someone reading the code, not for the next session.** The date,
the slug, who found it, what was tried first: all route, and all of it reads as
noise to whoever maintains that file, so it gets dropped in the next refactor and
takes the trap with it. `[[slug]]` does not resolve there either. State what goes
wrong and what to do instead, in the language and comment style of the code
around it.

⚠️ **Nothing in `decisions.md` moves here — neither a `mandate` nor a `held`.** A
comment is revised by anyone who touches that code, including someone with no
access to the workspace — the same reason a mandate cannot live only in
`docs/design/`. The entry stays in `notes/decisions.md`; the comment may restate it
in one line.

⚠️ **The diff is comments only, and it is reported.** This edits the project repo
as a side effect of tidying the workspace, so say which files got comments and
leave committing them to that repo's own rules — a `notes/` count that fell
because unreported changes landed in the user's code is not the reduction they
asked for.


## `docs/` — **location is lifetime**

**`docs/` itself holds one document and no others** — `closed-pipelines.md`, the
log a closed slug resolves to. Everything else sits in `design/` or `archive/`,
and which one it is decides whether it is ever revised again.

⚠️ **The exception is that one filename, not a tier.** This rule exists to stop an
unclassified pile forming at the root, and a fixed name cannot become one — a
second document there is the old shape returning. It sits outside both
directories because it belongs to neither: `design/` is revised when the code
changes, `archive/` is the judgment of a day, and this is an index that is only
ever appended to. ⚠️ **Its kind is `archive/1`, and that is not a directory.** A
log filed under `docs/archive/` is misfiled — the ledger reports it, and `cleanup`
moves it to the root.

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
document, a plan, `notes/` and `backlog.md` are read as the present, so a
superseded line in one of them is corrected, not annotated.

⚠️ **Change a convention, revise the live docs in the same session.** Miss it and
the next analysis runs on the old premise.

⚠️ **`design/` is revisable by rule, so a user's mandate cannot live only here.**
`revise_when` fires on the code changing; a mandate stops holding only when the
user says so, and a session correctly applying the revision rule takes the mandate
with it without noticing there was one. **The mandate goes in `notes/decisions.md`
marked `mandate`, and the design document says in one line that it rests on that
entry.**

## The ledger — derived, never kept

There is no index file. Run from a project root,
`~/.claude/skills/csync/scripts/csync-ledger.sh` prints what the workspace holds,
read from the documents each time:

| | what it shows | used by |
|---|---|---|
| *(no argument)* | plans — status, next, findings count, blocked, pairs — then the backlog, then anything out of shape | `list`, and so the end of a `sync` |
| `docs` | `docs/design/` with each `revise_when`, `docs/archive/` with date and title, the closed-log count | finding the document a task needs |
| `gauges` | every gauged file against its `<max>/<alarm>` | `open`, and after writing a gauged file |
| `resolve <slug>` | the file a `[[slug]]` names, or its line in `docs/closed-pipelines.md` | following a reference |

**Why there is no file.** An index a session keeps is one more thing to update at
every create, rename, close and fold, and every miss reads exactly like a current
line — a findings marker with no block behind it, a status one edit behind its
plan. A derived listing cannot be behind. It is also not read at session start:
the lookup costs its tokens when someone is looking.

⚠️ **The ledger reports and never repairs.** Anything under "out of shape" is
`cleanup`'s, and `cleanup` is the user's to ask for. Its values are trimmed to one
line and never reworded, and so are they when you relay them.

**Order is status, then most recently advanced.** Nothing records "the leading
pipeline" apart from that: a pipeline that should lead says so by being `active`,
and one that should not by being `waiting` or `parked`.

**Record cross-repository pairs in the plan's `pairs`**, or closing one side
orphans the other. Paths cannot be used, so write **the repository name plus a
fragment of what the document does** — ⚠️ never the slug alone, because a slug that
changes over there leaves this side pointing at a name that no longer exists,
silently.

**When one side merges or renames a document, sweep the other in the same
session** — `grep -rn '<old-slug>'` over that workspace and the memory directory is
the whole job.

## The backlog — work with no plan yet

`backlog.md`, at the workspace root, holds **one dated line per item** —
`- YYYYMMDD <what>` (`document-format.md`). It fills from two places: a finding
whose other side does not exist yet, and the unstarted follow-ups extracted when a
pipeline closes.

It sits outside `notes/` because it is not something every session must know: it
is what a session with no pipeline open picks work from, and the ledger shows it
there.

**Not everything needs a plan.** A backlog item may simply be done — in a session
that has another pipeline open, or in one that has none. Doing it is **not opening
a pipeline**: a pipeline is opened by working a *plan* (`SKILL.md`), so a backlog
item does not spend the one-per-project budget and does not rename the session.

**Distribute it anyway when it is done.** There is no plan file to close, but the
contents go to the same places as a closing plan's — the table under "Closing a
pipeline" (`references/cleanup.md`) applies unchanged. ⚠️ **Then delete the backlog line in the same
session.** An item finished but still listed is indistinguishable from one nobody
has started, and the next session either does it a second time or stops trusting
the index.

**Promote it to a plan when it stops being one line.** The test is not size; it is
whether something has to be **carried between sessions**:

- more than one step, and their **order matters**
- it will not finish in the session that starts it, so a **next step** has to
  survive that session
- another pipeline is likely to find something for it — a finding needs a
  `## findings` block to land in, and only a plan has one
- it is paired with work in another repository, which has to be recorded as a pair

⚠️ **Meeting the bar is grounds for proposing, never for promoting.** Say which
test it met and what the plan would cover, then **wait for an explicit yes.** A
session that promotes on its own has decided what the project's next sessions are
offered: a plan becomes one of the pipelines every `list` shows. That is the same
reason `list` is not a menu and `open` is the user's to ask for (`SKILL.md`) —
taking work up, and creating work to be taken up, are decisions, never fallbacks.

Once approved, promotion is a file from
`~/.claude/skills/csync/templates/document/plan.md` and **the
backlog line removed in the same edit** — an item that is both a plan and a
backlog line gets done twice or not at all.

⚠️ **The backlog is not a second `plans/`.** An item that has sat there through
several cleanups without being done or promoted — its date says how long — is one
nobody intends to do, and leaving it there funds the appearance of a tracked queue.
⚠️ **Say so and propose dropping it — name the item, then wait**, exactly as with
promotion and for the same reason: **neither way out of the backlog while the work
is still undone is a session's to take alone.** Deleting the line of an item you
have just finished is not that — it records a fact.

**Past its max, the same holds.** Propose — the items that meet the plan test, the
ones gone stale, or a higher max — and wait. A full backlog is not a reason to
promote anything: the test above is.

## Each workspace must stand alone

`prj/<name>` branches are orphan histories. A path into another project's
workspace resolves on your disk today and nowhere else — not on another machine,
not in a session that opened only that project.

So when one project's notes need something another project decided, **copy the
substance in, with attribution and a date**. Do not link.

```
> 2026-08-21, carried over from the protocol-lib side:
> `Entry` field numbers were renumbered — ship server first, then clients.
```

The cost is duplication that can drift. The alternative is worse: a session
opened alone on that project reads a dangling reference, or reads a stale local
note and concludes the work never happened. State the fact and its date rather
than pointing at it.

**Files inside the project repo are different** — the reader has those. Point at
`PROTOCOL.md` or `README.md` freely; they travel with the code.

When you notice one project's workspace describing work that has since shipped
elsewhere, fix it in that project, not in the one you happen to be sitting in.

## Session start

1. Read `notes/` — `decisions.md` and `knowledge.md`. The workspace `CLAUDE.md`
   comes with them; Claude Code loads it on reading a file under the workspace
2. Work out which pipeline the user's request belongs to — the ledger lists them.
   With no instruction, **ask which one to continue** — do not pick one yourself
3. **If that plan has a `## findings` block, fold it in first** — promote, backlog
   or reject. Until they are folded the "next step" may be stale
4. Run that one, and only that one

`/csync open <slug>` is steps 2 and 3 as one command, and the only thing that
renames the session (`SKILL.md`). The four steps stand on their own without it.

## During a session — finding something that belongs to another pipeline

Do not touch it where you found it. **Put it in the other plan's `## findings`.**
The pipeline you are running continues unchanged.

## Session end

1. **Update the plan's "next step."** A stale one is worse than none, because it
   reads as a step someone checked
2. **Raise the advanced-date** — only if the pipeline actually moved
3. **Fold every section this session closed into one line each.** This is the
   moment that rule fires; left to "eventually", nothing checks it, and a closed
   section left standing reads as work still on the table. ⚠️ **Striking a heading
   through is not folding** — the heading, the strike and the body all go, and the
   one-line conclusion stays


## Closing a pipeline, and cleanup

Both are in `references/cleanup.md`. **Read it before closing a pipeline** — when
the user says one is done — **and when `/csync cleanup` runs.** Neither happens in
an ordinary session, so neither is paid for by one.

⚠️ **Closing starts with verifying completion in the code and extracting the
unstarted follow-ups, before anything is deleted.** A plan deleted without those
two steps takes the work nobody started with it, and nothing reports the loss.
