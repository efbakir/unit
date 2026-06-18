#!/usr/bin/env bash
# PreToolUse hook for Edit/Write — blocks UI patterns banned by CLAUDE.md §5.
# Spec: https://docs.claude.com/en/docs/claude-code/hooks
# Stdin: JSON with .tool_name and .tool_input. Exit 2 = block, stderr shown to Claude.

set -euo pipefail

input="$(cat)"
tool_name="$(jq -r '.tool_name // empty' <<< "$input")"
file_path="$(jq -r '.tool_input.file_path // empty' <<< "$input")"

# Only Swift files inside Unit/ are checked.
[[ "$file_path" == *Unit/*.swift ]] || exit 0

# DesignSystem.swift is the ONE place tokens may be defined as raw values.
[[ "$file_path" == *Unit/UI/DesignSystem.swift ]] && exit 0

# Pull the new content depending on tool.
case "$tool_name" in
  Edit)        new_content="$(jq -r '.tool_input.new_string // empty' <<< "$input")" ;;
  Write)       new_content="$(jq -r '.tool_input.content    // empty' <<< "$input")" ;;
  MultiEdit)   new_content="$(jq -r '[.tool_input.edits[]?.new_string] | join("\n")' <<< "$input")" ;;
  *)           exit 0 ;;
esac

[[ -z "$new_content" ]] && exit 0

declare -a violations=()

check() {
  local pattern="$1" message="$2"
  if grep -qE "$pattern" <<< "$new_content"; then
    violations+=("$message")
  fi
}

# --- §5 banned-in-view-code list ---
check 'chevron\.right|chevron\.forward'                                    'chevron.right / chevron.forward — banned (CLAUDE.md §5)'
check 'Color\(red:[[:space:]]*[0-9.]'                                      'Color(red:green:blue:) — use AppColor.* tokens'
check 'Color\.(black|white|gray|red|green|blue|primary|secondary)\b'       'Color.black/.white/.gray/.red/etc — use AppColor.* tokens'
check '0x[0-9A-Fa-f]{6,8}'                                                 'hex literal — define in DesignSystem.swift, not in feature code'
check '\.foregroundStyle\(\.gray\)|\.foregroundColor\(\.gray\)'            '.foregroundStyle(.gray) / .foregroundColor(.gray) — use AppColor.textSecondary'
check '\.font\(\.system\(size:'                                            '.font(.system(size:)) — use AppFont.* tokens'
check '\.padding\([[:space:]]*[0-9]+'                                      'hardcoded numeric padding — use AppSpacing.* tokens'
check '\.padding\(\.[a-z]+,[[:space:]]*[0-9]+'                             'hardcoded directional padding — use AppSpacing.* tokens'
check 'cornerRadius\([[:space:]]*[0-9]+'                                   'hardcoded cornerRadius — use AppRadius.* tokens'
check 'RoundedRectangle\(cornerRadius:[[:space:]]*[0-9]+'                  'RoundedRectangle(cornerRadius: <number>) — use AppRadius.* tokens'
check '\.cornerRadius\('                                                   '.cornerRadius(...) modifier — deprecated and always renders .circular corners. Use .clipShape(RoundedRectangle(cornerRadius: AppRadius.x, style: .continuous)).'

# RoundedRectangle without explicit .continuous style → would default to
# .circular and ship a wrong-shape corner. Squircle is the system; .continuous
# is non-negotiable. Line-scoped scan: any line that opens a RoundedRectangle
# with cornerRadius must also carry style: .continuous on the same line.
if grep -nE 'RoundedRectangle\(cornerRadius:' <<< "$new_content" \
   | grep -vE 'style:[[:space:]]*\.continuous' \
   | grep -q .; then
  violations+=('RoundedRectangle(cornerRadius:) without style: .continuous — every radius container must use the iOS-native squircle. Use RoundedRectangle(cornerRadius: AppRadius.x, style: .continuous).')
fi
check 'preferredColorScheme\(\.dark\)'                                     '.preferredColorScheme(.dark) — Unit is light-mode only (CLAUDE.md §5 P3)'
check '\.scrollEdgeEffectStyle\(\.(automatic|hard)'                        'scrollEdgeEffectStyle .automatic/.hard — use appScrollEdgeSoft(top:bottom:)'
check 'ProcessInfo\.processInfo\.environment\["UNIT_'                      'UNIT_* env scaffolding — must be reverted before turn end (CLAUDE.md §5)'
check '\.fontWeight\(\.regular\)|\.weight\(\.regular\)'                    '.weight(.regular) — banned per recurring-rules memory'
check '#FF4400|0xFF4400'                                                   'orange #FF4400 — dead accent, do not resurrect'

# Toolbar buttons: heuristic — flag .weight(.semibold/.bold/.heavy) appearing in same diff as ToolbarItem
if grep -q 'ToolbarItem' <<< "$new_content" \
   && grep -qE '\.weight\(\.(semibold|bold|heavy)\)' <<< "$new_content"; then
  violations+=("ToolbarItem button .weight(.semibold/.bold/.heavy) — use iOS-native default weight (CLAUDE.md §5 parallel-ban)")
fi

# Sheet content with ScrollView/AppCard root — heuristic
if grep -qE '\.sheet[[:space:]]*\{' <<< "$new_content" \
   && grep -qE '\.sheet[[:space:]]*\{[^}]*ScrollView' <<< "$new_content"; then
  violations+=(".sheet { ScrollView … } — sheet root should be plain VStack with presentationDetents (CLAUDE.md §5)")
fi

# En-dash / em-dash as placeholder copy in Text("…")
if grep -qE 'Text\("[[:space:]]*[–—][[:space:]]*"\)' <<< "$new_content"; then
  violations+=('Text("–") / Text("—") placeholder — write explicit copy ("No history yet", "BW", etc.)')
fi

# "0 kg" placeholder
if grep -qE 'Text\("0[[:space:]]*kg"\)' <<< "$new_content"; then
  violations+=('Text("0 kg") for bodyweight — show "BW" or "No history yet"')
fi

# AppCard(contentInset: 0) outside DesignSystem.swift — proximate cause of broken
# list-in-card padding (8 + 16 = 24pt is canonical; 0 + 16 reads as 16pt-from-edge
# AND collapses vertical inset to 0). The docstring on AppCard reserves 0 for
# full-bleed media, which is rare. Use AppCardList for any "list inside its own
# card" surface — it bakes the recipe.
if grep -qE 'AppCard[[:space:]]*\([^)]*contentInset:[[:space:]]*0\b' <<< "$new_content"; then
  violations+=('AppCard(contentInset: 0) — banned in feature code. Use AppCardList for list-in-card; if you genuinely need full-bleed media, ask the user before bypassing.')
fi

# Composing AppCard + AppDividedList by hand — this is exactly what AppCardList
# replaces. Heuristic: AppCard followed within the diff by AppDividedList.
if grep -q 'AppCard[[:space:]]*[({]' <<< "$new_content" \
   && grep -q 'AppDividedList[[:space:]]*[({]' <<< "$new_content"; then
  violations+=('AppCard wrapping AppDividedList — use AppCardList instead. The molecule bakes the canonical 8/16 inset recipe so dividers and rows compose to the documented 24pt offset.')
fi

# Parallel-implementation ban — flag new struct ... : View declarations in feature code
if grep -qE '^[[:space:]]*(public[[:space:]]+|private[[:space:]]+|internal[[:space:]]+|fileprivate[[:space:]]+)?struct[[:space:]]+[A-Z][A-Za-z0-9_]*[[:space:]]*:[[:space:]]*View' <<< "$new_content"; then
  # Allow inside Features/**/*View.swift top-level — but flag for review.
  # We don't outright block, we surface a warning. (Keep as advisory: stderr non-blocking.)
  printf 'NOTE — new "struct X: View" detected in %s. Verify you cannot extend an existing atom/molecule in DesignSystem.swift. (CLAUDE.md §5 parallel-ban)\n' "$file_path" >&2
fi

if [[ ${#violations[@]} -gt 0 ]]; then
  {
    printf 'BLOCKED — banned UI patterns in %s:\n' "$file_path"
    for v in "${violations[@]}"; do
      printf '  - %s\n' "$v"
    done
    printf '\nFix in Unit/UI/DesignSystem.swift or use existing tokens. See CLAUDE.md §5.\n'
    printf 'If this is an intentional override, ask the user explicitly before proceeding.\n'
  } >&2
  exit 2
fi

exit 0
