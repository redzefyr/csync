#!/usr/bin/env bash
# One-shot sync for this project: pull the sync repo and this project's
# workspace (via the same script the SessionStart hook runs), then commit and
# push the same two. Pulling first keeps rejected pushes rare; on divergence
# the push half reports and leaves it to the user. A session holding more than
# one project root runs this once from each -- other projects are never touched
# on its behalf.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$HERE/csync-pull.sh"
exec "$HERE/csync-push.sh"
