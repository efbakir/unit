# Unit 2.1 (87) — rounded typography and JOI overhaul

User authorized rounded-font trial, secondary-button contrast correction and
installation. Includes the JOI overhaul described in 2026-10-20-joi-overhaul.md,
plus centered logging weight/unit, #F5F5F5 page background, SF Pro Rounded through
the existing UIFont typography bridge, and #E8E8E8 secondary control fill
(#D6D6D6 active). SF Mono workout values remain unchanged. JOI's exact font is
not confirmed; this is an approved trial. No new components or schema changes.

Source guards and whitespace checks pass. Six earlier focused iOS27 UI tests
cover the overhaul; latest font/color changes require user visual review.
Device delivery evidence: /private/tmp/unit-delivery87.
Preinstall backup includes Application Support and Preferences, not the full
container. SQLite integrity is ok: 14 workouts, 250 sets, 9 templates.
Build log: /private/tmp/unit-device87-build.log.
Installation and launch status will be appended after completion.
Development build only; no App Store upload/submission/reservation.

Signed build succeeded. In-place installation succeeded. All five training tables
are identical before/after installation; integrity ok. Normal launch blocked
by locked iPhone. User can unlock and open Unit; launch confirmation pending.
