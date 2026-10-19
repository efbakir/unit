# Unit — October 19 motion and iPhone release handoff

## Status and source

This is a development release pass, not an App Store submission. The public app is **2.0** (Apple lookup checked October 19). The connected iPhone started with **2.1 (65)**; the repository started at **2.1 (67)**. This pass prepares **2.1 (68)**, **development-only and unreserved** until App Store Connect's highest uploaded build can be read. Final device/test results are recorded below as they complete.

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
- **Visuals:** final SF Pro Today, active workout, progression explanation, target editor, History, and Undo/relaunch screenshots are saved in `../evidence/final/` relative to the checkout parent. The compact Simulator's system appearance was dark; Unit stayed light. Main screens were inspected directly.
- **Guard:** final 26-mutation self-test passed.
- **Device build:** signed Debug build succeeded from code checkpoint `f9087ae`; **2.1 (68)** installed in place successfully. The first normal launch attempt hit a wireless CoreDevice tunnel timeout; retry and post-install data comparison are pending.
- Further final evidence follows below.
