---
name: csync
description: "Use when the user is asking about Claude's own working state rather than their product code: the global CLAUDE.md, per-project memory, and the workspace directory of plans, notes, decisions, traps and docs. Handles `/csync` and every subcommand (setup, init, sync, list, open, status, pull, push, cleanup, config, remote, update, uninstall). Trigger it when the user can't recall what work is open here, asks which pipelines exist, how far each got, which to resume, or what to read at session start; says notes or plans written on another machine are missing, sets up a fresh machine or a freshly pulled/moved clone, or wonders whether install.sh must run again; has a notes/plans/docs file grown too long, gone stale, or needing closing, renaming, filing; finds one project's work depending on or breaking another project's plan. It also defines how these documents are organised — GRAPH.md entry point, one pipeline per project per session, notes limited to decisions and traps, docs live vs archive — so consult it before creating or moving one."
---

# csync

csync keeps two things in one private git repo the user owns:

1. **Claude's global state** — `~/.claude/CLAUDE.md` and the per-project memory
   directories — so a second machine starts where the first left off.
2. **A workspace directory inside each project** — plans, decisions, traps and
   research that belong to the work but not in the project repo.

The second half stands on its own. A single machine with no remote still gets
version history and the pipeline discipline in `references/workspace.md` — see
**Local-only** under `setup`.

## Two repos

| | what | where |
|---|---|---|
| **tool repo** | this skill, its scripts and templates | `~/.claude/skills/csync` |
| **sync repo** | the user's own private repo | wherever they chose (default `~/.csync`) |

The sync repo's `main` branch holds `global/`, `bin/` and `csync.conf`. Each
connected project gets a `prj/<name>` branch holding that project's workspace
directory, as an independent (orphan) history.

**Never merge or rebase between `main` and `prj/*`.** They share no content and
no history. Everything is fast-forward only; on a rejected push, pull
`--ff-only` and retry. Force push and branch deletion always need the user.

**Reading the sync repo's past needs the user too — once before reading, once
before applying.** Committing and pushing here may be routine, but pulling content
*out of history* is not, and the two approvals do not substitute for each other.

1. **Before reading.** Say why you need it, then wait. This covers anything that
   surfaces content the current checkout does not have — `git show <old>:<path>`,
   `git log -p`, a diff against an old revision, restoring a deleted file. It does
   **not** cover `git status`, `git log --oneline`, or a working-tree `git diff`;
   those describe the present, which is what you are allowed to look at freely.
2. **Before applying what you read.** Report exactly what would come back and
   where it would land, then wait again.

**Why:** a workspace advances by reversing and deleting — that is what capping
`notes/` and deleting plans on close *mean*. History therefore holds **superseded
judgments stated with their original confidence**, and nothing in the text marks
them as retired. Pulled back without that context, a rule the user already changed
comes back to life. The gates exist so the person who ordered the change decides
which version is current; the diff alone does not say.

## Resolve first

Every command starts here. Two symlinks are the entire machine-local state:

```bash
TOOL="$(cd -P ~/.claude/csync-tool && pwd)"    # absent => csync is not installed
REPO="$(cd -P ~/.claude/csync-repo && pwd)"
WS="$(sed -n 's/^[[:space:]]*workspace_dir[[:space:]]*=[[:space:]]*//p' "$REPO/csync.conf" 2>/dev/null | tail -1)"
WS="${WS:-.csync}"
```

`$WS` is the workspace directory name — `.csync` unless the user changed it.
Wherever this skill says "the workspace", it means `<project-root>/$WS/`.

Before setup neither pointer exists; `scripts/` and `references/` are then
under `~/.claude/skills/csync/`, or wherever the tool repo was cloned.

## The privacy gate

The sync repo carries the user's standing instructions to Claude and everything
Claude has recorded about their work. Before the first push to any real remote —
in `setup`, and again in `remote` — **check that the remote is private. Do not
merely ask.** Asking has the failure mode this gate exists to catch: the user
believes it is private and is wrong. And **flipping the repository back to
private afterwards does not recall what was already fetched, cached or indexed.**

The probes and the three outcomes they produce are in `references/setup.md` —
including "cannot tell", which is never rounded up to private, and the
local-only way out, which is the option users do not know exists.

## Reporting

Sync is background plumbing — without csync it would be invisible local state.
Run `sync` on your own at natural points (after writing memories or workspace
notes, when wrapping up work) and report it in **one short line**: "csync:
pulled and pushed". Do not enumerate commits, hashes, or per-repo results.
Report in whatever language the user is speaking.

