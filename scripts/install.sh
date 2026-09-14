#!/usr/bin/env bash
# Wire this machine up to a csync sync repo. Idempotent: safe to re-run, and
# re-running is the documented fix for most "my config vanished" symptoms.
#
#   install.sh [--dry-run] [--repo <path>]
#
# --dry-run prints the plan and changes nothing. The skill always runs it that
# way first: this script adopts your real ~/.claude/CLAUDE.md into a git repo
# and replaces it with a symlink, which is not something to do to someone's
# machine without showing them first.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# -P, so the value does not depend on which path install.sh was invoked through.
# A clone reached via a symlink would otherwise yield a different TOOL_ROOT each
# time and the pointer below would be rewritten on every run.
TOOL_ROOT="$(cd -P "$HERE/.." && pwd)"
. "$HERE/lib.sh"

CLAUDE_DIR="$HOME/.claude"
DRY=0
REPO_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --repo) shift; REPO_ARG="${1:-}" ;;
    --repo=*) REPO_ARG="${1#--repo=}" ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "install.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -n "$REPO_ARG" ]; then
  REPO_ROOT="$(csync_abspath "$REPO_ARG")"
  if [ -z "$REPO_ROOT" ]; then
    echo "install.sh: no such directory: $REPO_ARG" >&2
    exit 2
  fi
else
  REPO_ROOT="$(csync_repo)" || {
    echo "install.sh: csync is not installed yet -- pass --repo <path> (run /csync setup)" >&2
    exit 2
  }
fi

if [ ! -d "$REPO_ROOT/.git" ]; then
  echo "install.sh: $REPO_ROOT is not a git repository" >&2
  exit 2
fi
if [ ! -f "$REPO_ROOT/csync.conf" ]; then
  echo "warning: $REPO_ROOT/csync.conf is missing -- assuming workspace_dir=.csync" >&2
fi

WS="$(csync_workspace "$REPO_ROOT")"

if [ "$DRY" -eq 1 ]; then
  echo "== plan only, nothing will be changed =="
fi
echo "sync repo:   $REPO_ROOT"
echo "tool repo:   $TOOL_ROOT"
echo "workspace:   $WS/"
echo

# say <message>       -- always printed
# act <command...>    -- run it, unless this is a dry run
act() { if [ "$DRY" -eq 0 ]; then "$@"; fi; }

# Create a symlink at $2 pointing to $1.
# If a real file/dir already exists at $2: adopt it into the repo when the
# repo side is missing, otherwise keep the repo side and back up the local one.
link() {
  local target="$1" link_path="$2"

  if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ]; then
    echo "ok:       $link_path (already linked)"
    return 0
  fi

  # A symlink that points somewhere else entirely -- someone's dotfiles repo,
  # or a predecessor tool. Say so instead of quietly taking it over.
  if [ -L "$link_path" ]; then
    echo "REPOINT:  $link_path (was -> $(readlink "$link_path"))"
  fi

  if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
    if [ ! -e "$target" ]; then
      echo "ADOPT:    $link_path -> moved into the repo at $target"
      act mkdir -p "$(dirname "$target")"
      act mv "$link_path" "$target"
    else
      echo "BACKUP:   $link_path -> $link_path.bak (the repo version wins)"
      act mv "$link_path" "$link_path.bak"
    fi
  fi
  echo "link:     $link_path -> $target"
  act mkdir -p "$(dirname "$link_path")"
  act ln -sfn "$target" "$link_path"
}

act mkdir -p "$CLAUDE_DIR"

# 1. The one machine-local pointer. Everything else resolves through it, so
#    moving the sync repo is a one-line fix instead of a rebuild.
if [ -L "$CSYNC_POINTER" ] && [ "$(csync_abspath "$CSYNC_POINTER")" = "$REPO_ROOT" ]; then
  echo "ok:       $CSYNC_POINTER (already points at the sync repo)"
else
  echo "link:     $CSYNC_POINTER -> $REPO_ROOT"
  act ln -sfn "$REPO_ROOT" "$CSYNC_POINTER"
fi

# 2. Pointer to this skill's own clone, so the scripts can find each other
#    and their templates no matter where the skill was cloned.
if [ -L "$CSYNC_TOOL_POINTER" ] && [ "$(csync_abspath "$CSYNC_TOOL_POINTER")" = "$TOOL_ROOT" ]; then
  echo "ok:       $CSYNC_TOOL_POINTER (already points at the tool repo)"
else
  echo "link:     $CSYNC_TOOL_POINTER -> $TOOL_ROOT"
  act ln -sfn "$TOOL_ROOT" "$CSYNC_TOOL_POINTER"
fi

