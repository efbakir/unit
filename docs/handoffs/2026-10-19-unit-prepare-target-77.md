# Unit target preparation — 2.1 (77)

## Problem and change
Entering an initial weight/reps through the upcoming-set sheet called completeSet and inserted a finished set. It now saves an unlogged target instead.

- Existing AdjustResultSheet’s upcoming mode is renamed from log to prepare; CTA is Save target. Empty workout CTA and hint say Set weight and reps. Completed-set chip editing retains Save changes and its existing update/delete behavior.
- Existing template starting-weight/reps fields retain initial values. A separate AppStorage JSON map scoped by session/exercise holds the explicitly prepared next target and note, ahead of automatic prefill for this session. It survives relaunch without adding a SwiftData field or migration. Accepted progression targets and history remain unchanged.
- Only Complete set inserts SetEntry, triggers success, advances progress and starts rest. It consumes the prepared note/values, then clears the draft only after persistence succeeds. Finish/cancel clear session drafts only after their own successful save. Failed saves leave the editor/draft intact.
- Prepared values are labelled Starting target (before any recorded set) or Next set; never Last time. The normal accepted-target/history/starting-target prefill order remains when no explicit session preparation exists. kg/lb conversion and explicit BW behavior reuse the existing editor.
- No new view, style, design token, layout or typography. No existing recorded sets were automatically removed or rewritten.

## Evidence and limits
Static guards and diff whitespace checks passed. No tests or Simulator runs, per instruction. Runtime preparation, cancellation, relaunch and failed-save interactions remain for visual/interaction review on the phone; compilation/installation evidence follows below.

## Delivery
Signed compilation succeeded. Build77 installed in place and launched normally. Before/after table hashes and checked preferences are identical. Integrity ok. Counts: ZDAYTEMPLATE=9, ZWORKOUTSESSION=13, ZSETENTRY=214, ZEXERCISE=951, ZSPLIT=1. No reset/uninstall. Build77 is development-only and unreserved in App Store Connect. Evidence: `/private/tmp/unit-prepare-77/`; build log: `/private/tmp/unit-prepare-77-build.log`. Checkpoint tag: `unit-dev-2.1-77-20261019`.