Elaborate only when something needs the user: a diverged history, a push that
failed after its retry, or anything the scripts sent to stderr.

Four subcommands sit outside that rule. `cleanup` deletes documents and makes
judgment calls, so it reports what it did — never run it on your own, wait to be
asked. `update` and `config` change the rules the next session runs under, so
they report what changed. `list` **is** its output — a table, printed whole — and
it is the one of the four that also runs unasked, in the single case `/csync
sync` names below.

**`DIVERGED` is the exception that is not a subcommand, and the one that actually
gets missed.** The
one-line rule above is why: a split reads like one more quiet line and gets
summarised away as "sync done". It is not routine — sync cannot complete until it
is settled, and the scripts refuse to commit on top of it. Raise it in the same
turn you see it and follow `references/divergence.md`. Never report success for a
run that printed `DIVERGED`.

## No argument

Bare `/csync` dispatches on how far along this machine is:

1. `~/.claude/csync-repo` missing → **`setup`**
2. installed, but this project root has no `$WS/` → **`init`**
3. otherwise → **`sync`** — which, in a session that has not yet opened a
   pipeline in that project, ends in `list`. Bare `/csync` at session start is
   therefore `pull → push → list`: the table is part of the answer, not an
   extra

`cleanup` is never the bare default — it has to be asked for by name, and
neither are `open` or `config`: taking up a pipeline and changing a setting are
both decisions, never fallbacks. Inside
the tool repo or the sync repo themselves, always `sync`: neither ever gets a
workspace directory of its own.

## Scope — every project this session touches

A session often has more than one project root: the primary working directory
plus any others. **Every subcommand except `init` covers all of them that have a
workspace**, not just `$PWD`. Missing the second one is the common failure — its
notes quietly fall a session behind and the next reader trusts them.

Both halves cover **one project per run**, so run each once from each root. They
find that project the same way — by **walking up from `$PWD`** for the directory
holding `$WS/.git` — so running either from inside the workspace or from a source
subdirectory works. One rule for both directions.

⚠️ **The SessionStart hook only ever covers the root it was handed.** A second
root is not fast-forwarded until something runs `pull` there, so pull it *before*
reading its notes, not after. Nothing warns you — a stale note reads exactly like
a current one.

Neither half touches a project this session never opened. On the write side that
would commit half-done work from another window. On the read side it was merely
harmless, and harmless is a permission, not a reason: a clone nobody commits in
cannot drift, and the session that opens it pulls it then.

## When `install.sh` must be re-run

`git pull` is enough for anything the repo links **as a whole**: this skill, the
global `CLAUDE.md`, an existing project's memory contents, any workspace. Those
are already symlinked, so new content arrives through them.

Re-run `$TOOL/scripts/install.sh` when a **new link** is needed, or one broke:

| Trigger | Why |
|---|---|
| **A project acquired memory after it was connected** | The memory loops link what already exists on one side or the other. A project connected before anything had been written about it has neither, so `init`'s own run finds nothing to link, and the directory Claude later creates stays local and unsynced until this runs |
| Another machine started using memory in a project this one already has | Same loops, opposite direction — the repo has the directory, this machine has no link to it |
| A new wrapper appeared in the sync repo's `bin/` | `~/.local/bin` links are per-file |
| The workspace shows up as untracked in a project repo | `$WS/` fell out of the global excludes file |
| The SessionStart pull stopped running | The hook entry in `~/.claude/settings.json` is gone |
| `/csync` stopped being a command | The link at `~/.claude/skills/csync` is gone. Run the clone's `scripts/install.sh` from a shell — there is no `/csync` left to invoke — and start a new session |
| **Either clone moved** | Re-running rewrites both pointers, the skill link and the hook path in one shot |

It is idempotent — run it when nothing is needed and it prints what already
exists and changes nothing. When in doubt, run it.

New machine, in this order: install the skill → `setup` → `init` each project.
**`init` runs `install.sh` itself** (step 7 of its procedure), and that run walks
every memory directory the repo holds — not only the project being connected — so
projects the repo already knows are linked by the time the last `init` finishes.
What it cannot link is a project nothing has been written about yet; that is the
first row of the table above.

## CLI wrappers in `bin/`

The sync repo's `bin/` is linked file-by-file into `~/.local/bin`. It exists for
thin adapters — a tool invokes a binary under one name or calling convention, and
the program the user installed answers to another.

