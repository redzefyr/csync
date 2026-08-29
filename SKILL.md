---
name: csync
description: Sync Claude Code's global CLAUDE.md, per-project memory, and a per-project workspace directory through one private git repo you own — and organise what goes in those workspaces. Use for /csync (bare — setup if not installed, init if this project is not connected, sync otherwise), /csync setup|sync|list|open|init|config|pull|push|status|cleanup|remote|update|uninstall, when the user asks what pipelines are open or how far along they are, when the user picks a pipeline to take up for this session or asks to open one by slug, when the user asks to sync Claude settings, memory, plans, or notes, when tidying a project's plans/notes/docs, or when asking whether install.sh needs re-running after connecting a project or moving a clone. Also the source of truth for how workspace documents are organised — GRAPH.md as the session entry point, one pipeline per plan file named <planned>-<advanced>-<slug>, notes capped at decisions and traps, docs split into design (live) and archive — so consult it when creating, renaming, closing, or filing a workspace document, or when deciding what to read at the start of a session.
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

Before setup neither pointer exists; the scripts are then at
`~/.claude/skills/csync/scripts/`, or wherever the tool repo was cloned.

## The privacy gate

`global/CLAUDE.md` is the user's standing instructions to Claude, and
`global/memory/**` is everything Claude has recorded about their work — decisions,
environments, things they said once and expected to stay between the two of you. A
sync repo that is not private publishes all of it, and **flipping the repository
back to private afterwards does not recall what was already fetched, cached or
indexed.**

So before the first push to any real remote — in `setup`, and again in `remote` —
**check that the remote is private. Do not merely ask.** Asking has the failure
mode this gate exists to catch: the user believes it is private, and is wrong.

```bash
# GitHub with gh installed — authoritative
gh repo view <owner/repo> --json visibility -q .visibility

# any host — if an anonymous read succeeds, the repo is public
GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/echo \
  git -c credential.helper= ls-remote https://<host>/<path> >/dev/null 2>&1 \
  && echo PUBLIC || echo "not readable anonymously"
```

The anonymous probe needs the **HTTPS** form of the URL; convert
`git@host:owner/repo.git` to `https://host/owner/repo.git` for the check only. It
proves public reliably, but it does not prove private — a network failure and a
private repo look identical.

| outcome | what to do |
|---|---|
| **private**, confirmed | one line saying so, then continue |
| **public**, confirmed | **stop before pushing.** Report it, and do not treat it as the user's oversight to wave through — offer the three ways out below |
| **cannot tell** | say exactly that, name what you tried, and let the user decide. Never round "unverified" up to "private" |

When it is public, the ways out are: make the repository private and re-check;
point csync at a different repository; or run **local-only**, where a bare repo on
their own disk plays the part of the remote and nothing leaves the machine. Say
that third one out loud — it is the option users do not know exists, and it costs
them nothing but multi-machine sync.

If a push already happened, say plainly that making it private now limits further
exposure but does not undo it, and that anything sensitive in the history should
be treated as disclosed.

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
3. otherwise → **`sync`**

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

`csync-push.sh` covers one project by design, so run it once from each root. It
finds that project by **walking up from `$PWD`** for the directory holding
`$WS/.git`, so running it from inside the workspace or from a source
subdirectory works. `pull` already traverses the whole registry, which is wider
and safe: fast-forward never touches uncommitted local work.

The write-side commands are deliberately *not* registry-wide. A project this
session never opened may hold half-done work from another window.

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

## When `install.sh` must be re-run

`git pull` is enough for anything the repo links **as a whole**: this skill, the
global `CLAUDE.md`, an existing project's memory contents, any workspace. Those
are already symlinked, so new content arrives through them.

Re-run `$TOOL/scripts/install.sh` when a **new link** is needed, or one broke:

| Trigger | Why |
|---|---|
| **After `init` on a machine that did not create the project** | Per-project memory is an individual symlink. Without it Claude writes memories into an unsynced local directory |
| Another machine started using memory in a project this one already has | Same reason, opposite direction — the repo has the directory, this machine has no link to it |
| A new wrapper appeared in the sync repo's `bin/` | `~/.local/bin` links are per-file |
| The workspace shows up as untracked in a project repo | `$WS/` fell out of the global excludes file |
| The SessionStart pull stopped running | The hook entry in `~/.claude/settings.json` is gone |
| `/csync` stopped being a command | The link at `~/.claude/skills/csync` is gone. Run the clone's `scripts/install.sh` from a shell — there is no `/csync` left to invoke — and start a new session |
| **Either clone moved** | Re-running rewrites both pointers, the skill link and the hook path in one shot |

