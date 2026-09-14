#!/usr/bin/env bash
# The workspace ledger: what is in this project's workspace, read from the
# documents themselves.
#
#   csync-ledger.sh              plans, backlog, and anything out of shape
#   csync-ledger.sh docs         docs/design and docs/archive, one entry each
#   csync-ledger.sh gauges       every file that declares a gauge, against it
#   csync-ledger.sh resolve SLUG the file a [[slug]] names, or its closed line
#
# It replaces a hand-kept GRAPH.md. An index a session maintains is an index
# that goes stale -- a marker left behind after its findings were folded, a
# status one edit behind the plan -- and every stale line reads exactly like a
# current one. Everything printed here is derived on the spot from frontmatter
# and filenames, so there is nothing to keep in step. Nothing is written to
# disk: a generated file committed from two machines is a divergence on a
# fast-forward-only branch.
#
# **It reports and never repairs** (document-format.md, "Conformance").
# Values are trimmed to their first line and never reworded: a status restated
# by something that did not do the work is indistinguishable from the original.
#
# Like pull and push it acts on one project, found by walking up from $PWD.
set -uo pipefail

# Byte semantics throughout. Under a UTF-8 locale BSD awk aborts on the first
# invalid byte, and a document it gives up on silently reads as legacy. Every
# marker matched here is ASCII or a fixed byte sequence, so nothing is lost.
export LC_ALL=C

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"

if REPO_ROOT="$(csync_repo)"; then
  WS="$(csync_workspace "$REPO_ROOT")"
else
  WS=.csync
fi

ROOT="$(csync_project_root "$PWD")" || {
  echo "csync-ledger: no $WS/ workspace at or above $PWD" >&2
  exit 1
}
W="$ROOT/$WS"

