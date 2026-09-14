# Closing a pipeline, and cleanup

Read with `workspace.md`, which says what each directory is for; this file is what
to do when a pipeline ends and when the user asks for `/csync cleanup`.

## Closing a pipeline — four steps before deleting

⚠️ **Not in an old-shape workspace.** Closing distributes into `notes/knowledge.md`
and `backlog.md`; until `cleanup` has migrated the workspace, say the pipeline is
ready to close and that cleanup comes first ("An old-shape workspace" in
`workspace.md`).

**The order matters.** Delete without this and the rule becomes a loss machine.

1. **Verify completion in the code** — grep the symbols, read the commits. Do not
   believe what the document says about itself
2. **Extract the unstarted follow-ups first.** This is where things die most often.
   Add them to `backlog.md`, one dated line each. One that already meets the plan
   test is **proposed** as a plan, and becomes one only on the user's yes
   (`workspace.md`, "The backlog")
3. **Grep the slug and the filename across the whole tree and the memory
   directory.** Memory files say "the plan for this is X" and go silently wrong
4. **If it is paired with another repository, handle both together**

Then distribute the contents:

| what is in the finished plan | where it goes |
|---|---|
| a standing choice, plus **why** — marked `judgment`, since it came out of the work | `notes/knowledge.md` |
| a trap that is easy to step on | `notes/knowledge.md`, marked `trap` |
| either of those two, when **one routine, type or interface** is its whole scope | a comment at that code site |
| the **verdict** on a rejected option ("do not try this again") | one `judgment` in `notes/knowledge.md` |
| a rule the user set during the work | `notes/decisions.md` — only once they confirm its wording and why |
| the **numbers and experiments** behind that verdict | `docs/archive/` |
| measurements, instrumentation, comparison tables | `docs/archive/` |
| a design criterion that outlives the pipeline | `docs/design/` |
| unstarted follow-ups | the backlog, or a plan the user approved (step 2) |
| checklists, status tables, step-by-step records | discard |

Finally **delete the plan file and append one line to
`docs/closed-pipelines.md`** — copy
`~/.claude/skills/csync/templates/document/closed-pipelines.md` on the first
close. That line is where the slug resolves from now on. After writing to
`notes/` or `backlog.md`, run `csync-ledger.sh gauges` ("Gauges" in
`workspace.md`). The workspace is a git clone, so the full text stays in the `prj/<name>` history.

## Cleanup

Pruning a workspace so a new session can trust it. There is nothing to run: read
the files, decide, edit, delete, then `sync`.

**Cleanup is a reduction, and it is measured.** Count the session-start reading
before and after — `wc -l CLAUDE.md notes/*.md`, the workspace `CLAUDE.md`
included because reading a note loads it. "What was deleted and what
survived" does not satisfy this: it is equally true of a run that dropped three
checklists and added four traps, and two numbers are not.

**Report the change as two columns**, because a cleanup does two jobs and only one
of them is pruning:

```
pruned      -180
migrated     +26     frontmatter keys, template headers
```

**Ending larger than it started is a failed cleanup, judged on the pruning column
alone.** Migration is the other job — cleanup is the only thing that migrates
document formats — and what it adds is required by the format, bounded, and
attributable line by line, so it neither excuses a run that pruned nothing nor
condemns one that pruned well. ⚠️ **The migration column is what the format
requires, not what this session felt like adding.** Anything you cannot point at a
template or a frontmatter key for goes in the pruning column, where it counts
against the run.

⚠️ **The unit is lines, and it stays lines.** Context is what the budget is really
about, but nothing here can count tokens and the number would move under you when
the model changes, leaving two sessions' figures incomparable. Bytes track the
real cost better, but a gauge and this report both need figures two sessions can
compare, and lines are the one unit both sides of that comparison can count.

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
piles up in the old place again.

⚠️ **Before migrating anything, two things must hold, in this order:**

