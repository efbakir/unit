# Unit 2.1 finalization, 2026-10-23

Efe delegated the whole finalization while away. This page says what was done, what is open, and the next action. Detail lives in the linked docs.

## Done / open / next

- **Done:** version 2.1 in App Store Connect with build 95 attached, release set to manual, new copy, reviewer notes and build-95 screenshots uploaded. Not submitted yet.
- **Done after build 95 (in the branch, not in a build yet):** new celebration with 3 looks plus the old one as baseline, delete buttons in the main-lift editor, a VoiceOver fix on main-lift cards, a large set-count picker, all UI tests fixed, a Hevy-style screenshot draft (`exports/6.9-inch-v2`), and your paywall reverts: Yearly preselected, Weekly for customers without a trial, "Save 80%", no "Paid plan required after setup." line.
- **Open (yours):** pick the celebration look, pick the screenshot set, send the before/after photos (`docs/app-store-assets/2.1/before-after/before.jpg` and `after.jpg`).
- **Next action:** after your picks I build 96, upload it, swap the screenshots in App Store Connect and submit for review. You tap Release after Apple approves.

## Your actions (only you can do these)

1. **Check build 95 on your phone, then release.** Release is set to manual: Apple reviews it, then it waits for your tap on "Release" in App Store Connect. Install with Xcode (Product → Run on the phone, tag `v2.1-build95`).
2. **Sandbox trial test on the phone.** Fresh sandbox account → finish setup → paywall → Start free trial → Yearly is preselected; Apple's sheet must show "7 days free, then $29.99/year" (or $4.99/month if you pick Monthly). Cancel in sandbox settings → relaunch → paywall again.
3. **Turn on Billing Grace Period** (App Store Connect → Unit → Subscriptions → Billing Grace Period → 16 days, all renewals). Keeps access while Apple retries a failed card; recovers revenue. My API call to set it was blocked by the permission system.
4. **Build the TelemetryDeck dashboard** from the list in [Data](#data). I can't log in to TelemetryDeck.
5. **Optional: App Store Connect API key with the Finance role**, so revenue and trial reports can be pulled automatically. The current App Manager key can't read Sales or Analytics.
6. **Merge the branch.** PR from `claude/app-finalization-launch-34a116` into `main`. The main checkout at `/Users/efbakir/unit` still holds the same build-90 work as uncommitted changes; after merging, discard those local changes there (they are identical to the committed snapshot `1e57ba5`).

## What changed in build 95

What a lifter sees:
- **Exercise done:** the finished card shows "Suggested next: 62.5 kg × 8 · +2.5 kg" (or "+1 rep", "same target"), or why there is none. It stays on screen above the next exercise.
- **Workout done:** the rest bar becomes a full-width "Finish workout" button.
- **Summary:** right after Finish, "Next time" comes first; the accept button says "Save for next workout" (people read "Use next workout" as "start the next workout").
- **Ready-made programs now suggest next targets.** Before, 26 of 27 had none.
- **Setup is 3 steps:** path, program, review. Unit picks kg or lb from the region or the pasted text; change it on review. No weekday step: new programs rotate, so Today offers workout 1 right after purchase.
- **Paywall:** "Start free trial" (no "$0.00"), billed price leads the line above the button, Monthly preselected for everyone, trial reminder on by default, Restore/Terms/Privacy/Support always visible, "Save 49%" vs Monthly, Restore works during a pending purchase.
- **Rest timer:** −30 / +30 seconds (was 20).
- **"Paid plan required after setup."** is back under the setup button.

Fixes: accepted targets survive rule edits; cancelling a start no longer skips the routine; the rest-alert notice no longer repeats after every set; bodyweight "Last time" shows BW; no "155.0"; comma decimals on review; a cut 7th day is reported; clearer paste error; best match preselected.

Measurement: new anonymous events (setup steps, purchase cancel/pending/fail, restore result, exercise-done suggestion, session start). A 50/50 Monthly-vs-Yearly default test is built but off until about 50 ratings (the panel predicted Yearly-by-default causes surprise charges and 1-star reviews).

All decisions with reasons and how to undo them: [decision log, 2026-10-23](../decision-log.md).

## Flows and edge cases

- [docs/flows/README.md](../flows/README.md): every flow, step by step, with rated edge cases.
- Biggest open risks:
  - "RPE 8" written before a number becomes 8 kg; junk rows can't be deleted on review.
  - An ignored suggestion only lives on in History.
  - "Workout from yesterday" is checked only on a cold launch.
  - No trial end date anywhere after a trial starts.
  - Lapsed subscribers lose access to their own history and have no export.

## Missed features and quick wins

Ranked by expected effect on money and habit. Effort: S = hours, M = days, L = weeks. None of these are in build 95.

| # | Change | Why it matters | Effort | Where |
|---|---|---|---|---|
| 1 | Trial end date and next charge in Settings ("Trial ends Oct 30, then $4.99/month") | Fewer surprise charges, refunds and 1-star reviews | S | SettingsView, StoreManager |
| 2 | Unaccepted suggestions on Today's rows ("Suggested 62.5 kg × 8") until the next workout | Ignored suggestions stop vanishing; a reason to open Unit before the gym | S-M | TodayView, SessionDetailView |
| 3 | "Done today · Next: Pull" instead of "Rest day" after training | Clear next step, habit | S | TodayView, AppCopy |
| 4 | Opt-in training-day reminder ("Push today · Bench 62.5 kg × 8") | Strongest pull-back for the week-2 drop | M | new notification owner, Settings |
| 5 | One-tap Paste button on the paste step | 1 to 2 fewer taps in setup | S | OnboardingProgramImportView |
| 6 | Offer-code redemption link on the paywall | Creator and Reddit promos without discounts in the app | S | PaywallView |
| 7 | Ask for a review right after the first accepted suggestion | Peak-satisfaction moment instead of "after workout 1" | S | TodayView, EngagementPromptTracker |
| 8 | Lapsed users: welcome-back copy, read-only history, CSV export, and an App Store win-back offer ($19.99/yr, already in pricing.md) | Win back churned payers; trust | M | PaywallView, StoreManager, Settings, App Store Connect |
| 9 | Parser: ignore "RPE 8" / "RIR 2" as weights, accept name-only lines, delete rows on review | Coached and Notes users finish setup | S each | ProgramImportParser, OnboardingProgramPreviewView |
| 10 | Live PR moment when a set beats your best | Motivation inside the workout | M (needs component approval) | ActiveWorkoutView, LoggedSetRow |
| 11 | Apple Health workout export | Fits the Apple fitness habit; fewer "where are my workouts" moments | M | new HealthKit owner |
| 12 | iCloud backup | "If I lose my phone I lose everything" is a churn reason | M-L (post-v1 per scope) | SwiftData + CloudKit |
| 13 | Edit or delete past workouts; swap an exercise mid-workout | Trust and busy-gym reality | M | SessionDetailView, ActiveWorkoutView |
| 14 | Percent-of-training-max loading and top/back-off set types | Unlocks 5/3/1 and coached lifters (worst-fit segment today) | L | engine, parser, logging |

Strategic gaps (not quick):
- Hard paywall with no free look is the main objection in every simulated segment; the 7-day trial is the only free look. Keep it, but watch paywall→trial rate.
- English-only UI caps Germany, Brazil, Turkey and Spain; localized metadata exists but is stale.
- Coaches can't see client logs (sharing is out of scope by design).

## Data

Collection stays anonymous and on-device first. No server, no account.

Events added in build 95: `onboarding_step_viewed` (method, paste, library, review), `purchase_outcome` (cancelled, pending, failed), `restore_outcome`, `progression_preview_shown`, TelemetryDeck's session start, and `default_plan` (monthly / annual) on paywall and purchase events once the default-plan test is switched on. Full event list: [first-run doc, analytics](../flows/first-run-and-paywall.md#13-analytics).

TelemetryDeck insights to create:
- Setup funnel: `onboarding_started` → `onboarding_step_viewed` (method) → (paste or library) → (review) → `program_setup_completed` → `paywall_viewed`.
- Paywall: `paywall_viewed` → `purchase_started` → `trial_started` or `purchase_completed`, split by `trial_eligibility` (and `default_plan` once the test runs).
- Purchase problems: `purchase_outcome` by outcome; `restore_outcome`.
- Habit: weekly unique users with `workout_completed`; active users from the session signal.
- Progression: `progression_preview_shown` and `progression_recommendation_shown` by outcome; `progression_decision` by action.

App Store Connect (money): Trends → Subscriptions for trial starts, trial-to-paid conversion, active subscriptions and churn.

Starting targets (adjust after 4 weeks of real data):

| Number | Target |
|---|---|
| Setup done ÷ setup started | 70% or more |
| Trial started ÷ paywall viewed (trial-eligible) | 10% or more |
| Trial → paid (App Store Connect) | 35% or more |
| 2+ workouts in the first 7 days ÷ trial starters | 50% or more |
| Any workout in week 4 ÷ payers | 30% or more |

Monthly vs Yearly default test: built but off. Switch `PaywallDefaultPlanExperiment.isRunning` on at about 50 ratings; after about 300 eligible paywall views per arm, keep the arm with more revenue per paywall view ([pricing.md](../pricing.md)).

Backend: none added, on purpose. Unit is local-first with no account, and the privacy page promises workout data stays on the phone. Supabase stays deferred (no Unit project exists; a new one would cost money). The next backend step only makes sense with iCloud backup or App Store Server Notifications for real-time renewals.

## Persona panel (MiroFish method)

- 20 simulated lifters in 4 segments walked the real flows, then argued about Unit in a Reddit-style thread. Treat it as hypotheses, not user research. Full write-up: [persona panel](../research/2026-10-23-persona-panel.md).
- Shipped because of it: Monthly preselected (a Yearly default hurt all 4 segments), trial reminder on, "Save for next workout", 3-step setup, suggestions on ready-made programs, kg/lb switch on review.
- Did not move: the hard paywall with no look before a card is the top objection in every segment. Watch paywall → trial rate.
- Still open: Hevy and Strong history import, RPE and percent loads, a calm restart after a gap, "your history stays on this phone" for returners.

## Verification

Simulators, final code (after your paywall reverts):

| iOS | Unit tests | UI tests |
|---|---|---|
| 18.6 (oldest supported) | 273 of 273 | Full suite 40 pass, 0 fail before the reverts; paywall, onboarding and progression suites re-run after them: all pass |
| 26.5 | 273 of 273 | Paywall, onboarding and progression suites pass; the rest passed in the full run before the reverts |
| 27.0 (current) | 273 of 273 | Full suite 40 pass, 0 fail |

- Skipped on purpose: 2 small-phone layout tests (they pass on the small iOS 18 simulator) and 1 manual celebration recording. On iOS 26 only, the existing-subscriber test skips: Apple's StoreKit test tool refuses that purchase in command-line runs. It passes on iOS 18 and 27.
- Fixed this round: reorder tests (direct drag), main-lift editor (app bug: no way to remove a lift), single-week analytics (app bug: VoiceOver read a comparison the card does not show), set-count picker (large native size on iOS 26+), component catalog scroll, the celebration policy test, and iOS 26/27 timing (menus and the Weekly button animate in, the Undo toast arrives later).
- Test simulators need the US region. With region Italy, iOS 27's StoreKit test tool reads "$2.99" as 2 (the Yearly badge showed "SAVE 72%"), and the test runner writes dates as "23 Oct". Real App Store prices are not affected. iOS 26 also needs the StoreKit config planted by hand (memory note `reference_unit_storekittest_sim_recipe.md`).
- Not verified by a person: the build on your phone, a sandbox purchase, the `docs/release-qa.md` gauntlet, and the celebration on an older iPhone.

## Where everything lives

- Branch: `claude/app-finalization-launch-34a116` (pushed). Tags: `v2.1-build94`, `v2.1-build95`.
- Flow docs: `docs/flows/`. Persona panel: `docs/research/2026-10-23-persona-panel.md`.
- App Store copy (canonical): `docs/app-store-copy.md`. Submit checklist: `docs/app-store-submission/final-submit-checklist.md`.
- Screenshots: captures in `docs/app-store-assets/2.1/source/`; live set in `exports/6.9-inch/`; Hevy-style draft in `exports/6.9-inch-v2/` (builder: `scripts/build-app-store-screenshots-v2.mjs`); side by side: `screenshot-options-2026-10-23.png`.
- Celebration recordings (old, plates, color, ribbons): `docs/qa/celebration-2026-10-23/`.
