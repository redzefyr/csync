# Why the rules are shaped the way they are

⚠️ **Do not read this file in order to do work.** `workspace.md` and
`document-format.md` are complete on their own: they are enough to write a
document, run a subcommand, or tidy a workspace. Read this one only when you are
**about to change a rule** in either of them, or when the user asks why a rule
exists.

This file is csync's own archive, and it exists for the reason csync gives its
users. The rules used to carry their origin incidents inline, so every session
loaded them — and a session that reads several hundred lines of incident
narration writes the user's documents in that register. Rules grew origin
stories, corrections were appended instead of applied, and the entry point
turned into a ledger. The rules stayed where they were; the reasons moved here.

Add to this file when a rule changes. An entry is **one incident and the rule it
produced** — not a running commentary on the rule's revisions.

---

## `workspace.md`

### The three directories are split by lifetime

Mixed together, every decision means reading all three; once that is true for
long enough, nobody reads any of them.

### The judgment test runs forward

**2026-08-30.** Every rule here was a preservation rule — fold, move, distribute,
mark "as of then". None permitted overwriting, so information only ever changed
address, and the one outlet, deleting a closed plan, fires rarely. Meanwhile
"write **why**" pulled in the route by which a judgment had been reached, and a
route can always be told at greater length: each cleanup pass found new defects
and recorded how it had found them, so the passes made the workspace bigger. A
backward test — "would it be a shame to lose this?" — cannot stop that, because it
answers yes to every line. Hence a forward test, and hence the explicit boundary
against folding: folding is the rule that has actually prevented losses, and
loosening it to make room would have swapped one failure mode for the other.

### The advanced-date must not rise for non-progress

Fixing a banner, correcting a typo, touching a file during cleanup — if the date
rises for those, the signal "how long has this been parked" dies, and that signal
is the only reason the filename carries two dates.

### Documents are referenced by slug, not by filename

Filenames carry dates, so they change every time a pipeline advances, and a
filename reference breaks with them. Files inside the project repo are exempt
because they move with the code — the reader already has them.

### One pipeline per project per session

The limit exists so each plan's hand-off is written while its context is still
loaded. Opening a second project to get a second pipeline produces two
half-written hand-offs instead of one good one, and the hand-off is the only
thing the next session has.

### `## findings` is a quarantine area

**2026-08-27.** A finding was written straight into the other plan's body and its
"next step" banner was rewritten on top of it. The finder does not know what that
pipeline should do first — the session that runs it does. Hence: entries go in
the block, the body is not touched, and the banner is not rewritten.

### The findings block's position is exact

The shape was already the rule and was already broken: one real block sat
entirely inside a blockquote with numbered entries. A reader that does not
recognise the block reports **zero pending findings**, and zero reads as "nothing
waiting" — the failure is silent and looks like good news. That is why the rule
is stated as an exact position rather than an example, and why the template is a
file to copy rather than prose to follow.

### Weighing a finding is not folding it

**2026-08-30.** In a real workspace, a session asked to continue a pipeline read
the plan's `## findings`, let one of them change its judgment about the next step,
and started work — leaving the entry exactly where it was. Nothing was lost and
nothing looked wrong, which is why it went unnoticed: an entry that is still there
reads as *not yet judged*, so every later session re-decides it, and the ones that
know it was settled are gone.

The diagnosis was **placement, not wording**. The fold rule was stated twice, in
`workspace.md`'s session-start steps and in `SKILL.md`'s `open` — both of which
require the skill to have loaded. The session that folds is usually driven by the
workspace's own `CLAUDE.md`, `GRAPH.md` and the plan, and none of those said
anything about findings; the one line that did reach it, the block's own heading,
read "fold these in when you start", which is fairly read as *take these into
account*. So the verdict vocabulary went in-band — into the heading, into prose
that travels with the block, into a comment marked to survive — and into the two
always-read files.

### There is no numeric threshold for escalating stalled findings

An earlier draft wanted one. A number invented to look decisive is one more
unfounded number in a file that already has to defend the one it has. The two
stated conditions are the test.

### `notes/` is capped, and the cap is a gauge

**2026-08-27, twice.** The original gauge was 300 lines. It was a Claude's
translation of the principle ("loaded every session, so keep it small") into a
number, written down without its reasoning — and a later session read the bare
number as a ceiling the user had set, then trimmed content to hit it. Two rules
came out of that: the number is derived from the principle and loses to it, and
folding means *moving*, not discarding. The gauge went to 400 at the same time,
because running over costs less than losing something while trimming.

### A decision carries who may revise it

**2026-09-01.** `notes/decisions.md` was titled "what must not be reversed" and had
one authority level, while its write paths mixed two sources: the user's explicit
instructions, and everything the closing table routes in at the end of a pipeline —
which is Claude's own conclusion. Two failures follow, both silent, and which one
occurs is settled by whichever reading the session arrives with. Read as the title
says, Claude's stale conclusions inherit the user's protection and the file
accumulates exactly as the preservation-only rules once made everything accumulate.
Read as the overwrite licence allows, the user's decisions lose theirs and change
without anyone choosing that.

