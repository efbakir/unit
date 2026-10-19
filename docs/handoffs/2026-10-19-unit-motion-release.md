# Unit — October 19 motion and iPhone release handoff

## Status and source

This is a development release pass, not an App Store submission. The public app is **2.0** (Apple lookup checked October 19). The connected iPhone started with **2.1 (65)**; the repository started at **2.1 (67)**. This pass prepares **2.1 (68)**, **development-only and unreserved** until App Store Connect's highest uploaded build can be read. The build is installed and launched on the connected iPhone. Detailed evidence and limits are below.

- Original checkout: `/Users/efbakir/unit`; its existing edits were preserved and left in place.
- Original HEAD: `765437b6a22feef3c1bab2a9a689e4ed9ab48e5a`.
- Recovery checkpoint: `27fdb7b70020ebb2437ea23f8eeda493bd202800`, including relevant untracked files and unfinished catalog, onboarding, and paywall work.
- Integrated checkout: `/Users/efbakir/.codex/worktrees/unit-release-20261019/unit`, branch `codex/unit-release-20261019`.
- Plate was read-only. Unit keeps its own monochrome palette, local-first models, native navigation, and fast set logging.
- Scope: 80-minute coordinated implementation and verification window, starting 08:00 UTC. No public submission is authorized.

## What changed and why

- **Typography:** the user's later instruction supersedes Geist: shared `AppFont` now uses native **SF Pro**, SF Mono for numeric roles, neutral caps tracking, and restrained negative heading tracking. Existing point sizes and native Dynamic Type remain; no enlarged-font layout redesign was undertaken. Bundled Geist files are unused compatibility assets pending cleanup.
- **Foundation:** one `AppMotion` token set, accessible custom press feedback, seven named haptic intents, and a scene-level 80ms strength gate. A set/PR produces one outcome cue; secondary navigation stays quiet.
- **Entrances:** stable reveal identities with scroll-session memory, shared onboarding step transitions, tab arrivals, and staged paywall/completion compositions. Controls do not wait for entrance effects. Reduce Motion or VoiceOver removes spatial motion, blur, bounce, and confetti.
- **Moments:** deterministic Canvas celebration with immutable start time/seed; first completion shower and later restrained popper; eight-dot accepted-target burst; shared numeric changes and stable busy-label transitions. History/relaunch does not replay completion.
- **Feedback and Undo:** identifiable toast events prevent replacement/cancellation races. Plain messages last 2s, actionable messages 4s, errors persist. Removed sets restore their exact ID, order, weight, reps, warmup flag, RPE/RIR, and note. Undo consumes the action before restoring, so it cannot duplicate a set.
- **Progression reliability:** unchanged targets at the rep ceiling say to repeat, not add a rep. Prefill skips invalid/incomplete/warmup-only history and preserves accepted same-routine targets → latest valid completed history → saved starting target → empty. Bodyweight remains BW. An accepted target is idempotent.
- **Save reliability:** success feedback, completion/navigation, and sheet dismissal follow a successful save. Failed writes restore loaded UI values as well as persisted records; this required an iOS 18-specific loaded-model rollback repair. Target editor drafts remain available for retry.
- **Onboarding:** draft import text, days, schedule, and related choices persist through backgrounding and termination via the existing preferences owner.
- **Consistency:** shared chip chrome, disabled/loading treatment, leading sheet close controls, button semantics on editable set chips, and a DEBUG component catalog at **Programs → Settings → Design system → Components**. The set editor's delete toolbar action is inside its navigation container so it appears on iOS 18.
- **Guards/docs:** `scripts/check-guards.sh` checks precise token/haptic owners across Unit and UnitWidget, with 26 mutation fixtures; `docs/protected-behaviors.md` records the contracts. Design documentation matches the current owners.

## Coordinated chats and checkpoints

All six chats used separate branches/worktrees. Shared-system edits were integrated sequentially. Builds and Simulator operations ran only from this coordinating checkout.

