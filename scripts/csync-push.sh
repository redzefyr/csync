#!/usr/bin/env bash
# The push half of sync.
#
# Commits and pushes pending changes in the sync repo and, when run inside a
# project that has one, its workspace clone. Only $PWD's clone is pushed --
# another project may hold half-done work from a session still running there.
# The pull half is scoped the same way and resolves the root the same way, so a
# session's two halves always mean the same clone (see csync-pull.sh).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"

REPO_ROOT="$(csync_repo)" || {
  echo "csync: not installed on this machine -- run /csync setup" >&2
  exit 1
}
WS="$(csync_workspace "$REPO_ROOT")"

# ahead<TAB>behind against @{upstream}, or empty when there is no upstream yet.
# Reads the remote as last fetched -- the pull half runs first and refreshes it.
divergence() {
  git -C "$1" rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null || true
}

push_repo() {
  local dir="$1" label="$2" counts ahead=0 behind=0
  [ -e "$dir/.git" ] || return 0

  counts="$(divergence "$dir")"
  if [ -n "$counts" ]; then
    ahead="${counts%%[[:space:]]*}"
    behind="${counts##*[[:space:]]}"
  fi

  # Already split: stop before adding to it. Committing here would be safe for
  # the *content* but makes the split one deeper every run, which is exactly
  # how a small divergence becomes a big one nobody wants to touch. Uncommitted
  # work stays in the working tree -- nothing is lost, and resolving the split
  # first then committing loses nothing either.
  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    echo "csync: DIVERGED $label -- local $ahead / remote $behind. Stopping without committing." >&2
    echo "csync:   resolve it following references/divergence.md" >&2
    return 2
  fi

  git -C "$dir" add -A

  local committed=0
  if ! git -C "$dir" diff --cached --quiet; then
    git -C "$dir" commit --quiet -m "sync: $(hostname -s) $(date '+%Y-%m-%d %H:%M')"
    committed=1
  fi

  # Say whether anything actually moved. A single "up to date" for both the
  # nothing-to-do case and the just-pushed-213-lines case reads as "did
  # nothing", which sends you off checking the log by hand to find out.
  local head upstream
  head="$(git -C "$dir" rev-parse HEAD)"
  upstream="$(git -C "$dir" rev-parse '@{upstream}' 2>/dev/null || true)"

  # No new commit and already level with the remote: nothing to send.
  # An unset upstream leaves $upstream empty, so that case still pushes.
  if [ "$committed" -eq 0 ] && [ "$head" = "$upstream" ]; then
    echo "csync: $label -- no changes"
    return 0
  fi

  if git -C "$dir" push --quiet -u origin HEAD; then
    echo "csync: $label -- pushed $(git -C "$dir" rev-parse --short HEAD)"
  else
    # Someone pushed between our fetch and this push. One fast-forward retry
    # covers it; anything else is a real divergence for the user to settle.
    if git -C "$dir" pull --ff-only --quiet 2>/dev/null \
       && git -C "$dir" push --quiet -u origin HEAD; then
      echo "csync: $label -- pushed $(git -C "$dir" rev-parse --short HEAD) (retried)"
      return 0
    fi
    echo "csync: push failed for $label -- may be diverged. See references/divergence.md" >&2
    return 1
  fi
}

# One project per run -- the innermost match wins, and other projects are
# deliberately left alone (see the header). csync_project_root is in lib.sh
# because the pull half resolves its scope with the same function.

status=0
push_repo "$REPO_ROOT" "sync repo" || status=1

if ROOT="$(csync_project_root "$PWD")"; then
  csync_remember_project "$ROOT"
  push_repo "$ROOT/$WS" "$WS" || status=1
fi
exit "$status"
