# {{WS}} — {{NAME}}

{{DESCRIPTION}}

Claude's workspace for this project. This directory is not part of the project
repo: it syncs to the `prj/{{NAME}}` branch of your csync repo. Files Claude
creates and maintains — working notes, plans, findings, design documents — live
here rather than in the project repo.

**Read `GRAPH.md` and `notes/` at the start of every session.** `GRAPH.md` is the
entry point: live pipelines, the next step for each, the backlog, and what has
been closed. **Advance one pipeline per project per session** (a session that
opened several projects gets one in each), and when you finish, update that
plan's "next step" and the advanced-date in its filename.
The source of truth for the structure rules is the csync skill's
`~/.claude/skills/csync/references/workspace.md`; the shape the documents take —
YAML frontmatter, the `## findings` block, the emoji vocabulary — is
`document-format.md` beside it. Both are plain files: read them there, whether or
not the skill itself is loaded.

⚠️ **If that plan has a `## findings` block, that block is the session's first
work** — before the "next step" you just read, because another session put those
there precisely because they change this pipeline's premise, next step or cost,
which can make that step stale. Give **each** entry a verdict — **promote** into
the body · **backlog** in `GRAPH.md` · **reject** in one line — and then **delete
the entry**. Weighing a finding and leaving it in place is not folding: the entry
still reads as *not yet judged*, so the next session meets it and decides it
again.

⚠️ **When you create a document here, copy the template from
`~/.claude/skills/csync/templates/document/` and fill it in — `plan.md`,
`design.md`, `archive.md`, `note-decision-entry.md`, `note-trap-entry.md`,
`findings-entry.md`. Do not rebuild the header from memory.** If that directory
is not on this machine, **say so and leave the header out rather than inventing
one**: the frontmatter is machine-read, so a guessed `csync:` value or an
invented key is taken for a real one, and nothing reports the difference.

- `GRAPH.md` — entry point. It also resolves `[[slug]]` references to files
- `plans/` — one pipeline = one file, `<planned>-<advanced>-<slug>.md`
- `notes/` — `decisions` (the standing choices) and `traps` (what is easy to
  step on), and nothing else. It is loaded every session, so keep it small
  (gauge: 500 lines, `GRAPH.md` and `notes/` together).
  ⚠️ **Every `decisions` entry carries an authority marker and it is binding**:
  `mandate` is the user's — raise it and let them decide, never revise it
  yourself; `judgment` is Claude's — revise it once its ground stops holding;
  `held`, which is also how an unmarked entry reads, is treated as a `mandate`
  until it is settled with the user. `notes/decisions.md` states the vocabulary
- `docs/design/` — **live**, design only: how something is built, or the
  criterion it was built against. Revised when the code changes
- `docs/archive/` — the judgment of a given day, left as written. Not the pile
  you can skip: the grounds an option was rejected on live here

Nothing sits directly in `docs/`. Procedures, structural surveys and analysis
guides belong to the code, so they go in the project repo, not here.

Commit and push with `/csync sync` when wrapping up.