| Stage | Branch | Stage commit | Result |
|---|---|---|---|
| Read-only gap audit | `codex/unit-motion-audit` | recovery checkpoint | Read-only gap table in its chat |
| Foundation | `codex/unit-motion-foundation` | `b53d339` | Integrated as `0f1762d` |
| Entrances | `codex/unit-motion-entrances` | `2cdab667` | Integrated as `ab8d511` |
| Moments | `codex/unit-motion-moments` | `2e53749` | Integrated as `f48cf21`, then compile/runtime fixes |
| Design consistency | `codex/unit-design-consistency` | `b285d6e` | Integrated as `fb29b2b`, then catalog compile fix |
| Quality/delivery support | `codex/unit-quality-delivery` | `1aae3d5`, `c30d575`, `5e21915`, `bcabcdd` | Guards, lifecycle fix, SF Pro; integrated |

Main-chat reliability work and regressions are separate commits on the integrated branch. A recovery integration stash `3677a4aead939e9b10b18d172fb549c0dc8f4be3` is retained; its changes are already applied/committed and must not be applied again.

## Verification evidence

Evidence paths are local, not uploaded. Tests used dedicated Simulator stores and StoreKit test fixtures, never the phone's real preferences or training data.

| Check | Evidence / result |
|---|---|
| Recovery baseline | Build succeeded; 88 focused progression, persistence, import, entitlement tests passed |
| Integrated moments, iPhone 17 / iOS 27 | `/private/tmp/unit-moments-journeys-v2.xcresult`: **204 passed, 0 failed** (197 unit + 7 UI). Includes accept/repeat/edit/next-workout/history/relaunch, first-set target, pounds, full paste onboarding → local purchase → logged workout, restore, cancellation/unverified purchase, offline cached entitlement |
| iOS 18 persistence repair | `/private/tmp/unit-rollback-ios18-restored.xcresult`: **20 persistence tests passed**. Failed-save rollback restores loaded UI as well as storage |
| Final SF Pro compact pass | `/private/tmp/unit-final-compact.log`: **201 unit tests passed**; onboarding and feedback catalog UI passed, including toast replacement and failed-target-save retry. Undo UI found the missing delete toolbar, fixed in `f9087ae`; rerun below. Xcode's result finalizer hung after reporting results and was stopped; the log is the evidence for this run |
| Guard mutation checks | 26 deliberate violations checked by `scripts/check-guards.sh --self-test`; final rerun below |

Earlier failures were not hidden: a stray animation variable and read-only accessibility environment overrides failed compilation and were fixed; iOS 18 deinitialization of the scene feedback/reveal owners crashed and was fixed with explicit nonisolated deinitializers; loaded-model rollback needed a dedicated repair. UI harness fixes covered locale-dependent units, precise scrolling, and offscreen catalog controls. No enlarged-text layout claim follows from these harness corrections.

## Device preservation and release boundaries

Before installation, the accessible phone store and preferences were copied to:
`/Users/efbakir/.codex/worktrees/unit-release-20261019/evidence/phone-before/`.
SQLite integrity was OK. Existing counts: **4 templates, 12 workouts, 208 sets, 19 exercises, 2 splits**. The phone used kg and retained a monthly entitlement cache. The upgrade must preserve those records and preferences; post-install comparison is recorded below.

- App Store Connect's live build list could not be read: no available authenticated API/CLI connection, and browser automation repeatedly timed out. Build 68 is therefore unreserved and must not be uploaded until the highest uploaded build is confirmed.
- Local StoreKit success/restore/cancellation/offline tests are **not Apple sandbox confirmation**. Real sandbox purchase/restore and store product state still need account-level release review.
- Simulator visuals and policy tests do not establish physical haptic feel or a full VoiceOver walkthrough.
- Release notes: `docs/app-store-submission/whats-new-2.1-motion-draft.md`. Existing submission checklist now labels its older August facts as historical. Public submission remains the user's action.

## Visual review on the phone

Review SF Pro and compact heading spacing on Today and Programs; crisp set completion and rest-timer feedback; the completed-workout summary and next-target acceptance; editing/deleting a set and immediately restoring it with Undo. Logging should remain one tap with a valid target. Settings' DEBUG component catalog provides isolated feedback samples without editing workouts.

