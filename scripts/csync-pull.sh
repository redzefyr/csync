#!/usr/bin/env bash
# The pull half of sync, and the SessionStart hook.
#
# Fast-forwards the sync repo and this session's project workspace clone.
# Never blocks the session on failure: an unreachable remote is normal.
#
# The tool repo is fetched but never merged -- see check_tool_update below.
#
# Scope mirrors the push half: the sync repo and *one* project, resolved by the
# same csync_project_root. A session holding more than one project root runs
# this once from each, exactly as it runs the push half -- one rule for both
# directions instead of one each.
#
# It used to fast-forward every clone in the registry. Fast-forward cannot touch
# uncommitted work, so that was safe -- but safe is a permission, not a purpose.
# A split only grows where this machine commits, and it only commits where you
# are working, so the sweep bought early warning of something that was not
# getting worse, and charged a network fetch per idle clone to every session
# start. It also pruned as it walked, which is the part that did damage; see
# csync_remember_project in lib.sh.
#
# Divergence is reported as its own thing, never folded into "offline". The
# two need opposite responses -- an unreachable remote fixes itself on the next
# run, while a diverged history gets *worse* every time sync commits on top of
# it -- so one message covering both gets read as the harmless one, and the
# split grows by a commit per sync until someone finally looks. That is how a
# 19-vs-53 split went unnoticed for two days (2026-08-26).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"

REPO_ROOT="$(csync_repo)" || exit 0   # not installed: nothing to pull
WS="$(csync_workspace "$REPO_ROOT")"

# Fast-forward one clone, naming precisely what stopped it:
#   unreachable  -> offline, harmless, retried next run
#   ahead+behind -> DIVERGED, needs a decision (references/divergence.md)
#   behind only  -> fast-forward, the ordinary case
pull_one() {
  local dir="$1" label="$2" counts ahead behind

  if ! git -C "$dir" fetch --quiet origin 2>/dev/null; then
    echo "csync: $label -- remote unreachable (offline). Will retry next run." >&2
    return 0
  fi

  # No upstream yet (a clone that has never pushed): nothing to fast-forward.
  counts="$(git -C "$dir" rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)" || return 0
  ahead="${counts%%[[:space:]]*}"
  behind="${counts##*[[:space:]]}"

  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    echo "csync: DIVERGED $label -- local $ahead / remote $behind" >&2
    echo "csync:   sync cannot complete until this is settled, and each run adds one more local commit" >&2
    return 0
  fi

  if [ "$behind" -gt 0 ]; then
    git -C "$dir" merge --ff-only --quiet '@{upstream}' 2>/dev/null \
      || echo "csync: $label -- fast-forward failed (check the working tree)" >&2
  fi
  return 0
}

# The tool repo is checked, never merged. Two reasons the hook must not pull it:
# this session already loaded the old SKILL.md, so a silent merge leaves the
# files on disk and the rules actually running out of step; and this clone is
# the one a contributor edits, so a merge can land on top of their work.
# Announcing it and leaving the merge to `/csync update` keeps both honest.
#
# Silent unless the answer is a clean "N commits are waiting". Offline is
# normal and would otherwise add a line to every session, and a clone that is
# ahead is someone's working tree -- not something a session-start hook should
# have an opinion about.
#
# The one exception is a clone that shares no history with origin, because
# origin was rewritten. That clone counts as *ahead* of a history it has nothing
# in common with, so the silence above would swallow it -- permanently, and in
# the one case where nothing else will say it either: `/csync update` only runs
# when the user asks, and its --ff-only failure reads like ordinary local work.
# Being ahead is a state the user chose; this one happened to them.
check_tool_update() {
  local dir counts ahead behind
  dir="$(csync_tool)" || return 0
  [ -e "$dir/.git" ] || return 0     # installed by copying files, not by cloning

  git -C "$dir" fetch --quiet origin 2>/dev/null || return 0

  # No upstream at all is not a rewrite -- say nothing. Checking this first
  # keeps the merge-base below from reading a missing ref as a rewritten one.
  git -C "$dir" rev-parse --verify --quiet '@{upstream}' >/dev/null 2>&1 || return 0

  if ! git -C "$dir" merge-base HEAD '@{upstream}' >/dev/null 2>&1; then
    echo "csync: tool clone shares no history with origin -- it was rewritten." >&2
    echo "csync:   nothing local is broken and there is no work here to rescue," >&2
    echo "csync:   but no pull will succeed again. Re-clone, or reset --hard to origin." >&2
    return 0
  fi

  counts="$(git -C "$dir" rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)" || return 0
  ahead="${counts%%[[:space:]]*}"
  behind="${counts##*[[:space:]]}"

  [ "$ahead" -eq 0 ] && [ "$behind" -gt 0 ] || return 0

  echo "csync: tool update available -- $behind commit(s) behind origin." >&2
  echo "csync:   run /csync update to apply it and see what changed" >&2
}

pull_one "$REPO_ROOT" "sync repo"
check_tool_update

# The project this run is for. $CLAUDE_PROJECT_DIR is what the SessionStart hook
# is handed; $PWD covers being invoked from a root directly, and walking up from
# it covers standing inside the workspace or in a source subdirectory.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -e "$CLAUDE_PROJECT_DIR/$WS/.git" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
else
  ROOT="$(csync_project_root "$PWD")" || ROOT=""
fi

if [ -n "$ROOT" ]; then
  csync_remember_project "$ROOT"
  pull_one "$ROOT/$WS" "${ROOT#"$HOME"/}/$WS"
fi
exit 0
