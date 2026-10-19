# Unit rest notifications — 2.1 (75)

## Changes
- Timer context now counts saved, completed working sets in the current exercise. Remaining sets show `Bench Press · Set 3`; only a completed exercise points to the following exercise’s first set. Both Lock Screen and Dynamic Island receive this shared context.
- RestTimerManager schedules a native local notification at the timer deadline: `Rest finished` / `Next: Bench Press · Set 3` (or `Start your next set.` when no context exists), with default sound. The manager enables foreground banners for rest alerts. Notification permission is requested on timer use if undecided; denial/scheduling failure uses the existing persistent error toast.
- Start/resume/adjust replace the pending alert; pause/stop cancel it. Generation-specific request IDs prevent an older asynchronous request from cancelling a newer timer. Completion retains the scheduled alert so the app countdown cannot cancel it just before delivery.
- Next-set text persists with the timer. Relaunch restores timing without rescheduling an existing system notification or requesting permission. Expired restored Live Activities end.
- PRODUCT.md now records plain, factual app copy with no motivational language or personality. No sizing, visual component or design token changes.

## Evidence
- Final signed iPhone Debug compilation succeeded: `/private/tmp/unit-rest-75-build.log`.
- Static source guards and whitespace checks passed. No tests or Simulator runs, per user instruction.
- Runtime notification delivery, first-permission prompt, sound/Focus settings and denied-permission path were not exercised. Installation/launch and data-preservation results are recorded below.
- Apple implementation references: [local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app), [foreground notification presentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/usernotificationcenter(_:willpresent:withcompletionhandler:)).

## Delivery
Final signed build75 installed in place and launched normally. Final before/after summaries are identical across every table and preference checked. Store integrity: ok. Table counts: ZDAYTEMPLATE=9, ZWORKOUTSESSION=13, ZSETENTRY=212, ZEXERCISE=951, ZSPLIT=1. kg and recovery-notice=false retained. Evidence/backups: `/private/tmp/unit-rest-75/`; final binary is in `/private/tmp/unit-motion-build/Build/Products/Debug-iphoneos/Unit.app`. An earlier readback timed out; the final fresh readbacks succeeded. No uninstall/reset. Local source checkpoint tag: `unit-dev-2.1-75-20261019`. Development-only; no public submission or App Store build reservation claimed.