It is idempotent — run it when nothing is needed and it prints what already
exists and changes nothing. When in doubt, run it.

New machine, in this order: install the skill → `setup` → `init` each project →
**`install.sh` again**. The second run is what picks up memory directories for
the projects you just connected.

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
2. **Show the whole script and where it goes** — `$REPO/bin/<name>`, linked to
   `~/.local/bin/<name>`, pushed to every machine
3. **Get an explicit yes**, then write it, `chmod +x`, and run
   `$TOOL/scripts/install.sh`. The link is per-file, so the wrapper does not
   exist anywhere until that runs
4. Commit it to the sync repo along with everything else

Keep them thin, and portable by construction:

- adapt the name and the arguments, nothing else. No logic, no defaults, no
  project knowledge
- resolve the real binary from `PATH`, with an environment variable to override
  it. A hardcoded absolute path is wrong on the next machine
- diagnostics to stderr — stdout belongs to whatever protocol is speaking
- fail with a message naming the missing package, not a bare non-zero exit

Editing an existing wrapper is the same conversation: it is already on every
machine, so a change that suits the one in front of you can break the other.

---

# Subcommands

## /csync setup

First-run wiring. This is the one command that touches files the user did not
ask you to touch — it moves their real `~/.claude/CLAUDE.md` into a git repo and
leaves a symlink behind — so **nothing here happens silently**.

**1. Ask two questions** (one `AskUserQuestion` call):

- **Where should the sync repo live?** Default `~/.csync`. Anything is allowed.
  Discourage `~/.claude/...`: Claude Code manages that directory and runs its own
  cleanup inside it, and links from `~/.claude` into `~/.claude` are needlessly
  self-referential.
- **How should it sync?** Three answers:
  - **existing repo** — a second machine, or a repo they made earlier. Needs the URL
  - **new remote** — they created an empty private repo and have the URL
  - **local only** — one machine, no network, no account anywhere
  - **a clone already on disk** — they checked the repo out themselves, or are
    moving over from a predecessor tool. Needs the path, not a URL

**2. Before adopting anything, say what gets published — and verify it.** Skip
for local-only:

> `global/CLAUDE.md` (your global instructions to Claude) and
> `global/memory/**` (per-project notes Claude has written) are pushed to this
> remote verbatim.

Then run the check in **The privacy gate** above and report which of the three
outcomes you got. A public remote stops setup here; an unverifiable one is the
user's call to make, not yours to assume.

**3. Create or clone the sync repo.**

*Existing repo* — verify before touching the disk; a bad URL or missing auth
should fail here, not halfway through:

```bash
git ls-remote <url> >/dev/null && git clone <url> <repo>
```

*A clone already on disk* — do not clone again, and do not copy it to the default
location. Use the path as-is:

```bash
git -C <repo> rev-parse --show-toplevel   # must print <repo> itself
git -C <repo> remote get-url origin       # must exist
```

If `csync.conf` is missing, copy it from `templates/repo/` — **and ask what the
workspace directory is actually called in their projects before writing
`workspace_dir`.** The default `.csync` will not match an existing layout, and
the failure is silent: pull and push simply look for a directory that is not
there, and every workspace they already have goes unsynced without an error.

Then go straight to step 4 — `workspace_dir` is answered already, so `config`
only has the rest to ask.

*New remote, or local only* — scaffold from the templates:

```bash
# local only: a bare repo on this machine plays the part of the remote.
# Everything downstream is unchanged — origin is simply a path.
git init --bare <repo>.git

git init -b main <repo>
git -C <repo> remote add origin <url-or-bare-path>
cp -R "$TOOL/templates/repo/." <repo>/
mv <repo>/gitignore <repo>/.gitignore
```

Fill in `README.md`'s `{{NAME}}` and leave `csync.conf` at its template
defaults — step 4 settles them. Then commit.

