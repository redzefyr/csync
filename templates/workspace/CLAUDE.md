# {{WS}} — {{NAME}}

{{DESCRIPTION}}

Claude's workspace for this project. This directory is not part of the project
repo: it syncs to the `prj/{{NAME}}` branch of your csync repo. Files Claude
creates and maintains — working notes, plans, findings, scratch analysis — live
here rather than in the project repo.

**Read `GRAPH.md` and `notes/` at the start of every session.** `GRAPH.md` is the
entry point: live pipelines, the next step for each, the backlog, and what has
been closed. **Advance one pipeline per project per session** (a session that
opened several projects gets one in each), and when you finish, update that
plan's "next step" and the advanced-date in its filename.
The source of truth for the structure rules is the csync skill's
`references/workspace.md`.

- `GRAPH.md` — entry point. It also resolves `[[slug]]` references to files
- `plans/` — one pipeline = one file, `<planned>-<advanced>-<slug>.md`
- `notes/` — `decisions` (what must not be reversed) and `traps` (what is easy to
  step on), and nothing else. It is loaded every session, so keep it small
  (gauge: 400 lines)
- `docs/` — **live**, revised whenever code or conventions change ·
  `docs/research/` — **archive**, the judgment of a given day, left as written

Commit and push with `/csync sync` when wrapping up.
