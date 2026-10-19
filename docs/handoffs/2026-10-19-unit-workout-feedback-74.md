# Unit workout feedback — 2.1 (74)

Installed in place and launched normally on the iPhone. Sizes are unchanged, following the user’s correction. Development-only build; no App Store submission or reservation claim.

## Changes
- Grok conversation/private-chat references collected under `docs/references/ios-screens/grok/`. Borrowed quiet surfaces, minimal outlines and clear action emphasis; no Grok branding or layout copied.
- Existing `AppPrimaryButton` extended with `isConfirmed`. A saved set shows a checkmark for one second without changing measured button layout. Existing settle/feedback tokens supply the brief pop/fade; Reduce Motion/VoiceOver receive fades. The next eligible set remains immediately tappable. Final planned sets show confirmation before the CTA disappears. No extra haptic or model mutation.
- Existing `WorkoutCommandCard` owns the cancellation-safe dwell, triggered only after persistence succeeds. No confirmation starts on initial appearance; disappearing cancels the dwell.
- Existing `RestTimerControl` uses existing cardRowFill instead of the heavier controlBackground and removes redundant outlines in both WorkoutCommandCard and SessionStateBar. Last-time metric uses textSecondary instead of textDisabled.
- No font sizes, control/card heights, padding, radii, palette values or touch targets changed. No new component, token or variant; one new optional parameter on the existing primary-button owner.

## Evidence and limits
- Signed iPhone Debug compilation: BUILD SUCCEEDED, `/private/tmp/unit-style-74-build.log`.
- Installation and normal launch succeeded. Evidence/backups: `/private/tmp/unit-style-74/`; signed artifact: `/private/tmp/unit-motion-build/Build/Products/Debug-iphoneos/Unit.app`.
- Before/after stores have identical row hashes for all five tables: 9 templates, 13 sessions, 211 sets, 951 exercises, 1 split. Integrity OK; kg and recovery-notice=false retained. No reset/uninstall/test flags.
- Static guards and diff whitespace checks passed. No tests or Simulator runs performed, per user instruction. The new animation, accessibility behavior and final styling have not received a runtime visual pass; review on the phone is pending. No new iOS18 execution claimed.
- Provisional contextual scorecard: `docs/qa/design-evaluation/scorecards/2026-10-19-workout-feedback.md`.

## Checkpoint and next review
- Local main checkpoint tagged `unit-dev-2.1-74-20261019`. No remote push/public submission.
- Review Complete set → saved checkmark → next set, the final set confirmation, and quiet idle/paused rest controls. Existing earlier release blockers remain documented in the build73 handoff; none were silently relabelled as resolved here.