**Never write one on your own initiative.** A file here lands on the user's
`PATH` and reaches every machine they sync. Those are two thresholds a session
does not cross unasked. When you hit a gap a wrapper would close:

1. **Say what is actually broken** — what invoked what, under which name and
   arguments, and what the installed program did instead. If the real fix is
   installing the right package, say that first. A wrapper is for when the two
   sides genuinely disagree, not for a missing dependency
Only then is the wrapper written — into `$REPO/bin/<name>`, linked per-file into
`~/.local/bin`, so it exists nowhere until `install.sh` runs, and committed with
everything else. The rules that keep one portable across machines, and the same
conversation for editing an existing wrapper, are in `references/maintenance.md`.

---

# Subcommands

## /csync setup

First-run wiring, and the one command that touches files the user did not ask you
to touch — it moves their real `~/.claude/CLAUDE.md` into a git repo and leaves a
symlink behind. **Nothing in it happens silently.**

Procedure in `references/setup.md`. Do not improvise a shorter version: it asks
where the repo lives and how it syncs, runs the privacy gate before adopting
anything, settles `csync.conf` **before** installing, and dry-runs `install.sh`
before the real run. It ends by pointing at `/csync init`.

## /csync init [name]

Connect the current project root to branch `prj/<name>` — default `name` is the
project directory's basename. Refuse if `$WS/` already exists. Procedure in
`references/setup.md`: it scaffolds the workspace, registers the project, runs
`install.sh`, and ends by telling the user to **start a new session**, which is
what makes any of it take effect.

## /csync sync

The default verb — use this unless the user asks for one direction only. Run
`$TOOL/scripts/csync-sync.sh` **from each of the session's project roots**: it
pulls everything (the same traversal the SessionStart hook does), then commits
and pushes the sync repo plus that directory's workspace. Running it from only
one root leaves the other project's notes unpushed.

**Then run `list` for each project in which this session has not opened a
pipeline**, so the run reads `pull → push → list`.

Judge that condition **per project, not per session**. A session holding two
projects may have advanced one and left the other alone, and the untouched one is
exactly the one whose plans nobody has looked at.

A session has **opened a pipeline** in a project once it is working one of that
project's plans. Reading `GRAPH.md` and `notes/` at session start is not opening
one; neither is `cleanup`, `status`, a lookup, working a backlog item, or writing a
`## findings` block into someone else's plan.

**Why it is conditional and not always.** A session that already has its pipeline
open knows what it is doing, and the table is then noise — worse, noise that
reads as an invitation to start a second, which the one-pipeline-per-project rule
forbids. A session that has not opened one is either just starting or has just
finished something unrelated, and that is precisely when "what is waiting" earns
the space.

The one-line rule still governs the sync itself: report "csync: pulled and
pushed" and put the table under it. They are one action, not two steps to
narrate.

## /csync list

Render the session's pipelines as a table — **read-only. It never edits anything
it finds.** One row per file in `<project>/$WS/plans/`:

| column | where it comes from |
|---|---|
| **banner** | `[[<slug>]] · <status>` — slug from the filename's `<slug>` field, status from the plan's frontmatter: `status_note` when it has one, otherwise `status`. A plan with no frontmatter is **legacy** — fall back to a `> **Status**:` line in the body, and say `(legacy)` in the row. One line: trim it and drop the markup left dangling by the trim. ⚠️ **Trim it, never rewrite it** — summarising is rewriting, and a status reworded by a session that did not do the work is indistinguishable from one the session that did wrote, so every session after takes it as fact |
| **findings** | how many `###` entries sit under that plan's `## findings` heading. Leave it blank when there is no such block. ⚠️ **A block whose entries are in some other shape is `?`, never `0`** — zero reads as "nothing waiting", and under-reporting is the failure this column exists to prevent |

Order the rows **the way `GRAPH.md` lists them.** That order is a judgment the
workspace already made — the leading pipeline is first — and re-sorting by date
throws it away. Plans `GRAPH.md` does not mention go last, most recently
advanced first.

Cover **every project root this session has open that has a workspace**, one
table each under the project's name — the same scope as `status` and `sync`.

Two mismatches are free to notice while reading, and both mean the entry point
is wrong, so **say them in a line under the table**: a plan file that `GRAPH.md`
does not list, and a `GRAPH.md` entry whose file no longer exists. Report them
and stop there — repairing the index is `cleanup`'s work, and `cleanup` is the
user's to ask for.