The template already had a `{{WHO}}` slot, defined nowhere and read by nothing —
and *contradicted*, because "What survives" listed "who noticed it" as route, and
route gets overwritten. Adding a marker without amending that rule would have left
a cleanup session correctly stripping it. Hence the carve-out: who *noticed* is
route, who *decided* is authority, and authority passes the forward test because it
decides whether the next session may revise the entry at all.

### An unmarked decision is `held`, not a default

The obvious shape was "unmarked defaults to protected". Naming the third state
instead makes it visible and countable, so an unmarked entry cannot quietly harden
into something indistinguishable from a `mandate`. `held` is settled **when it is
actually in the way**, with the user, one entry at a time — never as a bulk pass,
which would have a session guessing at precisely what the marker exists to stop it
guessing at. The cost of an unsettled entry nobody has bumped into is zero, and it
is paid by whoever bumps into it.

The guard that carries the whole design is that **inferred intent is not a
mandate.** Without it, "the user would want this" marks itself `mandate`, the
protected tier swallows the file, and the distinction is back to one level.

### The gauge covers `GRAPH.md` and `notes/` together

**2026-08-30.** `notes/` was capped at 400 lines; `GRAPH.md`, read in the same
breath at every session start, was capped at nothing. A limit on one of two files
that are always read together is not a limit, and the measured sums were 734 and
544 lines. The 500 is the old 400 plus what a `GRAPH.md` at the structural cap
costs — stated that way so the next session that moves the number knows what it
is moving.

### `docs/` splits live from archive by directory, not by label

When two opposite lifetimes share a directory, a snapshot gets read as the
standard and the work proceeds from a stale premise. Labels are not enough.

**Precedent:** an archive schema changed while a live analysis guide still told
readers to look up the old keys. Hence "change a convention, revise the live docs
in the same session".

### The archive directory is named `archive/`

It was called `research/` for exactly one reason: `archive/` reads as "the pile
you can skip", and that directory holds the grounds on which a track was
abandoned — when those cannot be found, the same experiment gets run again.

**Reversed 2026-08-30, deliberately.** The lifetime rule was the thing that kept
breaking, and it broke because the directory names did not state it: `docs/*.md`
and `docs/research/` do not look like opposites, so live documents accumulated at
the root and the split had to be re-derived from prose every time. Naming the two
directories after their lifetimes locks the rule into the path. The "not the
skippable pile" point survives as a sentence in the rule, which is where it
should have been — a directory name is a poor place to carry an argument.

### `docs/design/` is design only

The live category used to read "analysis procedures, structural surveys, constant
tables, setup docs", which is broad enough that almost any document can argue its
way in — and documents that argue their way in are exactly the over-production
the workspace is meant to prevent. Narrowing live to *design decisions and the
criteria behind them* gives the category an edge. Deployment procedures,
structural surveys and analysis guides belong to the code, so they go to the
project repo, which `notes/`'s overflow rule already said.

### A user's mandate cannot live only in `docs/design/`

`design/` is live and revisable by rule — `revise_when` fires when the code
changes. A criterion the user fixed stops holding only when the user says so, so a
session correctly applying the revision rule would carry it off without noticing
there was anything to notice. Keeping the mandate in `notes/decisions.md` and
having the design document name that entry lets `revise_when` fire on the design
without touching what the user fixed. The alternative — a second authority marker
inside design documents — would put the same rule in two schemas, and the one that
is not read every session is the one that goes stale.

### `GRAPH.md`'s entries are free prose

Real entries carry emoji-led lines that no schema anticipated. A line a tool
cannot classify must be displayed, never dropped: dropping raises no error, and
the reader concludes it was never written.

### `GRAPH.md` gets a structural cap, not a line count

**2026-08-30.** The two indexes measured carried 28 struck-through entries and 155
date mentions between them — renames, corrected statuses, the whereabouts of
closed sections, all settling into the index. A line budget spread over the whole
file would have been met by trimming live entries instead, so the cap is per
pipeline, which is the unit a reader scans. The present-state rule names the thing
that was actually growing.

### Cross-repository pairs are recorded as a description, never a bare slug

On the day five plans were merged into two, five cross-repository references died
at once. A validation script only ever sees its own repo, so the break is silent;
a reader can still find the document when a fragment of what it does is written
next to the name.

### A closed section is folded at session end

**2026-08-30.** "Do not leave finished sections in a plan" was already the rule and
was already being broken: live plans of 1120, 757 and 680 lines, with headings
struck through and their bodies still standing underneath. The rule named no
moment, so no moment checked it. Session end is the moment because the session
that closed the section is the only one that knows what its one line should say.