1. **Every machine linked to this sync repo runs the updated skill.** Ask; this is
   the one only the user can answer. An older skill recreates `GRAPH.md`, writes
   judgments back into `decisions.md` and traps into `traps.md` — and step 2's
   change reaches every linked machine, not only the ones that sync this workspace
2. **No older copy of the rules is still in force.** csync's rules reach each
   machine as a link into its own skill (`~/.claude/rules/csync.md`), so updating
   the skill updated them. What can still send a gate-closed session to
   `GRAPH.md` is a leftover **csync section in the global `CLAUDE.md`**, from
   before the rules were linked — check it yourself, do not ask. If one is there,
   propose removing it, and apply it on a yes. Do it after 1, not before: the
   global `CLAUDE.md` is shared, and a machine that has not run the new
   `install.sh` has no rules link to fall back on

**Without both, cleanup stops here and writes nothing** — not the migration, not
steps 1–8, which distribute into and prune files that do not exist yet in the new
shape. Say what is waiting and for whom. A half-migrated workspace is the one both
versions misread.

⚠️ **Do not sync until the migration is complete, and ask the user to leave other
sessions on this project idle meanwhile.** A push halfway through — this session's
or another window's own sync — hands every other machine the half-migrated
workspace.

**Run `csync-ledger.sh` and start from its "out of shape" list** — it names every
old shape it can decide from the tree. Beyond that list: hand-off notes and
session logs in `notes/`, and a workspace `CLAUDE.md` carrying copies of the rules.

⚠️ **Copy a template only where the file does not exist.** Where it does, merge
into it — never copy over it.

**Work in this order.** The `OLD SHAPE` reasons print in it too; every reason the
banner lists is cleared by one of these steps.

**a. `notes/knowledge.md` — create it and set its markers, before anything moves
in.** If it already exists, keep the markers it declares and use those below. If
it is absent, copy `~/.claude/skills/csync/templates/workspace/notes/knowledge.md`
and set, in the corpus's language: `why_marker` and
`entry_markers.judgment` to what the old `decisions.md` declares for `why_marker`
and `authority_markers.judgment`; where it declares nothing (no frontmatter), to
the words its entries actually use; `entry_markers.trap` to a word in the same
language. ⚠️ **Skip this and nothing reports it**: moved entries keep their old
tokens, the file declares English ones, and the next cleanup reads every judgment
as unmarked and files it as a trap.

**b. `backlog.md`** — copy `~/.claude/skills/csync/templates/workspace/backlog.md`
if absent.

**c. `notes/traps.md`** (whether `decisions.md` is `note/1` or already `note/2`) —
move every trap into `knowledge.md` with `(<trap>)` appended to its heading,
`<trap>` being the value set in a. Delete `traps.md` once every entry is across.

**d. `notes/decisions.md` that is not `note/2`** (with or without `traps.md`) —
move every entry marked `judgment` into `knowledge.md` unchanged. Then switch the
file to `note/2`: `authority_markers` keeps `mandate` and `held` in the words the
file already uses (or the words its entries use, when it had no frontmatter) and
loses `judgment`; `gauge` is added; and **the header prose under the title is
replaced from `~/.claude/skills/csync/templates/workspace/notes/decisions.md`**,
because the old prose tells sessions to write judgments there. **`held` and
unmarked entries stay** (below).

**e. `GRAPH.md`** — its backlog lines go to `backlog.md`, **except items the user
confirms are already done.** An old-shape workspace could not delete a finished
item's line, and no earlier session's report is on disk, so **show the user every
backlog line and ask which are done** — checking the code or the git log first
where a line names something checkable — before carrying any over as unstarted. Prose under a plan's entry that still states something true
goes into that plan — `status_note` only in the words already there — and the rest
is route. Then delete the file. The `docs` and `notes` listings go with it: the
ledger derives them.

**f. The rest of the list**, in any order:

- **backlog lines without a date** → prefix today's `YYYYMMDD`: it reads "listed
  since at least", which is true
- **a `knowledge.md` entry with no kind token** → `judgment` when it carries a
  reason paragraph opening with `why_marker`, otherwise `trap`. Both are Claude's,
  so this settles a format, not an authority
- **a closed-pipeline log under `docs/archive/`** → `docs/closed-pipelines.md`.
  If both exist, merge newest first and keep every line
- **`## findings` blocks whose prose says `GRAPH.md`** → rewrite that prose from
  `~/.claude/skills/csync/templates/document/findings-entry.md`; the `###` entries
  are not touched
- **a workspace `CLAUDE.md` carrying rules** → cut it back to the template's shape:
  the description, the pointer lines, and project facts such as `## LSP`. It is
  loaded whenever a note is read, so every rule copy in it is paid for every
  session and goes stale with the next skill update

`docs/research/` → `docs/archive/`, wholesale. Documents at the root of `docs/`
other than `closed-pipelines.md` go one of three ways: **design** →
`docs/design/` · **the judgment of a day** → `docs/archive/` · **procedures, surveys and guides that belong to the code** → the
project repo, the workspace copy deleted once the move is verified.

**Migrating documents to the frontmatter format belongs here and nowhere else.** A
document without frontmatter is legacy, not broken; converting one is an edit to
the user's own record, so it happens when they ask for cleanup — never
opportunistically, while a session is doing something else. Convert by **moving**
what is already there: a plan's leading blockquote becomes `status` /
`status_note` / `next` / `blocked`, keeping the original wording. ⚠️ **Do not
restate a status in your own words** — that is the one way this migration loses
something, and it loses it invisibly.

⚠️ **The same rule bounds the authority markers.** Moving an entry that already
says `judgment` into `knowledge.md` is a format migration and belongs here.
**Assigning authority to an entry that has none is not** — there is nothing to move
it from, so it would be a guess, and the entry stays in `decisions.md` as `held`
until the session that meets it settles it with the user. A cleanup run that
sorted unmarked entries between the two files would be inventing the one thing the
file split exists to record.

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

**3. Distribute, then delete — and append the closure to `docs/closed-pipelines.md`.**
Follow the four steps and the distribution table above.

**4. If a document's content moved elsewhere, verify the move before deleting.**
Compare section lists, not file sizes. When the destination is another repo, name it
explicitly as the source of truth.

**5. Repair dangling references — this is the step that gets skipped.** After
deleting, grep the whole tree *and the memory directory* for the removed filenames.

**6. Refresh `docs/design/`** against each document's own `revise_when`; they go
stale untouched, because they encode assumptions the conventions have since
changed. `docs/archive/` is not touched — an outdated passage there is marked "as
of then", not corrected.

**7. Notes — hold the principle** (in context every session). `decisions.md` is
the user's and is not pruned by this run — past its alarm, say so. In
`knowledge.md` only **standing choices whose ground still holds** and **traps whose
condition still stands** survive; past its max, move things to their real homes —
**including into the code itself**, for an entry one routine, type or interface is
the whole scope of ("Where the reader stands decides the home"). ⚠️ **Never trim a
live entry to meet the max** — when nothing is left that can move, ask the user to
raise it, with the line count and the value proposed. Session notes recording only
what happened get discarded; anything recording a trap does not.

**8. Run `csync-ledger.sh` again, and `csync-ledger.sh gauges`.** **No `OLD SHAPE`
line may remain** — while it prints, the workspace takes no writes. The "out of
shape" list should be empty or explained, and every gauged file under its max **or
raised with the user's yes**. A backlog past its max is proposed to the user, not pruned
here.

Run cleanup over each of the session's project roots, not only the one you are
sitting in — a second project's workspace is exactly where stale notes hide.

Finish with `sync`. Report the session-start reading before and after, then what was
deleted and what survived — not a file-by-file diff.
