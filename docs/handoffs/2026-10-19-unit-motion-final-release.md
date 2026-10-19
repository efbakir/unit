# Unit final gym handoff — 2.1 (73)

**Installed in place and launched normally on the connected iPhone. The cable can be disconnected.** Final application source: `1808d5f`. No further tests or Simulator runs were performed, following the user’s instruction.

## Included

- All Analytics/native SwiftUI changes, symmetric Today preview padding, full-width preview/divided-list separators, 64pt Programs day targets, and lighter shared navigation disclosures.
- Shared list identity now uses caller IDs; additions/removals/reordering retain row state and animate through existing motion owners. Button/chip enablement, selected surfaces, chart/history/filter/empty states, progression explanations and workout handoffs reuse AppMotion/AppBlurTransition/appNumericValue. Old completed-set checks no longer all bounce for every logged set.
- Explicit Start Workout has a spring/blur-scale handoff and one firm haptic only after saving succeeds. Failed creation rolls back and uses the existing persistent error toast. Resume stays immediate; no launch confetti, timed interaction delay, or entitlement-root animation was added. Reduce Motion/VoiceOver use fades.
- The workout weight/reps value and its editor reuse the existing `AppFont.numericInput` role at **30pt**, between the original36pt and smaller24pt versions. Timer numerics and unrelated product headings retain their existing sizes.
- Existing components/tokens were reused. Approved shared disclosure support is `appNavigationDisclosure` plus the existing row opt-in. No parallel motion/component system or new font token was introduced.

## Actual evidence

- Final signed Debug compilation: **BUILD SUCCEEDED**, `/private/tmp/unit-motion-73-build.log`.
- Installed **2.1 (73)** over the existing app and launched `app.unitlift` without test flags. No uninstall/reset. Install and launch JSON, binary hash and data comparison are in `/Users/efbakir/.codex/worktrees/unit-release-20261019/evidence/motion-73/`.
- Immediately before/after final refresh all five tables are row-identical: **9 templates, 13 sessions (12 existing workouts plus the live unfinished workout), 208 sets, 951 exercises, 1 split**. Integrity OK; kg and recovery-notice=false retained. The extra unfinished session appeared during live use before build72; no original workout/set was modified or removed by delivery.
- Static source guards passed. No final Simulator, manual motion/haptic/VoiceOver or enlarged-text review is claimed. Earlier build69’s204unit/5UI passes remain historical evidence; its interrupted/corrected-but-not-rerun checks and missing final iOS18 run are detailed in the previous handoff. No new tests were started for builds71–73.

## Source and chat closeout

- Motion chat2464f1d integrated as6e836c1; shared disclosureddad154 retained through e06dc3d. Launch7b2aef4/1cbb0bf integrated asa4f34cc/d872cfd, with resumed-session gating in11d006a. Final30pt adjustment1808d5f.
- Local `main` is fast-forwarded to the final checkpoint; remote push/public submission were not performed. Original52dirty files were byte-compared with recovery27fdb7b and preserved in an additional named stash `cce62d2a6988ffc61a7da476423ee7068e27aba4` before the user-approved main integration. Their work is already included in release ancestry; do not blindly reapply that stash.
- Final tag: `unit-dev-2.1-73-20261019`. Supporting branches remain recoverable; all participating chats were told to stop further work.
- Development-only build. App Store Connect reservation, actual Apple sandbox purchase/restore and public submission remain separate from this successful phone install.
