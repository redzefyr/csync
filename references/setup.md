# Setup and connection

Read this when running `setup`, `init` or `remote` — the commands that wire a
machine up or move where the sync repo points. Nothing here is needed by a
session that is only working a pipeline.

Before `setup` has run, `~/.claude/csync-tool` does not exist yet; this file is
then at `~/.claude/skills/csync/references/`, or wherever the tool repo was
cloned.

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

**4. Settle the settings — hand off to `config`** (`references/maintenance.md`).
Run it bare and walk the values with them.

**This has to happen before install, not after.** `install.sh` reads
`workspace_dir` and writes it into the global excludes file as a line of its own;
settle it afterwards and that line names a directory nobody uses.

It is also the only moment `workspace_dir` is a plain setting — see `config` in
`references/maintenance.md`. Nothing is connected yet, so there is nothing to
migrate.

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

**7. Check the rules that make the workspace get read.** Nothing reads
`$WS/notes/` at session start on its own. What makes it deterministic is csync's
rules — read `notes/` in every session, and nothing else under the workspace until
the user runs `/csync` — which step 5 installed into `~/.claude/rules/`:
`csync.md`, a link to `$TOOL/rules/csync.md`, and `csync-workspace.md`, generated
with the workspace name. Confirm the install output showed both, not a `SKIP`.
**Without them, `init` produces a workspace that no session ever opens.**

`$WS/CLAUDE.md` needs no rule of its own: Claude Code loads a subdirectory's
`CLAUDE.md` when a file under it is read with the Read tool, so it arrives with the
first note (observed 2026-09 for a dot-directory, a globally git-ignored one and a
nested clone alike; a shell `cat` did not trigger it).

Then look at the global `CLAUDE.md` being adopted. Earlier versions of csync
appended these rules to it as a section; if one is there, say so and offer to
remove it — it is a copy that no longer changes when the skill does. ⚠️ **If other
machines share this sync repo, only once each has run the new `install.sh`**: the
file reaches them on their next pull, and a machine without the rules link loses
the rules entirely.

⚠️ **Do not move the rules back into the global `CLAUDE.md` or a SessionStart
hook**, and do not paste them anywhere for convenience. Either is a second copy,
and the hook also loses them at compaction.

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
   cp "$TOOL/templates/workspace/CLAUDE.md" "$TOOL/templates/workspace/backlog.md" "$WS/"
   cp "$TOOL/templates/workspace/notes/"*.md "$WS/notes/"
   ```

   Replace `{{NAME}}` and `{{WS}}` in the copied files, and `{{DESCRIPTION}}` with
   one line about the project. Commit, then
   `git -C "$WS" push -u origin "prj/<name>"`.

   Both `notes/` files and `backlog.md` are created **even though they are
   empty**: their headers carry the entry rules and the `gauge`, and a file
   improvised later carries neither. ⚠️ **Keep the workspace `CLAUDE.md` to the
   description and project facts** — it is loaded whenever a note is read, so
   every line in it is charged to every session.
4. Append the project root to `~/.claude/csync-projects` if it is not already
   listed. This is **not** what makes the project sync — both halves resolve
   their project from `$PWD`. It is the list `/csync remote` repoints, and it is
   append-only: add to it, never remove from it.
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
8. **Check the rules before finishing.** Step 7's run must have printed
   `~/.claude/rules/csync.md` and `csync-workspace.md` as linked, written or
   `ok` — a `SKIP` means a file of the user's own holds that name, and **this
   workspace then gets no notes read and no gate**; say so. If the global
   `CLAUDE.md` still carries a csync section from an earlier version, offer to
   remove it, on the terms `setup` step 7 gives
9. **Tell them to start a new session, and say why.** `init` finishes with the
   workspace on disk and nothing reading it: the rules that read `notes/` were
   loaded at session start, and step 7's memory symlink arrived after this session had
   already resolved where memories go. So the project is connected and this
   session still behaves as though it were not — which looks like `init` having
   silently failed. It did not; it takes effect next session.

## /csync remote [url]

Give a local-only setup a real remote — the upgrade path when a second machine
appears. With no argument, report the current origin.

The bare repo already holds every branch, so it is the thing to publish:

```bash
git -C <repo>.git push --mirror <url>          # needs the user's yes
```

Then repoint every clone — the sync repo and each project workspace the registry
names. Missing one leaves it pointed at the old location, where it goes on
working until the day it does not; needing a list that errs long is why that file
is append-only:

```bash
git -C "$REPO" remote set-url origin <url>
while read -r root; do
  [ -e "$root/$WS/.git" ] || continue   # listed, not on this disk: skip, keep the line
  git -C "$root/$WS" remote set-url origin <url>
done < ~/.claude/csync-projects
```

`--mirror` can delete refs on the target, so it is only safe into an **empty**
repo. Verify with `git ls-remote <url>` first, and confirm with the user before
running it.

**Run the privacy gate here too, and run it before the mirror push, not after.**
This is the moment a setup that never left the machine starts leaving it, and it
publishes the whole history at once — every memory and every workspace note ever
committed, not just the current state. A `setup` that ran local-only never had
this checked, so there is no earlier verdict to inherit.