Push: **local-only pushes immediately** — it is a directory on their own disk and
nothing leaves the machine. **A real remote is a publish**: show what is about to
go up and get an explicit yes first.

**4. Settle the settings — hand off to `config`.** Run it bare and walk the
values with them.

**This has to happen before install, not after.** `install.sh` reads
`workspace_dir` and writes it into the global excludes file as a line of its own;
settle it afterwards and that line names a directory nobody uses.

It is also the only moment `workspace_dir` is a plain setting — see `config`.
Nothing is connected yet, so there is nothing to migrate.

**5. Install — dry run first, every time.**

```bash
"$TOOL/scripts/install.sh" --dry-run --repo <repo>
```

Show the plan verbatim. `ADOPT` means a real file is moved into the repo;
`BACKUP` means a real file is renamed to `.bak` because the repo already has
that file. Get an explicit yes, then run the same command without `--dry-run`.

**6. Offer to skip the permission prompt on syncs.** Do not add it silently — ask,
and add these to `permissions.allow` in `~/.claude/settings.json` if they agree:

```
Bash($TOOL/scripts/csync-sync.sh:*)
Bash($TOOL/scripts/csync-pull.sh:*)
Bash($TOOL/scripts/csync-push.sh:*)
```

Scoped to the three scripts on purpose. A blanket `git push` allowance would
cover every repo on the machine.

**7. Offer the global rule that makes the workspace get read.** Nothing loads
`$WS/CLAUDE.md` on its own — it is not one of the paths Claude Code picks up
automatically. What makes it deterministic is a rule in the user's global
`CLAUDE.md` telling Claude to read the workspace when a project has one.
`templates/repo/global-rules.md` is that rule; substitute `{{WS}}` and offer to
append it to `$REPO/global/CLAUDE.md`.

Skip this only if the user declines. **Without it, `init` produces a workspace
that no session ever opens.** Do not reach for a hook or `CLAUDE.local.md`
instead — the global rule is enough, and the alternatives put the same
instruction in a second place that then has to be kept in step.

**8. Tell them what they now have**, briefly: the subcommands they will actually
use (`init`, `sync`, `open`, `cleanup`), that a SessionStart hook now fast-forwards
everything when a session starts (**registered for the next session, not this
one**), and that the next step is `/csync init` inside a project.

## /csync init [name]

Connect the current project root to branch `prj/<name>`. Default `name` is the
project directory's basename. Refuse if `$WS/` already exists.

1. Does the branch exist already?
   `git ls-remote <origin> "refs/heads/prj/<name>"`
2. If it does — another machine connected this project — clone it:
   `git clone -b "prj/<name>" --single-branch <origin> "$WS"`
3. If not, create it and scaffold. Doing the scaffold now matters: an empty
   `notes/` invites session logs, and a `docs/` with nothing under it invites
   documents at its root — where nothing states their lifetime. Both are hard to
   undo once the project has content.

   ```bash
   git init -b "prj/<name>" "$WS"
   git -C "$WS" remote add origin <origin>
   mkdir -p "$WS/docs/design" "$WS/docs/archive" "$WS/plans" "$WS/notes"
   touch "$WS/docs/design/.gitkeep" "$WS/docs/archive/.gitkeep" "$WS/plans/.gitkeep"
   cp "$TOOL/templates/workspace/gitignore" "$WS/.gitignore"
   cp "$TOOL/templates/workspace/CLAUDE.md" "$TOOL/templates/workspace/GRAPH.md" "$WS/"
   cp "$TOOL/templates/workspace/notes/"*.md "$WS/notes/"
   ```

   Replace `{{NAME}}`, `{{DATE}}` and `{{WS}}` in the copied files, and
   `{{DESCRIPTION}}` with one line about the project. Commit, then
   `git -C "$WS" push -u origin "prj/<name>"`.

   `GRAPH.md` and both `notes/` files are created **even though they are empty**.
   Without `GRAPH.md` the next session has no entry point, and the place it gets
   improvised is `notes/`.
4. Register the project root in `~/.claude/csync-projects` (append `$PWD` if not
   already listed) so the SessionStart pull covers it from any session.
5. Detect the project's languages and record which language servers are
   available — see `references/lsp.md`.
