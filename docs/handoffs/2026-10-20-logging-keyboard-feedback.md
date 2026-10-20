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

## Central visual follow-up

Central iOS 27 capture `/private/tmp/unit-gym-feedback-captures/AF2545F9-E45A-43DC-AA5C-D37952C58B87.png` showed the native keyboard ToolbarItem compressing the HStack into a small capsule; Kg and Done wrapped. The follow-up removes that keyboard ToolbarItem entirely. The existing bottom safe-area inset now hosts the same four equal-width, single-line native buttons for every focused row. The current Save target/Complete action sits above them only when editing the current row. Logged/planned editing also retains the full accessory row. Native top navigation, validation, canonical conversion, drafts and rest behavior are unchanged.

Syntax parsing, source guards and whitespace checks pass. Main must rerun the keyboard capture on compact/current iOS and verify full width, one-line labels and comfortable hit areas. No build or Simulator run here.

## Independent controls and clear destinations

Follow-up feedback requested a distinct container for every keyboard action and plain destination labels. The four equal cells now each reuse `AppSecondaryButton` with its existing neutral fill, corners, centered plain label, press feedback and 60pt minimum. The grouped native bordered button style is removed. The no-detail, full-width secondary path has zero horizontal label padding; Weight fits within the approximately 72pt cell at the existing compact content width. Labels are limited to one line. The switch shows Reps while editing weight and Weight while editing reps; accessibility says Edit reps / Edit weight. Numeric steps still follow kg/lb. No design-system component, token, variant, CurrentSetRow or input/save behavior changed in this follow-up.

Baseline main ad8d01a merged as 4bd1fab. Initial worktree was clean; merge-only conflict resolved from Main after preserving original 7b1e22d and `/private/tmp/unit-keyboard-container-merge.patch`. Syntax, source guards and whitespace checks pass. Main owns the focused runtime/compact capture; no build or device operation here.

### Central verification — separate button containers and clear destination names

Main integrated c06fe31 as4e9f9c7. All four controls now reuse individual AppSecondaryButton containers, with no inherited native bordered group. Visible field-switch names are Weight/Reps; accessibility labels are Edit weight/Edit reps. No new component/token/variant; only copy constants added in AppCopy.

The focused iOS27 Simulator test passed: switch Weight→Reps→Weight→Reps, preserve24kg×8, Save target without logging, reopen current input and explicitly Complete once to advance. Build/source guards/whitespace passed. Result /private/tmp/unit-keyboard-buttons-clarity.xcresult. Actual screenshots viewed and saved in docs/qa/build85-gym-feedback/keyboard-separate-buttons. This small follow-up was not freshly rerun on iOS18; the prior full-width keyboard flow had passed there. No phone install or build-number change.
