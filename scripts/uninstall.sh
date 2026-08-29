#!/usr/bin/env bash
# Unwire this machine from csync, leaving the content behind as real files.
#
#   uninstall.sh [--dry-run]
#
# Every symlink csync created is replaced by a real copy of what it pointed at,
# so nothing disappears when the sync repo is later deleted. The sync repo and
# every project workspace clone are left exactly where they are -- removing
# those is your call, not this script's.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"

CLAUDE_DIR="$HOME/.claude"
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

REPO_ROOT="$(csync_repo)" || {
  echo "uninstall.sh: csync is not installed on this machine" >&2
  exit 0
}

act() { if [ "$DRY" -eq 0 ]; then "$@"; fi; }

[ "$DRY" -eq 1 ] && echo "== plan only, nothing will be changed =="
echo "sync repo (left in place): $REPO_ROOT"
echo

# Replace a symlink that points into the sync repo with a real copy.
detach() {
  local path="$1" dest
  [ -L "$path" ] || return 0
  dest="$(readlink "$path")"
  case "$dest" in
    "$REPO_ROOT"/*) ;;
    *) return 0 ;;   # not ours
  esac
  if [ ! -e "$dest" ]; then
    echo "remove:   $path (dangling)"
    act rm -f "$path"
    return 0
  fi
  echo "detach:   $path (symlink -> real copy)"
  if [ "$DRY" -eq 0 ]; then
    rm -f "$path"
    cp -R "$dest" "$path"
  fi
}

detach "$CLAUDE_DIR/CLAUDE.md"

for pdir in "$CLAUDE_DIR"/projects/*/; do
  detach "${pdir%/}/memory"
done

# Wrappers are just conveniences: unlink rather than copy, so a stale binary
# does not sit on PATH pretending to still be maintained.
for f in "$HOME"/.local/bin/*; do
  [ -L "$f" ] || continue
  case "$(readlink "$f")" in
    "$REPO_ROOT"/bin/*) echo "remove:   $f"; act rm -f "$f" ;;
  esac
done

# SessionStart hook
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$SETTINGS" "$DRY" <<'PYEOF'
import json, os, sys
path, dry = sys.argv[1], sys.argv[2] == "1"
with open(path) as f:
    data = json.load(f)
entries = data.get("hooks", {}).get("SessionStart", [])
kept = []
removed = 0
for e in entries:
    e = dict(e)
    hooks = e.get("hooks", [])
    left = [h for h in hooks if not h.get("command", "").endswith("csync-pull.sh")]
    removed += len(hooks) - len(left)
    e["hooks"] = left
    if left:
        kept.append(e)
if not removed:
    print("ok:       no SessionStart hook to remove")
    sys.exit(0)
print("hook:     removing SessionStart entry")
if dry:
    sys.exit(0)
data["hooks"]["SessionStart"] = kept
# Do not leave empty scaffolding behind in someone's settings file.
if not kept:
    del data["hooks"]["SessionStart"]
if not data.get("hooks"):
    data.pop("hooks", None)
tmp = path + ".csync-tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
PYEOF
  else
    echo "warning: python3 not found -- remove the csync-pull.sh SessionStart hook from $SETTINGS by hand" >&2
  fi
fi

echo "remove:   $CSYNC_POINTER"
act rm -f "$CSYNC_POINTER"
if [ -L "$CSYNC_TOOL_POINTER" ]; then
  echo "remove:   $CSYNC_TOOL_POINTER"
  act rm -f "$CSYNC_TOOL_POINTER"
fi
if [ -f "$CSYNC_REGISTRY" ]; then
  echo "remove:   $CSYNC_REGISTRY"
  act rm -f "$CSYNC_REGISTRY"
fi

echo
WS="$(csync_workspace "$REPO_ROOT")"
echo "left alone on purpose:"
echo "  - the sync repo at $REPO_ROOT"
echo "  - every project's $WS/ clone"
echo "  - '$WS/' in your global git excludes file -- removing it would make"
echo "    every leftover $WS/ show up as untracked in its project repo"
[ "$DRY" -eq 1 ] && echo && echo "plan only -- nothing was changed."
exit 0
