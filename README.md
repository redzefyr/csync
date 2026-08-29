# csync

**English** · [한국어](README_kr.md)

A Claude Code skill that gives Claude a **persistent, versioned workspace** in
each of your projects — and, if you want it, keeps that workspace and Claude's
global configuration in step across several machines.

Two things go into one private git repository you own:

1. **Claude's global state** — your `~/.claude/CLAUDE.md` and the per-project
   memory directories Claude writes to.
2. **A workspace directory inside each project** (`.csync/` by default) — plans,
   decisions, traps and research that belong to the work but do not belong in the
   project repo.

Install it, type `/csync`, and it walks you through the rest.

## Contents

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

Once setup finishes, connect a project:

```
cd ~/dev/my-project
/csync init
```

## What ends up where

```
~/.claude/
├── skills/csync/              this skill (a clone of this repo)
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

Because each memory directory is its own symlink, **connecting a project on a
second machine requires re-running the installer** — `install.sh` is what creates
that individual link. `/csync init` reminds you and runs it; if you skip it,
Claude writes memories into an unsynced local directory and they are lost when
you switch machines.

## The workspace

`/csync init` scaffolds this inside the project:

```
.csync/
├── CLAUDE.md          how to work in this workspace
├── GRAPH.md           the entry point: live pipelines, next steps, backlog, closed work
├── plans/             one pipeline = one file, <planned>-<advanced>-<slug>.md
├── notes/
│   ├── decisions.md   what must not be reversed, and why
│   └── traps.md       what is easy to step on
└── docs/
    ├── *.md           live — revised whenever code or conventions change
    └── research/      archive — the judgment of a given day, left as written
```

The shape is the point. The three directories have **different lifetimes**:
plans are deleted when they close, notes are permanent but deliberately capped,
docs are permanent and may grow. Mixing them means reading all three to decide
anything, and once that is true nobody reads any of them.

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
3. **run the installer once more** — `~/.claude/skills/csync/scripts/install.sh`

Step 3 is the one people skip. It is what creates the individual memory symlink
for each project you just connected.

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
- **every `prj/<name>` branch** — your plans, notes and research per project.

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

replaces every symlink csync created with a real copy of what it pointed at, so
nothing disappears afterwards, and removes the hook, the pointers and the
registry. **The sync repo and your project workspaces are left where they are** —
deleting those is your call. Run it with `--dry-run` first; the skill does.

## When something looks wrong

**"My global CLAUDE.md and memory vanished."** A clone moved and the symlinks are
dangling. Re-run `install.sh`; it rewrites both pointers and the hook path.

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
