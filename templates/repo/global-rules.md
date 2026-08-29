## Claude's workspace (`{{WS}}/`)

- When a project root has a `{{WS}}/` directory, read `{{WS}}/CLAUDE.md` and
  `{{WS}}/GRAPH.md` before starting substantive work, and follow them.
  `GRAPH.md` is the entry point — live pipelines and the next step for each are
  there, and **one pipeline is advanced per session**.
- Files Claude creates and maintains — working notes, plans, design documents,
  research, scratch scripts — go under `{{WS}}/`, not into the project repo.
  - `{{WS}}/plans/` — one pipeline per file · `{{WS}}/docs/` — live, with
    `docs/research/` as archive · `{{WS}}/notes/` — decisions and traps, nothing else
  - **Session notes and scratch files do not go in `{{WS}}/`.** Use a scratchpad.
    The structure rules live in the csync skill's `references/workspace.md`
- Exception: code, tests, and documents shared with the team follow the
  project's own conventions and belong in the project repo.
- Decide when to sync yourself — run `/csync sync` after saving memories or
  workspace notes, and when wrapping up work.
- Report a sync in one line ("pulled and pushed"). Do not list commit hashes or
  files. Do raise anything that needs a decision: a diverged history, or a push
  still failing after its retry.