## Prioritized follow-up

1. Resolve App Store Connect access, reserve the final upload number, confirm current subscriptions/products, and perform Apple sandbox purchase/restore before store submission.
2. Review actual phone motion/haptics and a full VoiceOver interaction pass; keep source/Simulator/device proof separate.
3. Finish any remaining manual route checks listed in the final evidence section, especially unusual import formats and interrupted purchase conditions.
4. Optional cleanup: remove unused Geist asset registration and compatibility helper names after all external callers are checked; expand guard coverage for legacy spacing literals without introducing new visual variants.

## Final evidence and delivery

- **Final compact verification:** `/private/tmp/unit-final-undo-progression.xcresult`: **203 passed, 0 failed** (201 unit + full progression journey + exact set Undo/interrupted-session relaunch), iPhone SE 3, iOS 18.6. Xcode reports TEST SUCCEEDED. This includes final SF Pro and the delete-toolbar repair.
- **Visuals:** final SF Pro Today, active workout, progression explanation, target editor, History, and Undo/relaunch screenshots are saved in `../evidence/final/` relative to the checkout. The compact Simulator's system appearance was dark; Unit stayed light. Main screens were inspected directly.
- **Guard:** final 26-mutation self-test passed.
- **Device build:** signed Debug build succeeded from code checkpoint `f9087ae`; **2.1 (68)** installed in place successfully. The initial wireless tunnel timeout was followed by an iOS locked-device refusal. After the user unlocked the phone, normal launch succeeded; the Unit process and widget were read back as running. No test launch arguments were used.
- **Post-install preservation:** every database row and all preferences matched the pre-install backup exactly, before normal launch (`phone-install-preservation.json`).
- **Post-launch preservation:** SQLite integrity OK; all **12 workout records and 208 set records remain byte-for-byte equal at the row level**, as do both splits and all 19 original exercises. Four templates remain. One routine now has one additional exercise appended while its original order remains; the exercise catalog expanded to 932 rows. These live additions were preserved, not reversed. StoreKit updated its last-check timestamp and the existing trial-reminder preference initialized; kg, cached entitlement, and `persistenceRecoveryNotice=false` remain intact (`phone-launch-preservation.json`). No automated phone UI interactions or workout edits were performed.
- **Final iOS 27 / Reduce Motion:** `/private/tmp/unit-final-reduced-motion.xcresult`: **4 UI journeys passed**, covering full import/onboarding/purchase/logging, pending-purchase tap blocking, failed/partial product loading recovery, and progression decisions through relaunch and next-workout prefill. The actual Simulator Reduce Motion setting was confirmed on, then returned off for normal-motion review.
- **Normal-motion recording:** `motion-normal-se.mp4` captures real completion confetti and acceptance feedback. The progression journey passed again. The catalog repeat found its Undo sample below the viewport; the harness now scrolls to it and explicitly asserts error dismissal. Final catalog rerun and iOS 27 recording are listed below.
- **Compatibility priorities:** per the user's latest direction, iOS 27 is the primary visual/interaction target and iOS 18 is the compatibility baseline. Compact checks catch clipping and older runtime behavior; they do not drive enlarged-font layouts.
- **Original checkout:** final status comparison matched the pre-work status exactly. All implementation remains in the isolated integrated branch.
- **iOS 27 normal motion:** `/private/tmp/unit-final-ios27-normal.xcresult`: **4 UI journeys passed** — ready-made program, full paste onboarding/purchase/logging, restore, and feedback catalog including error dismissal, Undo, failed save, and retry. `motion-normal-ios27.mp4` shows first-workout shower and normal interactions; the initial completion and subsequent settled state were visually inspected.
- **Final visual defect correction:** `SessionExerciseSummary` in `HistoryView.swift` now uses `ViewThatFits` to keep complete performance metrics readable; on narrow rows it stacks the metric below the exercise name. Both History and workout completion reuse this owner. No new component, token, or variant was added. Its progression regression passed; final standard-size catalog rerun and signed build refresh are recorded below.
- **Standard-size scope:** the optional large-text catalog-preview navigation was removed from the functional regression after an offscreen-toggle lookup failed. All functional toast/Undo/save-retry assertions remain. An earlier iOS 27 large-text preview ran successfully, but this pass does not claim a full enlarged-font layout review.

