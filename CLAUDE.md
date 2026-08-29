# Working in the csync tool repo

This repository **is** the skill — `SKILL.md`, `references/`, `scripts/`,
`templates/`. It is public and MIT-licensed. The user's data lives in a separate
**private** repo (the sync repo, `~/.csync` on this machine). Never conflate the
two: this one holds the mechanism, that one holds their global instructions,
memory and workspaces.

## This clone is live

`~/.claude/skills/csync` is a symlink to this directory, so an edit here changes
the installed skill immediately, before any commit.

- **`SKILL.md` and `references/` are loaded at session start.** Editing them does
  not change the session already running. Say so rather than proceeding as if the
  new rule were in force.
- **`scripts/` act on the user's real environment.** `install.sh` and
  `uninstall.sh` take `--dry-run`, and that is the only correct first invocation —
  of the two, `install.sh` is the one that moves the user's actual
  `~/.claude/CLAUDE.md` into a git repo.
- Do not "test" a script by running it plainly to see what happens.

## This repository is public, and nothing personal belongs in it

Everything committed here ships to people who share nothing with the user but the
tool. Keep all of this out:

- **names** — the user, their machines, their git identity, their private remote
- **their projects**, in any form — repo names, module names, a domain from their
  work, a real ticket or branch name
- **paths under their home**, and their `workspace_dir` when it is not the default
- **assumptions from their setup** — how many machines they run, what language
  they speak, which editor or toolchain they happen to use
- **conventions inherited from their own global rules.** This repo's conventions
  are the sections above and nothing else

Examples use placeholders: `~/dev/my-project`, `you/your-sync-repo`, `~/.csync`.

### Check the staged diff before every commit

The rule above is not enough by itself. It was already in force when a real
project name reached `SKILL.md` as a worked example, and when the private repo's
name reached this file — both read as perfectly natural prose, which is exactly
why prose review misses them. Derive the pattern from the machine so that no real
name has to be written down here:

```bash
REPO="$(cd -P ~/.claude/csync-repo && pwd)"
pat=$( { echo "$HOME"; hostname -s
         git config --global user.email; git config --local user.email
         ls "$REPO/global/memory" | sed 's/^Developer-project-//; s/^Developer-//' |
           awk -F- '{print; if (NF>1) print $1}'
         git -C "$REPO" remote get-url origin | sed 's#.*[/:]##; s#\.git$##'
         ws=$(sed -n 's/^ *workspace_dir *= *//p' "$REPO/csync.conf")
         [ "$ws" = .csync ] || echo "$ws"
       } | grep -v '^$' | grep -vxE 'csync|csync-tool|csync-repo' | awk 'length >= 4' |
       sed 's/[][^$.*\\/]/\\&/g' | sort -u | paste -sd'|' - )
git diff --cached | grep -i -nE "$pat"
```

It only knows what it can derive: memory-directory keys, the sync remote, the
hostname, the git identity, `$HOME`, a non-default `workspace_dir`. A project the
sync repo holds no memory for is invisible to it, and so is anything the user
mentioned only in conversation. **A clean run is one check passed, not
clearance** — read the diff too.

### Commit identity

The author field is as public as the diff, and git resolves it per-clone: a fresh
clone has no local setting and falls back to whatever global identity the machine
happens to carry. That is how a work address once reached three commits here, and
the staged-diff scan above cannot catch it — the scan reads the diff, not the
commit header.

The identity this repo commits under is a **deliberate choice**, never the machine
default. Before the first commit in a clone:

```bash
git config --local user.email    # empty means the next commit uses the global identity
```

If it is empty, **ask which identity to use.** Do not infer one and do not fall
through to the global value — that address may be one the user does not want
attached to a public repository. Both `user.name` and `user.email` are set
locally, together.

## Language

Documentation, comments and commit messages are **English** — this repo is
distributed to people who do not share the user's language. The private data repo
is Korean; do not carry that convention across.

## Remote operations

The standing permission to commit and push without asking applies **only** to the
user's private sync repo. Here, report the commit message before committing, and
do not push, tag or publish a release unless asked.

## Two documents, two audiences

| file | written for | contains |
|---|---|---|
| `README.md` | a person installing or evaluating csync | what it does, how to set it up, what gets pushed, what to do when something looks wrong |
| `SKILL.md` | Claude, at runtime | subcommand procedures and the rules governing them; `references/` holds what is too long to keep loaded |

Keep them apart. Procedure does not go in `README.md`, and installation prose
does not go in `SKILL.md`. The same split governs the sync repo's own two root
files — see its `CLAUDE.md` and `README.md`.

`references/workspace.md` is the source of truth for how a workspace is
organised. When a rule about `plans/`, `notes/`, `docs/` or `GRAPH.md` changes, it
changes there — not in a second copy inside `SKILL.md`.

## No workspace here

Neither this repo nor the sync repo gets a workspace directory of its own; bare
`/csync` always means `sync` inside them. csync work memory attaches to this
project's key, `Developer-csync`, because this is where those sessions are opened.