# 3. Claude Code only discovers skills under ~/.claude/skills. The pointer above
#    lets the scripts and templates find each other from anywhere, but nothing
#    loads SKILL.md, so a clone kept elsewhere leaves the *skill* uninstalled --
#    /csync is simply not a command. Link the clone into place.
SKILL_LINK="$CLAUDE_DIR/skills/csync"
if [ "$(csync_abspath "$SKILL_LINK")" = "$TOOL_ROOT" ]; then
  echo "ok:       $SKILL_LINK (already resolves to the tool repo)"
elif [ -e "$SKILL_LINK" ] && [ ! -L "$SKILL_LINK" ]; then
  # A real directory: a second clone, installed the documented way. Backing it
  # up the way link() does would move someone's git clone aside, so refuse and
  # say which copy is actually in force -- that one is, not this one.
  echo "SKIP:     $SKILL_LINK is a real directory, not a link to this clone." >&2
  echo "          Claude Code loads that copy of the skill, not $TOOL_ROOT." >&2
  echo "          Remove it, or install from it instead, then re-run." >&2
else
  [ -L "$SKILL_LINK" ] && echo "REPOINT:  $SKILL_LINK (was -> $(readlink "$SKILL_LINK"))"
  echo "link:     $SKILL_LINK -> $TOOL_ROOT"
  act mkdir -p "$(dirname "$SKILL_LINK")"
  act ln -sfn "$TOOL_ROOT" "$SKILL_LINK"
fi

# 4. Ignore the workspace dir in every repo, without touching shared
#    .gitignore files that belong to the projects themselves.
excludes="$(git config --global core.excludesFile 2>/dev/null || true)"
if [ -z "$excludes" ]; then
  excludes="$HOME/.config/git/ignore"
  echo "git:      core.excludesFile = $excludes"
  act git config --global core.excludesFile "$excludes"
fi
excludes="${excludes/#\~/$HOME}"
if [ -f "$excludes" ] && grep -qxF "$WS/" "$excludes" 2>/dev/null; then
  echo "ok:       $WS/ already in $excludes"
else
  echo "excludes: $WS/ -> $excludes"
  if [ "$DRY" -eq 0 ]; then
    mkdir -p "$(dirname "$excludes")"
    touch "$excludes"
    echo "$WS/" >> "$excludes"
  fi
fi

