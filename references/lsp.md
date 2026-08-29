# Language-server detection during `init`

`init` records which language servers this machine actually has, so a session
knows whether to use LSP navigation or fall back to text search. Availability is
per-machine, which is why the result is stamped with a date and a hostname.

Detect the project's languages from marker files, then check the matching binary
with `command -v`:

| Marker | Language | Server binary |
|---|---|---|
| `go.mod` | Go | `gopls` |
| `pyproject.toml`, `*.py` | Python | `pyright-langserver` or `basedpyright-langserver` |
| `tsconfig.json`, `package.json` | TS/JS | `typescript-language-server` |
| `Package.swift`, `*.xcodeproj`, `*.swift` | Swift | `sourcekit-lsp` (or via `xcrun --find sourcekit-lsp`) |
| `build.gradle*`, `*.kt` | Kotlin | `kotlin-lsp` (often needs a wrapper — see below) |
| `CMakeLists.txt`, `compile_commands.json`, `*.c`, `*.cpp` | C/C++ | `clangd` |
| `Cargo.toml` | Rust | `rust-analyzer` |
| `pom.xml`, `*.java` | Java | `jdtls` |

Append an `## LSP` section to the workspace's `CLAUDE.md` listing each detected
language, its server, and the result:

```markdown
## LSP

Prefer the LSP tools for code structure (go to definition, find references,
symbol lookup) in the languages below. When the server binary is missing on this
machine, fall back to text search and say so.

- <language>: `<server>` — present (<YYYY-MM-DD>, <hostname>)
- <language>: `<server>` — missing; use text search until it is installed
```

## When the expected binary is not the installed one

A server can be installed and still unreachable. Claude Code's LSP tool invokes
each one under a particular name and argument convention, and the package the
user actually installed may answer to a different name, or reject the arguments
it is handed. Kotlin is the common case: the tool calls `kotlin-lsp --stdio`,
while the widely packaged server has another name and exits on the unknown
argument.

A thin wrapper in the sync repo's `bin/` closes that gap — it takes the name the
tool expects, drops or translates the arguments, and delegates to the real
binary. `bin/` is linked into `~/.local/bin` on every machine, so the wrapper
follows the user around.

Writing one is not a silent step: it puts an executable on the user's `PATH` and
pushes it to every machine they sync. The procedure, including what to show
before asking, is **CLI wrappers in `bin/`** in `SKILL.md`.

Two halves have to line up, and either can be the missing one — the wrapper has
to resolve, **and** the underlying server has to be installed. Report whichever
is absent rather than the symptom.
