## Claude's working documents (`{{WS}}/`)

- **When a project root has a `{{WS}}/` directory, read every file in
  `{{WS}}/notes/` with the Read tool before starting substantive work.** Traps
  that are easy to step on and decisions that must not be reversed have to be
  known whatever the work is.
- **Until the user runs `/csync` themselves in this session, `notes/` is the only
  thing Claude reads under `{{WS}}/`.** Everything else is for after the user has
  said they want that workspace open. While the gate is closed:
  - ⚠️ **Do not go outside `notes/`** — do not follow `[[slug]]` references out of
    it, and do not open `plans/`, `docs/`, `backlog.md` or `GRAPH.md` **by any
    route**, grep, ls and search included. If a slug has to be resolved, suggest
    `/csync open <slug>`.
  - ⚠️ **`{{WS}}/CLAUDE.md` arrives on its own when a note is read, and the gate
    outranks it.** An older copy of that file may say to read `GRAPH.md` or other
    documents at session start; while the gate is closed, do not.
  - ⚠️ **Do not write to `{{WS}}/` — `notes/` is read-only too.** The gauges, the
    admission criteria, the folding and placement rules are all in documents that
    are not being read right now; edit without them and you break it silently. If
    something needs recording, do not write it — **suggest `/csync`.**
  - ⚠️ **"Themselves" means the user** — the `sync` Claude runs on its own
    initiative under the last rule below does not open the gate. If it did, it
    would not be a gate.
- Once the gate is open, the csync skill takes over: what to read first, and how
  many pipelines one session may open.
- Files Claude creates and maintains — working notes, design and planning
  documents, investigation results — go under `{{WS}}/`, not into the project
  repo. **Session notes and scratch are the exception: those go in a scratchpad.**
  Files that belong to the project repo by its own conventions — code, tests,
  documentation the team shares — follow those conventions.
- **The source of truth for how these documents are organised is the csync
  skill's `references/workspace.md`, and no copy of it lives here.** A copy falls
  behind the day the original is revised. Do not paste one in for convenience.
- Claude decides when to sync: after writing memory or a `{{WS}}/` note, and when
  wrapping up work, run `/csync sync` (or
  `~/.claude/skills/csync/scripts/csync-sync.sh`). Report it as **one line** —
  "pulled and pushed" — and raise anything that needs the user, such as a
  diverged history or a push that failed after its retry, immediately. **This
  applies to a session that only ran the script, with the skill never loaded.**