# 5. Global CLAUDE.md. When neither side exists yet, seed the repo copy first:
#    link() would otherwise leave a dangling symlink at ~/.claude/CLAUDE.md,
#    which reads as "Claude lost my global instructions".
if [ ! -e "$REPO_ROOT/global/CLAUDE.md" ] && [ ! -e "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "create:   $REPO_ROOT/global/CLAUDE.md (empty -- no global instructions yet)"
  if [ "$DRY" -eq 0 ]; then
    mkdir -p "$REPO_ROOT/global"
    printf '# Global instructions\n\nRules that apply to every Claude Code session on every machine.\n' \
      > "$REPO_ROOT/global/CLAUDE.md"
  fi
fi
link "$REPO_ROOT/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 6. CLI wrappers: link everything in the repo's bin/ into ~/.local/bin.
if [ -d "$REPO_ROOT/bin" ]; then
  for f in "$REPO_ROOT"/bin/*; do
    [ -f "$f" ] || continue
    link "$f" "$HOME/.local/bin/$(basename "$f")"
  done
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "warning: ~/.local/bin is not on PATH -- add it to your shell profile" >&2 ;;
  esac
fi

# 7. Per-project memory: adopt local dirs into the repo, then link every dir
#    the repo already has (covers dirs created on another machine).
#
# Claude keys project dirs by absolute path with '/', '.' and spaces mangled to '-'
# (/Users/ann/dev/foo -> -Users-ann-dev-foo), which embeds the username.
# Store repo dirs keyed relative to $HOME instead (dev-foo), so machines with
# different usernames resolve to the same repo directory. Projects outside
# $HOME keep their full mangled key and need identical paths on both machines.
# The set of characters must match Claude's mangling exactly. A '/' or '.' in
# $HOME was covered from the start; a space was not, and a $HOME containing one
# ("/Users/First Last") then produced a HOME_KEY that no project key begins
# with. Every project on that machine would fall through to its full mangled
# key -- silently giving up the username-independence this whole block exists
# for, and splitting one project into two memory directories across machines.
HOME_KEY="$(printf '%s' "$HOME" | tr '/. ' '---')"

# A mangled key can never contain '.', because mangling is what turns '.' into
# '-'. That makes a leading "home." an unambiguous marker, and it is needed for
# exactly one case the plain rule gets wrong: a project directly under $HOME
# whose name starts with a dot. ~/.csync -- csync's own default location --
# mangles to -Users-ann--csync, strips to "-csync", and the leading '-' would
# then be misread as an absolute-path key, linking memory into a directory
# nothing ever reads.
repo_key() {
  local stripped
  case "$1" in
    "$HOME_KEY"-*)
      stripped="${1#"$HOME_KEY"-}"
      case "$stripped" in
        -*) printf 'home.%s' "$stripped" ;;
        *) printf '%s' "$stripped" ;;
      esac
      ;;
    *) printf '%s' "$1" ;;
  esac
}

local_name() {
  case "$1" in
    home.*) printf '%s' "$HOME_KEY-${1#home.}" ;;
    -*) printf '%s' "$1" ;;
    *) printf '%s' "$HOME_KEY-$1" ;;
  esac
}

# Both directions below walk the same pairs, so each link comes up twice.
# Report it once -- the plan is something the user has to read.
linked_paths=""
link_memory() {
  local target="$1" link_path="$2"
  case " $linked_paths " in *" $link_path "*) return 0 ;; esac
  linked_paths="$linked_paths $link_path"

  # A memory symlink whose repo directory never existed -- the directory was
  # empty, so git never tracked it -- is left dangling, and every memory write
  # into it fails. Create the directory instead of walking past it.
  if [ ! -e "$target" ] && [ -L "$link_path" ]; then
    echo "create:   $target (repairing a dangling link)"
    act mkdir -p "$target"
  fi
  link "$target" "$link_path"
}

for pdir in "$CLAUDE_DIR"/projects/*/; do
  # -L as well as -d: a dangling symlink is precisely the case needing repair.
  [ -d "$pdir/memory" ] || [ -L "$pdir/memory" ] || continue
  link_memory "$REPO_ROOT/global/memory/$(repo_key "$(basename "$pdir")")" "${pdir%/}/memory"
done
for mdir in "$REPO_ROOT"/global/memory/*/; do
  [ -d "$mdir" ] || continue
  link_memory "${mdir%/}" "$CLAUDE_DIR/projects/$(local_name "$(basename "$mdir")")/memory"
done

# 8. SessionStart hook -> the tool repo's pull script. The path is the skill's
#    own directory, not the sync repo's, so moving the sync repo never breaks
#    the hook.
HOOK_CMD="$TOOL_ROOT/scripts/csync-pull.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

register_hook_python() {
  python3 - "$SETTINGS" "$HOOK_CMD" "$DRY" <<'PYEOF'
import json, os, sys

path, cmd, dry = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)

entries = data.setdefault("hooks", {}).setdefault("SessionStart", [])

# Drop every csync hook first, ours included, then add ours back. That makes
# the script idempotent AND cleans up an entry left behind by a tool repo that
# has since moved -- a dead hook that otherwise fails silently every session.
def keep(h):
    return not h.get("command", "").endswith("csync-pull.sh")

before = json.dumps(entries, sort_keys=True)
kept = []
for e in entries:
    e = dict(e)
    e["hooks"] = [h for h in e.get("hooks", []) if keep(h)]
    if e["hooks"]:
        kept.append(e)
kept.append({"matcher": "startup", "hooks": [{"type": "command", "command": cmd}]})

if json.dumps(kept, sort_keys=True) == before:
    print("ok:       SessionStart hook already registered")
    sys.exit(0)

print("hook:     SessionStart -> " + cmd)
if dry:
    sys.exit(0)

data["hooks"]["SessionStart"] = kept
tmp = path + ".csync-tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
PYEOF
}

register_hook_jq() {
  local tmp
  [ -f "$SETTINGS" ] || { [ "$DRY" -eq 1 ] || echo '{}' > "$SETTINGS"; }
  echo "hook:     SessionStart -> $HOOK_CMD"
  [ "$DRY" -eq 1 ] && return 0
  tmp="$SETTINGS.csync-tmp"
  jq --arg cmd "$HOOK_CMD" '
    .hooks.SessionStart = (
      ((.hooks.SessionStart // [])
        | map(.hooks = ((.hooks // []) | map(select((.command // "") | endswith("csync-pull.sh") | not))))
        | map(select((.hooks | length) > 0)))
      + [{matcher: "startup", hooks: [{type: "command", command: $cmd}]}]
    )' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
}

if command -v python3 >/dev/null 2>&1; then
  register_hook_python
elif command -v jq >/dev/null 2>&1; then
  register_hook_jq
else
  echo "warning: neither python3 nor jq found -- add this to $SETTINGS by hand:" >&2
  cat >&2 <<MANUAL
  "hooks": {
    "SessionStart": [
      { "matcher": "startup",
        "hooks": [ { "type": "command", "command": "$HOOK_CMD" } ] }
    ]
  }
MANUAL
fi

# 9. csync's own rules -- the read gate, where Claude's documents go, when to
#    sync. They have to hold in sessions that never load the skill, so they live
#    in ~/.claude/rules/, which loads in every session, survives compaction and
#    reaches subagents. Two files:
#
#    csync.md is a link into the tool clone, through the pointer rather than to
#    $TOOL_ROOT, so a moved clone is repaired by step 2 alone. Being a link, it
#    changes when the skill does -- never a copy that falls behind.
#
#    csync-workspace.md is generated, and does two jobs. It names the workspace
#    directory, which the linked rules cannot hardcode. And it is a real file, so
#    it is still loaded when the link above dangles -- which Claude Code skips
#    without a word -- and can tell the session the rules are missing.
RULES_DIR="$CLAUDE_DIR/rules"
RULES_LINK="$RULES_DIR/csync.md"
RULES_TARGET="$CSYNC_TOOL_POINTER/rules/csync.md"
WS_RULE="$RULES_DIR/csync-workspace.md"
WS_RULE_MARK="<!-- csync:generated"

if [ -L "$RULES_LINK" ] && [ "$(readlink "$RULES_LINK")" = "$RULES_TARGET" ]; then
  echo "ok:       $RULES_LINK (already linked)"
elif [ -e "$RULES_LINK" ] && [ ! -L "$RULES_LINK" ]; then
  # Someone's own rules file under our name. link()'s ADOPT would move it into
  # the tool clone, which is not somewhere their file belongs.
  echo "SKIP:     $RULES_LINK is a real file, not csync's link." >&2
  echo "          csync's rules stay uninstalled until it is renamed; then re-run." >&2
else
  [ -L "$RULES_LINK" ] && echo "REPOINT:  $RULES_LINK (was -> $(readlink "$RULES_LINK"))"
  echo "link:     $RULES_LINK -> $RULES_TARGET"
  act mkdir -p "$RULES_DIR"
  act ln -sfn "$RULES_TARGET" "$RULES_LINK"
fi

# The heading this file tells the session to look for is read from the rules
# themselves, so renaming it there leaves no stale copy here -- only a file that
# is regenerated on the next run.
#
# No heading, no file: a sentinel naming a heading the rules do not carry reports
# the link broken in every session, working link or not. Leaving the file out
# (or as it was) loses only the warning.
RULES_HEADING="$(sed -n 's/^## //p' "$TOOL_ROOT/rules/csync.md" 2>/dev/null | head -1 | tr -d '\r')"

ws_rule() {
  cat <<EOF
$WS_RULE_MARK by csync's scripts/install.sh from csync.conf. Edits are
  overwritten: change workspace_dir with /csync config, then re-run install.sh. -->
## csync workspace directory

csync's workspace directory is \`$WS/\` in every project.

The rules for it arrive in a second rules file, linked from the installed csync
skill, under this heading:

"$RULES_HEADING"

⚠️ **If that heading is not in your context beside this one, the link is broken**
— or this host skips linked rules files, as Cowork sessions do. Then read nothing
and write nothing under \`$WS/\`, \`notes/\` included: tell the user once, and
suggest re-running csync's \`scripts/install.sh\`.
EOF
}

want="$(ws_rule)"
if [ -z "$RULES_HEADING" ]; then
  echo "SKIP:     $WS_RULE -- no '## ' heading in $TOOL_ROOT/rules/csync.md; is this clone complete?" >&2
elif [ -L "$WS_RULE" ]; then
  # A link, dangling or not, is never the file this writes -- and writing through
  # a dangling one would create its target, somewhere outside ~/.claude/rules/.
  echo "SKIP:     $WS_RULE is a symlink; csync writes a real file here -- remove it, then re-run." >&2
elif [ -f "$WS_RULE" ] && [ "$(cat "$WS_RULE")" = "$want" ]; then
  echo "ok:       $WS_RULE (up to date)"
elif [ -e "$WS_RULE" ] && ! grep -qF "$WS_RULE_MARK" "$WS_RULE" 2>/dev/null; then
  echo "SKIP:     $WS_RULE exists and was not written by csync -- rename it, then re-run." >&2
else
  echo "write:    $WS_RULE (workspace directory: $WS/)"
  if [ "$DRY" -eq 0 ]; then
    mkdir -p "$RULES_DIR"
    printf '%s\n' "$want" > "$WS_RULE"
  fi
fi

echo
if [ "$DRY" -eq 1 ]; then
  echo "plan only -- nothing was changed."
else
  echo "done."
fi
