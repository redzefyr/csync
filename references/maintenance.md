# Maintenance

Read this when running `config`, `update` or `uninstall`, when `open` reaches
step 4 with `auto_title` on, or when the user has asked for a `bin/` wrapper.
None of it is needed by a session that is only working a pipeline.

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
directories are renamed — where it fails exactly as `setup` describes in
`references/setup.md`: pull and push look for a directory that is not there, and
every workspace goes unsynced without an error.

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

## The session title — `open` step 4

Read this once `csync_auto_title "$REPO"` has come back `on`. With the setting
off — the default — none of it applies, and `open` says nothing.

**Finding the rename tool.** Hosts name them differently and may keep them behind
a tool search; under Claude Code they are `get_session` and `set_session_title`,
both taking the literal `self`. Read the current title, merge, write it back.

The title:

```
<project>:<slug>                            one pipeline
<projA>:<slugA> / <projB>:<slugB>           several, in the order they were opened
```

**The project prefix is always there, even for a single pipeline.** Slugs collide
across paired repos by design — the two ends of one piece of work carry one name
— and this title is read in a list beside other sessions, where a bare slug does
not say which end. Use the project's `prj/<name>` name.

**Either half of step 4 missing is not a failure, and they are not reported the
same way.** `auto_title = off` is the default and the silent case — say nothing.
A host with no rename tool, where the user *did* turn it on, is worth **one line,
once in the session**: this host has no rename tool. Leave it there. Do not send
them to install one — where the tool exists it arrives with the host, not from
anything installable. Steps 1–3 stand either way; the title is a label on an open
pipeline, not the thing itself.

## /csync update

Update the tool repo, not the user's data — and **report what changed**. An
update that lands as "pulled, done" is one the user cannot act on: the rules
governing how this session works just moved under it, and only they can tell
whether that matters to the work in front of them.

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

## Writing a `bin/` wrapper

Reached only after the user has said yes — see the prohibition in `SKILL.md`.

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