⚠️ **The table is not a menu.** Printing it does not license starting one of the
rows: a session with no instruction **asks which pipeline to continue**
("Session start" in `references/workspace.md`). It is least of all a licence to
open a second pipeline in a project that already has one running. Taking a row up
is `open`, and `open` is the user's to ask for.

## /csync open [slug]

Take up a pipeline for this session. This is the command `list` deliberately is
not: `list` prints the rows, `open` picks one.

**It is the only thing that renames the session.** Any other path to a title
change is a guess at what the user meant, and the tool overwrites a title the
user set by hand without asking. So: a session that never runs `open` is never
renamed.

`/csync open` with no slug **is the question**. Show the session's open pipelines
as `list` does and ask which one to continue — once per project root that has a
workspace. Do not pick one.

`/csync open <slug>`:

1. **Resolve the slug against the disk** — `$WS/plans/*-<slug>.md` in each of the
   session's project roots. No match → say so and **stop; do not rename**. A
   title naming a plan nobody can open is worse than no title, because a sidebar
   is read as fact. A match in two projects → ask which; never guess
2. **Report the plan's header** — `status` (with `status_note`), `next` and
   `blocked`, from its frontmatter. That next step is what this session starts
   on, as written. A legacy plan carries them as a leading blockquote instead;
   read them there and say the plan is legacy — **do not migrate it here**, that
   is `cleanup`'s call
3. **Fold in `## findings` if the plan has one** — promote, backlog or reject
   each entry, per `references/workspace.md`. **This is the substance of the
   command**, not step 4: another session handed those over, and until they are
   folded the next step you just reported may already be stale
4. **Rename the session — only if `auto_title` is on and this host can.** Read
   the setting with `csync_auto_title "$REPO"`. `off` is the default and the
   silent case: say nothing and stop here. When it is on, the title format, the
   project prefix it always carries, and what to say on a host with no rename
   tool are in `references/maintenance.md`
never set, and it is why there is no separate rename command.

**A second `open` in a project that already has one open — ask first.** One
pipeline per project per session is `workspace.md`'s rule and this command is not
the way around it. A second `open` in a *different* project is ordinary — that
the rule is per project is exactly because cross-repo pairs exist — and it adds
an entry to the title.

**Read the existing title before writing it.** It is the only record of what this
session has already opened: nothing on disk holds that, and unlike the
conversation it survives being summarised away. Merge into it — never overwrite
it with the new entry alone.

⚠️ **Renaming is not opening.** The title records a decision already made; it
does not make one. A session that has not done steps 1–3 has opened nothing,
whatever its title says.

**`open` writes nothing to disk except through step 3.** In particular it does
not touch `GRAPH.md`. That file is the *project's* state — two windows open on
one project would each stamp their own session over it. Session state lives in
the session's title.

**There is no `close`.** Closing is the four-step judgment in
`references/workspace.md` — verify in the code, extract the unstarted follow-ups
— and wrapping it in a command would make it look like something that can just be
run. The title also stays as it is when the pipeline closes or the session drifts
elsewhere: that session's work *was* that plan, and the label stays true after
the fact.

## /csync status

Report `git status --short --branch` for `$REPO` and for **each of the session's
project roots** that has a workspace.

## /csync pull

The pull half alone. Run `$TOOL/scripts/csync-pull.sh`; it fast-forwards `$REPO`
and this project's workspace clone — the same one project `push` covers, resolved
the same way, so a session's two halves always mean the same clone. It also
fetches the tool repo and prints one line when that clone is cleanly behind — it
never merges that one; see `update`.
A diverged history is reported as `DIVERGED`, never as "offline" — see
`references/divergence.md`. There is no sweep and no flag for one: to cover a
second project, run it from that root.

## /csync push

The push half alone. Run `$TOOL/scripts/csync-push.sh` from the project root. It
commits everything pending as `sync: <host> <timestamp>` and pushes the sync repo
plus the current directory's workspace only — other registered projects are
deliberately left alone, since they may hold half-done work from another session.
To push several projects in one session, run it from each root. It already
retries a rejected push once via fast-forward, and refuses to commit at all when
the clone is already diverged.

Registry note: `~/.claude/csync-projects` is machine-local (absolute project
roots, one per line) and **append-only** — `pull`, `push` and `init` add to it,
and nothing removes a line. Push registers **the root it resolved**, never the
subdirectory you happened to be standing in.

It is not what makes a project sync; both halves resolve their project from
`$PWD` and neither reads this file. Its reader is `/csync remote`, which has to
repoint *every* clone on the machine — so it needs a list that errs long rather
than short, and a line whose workspace is gone costs it nothing. ⚠️ **Do not
prune it.** The sweep that used to do so dropped projects on unmounted disks for
good, because nothing re-adds a root except working in it.