6. Confirm the project repo ignores it: `git check-ignore -q "$WS"` must succeed.
   If it does not, `$WS/` is missing from the global excludes file, which step 7
   fixes.
7. **Run `$TOOL/scripts/install.sh`.** Not optional, and easy to skip because
   `init` looks finished without it. Per-project memory is an individual symlink,
   so a project the repo already knows from another machine has **no memory link
   here until this runs** — Claude then writes memories into an unsynced local
   directory and they are lost on the next machine.

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
one; neither is `cleanup`, `status`, a lookup, or writing a `## findings` block
into someone else's plan.

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
4. **Rename the session — only if `auto_title` is on and this host can.** The
   setting is `config`'s and defaults to `off`; read it with
   `csync_auto_title "$REPO"`. Then look for a rename tool — hosts name them
   differently and may keep them behind a tool search; under Claude Code they
   are `get_session` and `set_session_title`, both taking the literal `self`.
   Read the current title, merge, write it back

**Re-opening the same slug is idempotent**: the findings are already folded, so
it reduces to step 4. That is the repair path for a title that is wrong or was
never set, and it is why there is no separate rename command.

**A second `open` in a project that already has one open — ask first.** One
pipeline per project per session is `workspace.md`'s rule and this command is not
the way around it. A second `open` in a *different* project is ordinary — that
the rule is per project is exactly because cross-repo pairs exist — and it adds
an entry to the title.

The title:

```
<project>:<slug>                            one pipeline
<projA>:<slugA> / <projB>:<slugB>           several, in the order they were opened
```

**The project prefix is always there, even for a single pipeline.** Slugs collide
across paired repos by design — the two ends of one piece of work carry one name
— and this title is read in a list beside other sessions, where a bare slug does
not say which end. Use the project's `prj/<name>` name.

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

**Either half of step 4 missing is not a failure, and they are not reported the
same way.** `auto_title = off` is the default and the silent case — say nothing.
A host with no rename tool, where the user *did* turn it on, is worth **one line,
once in the session**: this host has no rename tool. Leave it there. Do not send
them to install one — where the tool exists it arrives with the host, not from
anything installable. Steps 1–3 stand either way; the title is a label on an open
pipeline, not the thing itself.

## /csync status

Report `git status --short --branch` for `$REPO` and for **each of the session's
project roots** that has a workspace.

## /csync pull

The pull half alone. Run `$TOOL/scripts/csync-pull.sh`; it fast-forwards `$REPO`
and every project in `~/.claude/csync-projects` that still has a workspace clone.
It also fetches the tool repo and prints one line when that clone is cleanly
behind — it never merges that one; see `update`.
A diverged history is reported as `DIVERGED`, never as "offline" — see
`references/divergence.md`. Pulling other projects' clones is safe because
fast-forward never touches uncommitted local work.

## /csync push

The push half alone. Run `$TOOL/scripts/csync-push.sh` from the project root. It
commits everything pending as `sync: <host> <timestamp>` and pushes the sync repo
plus the current directory's workspace only — other registered projects are
deliberately left alone, since they may hold half-done work from another session.
To push several projects in one session, run it from each root. It already
retries a rejected push once via fast-forward, and refuses to commit at all when
the clone is already diverged.

Registry note: `~/.claude/csync-projects` is machine-local (absolute project
roots, one per line), maintained by the hook and the push script. Pull traverses
every entry; push stays scoped to the one project it resolved from `$PWD` — and
it registers **that resolved root**, never the subdirectory you happened to be
standing in. Entries whose workspace disappeared are pruned by the hook.

## /csync cleanup

Prune the current project's workspace so a new session can trust it. **This is a
judgment task, not a script** — there is nothing to run. The procedure is in
`references/workspace.md`, under "Closing a pipeline" and "Cleanup".

**Its measure is reduction.** Count what every session reads — `GRAPH.md` plus
`notes/` — before and after, report both, and call a run that ends larger a
failed cleanup.

## /csync config [key] [value]

Read or change `csync.conf` — **that file and nothing else.** The machine-local
state is two symlinks and a registry, all of it `install.sh`'s; a `config` that
reaches past the file it names is how a settings command turns into the drawer
everything gets thrown into.

