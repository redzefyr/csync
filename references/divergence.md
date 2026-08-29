# When a history has diverged

`DIVERGED <label> — local N / remote M` means two machines each moved on after a
common ancestor. **The scripts detect it and stop; they never touch the
history** — no automatic rebase, no automatic merge, and no commit at all while
it stands (committing keeps the content safe but drops the split one notch
deeper every run). Resolving it is the user's judgment call, so **investigate,
present the situation, and ask.**

Investigate before asking. "It has diverged" on its own gives the user nothing to
decide with.

```bash
git -C <dir> log --oneline @{upstream}..HEAD | head       # local only
git -C <dir> log --oneline HEAD..@{upstream} | head       # remote only
B=$(git -C <dir> merge-base HEAD @{upstream})
comm -12 <(git -C <dir> diff --name-only $B HEAD | sort) \
         <(git -C <dir> diff --name-only $B @{upstream} | sort)   # conflict candidates
```

Present: the last commit time and host on each side, the commit counts on each
side, **the list of conflict candidates**, and — if no files overlap — say so,
because that case usually merges cleanly on its own.

The options are merge (keeps both histories; the default), rebase (keeps it
linear), or leave it for now. **Never propose anything in the `--force` family**,
from either side.

## Resolving the conflicts

A workspace is a document repository and both sides are real work, so **never
discard one side wholesale.** Two places have drawn blood before.

- **When a completed-items list conflicts, it is usually because each side
  completed different items.** Keep both. Picking one erases the other's record
- **When one side deleted a plan and the other edited it, the editing side is
  usually right.** Even if the deleting side considered it finished, the editing
  side attaching a status banner means unstarted items remain. **A plan with even
  one item left is live** (same test as cleanup). Two plans with a section still
  open were nearly deleted as complete this way
- **Before discarding anything, check whether its traps and evidence exist
  elsewhere.** If they do, discard freely; if not, copy them across
- After merging, **grep the whole tree and the memory directory for the deleted
  filenames** (the same reason cleanup step 5 exists, and the same reason it is
  the step most often skipped)

Write **what you chose and why** in the merge commit message. The same judgment
comes back at the same spot later.

## Not diverging in the first place

A split happens **when one machine leaves without pushing and another one starts
working.** Running `sync` when you finish is the whole preventative. Moving
between machines, run it once more before you leave — and if the session had
several projects open, it has to run **from each project root** (see the "Scope"
section of `SKILL.md`).