# Frontmatter and body facts of one document, as `key<TAB>value` lines.
#
#   <key>          top-level scalar; a block scalar (`|`) yields its first
#                  non-blank line; a list yields `<n> items`, `[]` `0 items`,
#                  a key with nothing under it an empty value. A repeated key
#                  keeps its first value, for every reader of these facts
#   @fm            1 when the file opens with `---`, else 0
#   @fm_unclosed   1 when that frontmatter never closes
#   @title         the first `# ` heading after the frontmatter
#   @findings      dated `###` entries under `## findings`; -1 with no block
#   @findings_blocks  how many exact `## findings` headings there are
#   @findings_odd  headings that say findings in any other shape
#   @findings_undated `###` headings inside a block that are not entries
#   @legacy_status a `> **Status**:` line, for plans with no frontmatter
#   @judgment      `##` headings ending in `· judgment)` -- legacy decisions.
#                  Matches the default English marker only, so it can miss and
#                  is reported only when it finds something; the legacy
#                  `note/1` kind is reported regardless
#   @untokened     `##` headings with no `(...)` token at the end
#   @item          one per backlog item line (`- ` at column 0)
#   @undated       backlog items that do not open with YYYYMMDD
#
# Only the subset of YAML the format allows is understood: keys at column 0,
# prose as literal block scalars. Headings inside fenced code and HTML comments
# are not headings. Anything else is reported by the caller, never guessed at.
doc_facts() {
  awk '
    function emit(k, v) { if (!(k in seen)) { seen[k] = 1; printf "%s\t%s\n", k, v } }
    function flush() {
      if (key != "") {
        if (mode == "block") emit(key, cur)
        else if (mode == "list") emit(key, cnt > 0 ? cnt " items" : "")
      }
      key = ""; mode = ""; cur = ""; cnt = 0; lind = -1
    }
    BEGIN { state = "start"; fm = 0; title = ""; nfind = -1; infind = 0
            blocks = 0; odd2 = 0; odd3 = 0; pend3 = 0; undh3 = 0; legacy = ""
            judg = 0; untok = 0; undated = 0; infence = 0; incomment = 0; lind = -1 }
    { sub(/\r$/, "") }
    NR == 1 { sub(/^\357\273\277/, "") }
    state == "start" {
      if ($0 == "---") { fm = 1; state = "fm"; next }
      state = "body"
    }
    state == "fm" {
      if ($0 == "---") { flush(); state = "body"; next }
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/) {
        flush()
        key = $0; sub(/:.*/, "", key)
        val = $0; sub(/^[^:]*:[ \t]*/, "", val)
        if (val !~ /^["\047]/) sub(/[ \t]+#.*$/, "", val)
        sub(/[ \t]+$/, "", val)
        if (val ~ /^[|>][-+0-9]*$/) mode = "block"
        else if (val ~ /^".*"$/ || val ~ /^\047.*\047$/) { emit(key, substr(val, 2, length(val) - 2)); key = "" }
        else if (val == "") mode = "list"
        else if (val == "[]") { emit(key, "0 items"); key = "" }
        else { emit(key, val); key = "" }
        next
      }
      if (mode == "block") {
        line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (cur == "" && line != "") cur = line
      } else if (mode == "list" && $0 ~ /^[ \t]*- /) {
        ind = match($0, /[^ \t]/) - 1
        if (lind < 0) lind = ind
        if (ind == lind) cnt++
      }
      next
    }
    state == "body" {
      # Comments first: a fence marker inside a comment is not a fence.
      if (incomment) { if ($0 ~ /-->/) incomment = 0; next }
      # A comment opens at the start of a line. `<!--` inside a code span is
      # prose, and treating it as an opener would hide the rest of the file.
      nocode = $0; gsub(/`[^`]*`/, "", nocode)
      if (!infence && nocode ~ /^[ \t]*<!--/ && nocode !~ /-->/) { incomment = 1; next }

      # Fences close only on the same character, at least as long. An opener
      # whose info string holds a backtick is inline code, not a fence.
      t = $0; sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      if (infence) {
        if (substr(t, 1, 1) == fch && length(t) >= flen && t ~ (fch == "`" ? "^`+$" : "^~+$")) infence = 0
        next
      }
      if (match(t, /^(```+|~~~+)/)) {
        rest = substr(t, RLENGTH + 1)
        if (!(substr(t, 1, 1) == "`" && rest ~ /`/)) {
          infence = 1; fch = substr(t, 1, 1); flen = RLENGTH; next
        }
      }

      if (title == "" && $0 ~ /^# /) title = substr($0, 3)
      if (legacy == "" && $0 ~ /^> \*\*Status\*\*:/) {
        legacy = $0; sub(/^> \*\*Status\*\*:[ \t]*/, "", legacy)
      }
      if ($0 ~ /^## / && $0 ~ /· judgment\)[ \t]*$/) judg++
      if ($0 ~ /^## / && $0 !~ /^## findings/ && $0 !~ /\)[ \t]*$/) untok++
      if ($0 ~ /^- /) {
        printf "@item\t%s\n", $0
        if ($0 !~ /^- [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] /) undated++
      }

      if ($0 ~ /^## findings( |$)/) {
        blocks++; infind = 1; pend3 = 0; if (nfind < 0) nfind = 0; next
      }
      if ($0 ~ /^# / || $0 ~ /^## /) { infind = 0; pend3 = 0 }
      # A findings heading in any other shape. At h2 it is always suspect. An
      # h3 counts only when dated entries follow it, since "### Findings" is
      # also an ordinary sub-heading in a report.
      low = tolower($0)
      if (low ~ /^[ \t>]*##[ \t]*[^a-z0-9#]*findings([^a-z]|$)/) { odd2++; next }
      if (low ~ /^[ \t>]*###[ \t]*[^a-z0-9#]*findings([^a-z]|$)/) { pend3 = 1; next }
      if ($0 ~ /^### [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] /) {
        if (infind) nfind++
        else if (pend3) { odd3++; pend3 = 0 }
        next
      }
      if ($0 ~ /^### /) { pend3 = 0; if (infind) undh3++ }
    }
    END {
      unclosed = (state == "fm")
      if (unclosed) flush()
      odd = odd2 + (blocks == 0 ? odd3 : 0)
      printf "@fm\t%d\n@fm_unclosed\t%d\n@title\t%s\n", fm, unclosed, title
      printf "@hidden_tail\t%d\n", (infence || incomment) ? 1 : 0
      printf "@findings\t%d\n@findings_blocks\t%d\n@findings_odd\t%d\n", nfind, blocks, odd
      printf "@findings_undated\t%d\n@legacy_status\t%s\n", undh3, legacy
      printf "@judgment\t%d\n@untokened\t%d\n@undated\t%d\n", judg, untok, undated
    }
  ' "$1"
}

# fact <facts> <key> -- one value out of doc_facts output.
fact() {
  printf '%s\n' "$1" | awk -F '\t' -v k="$2" '$1 == k { sub(/^[^\t]*\t/, ""); print; exit }'
}

rel() { printf '%s' "${1#"$W"/}"; }

ANOMALIES=""
anomaly() { ANOMALIES="${ANOMALIES}  $1"$'\n'; }

# Kinds this version of the format knows. An unknown one is reported, never
# parsed as best we can: the skill updates at different moments on different
# machines, and a newer document read by older rules is misread silently.
# Sets KIND_STATE to `ok`, `legacy` or `unknown` -- a variable, not output,
# because calling this inside $(...) would lose the anomaly it records.
KIND_STATE=""
check_kind() {
  local file="$1" want="$2" facts="$3" kind fm
  kind="$(fact "$facts" csync)"; fm="$(fact "$facts" @fm)"
  [ "$(fact "$facts" @fm_unclosed)" = 1 ] &&
    anomaly "frontmatter never closes (deviating): $(rel "$file") -- nothing after it is read as body"
  local legacy=""
  case "$want" in note/2) legacy=note/1 ;; design/1) legacy=doc/1 ;; archive/1) legacy=research/1 ;; esac
  if [ -z "$kind" ]; then
    if [ "$fm" = 1 ]; then
      anomaly "frontmatter has no \`csync:\` key (deviating): $(rel "$file")"; KIND_STATE=unknown
    else
      anomaly "no frontmatter (legacy): $(rel "$file")"; KIND_STATE=legacy
    fi
    return 0
  fi
  if [ -n "$legacy" ] && [ "$kind" = "$legacy" ]; then
    anomaly "legacy kind \`$kind\`: $(rel "$file") -- migrated by cleanup"; KIND_STATE=legacy
    return 0
  fi
  case "$kind" in
    "$want") KIND_STATE=ok ;;
    plan/1|note/1|note/2|backlog/1|design/1|doc/1|archive/1|research/1|graph/1)
      anomaly "misfiled: kind \`$kind\` where $want belongs: $(rel "$file")"; KIND_STATE=unknown ;;
    *)
      anomaly "unknown kind \`$kind\` (expected $want): $(rel "$file") -- not read; this skill may be older than the document"
      KIND_STATE=unknown ;;
  esac
}

# `gauge: <max>/<alarm>`, either side empty. Prints "max alarm" with `-` for
# an empty side, or fails when malformed.
parse_gauge() {
  case "$1" in
    */*)
      local max="${1%%/*}" alarm="${1#*/}"
      case "$max" in ''|*[!0-9]*) [ -z "$max" ] || return 1; max=- ;; esac
      case "$alarm" in ''|*[!0-9]*) [ -z "$alarm" ] || return 1; alarm=- ;; esac
      [ "$max$alarm" = -- ] && return 1
      printf '%s %s' "$max" "$alarm" ;;
    *) return 1 ;;
  esac
}

# The shape this skill writes into, or not. A workspace in the old shape is
# migrated by `cleanup` before anything is written to notes/ or backlog.md
# (workspace.md, "An old-shape workspace"), so every listing says so first.
old_shape_reasons() {
  local r="" kind facts
  # Ordered as cleanup.md works through them: the new files first, so the
  # markers are set before anything is moved into them.
  [ -e "$W/notes/knowledge.md" ] || r="${r} no-knowledge.md"
  [ -e "$W/backlog.md" ] || r="${r} no-backlog.md"
  [ -e "$W/notes/traps.md" ] && r="${r} notes/traps.md"
  if [ -e "$W/notes/decisions.md" ]; then
    facts="$(doc_facts "$W/notes/decisions.md")"
    kind="$(fact "$facts" csync)"
    if [ -z "$kind" ]; then
      if [ "$(fact "$facts" @fm)" = 1 ]; then kind=no-csync-key; else kind=no-frontmatter; fi
    fi
    # A newer kind is not the old shape; it is reported as unknown instead.
    case "$kind" in note/1|no-frontmatter|no-csync-key) r="${r} decisions.md:${kind}" ;; esac
  fi
  [ -e "$W/GRAPH.md" ] && r="${r} GRAPH.md"
  printf '%s' "${r# }"
}

old_shape_banner() {
  local reasons
  reasons="$(old_shape_reasons)"
  [ -n "$reasons" ] || return 0
  echo "OLD SHAPE ($reasons)"
  echo "  write nothing to notes/, backlog.md or GRAPH.md and close no pipeline until /csync cleanup migrates this workspace"
}

# ---------------------------------------------------------------------------

# Load a plan's facts into F_* variables in one pass, without a process per
# field -- this runs for every plan on every `list`, and so after every sync.
load_plan_facts() {
  F_fm=""; F_status=""; F_status_note=""; F_next=""; F_blocked=""; F_pairs=""
  F_legacy_status=""; F_findings=""; F_findings_odd=""; F_findings_blocks=""
  F_findings_undated=""; F_hidden_tail=""
  local k v
  while IFS=$'\t' read -r k v; do
    case "$k" in
      @fm) F_fm="$v" ;; status) F_status="$v" ;; status_note) F_status_note="$v" ;;
      next) F_next="$v" ;; blocked) F_blocked="$v" ;; pairs) F_pairs="$v" ;;
      @legacy_status) F_legacy_status="$v" ;; @findings) F_findings="$v" ;;
      @findings_odd) F_findings_odd="$v" ;; @findings_blocks) F_findings_blocks="$v" ;;
      @findings_undated) F_findings_undated="$v" ;; @hidden_tail) F_hidden_tail="$v" ;;
    esac
  done <<EOF
$1
EOF
}

plan_rank() {
  case "$1" in active) echo 0 ;; waiting) echo 1 ;; parked) echo 2 ;; *) echo 3 ;; esac
}

# plan_slug <basename> -- the slug field, or the whole name when malformed.
plan_slug() {
  case "$1" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-?*)
      printf '%s' "${1:18}" ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-?*)
      printf '%s' "${1:22}" ;;
    *) printf '%s' "$1" ;;
  esac
}

show_plans() {
  local f base advanced facts status note next blocked pairs findings rank slug odd row
  local order="" n=0 i
  ROWS=()

  # One parse per plan. Each row is rendered here and stored by index, and only
  # the sort key goes through sort -- so the order and the row can never have
  # been read from the file two different ways.
  for f in "$W"/plans/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"
    slug="$(plan_slug "$base")"
    case "$base" in
      [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-?*)
        advanced="${base:9:8}" ;;
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-?*)
        advanced="${base:11:10}"; advanced="${advanced//-/}"
        anomaly "dashed dates (legacy): $(rel "$f") -- renamed by cleanup" ;;
      *)
        advanced="00000000"
        anomaly "malformed plan filename: $(rel "$f") -- expected <planned>-<advanced>-<slug>.md" ;;
    esac

    facts="$(doc_facts "$f")"
    load_plan_facts "$facts"
    next=""; blocked=""; pairs=""; rank=3

    if [ "$F_fm" = 1 ]; then
      check_kind "$f" plan/1 "$facts"
      if [ "$KIND_STATE" = unknown ]; then
        ROWS[$n]="  [[$slug]] · (not read -- see out of shape)"$'\n'
        order="${order}3"$'\t'"${advanced}"$'\t'"$n"$'\n'
        n=$((n + 1))
        continue
      fi
      status="$F_status"; note="$F_status_note"
      next="$F_next"; blocked="$F_blocked"; pairs="$F_pairs"
      rank="$(plan_rank "$status")"
      case "$status" in
        active|waiting|parked) ;;
        "") anomaly "plan has no \`status\` (deviating): $(rel "$f")" ;;
        *)  anomaly "plan status \`$status\` is not active|waiting|parked (deviating): $(rel "$f")" ;;
      esac
      [ -n "$next" ] || anomaly "plan has no \`next\` (deviating): $(rel "$f")"
      row="  [[$slug]] · ${status:-?}"
      [ -n "$note" ] && row="$row — $note"
    else
      note="$F_legacy_status"
      row="  [[$slug]] · ${note:-no status} (legacy)"
    fi
    row="$row"$'\n'

    findings="$F_findings"
    odd="$F_findings_odd"
    # A fence or comment that never closes hides everything after it, a
    # findings block included -- which would read as "nothing waiting".
    if [ "$F_hidden_tail" = 1 ]; then
      anomaly "a code fence or comment never closes: $(rel "$f") -- the rest of the file is unread, findings counted as ?"
    fi
    [ "$F_findings_blocks" -gt 1 ] 2>/dev/null &&
      anomaly "more than one \`## findings\` block: $(rel "$f") -- entries in all of them are counted"
    [ "${odd:-0}" -gt 0 ] &&
      anomaly "findings heading in a shape nothing reads: $(rel "$f") -- counted as ?"
    [ "$F_findings_undated" -gt 0 ] 2>/dev/null &&
      anomaly "\`###\` inside a findings block that is not an entry: $(rel "$f")"

    if [ "$advanced" = 00000000 ]; then row="$row      advanced ?"; else row="$row      advanced $advanced"; fi
    # A block with no dated entries, or a findings heading in any other shape,
    # is `?`, never 0 or blank: the last entry going takes the block with it,
    # so what is left is a hand-off nothing can read, and 0 would say "nothing
    # waiting".
    if [ "${odd:-0}" -gt 0 ] || [ "$F_hidden_tail" = 1 ]; then
      row="$row · findings ?"
    elif [ "$findings" -ge 0 ] 2>/dev/null; then
      if [ "$findings" -eq 0 ]; then row="$row · findings ?"; else row="$row · findings $findings"; fi
    fi
    case "$blocked" in ''|'0 items') ;; *) row="$row · blocked ${blocked% items}" ;; esac
    case "$pairs" in ''|'0 items') ;; *) row="$row · pairs ${pairs% items}" ;; esac
    row="$row"$'\n'
    [ -n "$next" ] && row="$row      next: $next"$'\n'

    ROWS[$n]="$row"
    order="${order}${rank}"$'\t'"${advanced}"$'\t'"$n"$'\n'
    n=$((n + 1))
  done

  echo "plans ($n)"
  [ "$n" -gt 0 ] || { echo "  (none)"; return 0; }
  # Status first, then most recently advanced. There is no hand-kept order to
  # honour any more; a pipeline that should lead says so by being `active`.
  while IFS=$'\t' read -r rank advanced i; do
    [ -n "$i" ] && printf '%s' "${ROWS[$i]}"
  done <<EOF
$(printf '%s' "$order" | sort -t $'\t' -k1,1n -k2,2r -k3,3n)
EOF
  return 0
}

show_backlog() {
  local f="$W/backlog.md" facts items undated
  if [ ! -e "$f" ]; then
    echo "backlog"
    echo "  (no backlog.md)"
    return 0
  fi
  facts="$(doc_facts "$f")"
  check_kind "$f" backlog/1 "$facts"
  if [ "$KIND_STATE" = unknown ]; then
    echo "backlog"
    echo "  (not read -- see out of shape)"
    return 0
  fi
  items="$(printf '%s\n' "$facts" | awk -F '\t' '$1 == "@item"' | wc -l | tr -d ' ')"
  echo "backlog ($items)"
  printf '%s\n' "$facts" | awk -F '\t' '$1 == "@item" { sub(/^[^\t]*\t/, ""); print "  " $0 }'
  undated="$(fact "$facts" @undated)"
  [ "${undated:-0}" -gt 0 ] && anomaly "backlog.md: $undated item(s) without a YYYYMMDD date -- cleanup stamps them"
  return 0
}

# The old shapes a workspace can still be in. Only things decidable from the
# tree itself; everything here is cleanup's to act on, and only when asked.
scan_shape() {
  local f name facts
  [ -e "$W/GRAPH.md" ] && anomaly "GRAPH.md present (old shape): backlog -> backlog.md, entry prose -> its plan, then delete -- cleanup"
  [ -e "$W/notes/traps.md" ] && anomaly "notes/traps.md present (old shape): entries -> notes/knowledge.md -- cleanup"
  [ -d "$W/notes" ] && [ ! -e "$W/notes/decisions.md" ] && anomaly "notes/decisions.md is missing"
  [ -d "$W/docs/research" ] && anomaly "docs/research/ present (old shape): -> docs/archive/ -- cleanup"
  for f in "$W"/notes/*; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    case "$name" in
      decisions.md)
        facts="$(doc_facts "$f")"
        check_kind "$f" note/2 "$facts"
        [ "$KIND_STATE" = unknown ] && continue
        [ -n "$(fact "$facts" gauge)" ] || anomaly "notes/decisions.md has no \`gauge\` key"
        [ "$(fact "$facts" @judgment)" -gt 0 ] 2>/dev/null &&
          anomaly "notes/decisions.md holds $(fact "$facts" @judgment) \`judgment\` entr(y/ies) -- they belong in notes/knowledge.md (cleanup)" ;;
      knowledge.md)
        facts="$(doc_facts "$f")"
        check_kind "$f" note/2 "$facts"
        [ "$KIND_STATE" = unknown ] && continue
        [ -n "$(fact "$facts" gauge)" ] || anomaly "notes/knowledge.md has no \`gauge\` key"
        [ "$(fact "$facts" @untokened)" -gt 0 ] 2>/dev/null &&
          anomaly "notes/knowledge.md: $(fact "$facts" @untokened) entr(y/ies) with no kind token (deviating) -- cleanup marks them" ;;
      traps.md) ;;
      *) anomaly "unexpected file in notes/: $name" ;;
    esac
  done
  if [ -d "$W/docs" ]; then
    for f in "$W"/docs/*; do
      [ -e "$f" ] || continue
      name="$(basename "$f")"
      if [ -d "$f" ]; then
        case "$name" in design|archive|research) ;; *) anomaly "unexpected directory in docs/: $name/" ;; esac
      else
        case "$name" in closed-pipelines.md|.gitkeep) ;; *) anomaly "document at the root of docs/ (old shape): $name" ;; esac
      fi
    done
    while IFS= read -r f; do
      [ -n "$f" ] && anomaly "closed-pipeline log misfiled at $(rel "$f") -- it lives at docs/closed-pipelines.md"
    done <<EOF
$(find "$W/docs/archive" "$W/docs/design" -type f -name 'closed-pipeline*.md' 2>/dev/null)
EOF
    if [ -d "$W/docs/design" ]; then
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$(basename "$f")" in closed-pipeline*) continue ;; esac
        facts="$(doc_facts "$f")"
        check_kind "$f" design/1 "$facts"
        [ "$KIND_STATE" = unknown ] && continue
        [ -n "$(fact "$facts" revise_when)" ] ||
          anomaly "design document with no \`revise_when\`: $(rel "$f") -- not design by its own test"
      done <<EOF
$(find "$W/docs/design" -type f -name '*.md' 2>/dev/null | sort)
EOF
    fi
  fi
  return 0
}

show_anomalies() {
  [ -n "$ANOMALIES" ] || return 0
  echo "out of shape (report only)"
  printf '%s' "$ANOMALIES"
}

# ---------------------------------------------------------------------------

show_docs() {
  local tier f slug facts title date sup rw n
  for tier in design archive; do
    n=0
    [ -d "$W/docs/$tier" ] && n="$(find "$W/docs/$tier" -type f -name '*.md' | wc -l | tr -d ' ')"
    echo "docs/$tier ($n)"
    [ "$n" -gt 0 ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      slug="$(basename "$f" .md)"
      facts="$(doc_facts "$f")"
      title="$(fact "$facts" @title | sed 's/[[:space:]]*$//')"
      if [ "$tier" = design ]; then
        printf '  [[%s]] — %s\n' "$slug" "${title:-(untitled)}"
        case "$(fact "$facts" csync)@$(fact "$facts" @fm)" in
          @0|design/1@*|doc/1@*) ;;
          *) printf '      (not read: %s -- see the ledger\047s out of shape list)\n' "$( k="$(fact "$facts" csync)"; [ -n "$k" ] && printf 'kind %s' "$k" || printf 'no csync: key' )"; continue ;;
        esac
        rw="$(fact "$facts" revise_when)"
        if [ -n "$rw" ]; then printf '      revise when: %s\n' "$rw"
        else printf '      revise when: (missing -- not design by its own test)\n'; fi
      else
        date="$(printf '%s' "$title" | sed -nE 's/.* — ([0-9]{4})-([0-9]{2})-([0-9]{2})$/\1\2\3/p')"
        title="$(printf '%s' "$title" | sed -E 's/ — [0-9]{4}-[0-9]{2}-[0-9]{2}$//')"
        [ -n "$date" ] || date="$(printf '%s' "$slug" | sed -nE 's/^([0-9]{8}).*/\1/p')"
        printf '  [[%s]] %s — %s' "$slug" "${date:--}" "${title:-(untitled)}"
        sup="$(fact "$facts" superseded_by)"
        [ -n "$sup" ] && printf '  (superseded by [[%s]])' "$sup"
        printf '\n'
      fi
    done <<EOF
$(find "$W/docs/$tier" -type f -name '*.md' | sort)
EOF
  done
  local closed="$W/docs/closed-pipelines.md"
  if [ -e "$closed" ]; then
    # Only real entries: the template's example line is not one.
    printf 'closed: docs/closed-pipelines.md (%s)\n' \
      "$(grep -cE '^- ~~\[\[[^]]+\]\]~~ closed ' "$closed" 2>/dev/null || true)"
  fi
  return 0
}

show_gauges() {
  local f facts g parsed max alarm lines state any=0
  for f in "$W"/notes/*.md "$W/backlog.md"; do
    [ -e "$f" ] || continue
    facts="$(doc_facts "$f")"
    lines="$(wc -l < "$f" | tr -d ' ')"
    any=1
    case "$(fact "$facts" csync)@$(fact "$facts" @fm)" in
      @0|note/1@*|note/2@*|backlog/1@*) ;;
      *) printf '  %-20s %4s lines  not read -- kind %s\n' "$(rel "$f")" "$lines" "$(fact "$facts" csync)"; continue ;;
    esac
    g="$(fact "$facts" gauge)"
    if [ -z "$g" ]; then
      printf '  %-20s %4s lines  no gauge\n' "$(rel "$f")" "$lines"
      continue
    fi
    if ! parsed="$(parse_gauge "$g")"; then
      printf '  %-20s %4s lines  gauge `%s` unreadable -- expected <max>/<alarm>\n' "$(rel "$f")" "$lines" "$g"
      continue
    fi
    max="${parsed% *}"; alarm="${parsed#* }"
    state=""
    if [ "$max" != - ] && [ "$lines" -gt "$max" ]; then state="  OVER MAX"
    elif [ "$alarm" != - ] && [ "$lines" -gt "$alarm" ]; then state="  OVER ALARM"
    fi
    printf '  %-20s %4s lines  max %s · alarm %s%s\n' "$(rel "$f")" "$lines" "$max" "$alarm" "$state"
  done
  [ "$any" = 1 ] || echo "  (no gauged files)"
  return 0
}

resolve_slug() {
  local slug="$1" f base hits="" count
  # A slug is one path segment with no glob characters. Anything else would be
  # read as a path or a pattern, and resolve to files it does not name.
  case "$slug" in
    ''|.*|*/*|*'*'*|*'?'*|*'['*|*']'*|*\\*)
      echo "csync-ledger: not a slug: $slug" >&2; return 64 ;;
  esac
  for f in "$W"/plans/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"
    [ "$(plan_slug "$base")" = "$slug" ] && hits="${hits}$(rel "$f")"$'\n'
  done
  # Compared as strings, not tested with -e: on a case-insensitive disk -e
  # would resolve a spelling that is not the file's name.
  for f in "$W"/notes/*.md "$W"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "$slug.md" ] && hits="${hits}$(rel "$f")"$'\n'
  done
  if [ -d "$W/docs" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      [ "$(basename "$f")" = "$slug.md" ] && hits="${hits}$(rel "$f")"$'\n'
    done <<EOF
$(find "$W/docs" -type f -name '*.md' 2>/dev/null)
EOF
  fi
  if [ -n "$hits" ]; then
    printf '%s' "$hits"
    count="$(printf '%s' "$hits" | wc -l | tr -d ' ')"
    [ "$count" -gt 1 ] && return 2
    return 0
  fi
  if [ -e "$W/docs/closed-pipelines.md" ] &&
     awk -v s="- ~~[[$slug]]~~ closed " 'index($0, s) == 1 { print "closed: " $0; found = 1 } END { exit !found }' \
       "$W/docs/closed-pipelines.md"; then
    return 0
  fi
  echo "csync-ledger: [[$slug]] resolves to nothing in $WS/" >&2
  return 1
}

case "${1:-}" in
  "")
    echo "ledger: $ROOT/$WS"
    old_shape_banner
    show_plans
    show_backlog
    scan_shape
    show_anomalies ;;
  docs)    show_docs ;;
  gauges)  echo "gauges: $ROOT/$WS"; old_shape_banner; show_gauges ;;
  resolve)
    [ -n "${2:-}" ] || { echo "usage: csync-ledger.sh resolve <slug>" >&2; exit 64; }
    resolve_slug "$2"; exit $? ;;
  *)
    echo "usage: csync-ledger.sh [docs | gauges | resolve <slug>]" >&2
    exit 64 ;;
esac