Bare `/csync config` prints the values with their defaults and offers to change
one. `/csync config <key> <value>` sets one directly. Keys are `snake_case`, and
an unknown key is **reported, not written** — a typo that lands silently reads
back later as a setting that does nothing.

| key | default | |
|---|---|---|
| `workspace_dir` | `.csync` | the directory csync creates inside each project |
| `auto_title` | `off` | may `open` rename the session |

`csync.conf` lives in the sync repo, so a change lands on every machine — **write
it, then `sync`.** A value left uncommitted is a value the other machine never
learns, and the two then disagree without either one erroring.

**`workspace_dir` stops being a setting the moment a project is connected.** It
is the literal directory name on disk; `install.sh` writes it into the global
excludes file as a line of its own, and `csync-push.sh` finds a project by
walking up from `$PWD` for `$WS/.git`. Changing it is therefore a rename in every
connected project **on every machine**, plus that excludes line on each. And
because this file is synced, the new value reaches the other machine *before* its
directories are renamed — where it fails exactly as `setup` describes: pull and
push look for a directory that is not there, and every workspace goes unsynced
without an error.

So check before writing it. Any `prj/*` branch means a project exists somewhere,
whether or not this machine has it:

```bash
git -C "$REPO" branch -a --list 'prj/*' 'origin/prj/*'
```

None → set it, and that is the ordinary case, because `setup` runs `config`
before anything is connected. Any → **do not write the value.** Say what the
migration would be and let the user decide. It is `cleanup`'s kind of task, not a
setter's.

**`auto_title` decides whether `open` renames the session**, and it is `off` so
that renaming is something the user asked for: the rename overwrites a title they
set by hand, without asking. It is a preference, not a capability — the same
answer on every machine, which is why it is synced — and whether a given host
*can* rename is probed at the moment `open` needs it, never stored. A stored
"unavailable" is wrong the next time they open the project from another host.

**The remote is not a key here.** Where the sync repo points is `/csync remote`,
which mirrors the history, repoints every clone, and runs the privacy gate before
any of it. `config` may *report* the current origin alongside the keys. It must
not move it.

## /csync remote [url]

Give a local-only setup a real remote — the upgrade path when a second machine
appears. With no argument, report the current origin.

The bare repo already holds every branch, so it is the thing to publish:

```bash
git -C <repo>.git push --mirror <url>          # needs the user's yes
```

Then repoint every clone — the sync repo and each registered project's
workspace:

```bash
git -C "$REPO" remote set-url origin <url>
git -C "<project>/$WS" remote set-url origin <url>
```

`--mirror` can delete refs on the target, so it is only safe into an **empty**
repo. Verify with `git ls-remote <url>` first, and confirm with the user before
running it.

**Run the privacy gate here too, and run it before the mirror push, not after.**
This is the moment a setup that never left the machine starts leaving it, and it
publishes the whole history at once — every memory and every workspace note ever
committed, not just the current state. A `setup` that ran local-only never had
this checked, so there is no earlier verdict to inherit.

## /csync update

Update the tool repo, not the user's data — and **report what changed**. An
update that lands as "pulled, done" is one the user cannot act on: the rules
governing how this session works just moved under it, and only they can tell
whether that matters to the work in front of them.

The SessionStart hook is what raises it: when the tool clone is cleanly behind,
`csync-pull.sh` prints `tool update available -- N commit(s) behind origin`.
That line is a notice, not the report, and **not an instruction to run the
update.** Relay it and let the user choose when — applying it mid-session moves
the rules under the work in progress, and the clone may be one they are editing.
It stays silent when the clone is ahead or the fetch failed, so **no line does
not mean up to date.** A clone whose history was rewritten upstream counts as
*ahead* of a history it shares nothing with, so it is silent there too —
permanently, and in the one case the user most needs told.

**1. Record the revision before pulling.** Afterwards there is nothing left to
compare against, and `git pull`'s own output is a file list, not a report.

```bash
before=$(git -C "$TOOL" rev-parse HEAD)
git -C "$TOOL" pull --ff-only
after=$(git -C "$TOOL" rev-parse HEAD)
```

Equal revisions are the whole report: "csync: already up to date."

