# csync

**English** · [한국어](README_kr.md)

A Claude Code skill that gives Claude a **persistent, versioned workspace** in
each of your projects — and, if you want it, keeps that workspace and Claude's
global configuration in step across several machines.

Two things go into one private git repository you own:

1. **Claude's global state** — your `~/.claude/CLAUDE.md` and the per-project
   memory directories Claude writes to.
2. **A workspace directory inside each project** (`.csync/` by default) — plans,
   decisions, traps and measurements that belong to the work but do not belong in
   the project repo.

Install it, type `/csync`, and it walks you through the rest.

## Contents

- [Quick start](#quick-start)
- [Two ways to use it](#two-ways-to-use-it)
- [Prerequisites](#prerequisites) — [Windows](#windows)
- [Install](#install)
- [What ends up where](#what-ends-up-where)
- [The CLAUDE.md files, and which is which](#the-claudemd-files-and-which-is-which)
- [The memory directories](#the-memory-directories)
- [The workspace](#the-workspace)
- [Everyday use](#everyday-use)
- [Adding a second machine](#adding-a-second-machine)
- [Going from local-only to a remote](#going-from-local-only-to-a-remote)
- [What gets pushed](#what-gets-pushed)
- [Updating and removing](#updating-and-removing)
- [When something looks wrong](#when-something-looks-wrong)
- [How it is put together](#how-it-is-put-together)

## Quick start

### 1. Install

Two places are involved and they are not the same place. **A shell** does the
cloning and linking; **Claude Code** does everything after that. Nothing below
mixes the two.

#### In a shell — clone the skill

```bash
git clone https://github.com/redzefyr/csync.git ~/.claude/skills/csync
```

That path is what makes `/csync` a command: Claude Code discovers skills under
`~/.claude/skills`. If you would rather keep the clone with your other
repositories, clone it there and link it — the scripts resolve everything through
their own pointers, so only the link matters:

```bash
git clone https://github.com/redzefyr/csync.git ~/dev/csync
ln -s ~/dev/csync ~/.claude/skills/csync
```

Either way, `install.sh` maintains that link from then on.

If you want a remote, **create an empty private repository now** — setup will ask
for its URL. On a single machine you can skip that: choose **local only** and a
bare repo on your own disk plays the part of the remote.

#### In Claude Code — start a session and run setup

```
/csync
```

Nothing is wired up yet, so this runs `setup`. It asks two questions, then shows
you every change before making it. Roughly:

```
you   /csync

      csync is not installed on this machine. Two questions first.

      Where should the sync repo live?          → ~/.csync
      How should it sync?                       → new remote

you   git@github.com:you/your-sync-repo.git

      global/CLAUDE.md (your standing instructions to Claude) and
      global/memory/** (per-project notes Claude has written) are pushed to
      this remote verbatim. Checking that it is private before anything is
      adopted...

      gh repo view: private. Continuing.

      install.sh --dry-run:
        ADOPT:    ~/.claude/CLAUDE.md -> moved into the repo at ~/.csync/global/CLAUDE.md
        link:     ~/.claude/csync-repo -> ~/.csync
        link:     ~/.claude/csync-tool -> ~/.claude/skills/csync
        hook:     SessionStart -> ~/.claude/skills/csync/scripts/csync-pull.sh

      ADOPT means a real file of yours is moved into the git repo and a symlink
      is left in its place. Apply this?

you   yes
```

The dry run is not optional and not a formality — `setup` is the one command that
touches files you did not ask it to touch. `ADOPT` moves one of your real files;
`BACKUP` renames one to `.bak` because the repo already has that file. What each
question means is in [Install](#install).

#### Then connect each project

Connecting a project is a Claude Code command, but it acts on **the project
Claude currently has open** — so the working directory has to be that project
first. Do it in whichever way you normally start Claude Code:

```bash
cd ~/dev/my-project
claude
```

and then, in that session:

```
/csync init
```

`init` scaffolds `.csync/` in the project, puts it on its own `prj/<name>`
branch, and re-runs the installer. **It ends by telling you to start a new
session** — that is what makes the workspace take effect, so do that before
expecting Claude to use it.

Repeat for every project you want connected. You do not have to run the installer
yourself between them — `init` runs it as part of its own procedure, and that run
links every memory directory the sync repo holds, not just the project in front of
it.

### 2. TL;DR — the loop after that

**Open a new session and type `/csync`.** With everything installed that means
*pull → push → the table of open pipelines* — so the session starts by telling
you what is waiting rather than by asking you to remember it.

From there:

| you want to | you type | what happens |
|---|---|---|
| work one pipeline properly | `/csync open <slug>` | the plan's status and next step are reported, findings other sessions handed it are folded in first, and the session is named after it |
| do something small | *nothing* | not everything needs a pipeline. A one-line item in `GRAPH.md`'s backlog can just be done, and Claude records the outcome where it belongs |
| turn that into real work | *approve the proposal* | when a backlog item turns out to need sequencing, a next step that has to outlive the session, or somewhere for other sessions to hand it findings, Claude says so and asks whether to promote it. On your yes it becomes a plan and the backlog line goes. It never promotes one by itself — a new plan is an entry every session reads |
| finish a pipeline | *say it is done* | Claude verifies completion **in the code**, extracts the follow-ups nobody started, distributes the contents to `notes/` and `docs/`, then deletes the plan and leaves one line under closed pipelines |

**There is deliberately no `/csync close`.** Closing is a judgment — the plan is
the least reliable witness to whether its own work is finished — and a command
would make it look like something you can just run. Say the pipeline is done and
Claude walks the four steps.

Two more you type yourself, and only yourself:

- **`/csync update`** — updates the skill. Claude will tell you when the clone is
  behind, and will not apply it mid-session: that would move the rules underneath
  work already in progress.
- **`/csync cleanup`** — prunes a workspace that has grown past being trustworthy.
  It deletes documents and makes judgment calls, so it never runs unasked. Its
  measure is reduction: a run that leaves the workspace bigger failed.

Everything else is plumbing. A SessionStart hook fast-forwards on open, and
Claude syncs on its own after writing notes or wrapping up, reporting it in one
line.

### 3. Best practice — teach your global `CLAUDE.md` about it

csync works without this. What it adds is the part the skill cannot reach: rules
that have to hold in sessions where **the skill was never loaded** — which is most
of them, because `~/.claude/CLAUDE.md` is read at the start of every session while
a skill is read only when something triggers it.

Add a section like this to `~/.claude/CLAUDE.md` (the file csync now versions for
you). Adjust `.csync/` if you renamed the workspace directory:

```markdown
## Claude's working documents

- **Until you run `/csync` yourself in this session, the only thing Claude reads
  under `.csync/` is `notes/`.** Traps that are easy to step on and decisions that
  must not be reversed have to be known whatever the work is; everything else is
  for after you have said you want that pipeline open. While the gate is closed:
  - ⚠️ **Do not go outside `notes/`** — do not follow `[[slug]]` references out of
    it, and do not open `GRAPH.md`, `plans/`, `docs/` or `.csync/CLAUDE.md` **by
    any route**, grep, ls and search included. If a slug has to be resolved,
    suggest `/csync open <slug>`.
  - ⚠️ **Do not write to `.csync/` — `notes/` is read-only too.** The caps, the
    admission criteria, the folding and placement rules are all in the documents
    you are not reading right now; edit without them and you break it silently. If
    something needs recording, do not write it — **suggest `/csync`.**
  - ⚠️ **"Yourself" means me, the user** — the `sync` Claude runs on its own
    initiative under the last rule below does not open the gate. If it did, it
    would not be a gate.
- Once the gate is open, the skill takes over: what to read first, and how many
  pipelines one session may open.
- Files Claude creates and maintains — working notes, design and planning
  documents, investigation results — go under `.csync/`, not into the project
  repo. **Session notes and scratch are the exception: those go in a scratchpad.**
  Files that belong to the project repo by its own conventions — code, tests,
  documentation the team shares — follow those conventions.
- **The source of truth for how these documents are organised is the skill's
  `references/workspace.md`, and no copy of it lives here.** ⚠️ The copy that used
  to be here fell behind after the original was revised, and was genuinely wrong
  by then — a cap with the wrong number, a directory that had been retired. Do not
  paste one back in for convenience.
- Claude decides when to sync: after writing memory or a `.csync/` note, when
  wrapping up work. Report it as **one line** — "pulled and pushed" — and raise
  anything that needs me, such as a diverged history or a push that failed after
  its retry, immediately. **This applies to a session that only ran the script,
  with the skill never loaded.**
```

#### What changes once it is in

| | without it | with it |
|---|---|---|
| **a session that never triggers the skill** | writes a design document into your project repo, where it shows up in your next diff and never syncs | writes it under `.csync/`, or says the workspace is not open and offers `/csync` |
| **the start of an ordinary session** | Claude either reads the whole workspace uninvited, or none of it | reads `notes/` — the traps and the decisions — and stops there until you open something |
| **work done in a session with no skill loaded** | is committed but never pushed: the SessionStart hook only ever pulls, so it sits on one machine until some later session happens to sync | is pushed when the work wraps up, reported in one line |
| **your global file over time** | gradually accumulates a summary of the workspace rules that drifts out of step with the real ones | keeps a pointer, and says out loud why it must stay a pointer |

The third row is the one people discover late. The hook that runs when a session
opens is a **pull**; nothing pushes on its own. Without a rule telling Claude to
sync, a session that never loaded the skill leaves its work local — and you find
out on the other machine, days later, when the note is not there.

The first bullet — the read gate — is the one to keep even if you take nothing
else. Its cost is one extra `/csync` when you actually want the pipeline; what it
buys is that opening a session about an unrelated bug does not pull several
hundred lines of somebody else's plans into the context.

## Two ways to use it

**One machine, no remote.** You want Claude to stop losing the thread between
sessions: a live plan with an explicit next step, a short list of decisions that
must not be reversed, and a record of the traps you already hit. csync creates a
bare git repository on your own disk to act as the remote, so you get full
history and the same workflow with nothing leaving the machine and no account
anywhere. The document discipline is the point; syncing is optional.

**Two or more machines.** The same, plus your global `CLAUDE.md`, your per-project
memory, and every project workspace fast-forwarded at the start of each session
and pushed when you finish.

You can start local-only and add a remote later — `/csync remote <url>` does the
migration.

## Prerequisites

| | | |
|---|---|---|
| **Claude Code** | any version with skills | the skill lives in `~/.claude/skills/` |
| **git** | 2.x | for `git init --bare` in local-only mode, and everything else |
| **bash** | 3.2 or newer | macOS ships 3.2; the scripts are written to that floor |
| **OS** | macOS or Linux | Windows is not supported as it stands — see [Windows](#windows) |
| **python3 or jq** | optional | only for editing `~/.claude/settings.json` during install/uninstall. With neither, the installer prints the JSON for you to paste |

For the multi-machine setup you also need:

- **A git repository you own, and it should be private.** Empty is fine — csync
  scaffolds it. See [What gets pushed](#what-gets-pushed).
- **Working authentication for it.** `git ls-remote <url>` must succeed from your
  shell before you start; csync checks this first and stops if it fails.

Optional: put `~/.local/bin` on your `PATH` if you plan to keep CLI wrappers in
the repo's `bin/`.

### Windows

Unsupported today, but the reason is narrow enough to be worth stating: **only
installation depends on symlinks.** `install.sh` and `uninstall.sh` create and
inspect them; the everyday `pull`, `push` and `sync` scripts contain no symlink
code at all and do nothing but drive git. Get a machine wired up and the rest is
already portable.

**WSL is the path of least resistance** — nothing in csync needs to change there.
The catch is that it only helps if Claude Code itself runs inside WSL. A Windows
Claude Code reads `%USERPROFILE%\.claude`, which is not the `~/.claude` that a WSL
install would be wiring up, so the two never meet. This is expected to work and
has not been tested; `install.sh --dry-run` prints the entire plan without
touching anything, which makes it cheap to find out.

**Git Bash is unverified in two specific ways.** Windows 10 and later allow
unprivileged symlinks under Developer Mode, and Git for Windows carries a
`core.symlinks` setting — but whether its `ln -s` produces a real symlink rather
than MSYS's copy fallback, and which shell Claude Code uses to run a SessionStart
hook on Windows, are both unknown to us. Everything else the scripts call
(`git`, `readlink`, `sed`, `grep`, `find`, `dirname`) is within what Git Bash
ships; `python3` and `jq` are optional either way.

A report from either setup is welcome — WSL in particular only needs one person
to try it before the "untested" above can go away.

**If you need the port itself, fork it.** That is the honest arrangement rather
than a pull request: the changes would be Windows-specific and nobody here runs
Windows to keep them working. The surface is small and already located — symlink
creation and inspection in `install.sh` and `uninstall.sh`, and the places that
assume `~/.claude`. Clone your fork to `~/.claude/skills/csync` and everything
downstream follows it, `/csync update` included, since that is just
`git pull --ff-only` in whatever clone lives there. Add this repo as a second
remote if you want later fixes. It is MIT; there is nothing to ask.

```bash
git clone https://github.com/you/csync.git ~/.claude/skills/csync
git -C ~/.claude/skills/csync remote add upstream https://github.com/redzefyr/csync.git
```

## Install

Before you start, create an **empty private git repository**. csync scaffolds it,
so it needs nothing in it — but it does need to exist, because setup asks for the
URL. On a single machine you can skip that entirely: choose **local only** during
setup and a bare repo on your own disk plays the part of the remote, with nothing
leaving the machine and no account anywhere.

```bash
git clone https://github.com/redzefyr/csync.git ~/.claude/skills/csync
```

That path is not incidental: Claude Code discovers skills under
`~/.claude/skills`, and that link is the only thing that makes `/csync` a
command. Nothing else depends on it — the scripts resolve everything through
pointers — so the clone can live wherever you keep your repositories, as long as
it is linked from there. On a first install you make the link yourself, since
there is no `/csync` yet to ask:

```bash
git clone https://github.com/redzefyr/csync.git ~/dev/csync
ln -s ~/dev/csync ~/.claude/skills/csync
```

`install.sh` maintains it from then on — it repoints the link when the clone
moves, and removes it on uninstall.

Then, in Claude Code:

```
/csync
```

With nothing set up yet, that runs `setup`, which asks two questions — where the
sync repo should live (default `~/.csync`) and whether it has a remote — and then
shows you exactly what it is about to change before it changes anything.

The installer's first pass is a dry run. It prints a plan in which
`ADOPT` means one of your real files is about to be moved into the git repo and
`BACKUP` means one is about to be renamed to `.bak`. Nothing happens until you
say yes.

Once setup finishes, connect a project. Two steps in two places — the working
directory has to be the project before the command can act on it.

In a shell:

```bash
cd ~/dev/my-project
claude
```

Then in that Claude Code session:

```
/csync init
```

`init` ends by telling you to start a new session. That is what makes the
workspace take effect.

## What ends up where

```
~/.claude/
├── skills/csync/              this skill (a clone of this repo, or a link to one)
├── csync-tool   -> ~/.claude/skills/csync      pointer, machine-local
├── csync-repo   -> ~/.csync                    pointer, machine-local
├── csync-projects                              registry of connected projects
├── CLAUDE.md    -> ~/.csync/global/CLAUDE.md   symlink
├── settings.json                               gains one SessionStart hook
└── projects/<key>/memory -> ~/.csync/global/memory/<key>   symlink

~/.csync/                      the sync repo, branch `main`
├── csync.conf                 settings shared by every machine
├── global/CLAUDE.md           the real file behind ~/.claude/CLAUDE.md
├── global/memory/<project>/   the real per-project memory directories
└── bin/                       CLI wrappers, linked into ~/.local/bin

~/.csync.git/                  local-only mode: a bare repo standing in for the remote

~/dev/my-project/.csync/       the workspace, branch `prj/my-project`
├── CLAUDE.md
├── GRAPH.md
├── plans/  notes/  docs/
```

Two symlinks — `csync-tool` and `csync-repo` — are the entire machine-local
configuration. Move either clone and re-running `install.sh` repoints everything,
including the hook.

`~/.claude/settings.json` itself is **not** synced. It holds machine-local
permissions and paths; csync only adds its hook to it.

## The CLAUDE.md files, and which is which

You end up with up to three, and they are not interchangeable.

| file | applies to | who it is for | synced by csync |
|---|---|---|---|
| `~/.claude/CLAUDE.md` | every session on this machine | **you** — your standing preferences | **yes**, as a symlink to `global/CLAUDE.md` |
| `<project>/CLAUDE.md` | that project | **the team** — it is checked into the project repo | no. It belongs to the project |
| `<project>/.csync/CLAUDE.md` | that project | **Claude** — how to work in this workspace | **yes**, on the `prj/<name>` branch |

**`~/.claude/CLAUDE.md` — your rules.** How you want Claude to talk to you, what
it must ask before doing, how you like commits written. It follows you between
machines. This is also where csync puts one short rule of its own (see below).

**`<project>/CLAUDE.md` — the project's rules.** Build commands, conventions,
architecture your teammates also rely on. csync deliberately does not touch it:
it is version-controlled by the project, reviewed by the project, and shared with
people who do not use csync.

**`<project>/.csync/CLAUDE.md` — the workspace's own rules.** A one-line
description of the project, where the plans and notes live, and anything
machine-specific about this project (which language servers are installed, for
instance). It is created by `/csync init` from a template.

One catch worth knowing: **`.csync/CLAUDE.md` is not loaded at session start.**
Claude Code has no reason to look inside a directory it knows nothing about. What
makes it reliably read is a short rule that `setup` offers to add to your global
`CLAUDE.md`:

> When a project root has a `.csync/` directory, read `.csync/CLAUDE.md` and
> `.csync/GRAPH.md` before starting substantive work, and follow them.

If you decline that rule, `init` will still create the workspace and no session
will ever open it. The full text is in
[`templates/repo/global-rules.md`](templates/repo/global-rules.md).

## The memory directories

Claude Code keeps per-project memory — short files it writes about you, the
project, and the decisions you have made — under `~/.claude/projects/`. Each
project gets its own directory, named after the project's absolute path with `/`
and `.` replaced by `-`:

```
~/dev/acme-api   ->   ~/.claude/projects/-Users-ann-dev-acme-api/memory/
```

Inside is an index plus one file per fact:

```
memory/
├── MEMORY.md                     the index, one line per memory
├── deploy-needs-jdk21.md
└── review-before-force-push.md
```

Each file carries frontmatter naming what kind of memory it is (`user`,
`feedback`, `project`, `reference`) and a one-line description used to decide
whether it is relevant. `MEMORY.md` is what gets loaded every session; the
individual files are pulled in as needed.

csync replaces that `memory` directory with a symlink into the sync repo:

```
~/.claude/projects/-Users-ann-dev-acme-api/memory  ->  ~/.csync/global/memory/dev-acme-api/
```

Note the repo-side name: **`dev-acme-api`, keyed relative to your home
directory** rather than `-Users-ann-dev-acme-api`. The local name embeds your
username, which would make the same project resolve to two different directories
on two machines with different accounts. Keying from `$HOME` instead means **your
two machines can have different usernames** — they only need the project to sit
at the same path *under* home.

Projects outside your home directory keep the full mangled key, so those need
identical absolute paths on both machines.

Because each memory directory is its own symlink, connecting a project on a second
machine has to create that individual link, and `install.sh` is what creates it.
**`/csync init` runs it for you**, as a step of its own procedure — that is why
connecting a project is one command and not two. What matters is that the step is
not skipped: without the link Claude writes memories into an unsynced local
directory and they are lost when you switch machines.

## The workspace

`/csync init` scaffolds this inside the project:

```
.csync/
├── CLAUDE.md          how to work in this workspace
├── GRAPH.md           the entry point: live pipelines, next steps, backlog, closed work
├── plans/             one pipeline = one file, YYYYMMDD-YYYYMMDD-<slug>.md
├── notes/
│   ├── decisions.md   what must not be reversed, and why
│   └── traps.md       what is easy to step on
└── docs/
    ├── design/        live — design only, revised whenever the code changes
    └── archive/       the judgment of a given day, left as written
```

The shape is the point. These directories have **different lifetimes**: plans are
deleted when they close, notes are permanent but deliberately capped, design docs
are permanent and get revised, archive is permanent and never does. Mixing them
means reading all of them to decide anything, and once that is true nobody reads
any of them. The lifetime is in the path, so it does not have to be remembered.

`GRAPH.md` is what a session reads first. It says which pipelines are live, what
the next step is for each, and where everything else went when it closed.

The rules — including how findings get handed between pipelines without one
session re-prioritising another's work — are in
[`references/workspace.md`](references/workspace.md). Claude reads that file when
it needs it; you do not have to.

`.csync/` is added to your **global** git excludes file, so it never shows up as
untracked in the project repo and no project `.gitignore` has to mention it.

## Everyday use

| command | what it does |
|---|---|
| `/csync` | dispatches: `setup` if not installed, `init` if this project is not connected, otherwise `sync` |
| `/csync init [name]` | connect the current project — creates `.csync/` on branch `prj/<name>` |
| `/csync sync` | pull everything, then commit and push |
| `/csync list` | the open pipelines as a table — status and waiting findings |
| `/csync open [slug]` | take one up for this session — folds its findings in, renames the session |
| `/csync status` | git status for the sync repo and this session's workspaces |
| `/csync config [key] [value]` | read or change `csync.conf` — workspace directory, auto-title |
| `/csync pull` / `push` | one direction only |
| `/csync cleanup` | prune this project's workspace so a new session can trust it |
| `/csync remote [url]` | give a local-only setup a real remote |
| `/csync update` | update the skill itself and report what changed |
| `/csync uninstall` | unwire this machine, leaving real files behind |

In practice you rarely type any of these. A SessionStart hook fast-forwards
everything when a session opens, and Claude runs `sync` on its own after writing
notes or wrapping up work — reporting it as a single line, because it is
plumbing.

`cleanup` is the exception: it deletes documents and makes judgment calls, so it
only ever runs when you ask for it by name.

`list` goes the other way — it also appears without being asked for, but only
when a `sync` runs in a session that has not opened a pipeline in that project.
The idea is that a sync at the start of a session, or after something unrelated,
ends by telling you what is waiting; a session already deep in one pipeline is
left alone. Each row is one plan: its status line, and how many findings other
sessions have handed it. **The status is quoted as the session that did the work
wrote it** — csync trims it to one line and never rewords it, because a status
reworded by someone who did not do the work still reads as fact.

## Adding a second machine

```bash
git clone https://github.com/redzefyr/csync.git ~/.claude/skills/csync
```

Then in Claude Code, in this order:

1. `/csync` → choose **existing repo** and give it the same remote URL
2. `/csync init` in each project you want connected

That is all of it. `init` runs the installer itself, and that run links the memory
directory the repo already holds for each project — which is what a second machine
needs, and the step people used to have to remember.

## Going from local-only to a remote

Create an empty **private** repository, then:

```
/csync remote git@github.com:you/your-sync-repo.git
```

It mirrors your local bare repo (every branch, `main` and every `prj/*`) up to the
new remote and repoints each clone. It asks first — this is the moment your global
instructions and memory leave the machine.

## What gets pushed

Everything under `global/` goes to the remote verbatim:

- **`global/CLAUDE.md`** — your standing instructions to Claude.
- **`global/memory/**`** — everything Claude has recorded about each project:
  decisions, environment details, things you told it to remember.
- **every `prj/<name>` branch** — your plans, notes and design docs per project.

Memory and workspace notes routinely contain internal details about the work.
**Keep the repository private.** Before the first push — during `setup`, and again
if you later promote a local-only setup with `/csync remote` — csync checks the
remote's visibility rather than taking your word for it, using `gh` where it can
and an anonymous fetch otherwise. A repository that reads as public stops the push;
one it cannot determine is reported as undetermined, not as private.

Turning a repository private after the fact does not recall what was already
fetched or indexed, which is why the check happens before anything is sent.

Not synced: `~/.claude/settings.json` (machine-local permissions and paths),
session transcripts, and anything else under `~/.claude` that csync did not put
there.

## Updating and removing

```
/csync update
```

pulls the tool repo and then tells you what changed — read from the diff between
the revision you were on and the one you landed on, phrased as what a session
will now do differently rather than as a list of touched files. When nothing came
down, it says so in a line and stops there.

It also spells out what the pull alone does not put into effect. Changes to
`SKILL.md` or `references/` apply from your **next** session, because the current
one loaded the old copy at startup. A change under `scripts/` means
`install.sh` should be re-run, since the SessionStart hook records a script path.
Updated `templates/` affect workspaces created from then on and never rewrite the
ones you already have.

You do not have to remember to run it. The SessionStart hook checks the skill's
own clone too — but that one it only ever *reports*: when your copy is cleanly
behind, the session opens with a line saying how many commits are waiting. It is
never merged behind your back, since that would move the rules under work already
in progress, and the clone might be one you are editing. The line stays quiet
when the clone has local commits or the network was down, so its absence is not a
guarantee that you are current.

```
/csync uninstall
```

replaces the symlinks holding your own content — the global `CLAUDE.md` and every
memory directory — with real copies, so nothing disappears afterwards. The links
that are only wiring are removed outright: the pointers, the registry, the hook,
the `bin/` wrappers and the skill link. **The sync repo, your project workspaces
and the skill's own clone are left where they are** — deleting those is your call.
Run it with `--dry-run` first; the skill does.

## When something looks wrong

**"My global CLAUDE.md and memory vanished."** A clone moved and the symlinks are
dangling. Re-run `install.sh`; it rewrites both pointers, the skill link and the
hook path.

**`/csync` is not a command.** Claude Code found no skill at
`~/.claude/skills/csync`. If your clone lives elsewhere, run its
`scripts/install.sh` from a shell — that is what creates the link — then start a
new session, since skills are loaded at session start.

**`.csync/` shows up as untracked in a project.** The entry fell out of your global
git excludes file. Re-running the installer puts it back.

**`DIVERGED sync repo — local 3 / remote 5`.** Two machines each moved on after a
common ancestor. The scripts stop rather than commit on top of it, because a split
committed over gets one commit deeper every run. Ask Claude to resolve it; the
procedure is in [`references/divergence.md`](references/divergence.md). Nothing is
lost in the meantime — your uncommitted work stays in the working tree.

**The session-start pull stopped running.** The hook entry is gone from
`~/.claude/settings.json`. Re-run the installer.

## How it is put together

- **`main`** holds global config; **`prj/<name>`** holds one project's workspace as
  an orphan history — no shared files, no common ancestor. That is deliberate: a
  workspace clone fetches its own branch and nothing else. Expect git tooling to
  misread it (GitHub shows meaningless ahead/behind counts, IDEs offer to merge);
  the branches are never merged or rebased into each other, and everything is
  fast-forward only.
- **Pull is registry-wide, push is `$PWD`-scoped.** Fast-forwarding every known
  clone is safe — it cannot touch uncommitted work — but committing on another
  project's behalf could easily commit half-done work from a session still running
  in another window.
- **A divergence is reported as its own thing, never as "offline".** The two need
  opposite responses: an unreachable remote fixes itself next run, while a split
  gets worse every time sync commits over it.
- **The workspace directory name lives in the repo** (`csync.conf`), not in
  machine-local config. It is the literal directory name inside each project, so
  two machines that disagree end up with two unrelated directories.

## License

MIT — see [LICENSE](LICENSE).