## /csync cleanup

Prune the current project's workspace so a new session can trust it. **This is a
judgment task, not a script** — there is nothing to run. The procedure is in
`references/workspace.md`, under "Closing a pipeline" and "Cleanup".

**Its measure is reduction.** Count what every session reads — `GRAPH.md` plus
`notes/` — before and after, report both, and call a run that ends larger a
failed cleanup.

## /csync config [key] [value]

Read or change `csync.conf` — **that file and nothing else.** The machine-local
state is two symlinks and a registry, all of it `install.sh`'s. Bare `/csync
config` prints the values and offers to change one; `/csync config <key> <value>`
sets one directly. Keys are `snake_case`, and an unknown key is **reported, not
written** — a typo that lands silently reads back later as a setting that does
nothing.

| key | default | |
|---|---|---|
| `workspace_dir` | `.csync` | the directory csync creates inside each project. ⚠️ **Stops being settable the moment any project is connected** — it is then a rename in every project on every machine, which is a migration to propose, not a value to write |
| `auto_title` | `off` | may `open` rename the session |

That table is here so a session can **point at the command** — "that is
`/csync config auto_title on`" — without loading anything. Suggest it; do not run
it unasked. `csync.conf` is synced, so a change reaches every machine: **write
it, then `sync`.** The rest — what to check before `workspace_dir`, and why
`auto_title` is a synced preference rather than a per-host capability — is in
`references/maintenance.md`.

**The remote is not a key here.** Where the sync repo points is `/csync remote`.

## /csync remote [url]

Give a local-only setup a real remote — the upgrade path when a second machine
appears. With no argument, report the current origin. Procedure in
`references/setup.md`: it mirrors the whole history at once, so the privacy gate
runs **before** the push, not after.

## /csync update

**This one is the user's to run, not yours.** The SessionStart hook raises it:
when the tool clone is cleanly behind, `csync-pull.sh` prints `tool update
available -- N commit(s) behind origin`. Relay that line, say that `/csync
update` is what applies it, and stop there. Applying it mid-session moves the
rules under the work in progress, and the clone may be one the user is editing.

⚠️ **No line does not mean up to date.** The notice stays silent when the clone
is ahead or the fetch failed — and a clone whose history was rewritten upstream
counts as *ahead* of a history it shares nothing with, so it is silent there too,
permanently, in the one case the user most needs told.

When they do run it, the procedure is in `references/maintenance.md`: what to
record before pulling, three `--ff-only` failures that read alike and need
different answers, and what a pull does **not** apply by itself.

## /csync uninstall

Dry run first, show the plan, then run it for real — procedure in
`references/maintenance.md`. Nothing the user owns disappears: the global
`CLAUDE.md` and every memory directory come back as real files, and only the
wiring is removed.
---

# References

- `references/workspace.md` — how a workspace is organised: `GRAPH.md`, `plans/`,
  `notes/` and who may revise a decision, `docs/`, the `## findings` hand-off, the
  backlog and when an item there becomes a plan, keeping each workspace
  self-contained, closing a pipeline, cleanup.
  **Read this before creating, renaming, filing or deleting any workspace
  document.**
- `references/document-format.md` — what those documents **look like**: the YAML
  frontmatter each kind carries, the exact position of the `## findings` block,
  the emoji vocabulary, and what a tool may and may not read. **Read it before
  writing one, and copy the matching file from `templates/document/` rather than
  rebuilding a header from prose.**
- `references/setup.md` — the procedures for `setup`, `init` and `remote`, and
  the privacy gate all three run. **Read it when one of them is invoked**, not to
  answer a question about them.
- `references/maintenance.md` — the procedures for `config`, `update` and
  `uninstall`, the session-title rules `open` step 4 needs when `auto_title` is
  on, and how to write a `bin/` wrapper once the user has approved one. **Read it
  when one of those is actually happening**, not to mention that it exists.
- `references/rationale.md` — the incidents the two workspace files came out of.
  ⚠️ **Not read to do work.** Read it only when a rule in one of them is being
  changed, or when the user asks why a rule exists. Keeping those reasons inline
  is what turned every session into a reader of several hundred lines of incident
  narration — and what taught sessions to write the user's documents that way.
- `references/divergence.md` — what to do when a clone has diverged.
- `references/lsp.md` — language-server detection during `init`.