A `--ff-only` failure has **three causes that need different answers.** Tell them
apart before saying anything:

```bash
git -C "$TOOL" merge-base HEAD @{upstream}    # a commit for the first two, fails for the third
```

| what happened | what to say |
|---|---|
| the clone carries local commits | this clone is one the user is editing. Say so and stop — merging or rebasing to force the update through is their call, not yours |
| the working tree is dirty | same answer, same reason |
| **no common ancestor** | origin's history was **rewritten**. This clone holds no local work to rescue, and no pull will ever succeed again |

⚠️ **The third reads exactly like the first unless you check**, and the misreading
costs the user real time: it tells them they have local commits to protect when
they have none, and leaves the clone stuck on a history that no longer exists.
Git's own wording invites it — the failure says `Diverging branches can't be
fast-forwarded`, and **that is not the `DIVERGED` this skill means elsewhere.**
That one is two real histories off a shared root, and it is repairable; this one
has no shared root at all, and nothing merges it back.

A rewritten history is not something to merge past. Report it as what it is, and
let the user pick — resetting in place **discards whatever this clone holds**, so
it is theirs to choose, not yours to run:

```bash
git -C "$TOOL" fetch origin && git -C "$TOOL" reset --hard origin/main
```

Re-cloning is the other answer and the cleaner one, since it drops the old objects
too. Either way, re-run `install.sh` afterwards — it is idempotent, and it is what
repairs any link the replacement disturbed.

**2. Read the range, and report behaviour rather than filenames.**

```bash
git -C "$TOOL" log --oneline "$before..$after"
git -C "$TOOL" diff --stat "$before..$after"
git -C "$TOOL" diff "$before..$after" -- SKILL.md references
```

Commit subjects are the author's summary of their own edit, not a statement of
what now behaves differently on this machine; quoting them back is not the
report. Read the diff and say, in a few lines, what a session will do
differently — a subcommand step that moved, a rule that got stricter, a check
that is now mandatory, a file that was renamed. If the range is too large to
read through, group it by area and say plainly which parts you did not read.

**3. Say what the pull does not apply by itself.** Each row below is a change
that looks live and is not:

| what the range touched | what still has to happen |
|---|---|
| `SKILL.md`, `references/` | **this session keeps running the old copy** — it was loaded at session start. The new rules apply from the next session |
| `scripts/` | re-run `$TOOL/scripts/install.sh`, `--dry-run` first. A renamed or added script leaves the SessionStart hook pointing at a path that no longer exists |
| `templates/` | scaffolding for **new** workspaces only. Workspaces that already exist are never rewritten, and nothing goes back to update them |

## /csync uninstall

Run `$TOOL/scripts/uninstall.sh --dry-run` first, show the plan, then run it for
real. Symlinks holding the user's own content — the global `CLAUDE.md` and every
memory directory — are replaced by real copies, so nothing disappears when the
sync repo is later deleted. The links that are only wiring are removed outright,
the skill link at `~/.claude/skills/csync` among them. The sync repo, the project
workspaces and the tool clone are left in place — deleting those is the user's
call, and worth saying out loud when you report. When the tool clone *is*
`~/.claude/skills/csync`, say so too: the skill stays loaded until they remove
it, and every subcommand then fails on a missing pointer.

---

# References

- `references/workspace.md` — how a workspace is organised: `GRAPH.md`, `plans/`,
  `notes/`, `docs/`, the `## findings` hand-off, closing a pipeline, cleanup.
  **Read this before creating, renaming, filing or deleting any workspace
  document.**
- `references/document-format.md` — what those documents **look like**: the YAML
  frontmatter each kind carries, the exact position of the `## findings` block,
  the emoji vocabulary, and what a tool may and may not read. **Read it before
  writing one, and copy the matching file from `templates/document/` rather than
  rebuilding a header from prose.**
- `references/rationale.md` — the incidents the two files above came out of.
  ⚠️ **Not read to do work.** Read it only when a rule in one of them is being
  changed, or when the user asks why a rule exists. Keeping those reasons inline
  is what turned every session into a reader of several hundred lines of incident
  narration — and what taught sessions to write the user's documents that way.
- `references/divergence.md` — what to do when a clone has diverged.
- `references/lsp.md` — language-server detection during `init`.
