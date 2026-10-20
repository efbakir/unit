# Rest footer consistency — 20 October 2026

## Scope and decision

Interpreted the user's bottom-area feedback as RestBar plus its keyboard accessory seam, as Main requested. Read the existing owners and JOI visual-language notes and inspected actual `final-b-after-set-two.png` and `keyboard-separate-buttons/gym-feedback-keyboard-complete.png` captures.

Confirmed mismatches: white rest surface versus page-colored keyboard surface; 15pt combined idle text versus 24pt running digits versus a separate 17pt finished message; custom 44pt timer controls versus shared 60pt keyboard controls. The old controls vanished outside running even though their geometry was retained.

Small existing-owner fix:

- `RestBar.status` draws one stable header for both modes. Rest and the existing Rest finished. cue share the 15pt caption role/leading anchor; the right-aligned countdown keeps the 17pt performance role in idle/running/finished. Finished explicitly reads 0:00. The mounted caption layers reserve the same space and crossfade.
- Three rest actions each use `AppSecondaryButton`, matching the four keyboard actions. Both rows use individual neutral containers, single-line text, equal flexible cells and the same existing 60pt minimum. Inactive rest controls stay visibly disabled, ignore taps and remain hidden from accessibility. No functioning action was removed.
- Both bottom regions use the page background, 16pt inset, 8pt internal spacing and existing top divider. Rest uses a header above controls instead of a state-dependent horizontal/vertical fit switch. All normal timer states keep identical anatomy and height; keyboard editing adds its already-required explicit current action above the accessory row.
- `RestBar.progressLine` is the sole deadline-driven blue progress renderer for both modes. Original deadline/total duration, clamping, fixed 3pt slot, no interpolated samples and Reduce Motion/VoiceOver gates remain.
- Existing RestBar root exposes `workout-rest-bar` with contained accessible children. The combined status exposes `rest-duration` and the actual displayed time as its accessible value.

No new View, component, token, variant, dependency, model field or migration. No changes to timer manager, saved/rest deadline/source, notifications, Live Activity, validation, drafts, prepare/Complete, native keyboard/top bar/tabs, other shared components or workout card composition.

## Checkpoint and evidence

Clean worktree merged main 44addf7 as e4c3819. The only merge conflict was additive handoff evidence; both source and central verification history were retained.

Changed production files:
- `Unit/UI/DesignSystem.swift`: RestBar only (header, progress rendering, controls, surface).
- `Unit/Features/Today/ActiveWorkoutView.swift`: focused bottom inset only (reuse RestBar header/progress and matching surface/divider).

Swift frontend syntax parsing, `scripts/check-guards.sh`, and diff whitespace checks pass. Source comparisons confirm DesignSystem before RestBar and the ActiveWorkoutView timer/action tail are byte-identical to the merged baseline. No build, test execution, Simulator, device install or version change here. The inspected images are baseline evidence, not screenshots of this change.

## Main verification requested

Use the isolated fixture with `-restDurationSeconds 15`. Measure `workout-rest-bar` bounds through idle → Complete/running → +15 → −15 → expiry/finished → Skip/idle. Check steady header/countdown anchors and footer height, Rest finished. plus 0:00, correct blue deadline progress, −15 disabled at minimum, and no inactive control taps or VoiceOver actions. Verify timer expiry while backgrounded and source-set removal retain existing behavior.

Capture standard and compact width, plus AX3/Reduce Motion if the central budget allows. Open/close weight and reps editors: confirm the same status anchors, separate keyboard buttons, visible explicit current action, native keyboard safe-area behavior, no second finish-message row and no accidental set completion. Confirm the deliberate 60pt shared controls do not crowd the compact workout viewport. Main owns any runtime follow-up and final installation.