## New follow-on work requested during delivery

These are separate isolated chats/branches, **not included in installed build 68**:

- `Unit · Profile and progression analytics`, chat `01a15368-863b-7011-9031-dcf77ff82dd0`, branch `codex/unit-profile-progress`: recover prior product research; inspect competitor analytics and App Store reviews; build a third Profile tab using existing owners, with honest local progress comparisons.
- `Unit · Native SwiftUI controls`, chat `01a1536a-4132-7740-9486-0121ba85ae55`, branch `codex/unit-native-controls`: use the user-invoked SwiftUI Pro and Atomic Design skills, trace all segmented-control consumers, adopt native controls where semantics fit, and retain documented exceptions for unanswered/disabled choices.

Their shared-file ownership is separated, and build access stays coordinated. Their results must be integrated and verified before a later phone build; do not imply these features shipped with the motion release.

### Closing evidence

- **Final standard-size checks:** `/private/tmp/unit-final-standard-ui.xcresult`: **2 UI tests passed** on iOS 18.6 after the History metric fix (full progression journey and feedback catalog). `/private/tmp/unit-final-ios27-history.xcresult`: **1 full progression UI journey passed** on iPhone 17 / iOS 27 after the same fix. The earlier 201-unit-test pass remains the unit evidence; no claim of a later full unit rerun.
- **Final phone refresh:** signed Debug build succeeded, installed in place, and launched normally after the user unlocked the phone. Application code is `9643cb8567b082cf37ace5529b23a4b188737a06`; source/test checkpoint is `be41f65`. The delivered app is **2.1 (68)**. No test flags, uninstall, or data reset were used.
- **Final data comparison:** the immediate pre-refresh and post-launch stores match row-for-row in all five tables: **9 templates, 12 workouts, 208 sets, 951 exercises, 1 split**. SQLite integrity is OK, kg is retained, and recovery notice is false. This preserves both the original workout history and the user's intervening live program changes. Evidence: `phone-final-preservation.json`.
- **Release preparation:** `Unit-2.1-68-development.xcarchive` archived successfully. The exact signed Debug app is retained as `Unit-2.1-68-development.zip`. Both live under `/Users/efbakir/.codex/worktrees/unit-release-20261019/evidence/`. Binary hash and source provenance are in `evidence/final/build-provenance.json`. Build 68 remains development-only and unreserved; nothing was uploaded or submitted publicly.
- **Final visual inspection:** `evidence/final/final-ios27-01b-completed-workout-summary.png` shows the complete exercise metric and PR badge without truncation. Normal-motion recordings and screenshots are in that same evidence directory.
- **Simulator coordination:** both release Simulators were shut down at the end of main verification. Follow-on chats may reuse them only under the shared atomic verification lock; unrelated Simulators remain untouched.
- **Remaining proof limits:** physical haptic feel, a complete manual VoiceOver walkthrough, unusual import formats, and real Apple sandbox purchase/restore are not fully verified. No known blocking defect remains in the exercised routes; this is not a claim of exhaustive coverage.
- **Reproducible handoff:** final documentation is committed on `codex/unit-release-20261019`; the intended source tag is `unit-dev-2.1-68-20261019`. The original dirty checkout remains untouched. The Profile and native-control branches continue separately and are not part of this installed build.


## Subsequent delivery — 19 October, build 69

The follow-on Analytics tab (renamed from Profile), native SwiftUI selections and approved navigation cues are now installed and launched as **2.1 (69)**. Training data remained row-identical. See [the final combined handoff](2026-10-19-unit-profile-native-release.md) for exact test limits, the user’s stop-testing instruction and final source checkpoint. Earlier pending follow-on statements above describe the build-68 checkpoint.
