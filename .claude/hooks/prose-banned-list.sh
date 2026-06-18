#!/usr/bin/env bash
# PreToolUse hook for Edit/Write/MultiEdit on Markdown files in this repo.
# WARNS (does not block) when prose puffery / jargon appears in .md content
# being authored. Mirrors .claude/hooks/ui-banned-list.sh in shape but is
# advisory only — false positives hurt for prose, so exit code is always 0.
#
# Sources:
#   - Low-mana model:    https://demiculus.com/low-mana/
#   - Communication:     https://demiculus.com/communication/
# See CLAUDE.md §9.
#
# Spec: https://docs.claude.com/en/docs/claude-code/hooks
# Stdin: JSON with .tool_name and .tool_input.

set -euo pipefail

input="$(cat)"
tool_name="$(jq -r '.tool_name // empty' <<< "$input")"
file_path="$(jq -r '.tool_input.file_path // empty' <<< "$input")"

# Only .md files inside this project are checked.
[[ "$file_path" == *.md ]] || exit 0
[[ -n "${CLAUDE_PROJECT_DIR:-}" && "$file_path" == "$CLAUDE_PROJECT_DIR"/* ]] || exit 0

# Skip vendored / quoted external content the user is not authoring.
[[ "$file_path" == */node_modules/* ]]   && exit 0
[[ "$file_path" == */docs/references/* ]] && exit 0
[[ "$file_path" == */.claude/plans/* ]]   && exit 0

# Pull new content depending on tool.
case "$tool_name" in
  Edit)        new_content="$(jq -r '.tool_input.new_string // empty' <<< "$input")" ;;
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

# --- corporate puffery / jargon (Demiculus communication model) ---
warn '\bleverag(e|es|ed|ing)\b'                              'leverage → "use"'
warn '\bsynerg(y|ies|ize|ized|izing|istic)\b'                'synergy family → say what you mean'
warn '\bcross-functional\b'                                  'cross-functional → name the teams/people'
warn '\bin order to\b'                                       '"in order to" → "to"'
warn '\butili[sz](e|es|ed|ing|ation)\b'                      'utilize → "use"'
warn '\boperationali[sz](e|es|ed|ing)\b'                     'operationalize → "run" / "do"'
warn '\bincentivi[sz](e|es|ed|ing)\b'                        'incentivize → "pay" / "reward"'
warn '\bideat(e|es|ed|ing|ion)\b'                            'ideate → "think" / "brainstorm"'
warn '\bholistic(ally)?\b'                                   'holistic → name the scope'
warn '\brobust\b'                                            'robust → name the property (fast? reliable?)'
warn '\b(seamless(ly)?|frictionless)\b'                      'seamless / frictionless → say what works'
warn '\b(best-in-class|world-class|best-of-breed)\b'         'superlative puff — cut'
warn '\b(cutting-edge|next-generation|next-gen)\b'           'tech-puff — cut'
warn '\bthought[- ]leader(ship)?\b'                          'thought leader → describe what was said'
warn '\bparadigm shift\b'                                    'paradigm shift → say what changed'
warn '\b(circle back|touch base)\b'                          'corporate verb → "ask again" / "talk"'
warn '\blow[- ]hanging fruit\b'                              'low-hanging fruit → name the tasks'
warn '\bmove the needle\b'                                   'move the needle → "help" / "matter"'
warn '\bdeep dive\b'                                         'deep dive → "look at" / "study"'
warn '\bgoing forward\b'                                     'going forward → "from now on" or cut'
warn '\bwin-win\b'                                           'win-win → say who gets what'
warn '\b(downsizing|rightsizing)\b'                          'euphemism → "firing"'

# --- intensifiers / filler (Demiculus low-mana model) ---
warn '\bvery\b'                                              '"very" — almost always cuttable'
warn '\b(basically|essentially|actually)\b'                  'filler — cut'
warn '\bsimply\b'                                            '"simply" — often condescending'

if [[ ${#hits[@]} -gt 0 ]]; then
  {
    printf 'PROSE ADVISORY — possible puff/jargon in %s:\n' "$file_path"
    for h in "${hits[@]}"; do
      printf '  - %s\n' "$h"
    done
    printf '\nWARN-only (CLAUDE.md §9). Rewrite if it tightens the prose; ignore if the term is precise and intentional.\n'
    printf 'For an explicit tightening pass: invoke the /low-mana skill.\n'
  } >&2
fi

exit 0