### Closing a plan starts with verifying the code

There is precedent for a plan marked "shipped" that described an abandoned branch
with no code behind it at all. The document's claim about itself is not evidence.

### The commonest loss is an unstarted follow-up in a finished plan

Even a plan whose main work shipped almost always still holds "if we ever need X,
start here" items. That is why extraction comes before deletion, as its own step.

### Deleting requires a grep of the memory directory too

Memory files say "the plan for this is X" and go silently wrong when X is
deleted. A stale pointer also leaves a finished item looking unfinished.

### Cleanup reports two numbers

**2026-08-30.** "Report what was deleted and what survived" is qualitative, and a
run that dropped three checklists while adding four traps satisfies it completely
— which is what had been happening. A count taken before and after cannot be
satisfied that way. It measures the session-start reading rather than the whole
workspace because that is the cost these rules exist to hold down; `docs/archive/`
growing is the system working.

### "Harvest" made cleanup read for material

**2026-08-30.** The step deciding what leaves a finished plan told the session to
*harvest what would otherwise be recomputed*, and a session told to harvest reads
looking for things to write. The same four exceptions, stated as exceptions to
deletion, produce the opposite posture. Seven of cleanup's eight steps produce or
move text; the one step that decides what goes has to make deletion the default in
its own wording.

### Cleanup migrates document formats, and nothing else does

Converting a document is an edit to the user's own record. Doing it
opportunistically, in passing, while a session is doing something else, means the
user never chose it. A document with no frontmatter reads fine — it is legacy,
not broken.

### Converting a legacy plan moves the status text, never rewords it

A status reworded by a session that did not do the work is indistinguishable from
one the session that did wrote, so every session after takes it as fact. This is
the one way the migration can lose something, and it loses it invisibly.

### Reading the sync repo's history needs approval twice

A workspace advances by reversing and deleting — that is what capping `notes/`
and deleting plans on close *mean*. History therefore holds superseded judgments
stated with their original confidence, and nothing in the text marks them as
retired. Pulled back without that context, a rule the user already changed comes
back to life.

---

## `document-format.md`

### There is machine-readable frontmatter at all

Everything a tool needed used to be encoded in prose, so the tool matched strings
— labels in two languages, bold runs, colons — and a document that phrased a
field slightly differently was read wrong without saying so. Frontmatter costs
the raw-text reader nothing and gives the parser a carrier no sentence in the
body can collide with.

### Every prose value is a literal block scalar

A plain YAML scalar breaks on a colon, a leading `#`, a quote, or a `[`. All four
occur constantly in this corpus. A rule with an "unless it's simple" clause is a
rule that gets guessed at, so short values are no exception.

### Templates are copied, not reconstructed

Every deviation found in the wild so far came from a session rebuilding a header
from memory of a rule. A `cp` does not drift.

### `status` is a closed set and `status_note` is free

"How many pipelines are parked" is a question no prose status can answer, and the
words the session used are the only honest record of where the work stands. The
two needs are separate fields because one field cannot serve both.

### The plan body carries no status header

`status`, `next` and `blocked` used to open the file as a three-line blockquote.
A plan whose retired status was restated mid-document got promoted into listings
as the current one. In frontmatter they appear exactly once, and a body sentence
that reads like a status is just a sentence.

### `why_marker` is declared per file

The corpus is written in the user's language. Declaring the marker once per file
is cheaper and more honest than a parser that knows how to say "why" in every
language.

### The authority token sits in the heading

Same reasoning as `why_marker`, one level up in stakes: putting the token in a
fixed position is what makes "who may revise this" checkable, so a tool can show
which entries are `held`. A missing `why` costs a re-derivation; a missing
authority costs either a reversed mandate or a frozen guess. The vocabulary is
declared per file for the same reason `why_marker` is.

### A workspace's pointer to a template has to resolve from the workspace

**2026-09-01.** Three independent sessions working in a workspace, without the
skill loaded, all hit the same wall: `CLAUDE.md` and the notes told them to copy a
template from `templates/document/`, and no such path exists relative to a
workspace — the templates live in the skill. What they did instead was **invent
the frontmatter**: one wrote `csync: doc/1` and a `kind:` key onto a design
document, where the real schema is `design/1` with no `kind`. The instruction
"copy the template, do not rebuild the header from memory" was already there and
could not be obeyed, and an unobeyable instruction is worse than none, because the
session substitutes its best guess and reports success.

The fix is the resolvable path, not a copy of the templates inside each workspace —
a second copy of the canon is the thing this repo has already watched drift once.
The same reasoning applies to every pointer a workspace file makes into the skill.

### Conformance is part of the format

The plan header and the findings block were both schemas before this file
existed, and both were broken in the wild — because nothing ever showed the
deviation to anyone. Rules without a feedback loop decay.

### A tool reports and never repairs

A tool that quietly fixed a document would erase the judgment that `cleanup`
exists to make.
