#!/usr/bin/env bash
# One-shot sync: pull everything (sync repo + all registered workspace clones,
# via the same script the SessionStart hook runs), then commit and push the
# sync repo and $PWD's workspace. Pulling first keeps rejected pushes rare; on
# divergence the push half reports and leaves it to the user.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$HERE/csync-pull.sh"
exec "$HERE/csync-push.sh"
