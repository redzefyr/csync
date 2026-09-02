#!/usr/bin/env bash
# Shared helpers for the csync scripts. Sourced, never executed.
#
# Portability: macOS ships bash 3.2, so nothing here may use associative
# arrays, `readlink -f`, `mapfile`, or `${var^^}`.
#
# It is also sourced by shells other than bash. The scripts here all run under
# bash, but a session follows SKILL.md by calling these helpers from its own
# shell, and that shell is whatever the user's login shell is — zsh, on a stock
# Mac. So nothing here may depend on bash-only parsing. Brace every expansion
# that is followed by `[`: zsh reads `$key[...]` as an array subscript, the
# command substitution dies, and the caller gets the default back through the
# ordinary path with nothing to show that it failed.

# Machine-local state. Both are absolute paths that differ per machine, which
# is exactly why they live outside the synced repo.
CSYNC_POINTER="$HOME/.claude/csync-repo"      # symlink -> the sync repo root
CSYNC_TOOL_POINTER="$HOME/.claude/csync-tool"  # symlink -> the tool repo root
CSYNC_REGISTRY="$HOME/.claude/csync-projects"  # one project root per line, append-only

# Absolute, symlink-resolved path of a directory. `readlink -f` is missing on
# older BSD userlands; `cd -P` is portable back to bash 3.2.
csync_abspath() {
  (cd -P "$1" 2>/dev/null && pwd)
}

# The project root a command should act on: the innermost ancestor of $1 that
# holds a workspace clone. Callers pass $PWD.
#
# $PWD itself is not enough. A session that has just edited a note is sitting
# *inside* the workspace, and a session working on code is often in a
# subdirectory; both used to fall through this check and skip the workspace
# **without saying so**, printing only the sync-repo line. That reads as
# success, so the note stays local and the next machine reads the old one.
#
# Both halves of sync resolve their project through this, so a session's pull
# and its push always mean the same clone.
#
# Needs $WS in scope, so call it after csync_workspace.
csync_project_root() {
  local dir="$1"
  while :; do
    [ -e "$dir/$WS/.git" ] && { printf '%s\n' "$dir"; return 0; }
    [ "$dir" = "/" ] && return 1
    dir="$(dirname "$dir")"
  done
}

# Record a project root in the machine-local registry.
#
# **Append only. Nothing here removes a line, and nothing should.** The
# registry's one reader inside csync is `/csync remote`, which repoints every
# clone on this machine after the sync repo moves; a clone it misses keeps
# working until the day it does not. That reader needs a *superset*, and a line
# for a project that is gone costs it nothing -- the path simply is not there.
#
# The pull sweep used to prune while it walked, which is the opposite trade: a
# project on a disk that happened to be unmounted dropped out silently, and
# nothing ever put it back, because only working in a project adds it.
csync_remember_project() {
  touch "$CSYNC_REGISTRY"
  grep -qxF "$1" "$CSYNC_REGISTRY" || echo "$1" >> "$CSYNC_REGISTRY"
}

# Print the sync repo root, or fail when csync is not installed on this
# machine. Callers decide whether that is an error or a quiet no-op.
csync_repo() {
  [ -L "$CSYNC_POINTER" ] || return 1
  local root
  root="$(csync_abspath "$CSYNC_POINTER")" || return 1
  [ -n "$root" ] || return 1
  printf '%s' "$root"
}

# Print the tool repo root (this skill's own clone). Falls back to the
# documented install location so setup can find its scripts before the pointer
# exists.
csync_tool() {
  local root
  if [ -L "$CSYNC_TOOL_POINTER" ]; then
    root="$(csync_abspath "$CSYNC_TOOL_POINTER")"
    [ -n "$root" ] && { printf '%s' "$root"; return 0; }
  fi
  root="$(csync_abspath "$HOME/.claude/skills/csync")" || return 1
  [ -n "$root" ] || return 1
  printf '%s' "$root"
}

# csync_conf <repo> <key> <default>
#
# Reads `key = value` from <repo>/csync.conf. Deliberately not JSON and
# deliberately not sourced: this runs on every session start, so it must not
# depend on python3/jq being installed, and a config file that is `source`d is
# a config file that can run arbitrary code.
csync_conf() {
  local repo="$1" key="$2" default="$3" value
  value="$(sed -n "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//p" \
    "$repo/csync.conf" 2>/dev/null | sed 's/[[:space:]]*$//' | tail -1)"
  if [ -n "$value" ]; then
    printf '%s' "$value"
  else
    printf '%s' "$default"
  fi
}

# The workspace directory name (`.csync` unless overridden). It must match on
# every machine — it is the literal directory name in each project — so it is
# stored in the repo, not in machine-local state.
csync_workspace() {
  csync_conf "$1" workspace_dir .csync
}

# Whether `open` may rename the session. Prints a normalised `on` or `off`.
#
# Tolerant on read, canonical on write: `config` only ever writes on/off, but a
# hand-edited `true` must not read back as `off` — a setting that silently means
# its opposite is the failure this whole file is written to avoid. Anything
# unrecognised is `off`, since that is also the default.
#
# This is the user's *preference*, identical on every machine, which is why it
# lives here. Whether a given host can actually rename a session is a separate
# question, probed when `open` needs it and never stored.
csync_auto_title() {
  case "$(csync_conf "$1" auto_title off | tr 'A-Z' 'a-z')" in
    on|true|yes|1) printf 'on' ;;
    *)             printf 'off' ;;
  esac
}
