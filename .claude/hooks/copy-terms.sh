#!/usr/bin/env bash
# PreToolUse hook for Edit/Write/MultiEdit on live user-facing copy in this repo.
# WARNS (does not block) when a *killed* product term reappears in shipping copy.
# Mirrors .claude/hooks/prose-banned-list.sh in shape — advisory only, exit 0 always,
# because false positives must never block work (the user runs parallel agents).
#
# Currently enforces the 2026-06-09 rename (docs/decision-log.md):
#   "Ghost values" → in-app label "Last time" / confirm "Same as last time".
#   The CODE identifiers metricIsGhost and AppGhostButton were intentionally KEPT —
#   the phrase "ghost value" never matches those, so this stays precise.
#
# NOT enforced here: "Pro" / "premium". Pro is deferred v1.1 monetization, not a
# banned term — it lives legitimately across pricing.md, PaywallView, StoreManager,
# LaunchConfig.proAvailable, and a stashed v1.1 WIP. Blocking it would misfire.
#
# Spec: https://docs.claude.com/en/docs/claude-code/hooks
# Stdin: JSON with .tool_name and .tool_input. See CLAUDE.md §3, §8.

set -euo pipefail

input="$(cat)"
tool_name="$(jq -r '.tool_name // empty' <<< "$input")"
file_path="$(jq -r '.tool_input.file_path // empty' <<< "$input")"

# Only files inside this project.
[[ -n "${CLAUDE_PROJECT_DIR:-}" && "$file_path" == "$CLAUDE_PROJECT_DIR"/* ]] || exit 0

# Only live user-facing surfaces: in-app Swift copy, marketing/app-store copy, website.
case "$file_path" in
  *.swift|*.md|*.ts|*.tsx|*.js|*.jsx|*.html|*.css) ;;
  *) exit 0 ;;
esac

# Skip vendored content and files that legitimately DOCUMENT the rename (history /
# explanatory references say "formerly ghost values" on purpose — don't nag those).
[[ "$file_path" == */node_modules/* ]]      && exit 0
[[ "$file_path" == */docs/references/* ]]   && exit 0
[[ "$file_path" == */docs/archive/* ]]      && exit 0
[[ "$file_path" == */docs/claude/* ]]       && exit 0
[[ "$file_path" == */.claude/plans/* ]]     && exit 0
[[ "$file_path" == *decision-log.md ]]      && exit 0
[[ "$file_path" == */CLAUDE.md ]]           && exit 0
[[ "$file_path" == */PRODUCT.md ]]          && exit 0

# Pull new content depending on tool.
case "$tool_name" in
  Edit)       new_content="$(jq -r '.tool_input.new_string // empty' <<< "$input")" ;;
  Write)      new_content="$(jq -r '.tool_input.content    // empty' <<< "$input")" ;;
  MultiEdit)  new_content="$(jq -r '[.tool_input.edits[]?.new_string] | join("\n")' <<< "$input")" ;;
  *)          exit 0 ;;
esac

[[ -z "$new_content" ]] && exit 0

declare -a hits=()

warn() {
  local pattern="$1" message="$2"
  local matches
  matches="$(grep -inE "$pattern" <<< "$new_content" || true)"
  [[ -z "$matches" ]] && return 0
  while IFS= read -r line; do
    hits+=("$message  │  $line")
  done <<< "$matches"
}

# --- killed product terms (docs/decision-log.md) ---
warn '\bghost[- ]?values?\b'   'ghost value(s) → "Last time" / "Same as last time" (renamed 2026-06-09). Code identifiers metricIsGhost / AppGhostButton are fine.'

if [[ ${#hits[@]} -gt 0 ]]; then
  {
    printf 'COPY ADVISORY — a killed product term reappeared in %s:\n' "$file_path"
    for h in "${hits[@]}"; do
      printf '  - %s\n' "$h"
    done
    printf '\nWARN-only. Fix if this is shipping copy; ignore if you are quoting/documenting the old term.\n'
  } >&2
fi

exit 0
