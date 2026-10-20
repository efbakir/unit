# Logging input and keyboard feedback — 20 October 2026

## Request and decision

Main delegated the user's build 85 feedback: simplify first-time target preparation, make the action reachable with the keyboard open, give keyboard actions comfortable full-width targets, and balance weight × reps inputs. Preserve native fields, canonical kg storage, explicit BW, lb conversion, blue actions, and training data. Main owns card composition, builds, Simulator checks and device installation.

Reuse check: extend the approved `CurrentSetRow` and reuse `AppPrimaryButton`, native keyboard buttons, the existing input modifier and existing typography/geometry tokens. No new View, primitive, token, dependency or model field. This feedback supersedes Final B's outlined Save starting target button.

- `CurrentSetRow` uses the shared blue primary button for both Save target and Complete set. Its `showsAction` option keeps its action slot mounted but hidden while the same action is pinned above the keyboard.
- `ActiveWorkoutView` pins Save target or the explicit numbered Complete action above the keyboard for the current editor. Editing a different logged/planned row cannot log the current row. Successful Complete first commits the current values, then uses the existing saved-set/timer path. Save target and keyboard Done never insert a set or start rest.
- Keyboard Done prepares a valid first target directly and dismisses. A subsequent explicit Complete is still required. Invalid input and failed durable saves keep their editor, focus and raw draft; neither deletes a set.
- The keyboard toolbar has one full-width HStack with four native bordered buttons. Each label owns the full flexible hit area, with the existing row-height minimum. Rest time accompanies the pinned action; RestBar itself is unchanged.
- Fields fill available width. Weight retains its existing load-specific minimum so its unit stays tight; reps receives the remaining space. The separator uses the existing small gap. Accessibility sizes, added BW load and long loads stack rather than clipping. Native SF roles and canonical conversion remain unchanged.
- Raw strings are scene-restorable under `unit.loggingInputDrafts`, scoped by session and row. They remain separate from validated session targets and SetEntry history. Row switches preserve unfinished preparation; successful commits clear the draft. No claim of force-quit restoration is made without runtime testing.

## Files and scope

- `Unit/Features/Today/ActiveWorkoutView.swift`: editor/focus/keyboard routines and exact value-field block.
- `Unit/UI/DesignSystem.swift`: `CurrentSetRow` only.
- This handoff.

Source comparisons confirm exercise/current/completed/upcoming card composition and RestTimerManager are unchanged. DesignSystem outside CurrentSetRow is byte-identical to the merged baseline. RestBar, motion/theme tokens, native tabs, project membership and version/build settings are unchanged.

## Baseline and source evidence

Merged main `8e3cf4d` into the clean existing logging branch. The merge encountered conflicts because Main had already integrated and corrected this branch's checkpoints. Initial status was clean; ORIG_HEAD `c96a458` retained the previous source. Approval review first rejected resolution over possible uncommitted loss, then accepted after that evidence was supplied. Resolved tree matched Main exactly; merge checkpoint `bfcbfda`. No existing work was reset or deleted.

- Swift frontend syntax parsing passed for both changed Swift files.
- `scripts/check-guards.sh` passed.
- `git diff --check` passed.
- Local SDK confirms SceneStorage Data is supported from iOS 14; Unit targets iOS 18+.
- No build, unit/UI test, Simulator, installation or version change in this chat.

## Central verification requested

1. On iOS 18 compact and current iOS: blank first target → type both values → tap keyboard Save target; no completed row/rest; explicit Complete logs once.
2. First target → keyboard Done now prepares directly. Update the old UI test that taps Save starting target after Done: expect Complete set 1, with no logged set before tapping it.
3. Prefilled current row → edit while keyboard stays open → tap pinned Complete; commit once, log once, correct values/rest/Undo. Keyboard Done alone only commits.
4. Logged/planned row editing → current Complete remains disabled; Done updates that row only. Failed save retains typed values and focus. Invalid reps/weight stay available for correction and never delete/log a set.
5. Switch rows during unfinished preparation; return and confirm raw values remain. Background/reopen and scene restoration require actual runtime checks.
6. Reps-only lb edit preserves exact original kg; explicit weight edit converts once. Check blank/zero weighted load, BW zero, BW added load and long values.
7. Capture compact, standard and AX3 keyboard states. Verify full-width toolbar, all tap areas, pinned action above the keyboard, no duplicate visible primary action and no native accessory clipping. Confirm scrolling can reveal either field with the pinned action present.

Main should integrate the source checkpoint together with its card-composition work, then run the central build/test/visual queue before installation.
