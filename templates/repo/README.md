# {{NAME}}

Private sync repo for Claude Code, managed by
[csync](https://github.com/redzefyr/csync).

- **`main`** — global config and memory
  - `global/CLAUDE.md` — the real file behind `~/.claude/CLAUDE.md`
  - `global/memory/<project>/` — per-project memory directories
  - `bin/` — CLI wrappers linked into `~/.local/bin`
  - `csync.conf` — settings shared by every machine
- **`prj/<name>`** — one project's workspace directory, with an independent
  (orphan) history per project

**Keep this repository private.** `global/CLAUDE.md` is your global instructions
to Claude and `global/memory/**` holds per-project notes; both are pushed here
verbatim.

Set a machine up with:

```bash
git clone https://github.com/redzefyr/csync ~/.claude/skills/csync
```

then run `/csync` in Claude Code and point it at this repository.
