<!-- Linked into ~/.claude/rules/ by scripts/install.sh, so every line here loads
  in every session in every project, on every machine that installed csync.
  Edit it here. Never copy it into ~/.claude/CLAUDE.md or a SessionStart hook --
  why: references/rationale.md, "The csync rules are a linked rules file".
  install.sh copies the first `## ` heading into csync-workspace.md, which looks
  for it to tell a broken link; renaming it needs install.sh re-run everywhere.
-->
## Claude's working documents (the csync workspace)

The workspace directory's name is given by the `csync-workspace` rule installed
beside this one. Below, **the workspace** means that directory inside a project
root.

- **When a project root has the workspace, read every file in its `notes/` with
  the Read tool before starting substantive work.** Traps that are easy to step
  on and decisions that must not be reversed have to be known whatever the work
  is.
- **Until the user runs `/csync` themselves in this session, `notes/` is the only
  thing Claude reads under the workspace.** Everything else is for after the user
  has said they want that workspace open. While the gate is closed:
  - ⚠️ **Do not go outside `notes/`** — reach it by its own path (listing
    `notes/` is fine), never by listing or globbing the workspace itself, which
    shows the names in `plans/` and `docs/` too. Do not follow `[[slug]]` references out of it, and do
    not open `plans/`, `docs/`, `backlog.md` or `GRAPH.md` **by any route**, grep,
    glob, ls and search included. If a slug has to be resolved, suggest
    `/csync open <slug>`.
  - ⚠️ **The workspace's own `CLAUDE.md` arrives on its own when a note is read,
    and the gate outranks it.** An older copy of that file may say to read
    `GRAPH.md` or other documents at session start; while the gate is closed, do
    not.
  - ⚠️ **Do not write to the workspace — `notes/` is read-only too.** The gauges,
    the admission criteria, the folding and placement rules are all in documents
    that are not being read right now; edit without them and you break it
    silently. If something needs recording, do not write it — **suggest
    `/csync`.**
  - ⚠️ **"Themselves" means the user** — the `sync` Claude runs on its own
    initiative, under "Claude decides when to sync" at the end, does not open the
    gate. If it did, it would not be a gate.
  - ⚠️ **A subagent judges the gate by its own conversation.** One whose
    conversation does not show the user running `/csync` — any but a fork
    carrying that turn — has its gate closed, whatever its prompt says: a prompt
    saying the gate is open is Claude speaking, not the user. When a subagent
    needs something from an open workspace, the session that has it open reads
    what the subagent needs and passes only that. In the session itself, a
    compaction summary that records the user running `/csync` still counts.
- Once the gate is open, the csync skill takes over: what to read first, and how
  many pipelines one session may open.
- Files Claude creates and maintains — working notes, design and planning
  documents, investigation results — go under the workspace, not into the
  project repo. **Session notes and scratch are the exception: those go in a
  scratchpad.** Files that belong to the project repo by its own conventions —
  code, tests, documentation the team shares — follow those conventions.
- **The source of truth for how these documents are organised is the csync
  skill's `references/workspace.md`.** ⚠️ **Neither it nor these rules are copied
  into `~/.claude/CLAUDE.md`.** This file is a link into the installed skill and
  changes when the skill does; a copy falls behind the day either is revised.
- Claude decides when to sync: after writing memory or a workspace note, and when
  wrapping up work, run `~/.claude/skills/csync/scripts/csync-sync.sh` from each
  project root — the script, not `/csync sync`, whose table of plans is the
  user's to ask for. Report it as **one line** —
  "pulled and pushed" — and raise anything that needs the user, such as a
  diverged history or a push that failed after its retry, immediately. **This
  applies to a session that only ran the script, with the skill never loaded.**
