# Unit 2.1 (86) — phone delivery

## Authorization / source
Direct human installation request in Unit Analytics implementation chat, read and verified by Main before acting. Install authorization supersedes the earlier no-install freeze. Build86 source657b01d, based on final rest consistency checkpoint1767b80. Source tree clean before the build. Version remains2.1; development build only, not uploaded/submitted/reserved in App Store Connect.

## Included
All integrated post-build85 feedback: stable separate exercise cards and trailing checks; JOI/Mobbin-informed shared typography/surfaces; full-width separate keyboard buttons with Weight/Reps labels; explicit target preparation versus completion; smooth blue rest line; matched rest/keyboard footer, stable idle/running/finished geometry and0:00 finish cue; scoped Analytics/onboarding/Programs/chart motion. Shared owners reused, no new design-system component/token in this feedback pass. Source details: 2026-10-20-build85-gym-feedback.md, 2026-10-20-logging-keyboard-feedback.md, 2026-10-20-rest-footer-consistency.md.

## Passed checks
- Source guards and whitespace checks.
- Final dedicated rest test passed on iOS27: idle→running→+15→−15→actual expiry, height/vertical position unchanged within1pt and inactive Skip disabled.
- Keyboard prepare/Complete and explicit field-switch checks passed on iOS27; earlier keyboard preparation/Complete also passed compact iOS18.6. Latest rest footer has not had a new compact18/VoiceOver/Reduce Motion physical run.
- Prior integrated logging/Undo/edit/advance/relaunch and Analytics main/info/detail/metric checks passed in focused Simulator runs. Historical failed assertions/build repairs remain documented in the linked handoffs; no claim of a fully passing exhaustive suite.
- Signed device-target build succeeded: /private/tmp/unit-device86-build.log. Candidate hashes/metadata: /private/tmp/unit-delivery86/candidate.json.

## Backup and preservation
Device00008150-00064558340A401C, bundleapp.unitlift. Fresh inventory before85, after86. App was not running at final backup; no termination needed. Full Library copy encountered an iOS-protected SplashBoard snapshot read error, so this is NOT a full-container backup claim. Separately copied all Library/Application Support (store plus WAL/SHM together) and Library/Preferences successfully. Backup: /private/tmp/unit-delivery86/recovery-training. Integrity checkok.

Before and after in-place installation, all five training table full-row hashes and preferences were identical:14WorkoutSessions,250SetEntries,9DayTemplates,951Exercises,1Split. Recovery noticefalse. Evidence: /private/tmp/unit-delivery86/preservation-before-launch.json. No uninstall/reset/restore-to-phone/test flags.

## Launch status
Installed and inventory-confirmed2.1(86). Normal launch attempt was denied only because iPhone is locked (FBSOpenApplicationErrorDomain7, Locked). Unlock requested in Main. Normal launch and postlaunch comparison are still pending; do not claim those completed. Phone data and preferences are preserved through installation.

## Evidence
/private/tmp/unit-delivery86 contains before/after inventories, candidate hashes, successful targeted backups, install JSON, blocked launch JSON and preservation comparisons. These include private workout data; keep local. Simulator captures: docs/qa/build85-gym-feedback. They are not physical-device visual evidence.
