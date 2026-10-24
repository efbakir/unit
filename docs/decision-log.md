# Unit — Decision Log

- Newest decisions come first.
- Each entry answers three questions: What changed? Why? What follows?
- **Superseded** means the entry is history, not current direction.
- Current product rules also live in `docs/product-compass.md` and `docs/pricing.md`.

<!-- Add new entries below this line. -->

## 2026-10-24 - Founder override: next targets apply at Finish

Efe chose this in the progression-loop session, after benchmark 4 (`docs/research/2026-10-24-benchmarks/4-exercise-done-summary.md`) and persona panel round 2.

- **Next targets apply at Finish.** Finishing a workout saves every suggested next target to the routine. The summary shows each as "Saved", with "Keep previous target" (then "Use suggested target") and "Edit". Why: lifters who skipped the summary lost their suggestions (about 3 of 5 per persona segment), and Efe wants the next workout to move forward by itself. Supersedes 2026-08-03 "Nothing changes automatically", the "accept or edit it" step of 2026-08-12 and the compass line "never changes a routine before acceptance". Still true: opt-in per exercise, evaluated after the workout, reason shown, no deloads, nothing changes during a set.
- **Set 1 prefill:** saved target, then set 1 of this routine's last workout with the lift, then set 1 of the last workout in any routine, then the routine's starting target. Set 2 and later still copy the set just logged. "Last time" on row N shows set N of that same workout. Refines the "latest completed session" step of 2026-08-04, which used the last set of the newest workout from any routine, often the weakest.
- **Finish dialog removed.** "Update routine with today's weights?" wrote the routine's planned numbers, which the next workout never reads once a lift has history.
- **Summary.** Blocks without a suggestion (weights varied, sets unfinished) get Edit. A repeated target names the short sets ("Set 3: 6 of 8 reps. Keep this target."). Going back to the previous target plays no burst.
- **Done card:** "Next time: 3 × 8 at 62.5 kg · +2.5 kg", the same-set wording as Today and History.
- **Analytics:** no new event. A target saved at Finish sends no decision event; "Keep previous target", "Edit" and "Use suggested target" send `progressionDecision` (repeat, edit, accept). Read accept counts as returns to the suggestion, not as approvals.
- **Copy:** the website FAQ and compare pages, the App Review notes (`docs/app-store-copy.md`), CLAUDE.md, PRODUCT.md principle 2, goals, scope, compass and flow docs now say targets are saved at Finish. Build 96 (the 2.1 submission) was cut before this change, so it ships in the next build, and the App Review note goes into App Store Connect with that build. The frozen listing lines stay true and unchanged.
- **Not changed:** lifts pasted with fixed reps ("3x8") still have no rule, so they never move up by themselves.
- **Undo:** remove the `applySuggestedTargets` calls in `ActiveWorkoutView.finishWorkout` and `TodayView.saveStaleSession`; the summary then falls back to "Save for next workout".

## 2026-10-24 - Yearly badge back to "Save 80%"

- **Decision:** The yearly badge says `Save N%` again, not `Save N% vs weekly`. Founder call on the paywall review.
- **Why:** Same as 2026-07-13: the long badge overpowered the plan card. The Weekly price sits two rows above, so the comparison stays readable.
- **Supersedes:** The badge half of the "Paywall price" line in the App Review fixes entry below. The price headline stays.
- **Effect:** Copy only. Savings math (52 × Weekly) and purchase behavior do not change.

## 2026-10-24 - Anonymous analytics is opt-in

- **Decision:** Analytics are off until the person turns them on. A missing `analytics.enabled` key now means off, so nothing is sent at launch.
- **Where:** The opt-in switch is on setup step 1 and in Settings. The paywall footer shows it only while it is on, so people who opted in (including lapsed subscribers, who cannot reach Settings) can turn it off before paying.
- **Why:** App Review Guideline 5.1.1(ii) asks for consent "even if such data is considered to be anonymous". A switch that starts on is not consent, and 2.1 is the first paywall Apple reviews.
- **Cost:** Funnel numbers come only from people who opt in, so the default-plan test (about 300 eligible paywall views per arm) reads later. If the numbers are too thin, the follow-up is a one-time "Share anonymous usage data?" question.
- **Copy:** Caption "Helps me improve Unit. Never sends exercise names or weights."
- **Supersedes:** The 2026-08-05 "on by default with a Settings opt-out" and the "Default stays on" line of the App Review fixes entry below.
- **Undo:** `UnitAnalytics.isEnabled` (missing key), `PaywallView.showsAnalyticsToggle`.

## 2026-10-24 — App Review fixes before the next 2.1 upload

- **5/3/1 volume blocks stay separate.** A day that lists the same lift twice (main work, then BBB) now saves the second block under its own exercise, named with its note (`Bench Press · BBB @ 50%`). Summary, history, and analytics no longer build a dictionary that traps on a repeated exercise id.
- **Privacy manifest.** Device ID is declared for Analytics, not linked and not used for tracking, next to Product Interaction and Purchase History. Matches the App Store Connect privacy answers. TelemetryDeck is still initialized with its default config, which sends a hashed device identifier.
- **Analytics switch before purchase.** The same Anonymous analytics setting is on the first setup step and on the paywall footer. Settings still uses it. Default stays on.
- **Paywall price.** An eligible trial headline is the billed price and the free period in one title line (`$29.99/year after 7 days free`). The yearly badge says `Save 80% vs weekly` (still 52 × Weekly). Free-trial wording still requires that product's own free introductory offer plus StoreKit eligibility for that product.
- **Build number.** Left at 95. The next archive is 96, cut when the upload is made. This change does not bump `CURRENT_PROJECT_VERSION`.

## 2026-10-23 — Founder override: paywall defaults and the setup notice

Efe reviewed the persona-panel changes and reverted four of them. The panel's warnings stay on record in `docs/research/2026-10-23-persona-panel.md`.

- **Yearly is preselected** for every trial-eligible customer (was Monthly). The default-plan test stays built and off; off now means Yearly.
- **Weekly is preselected for customers without a trial** (returning or lapsed), as before build 94.
- **"Save 80%":** Yearly is compared with 52 weeks of Weekly again (was 12 months of Monthly, "Save 49%").
- **No "Paid plan required after setup." line** under "Set up your program". Supersedes the 2026-08-05 disclosure decision.
- **Open:** "Try for $0.00" on the trial button. Held because Apple rejects paywalls where the trial price stands out more than the billed amount (3.1.2), and 2.1 is the first paywall Apple reviews. Waiting on Efe.
- **Kept:** trial reminder on by default; the billed price leads the line above the button; Restore, Terms, Privacy and Support in every paywall state.
- **Undo:** `PaywallDefaultPlanExperiment.arm()` (off value), `PaywallPlanSelectionState.applyInitialDefault`, `PaywallView.annualSavingsBadgeText`, the CTA block in `OnboardingSplashView`.

## 2026-10-23 — Finalize 2.1 for the App Store (founder delegated all decisions)

Efe asked for the app to be finalized and shipped while away, with full decision authority. Each item below is a decision, its reason, and how to undo it.

- **Release source:** Version 2.1 ships as build **94**, built from the build-90 phone state (uncommitted in the main checkout, now committed on `claude/app-finalization-launch-34a116`) plus this session's changes. Build 74 (August) was not used because it lacks all October work.
- **Release type:** Manual release after approval. No person has tested build 94 on a phone; the founder checks it, then taps Release.
- **Exercise-done suggestion (founder request):** When every planned set of a progression exercise is logged, its collapsed card shows "Suggested next: 62.5 kg × 8 · +2.5 kg" (or "+1 rep", "same target"). Read-only; acceptance stays on the summary after Finish. This explicitly overrides the "post-workout only" wording in CLAUDE.md for this read-only preview. The finished card stays on screen when the next exercise sits right below it.
- **Finish workout button:** When every planned set is logged, the rest bar becomes a full-width "Finish workout" button. Why: the small toolbar Finish was easy to miss, and the summary is where next targets are accepted.
- **Ready-made programs get next-target rules:** 26 of 27 catalog programs had no rep ranges, so most lifters never saw a suggestion. Programs that define no ranges now give weighted lifts Unit's standard rule at import: start at the program's reps, build up to two more, then add 2.5 kg (2 kg for dumbbells, 5 lb in pounds). Bodyweight moves, timed or 20+ rep work and 5/3/1 percentage sets keep no rule. Catalog data is unchanged; Combat Power keeps its own ranges. Undo: `ProgramImporter.libraryProgressionConfiguration`.
- **Accepted targets survive rule edits:** Changing sets, rep range or weight step no longer drops an accepted target; its weight stays and reps clamp into the new range.
- **Onboarding 5 steps to 3:** Path, program, review. The weight unit comes from the phone region (pounds only for US-measurement regions) or the pasted text, and can be changed on review and in Settings. The weekday step is removed: new programs start as a flexible rotation, so Today offers the first workout right after purchase instead of "Rest day" on 4 of 7 days. Weekdays can still be set in Programs. Drafts saved on retired steps resume on their replacement.
- **Summary:** Right after Finish, "Next time" is the first section (it sat below the whole log). The accept button says "Save for next workout" (3 of 4 returning-adult personas read "Use next workout" as "start the next workout"; "Save" matches the "Saved" status). A progression exercise with no suggestion now says why on its done card.
- **Setup details:** "Paid plan required after setup." is back under the setup button (the 2026-08-05 decision was lost in the 2026-08-13 layout pass). The best ready-made match is preselected. Review accepts comma decimals, reports a cut 7th pasted day, and re-reads unit-free pasted numbers when kg/lb changes.
- **Celebration redesign (founder request: "fix the confettis"):** One physics renderer for all three moments (first workout, every finished workout, saved target): pieces fire from the bottom corners, slow down in the air, fall with flutter and a 3D flip. Looks: Plates (lifting pieces in Unit blues and ink, the default), Color (same pieces, multi-color), Ribbons, and the old renderer as the baseline. The saved-target burst grows from 8 dots in 0.45 s to 14 pieces in 0.9 s and stays the smallest moment; the old numbers stay tested as the baseline. Final look is the founder's pick (debug component catalog has a switcher; recordings in `docs/qa/celebration-2026-10-23/`). Reduce Motion and VoiceOver still get no motion. Undo: set `AppCelebrationLook.production` to `.classic`.
- **Rest steps (founder request):** The rest buttons move by 30 seconds instead of 20 (−30 / +30). One constant, `AppCopy.Workout.restStepSeconds`, drives the labels, VoiceOver and the timer; the 15-second minimum is unchanged.
- **Cancelled starts:** Cancelling a started workout (or the empty-yesterday cleanup) restores the routine's last-performed date, so a flexible rotation does not skip it.
- **Rest-alert notice:** With notifications off, the notice shows once per workout and dismisses itself; it used to stay after every set.
- **Paywall:** Hard paywall, prices, 7-day trial and Lifetime $44.99 stay. Changes: "Start free trial" replaces "Try for $0.00" and the line above the button leads with the billed price (App Review 3.1.2); Restore, Terms, Privacy and a new Support link show in every state; Restore works during a pending purchase; Yearly "Save N%" compares with 12 months of Monthly ("Save 49%"), not 52 weeks ("Save 80%" read as an inflated anchor). Monthly is preselected for every customer, including those without a trial (a preselected Weekly plan read as a trap to returning users; Weekly stays listed). The trial reminder now defaults on; permission is still asked only after a verified trial purchase. A 50/50 Monthly-vs-Yearly default test is built (`PaywallDefaultPlanExperiment`, `default_plan` on paywall and purchase events) but switched off: the persona panel predicted surprise $29.99 charges, refunds and 1-star reviews, the costliest outcome while Unit has few ratings. Turn it on at about 50 ratings. Supersedes the 2026-08-04 Weekly default for ineligible customers and the 2026-08-13 reminder-off default.
- **Data, no new backend:** Supabase and any server stay deferred (local-first; no account; the privacy promise). Data collection is TelemetryDeck plus App Store Connect: added anonymous events for onboarding steps, purchase cancel/pending/fail, restore result and the exercise-done suggestion, plus TelemetryDeck's session-start signal for active users and retention. Pulling revenue reports automatically needs an App Store Connect API key with the Finance role; the current App Manager key cannot read Sales or Analytics reports.
- **MiroFish:** The real tool cannot run here (needs a Zep Cloud key and an LLM key, and it simulates social-media opinion rather than app use). Its method was replicated with Claude agents; results are in `docs/research/2026-10-23-persona-panel.md`.

## 2026-08-13 — Put the trial decision on one complete purchase surface

- **Decision:** Replace the two-page paywall with one scrolling `AppScreen`. Keep the personalized program payoff, grouped Weekly/Monthly/Yearly/Lifetime choices, selected-offer timeline, optional reminder, included features, renewal disclosure, legal actions, and sticky purchase CTA together.
- **Purchase action:** An eligible introductory trial uses StoreKit-localized `Try for 0.00`; subscriptions without a trial use `Subscribe for [full billed price]`; Lifetime uses `Buy for [price]`. Every action purchases the currently selected StoreKit product through Apple's native confirmation sheet.
- **Reminder:** `Remind me 2 days before` defaults off and appears only for a verified eligible trial presentation. Toggling it never requests permission. After a verified trial purchase, Unit requests permission and schedules at expiration minus 48 hours only when the customer opted in. The persisted choice supports delayed transactions and reconciliation without unexpected prompts.
- **Offer hierarchy:** All available plans share one group. The selected plan expands to show complete billing detail; unselected plans remain compact. Lifetime has no separate `Or pay once` heading.
- **Why:** The local Opal benchmark and the supplied Headspace/Napper-style references keep timing, confidence copy, and purchase together. Unit adopts that lower-friction structure while preserving localized StoreKit truth, a visible full renewal amount, and an optional—not assumed—notification choice.
- **Supersedes:** The two-page flow, separate Lifetime grouping, automatic reminder, and paywall page-view split in the two 2026-08-13 decisions below. The hard gate, plan defaults, StoreKit eligibility rules, and direct plan comparison remain.

## 2026-08-13 — Make purchase options directly comparable

- **Decision:** Show Weekly, Monthly, and Yearly directly on page two as the three primary recurring choices. If StoreKit returns Lifetime, show it below a separate `Or pay once` label instead of making four equal offers compete.
- **Hierarchy:** Increase the included-feature heading, labels, checks, spacing, and card inset. Reduce Restore, Terms, and Privacy to the muted text token while preserving 44pt tap targets.
- **Why:** Apple's purchase examples keep available durations visible, while Superwall's large-sample guidance favors multiple offers but recommends limiting the primary comparison to one-to-three choices with a clear winner. Direct comparison removes a hidden interaction; separating Lifetime keeps the decision legible.
- **Supersedes:** The 2026-08-12 collapsed-alternatives rule and the `Change` sheet portion of the two-page decision below. The two-page flow, StoreKit-derived prices, defaults, and trial eligibility rules remain.

## 2026-08-13 — Separate trial reassurance from the purchase decision

- **Decision:** Use two native hard-paywall pages. Page one shows the goal-personalized headline, centered completed-program card, and StoreKit-derived access timeline. `Continue` opens page two with the selected plan, `Change` sheet, included features, renewal disclosure, legal actions, and dynamic purchase CTA.
- **Trial reminder:** A verified introductory-trial purchase unlocks Unit before notification permission is requested. If allowed, schedule `unit.trial-reminder` for the verified expiration date minus 48 hours. Denial never blocks access, reconciliation never prompts unexpectedly, and stale reminders are cancelled.
- **Measurement:** Record each paywall page view and controlled reminder authorization outcomes without program names or workout content.
- **Why:** Separating reassurance from checkout reduces information density while keeping the billed amount and purchase disclosure together. The Day 5 promise is now backed by real local-notification behavior.
- **Supersedes:** The 2026-08-12 one-page/no-reminder decision. The hard gate, StoreKit-derived truthfulness, and no-reminder-toggle rule remain.

## 2026-08-13 — Expand the weekly starter-program catalog without copying Liftosaur

- **Decision:** Grow Unit's catalog from 13 to 27 complete programs. Keep the current top three schedule-compatible matches visible and place remaining same-schedule programs behind the existing `Show all` action.
- **Source boundary:** Use Liftosaur only as a market inventory. Independently write Unit's program names, summaries, descriptions, day structures and prescriptions. Do not copy Liftosaur text, scripts, progression logic or repository data.
- **Product boundary:** Add repeatable two-to-six-day weekly templates only. Do not flatten multi-week peaking blocks or periodized cycles into misleading one-week programs.
- **Ranking:** Continue ranking by the answers Unit can honor—training days as a hard constraint, then goal and experience. Do not claim popularity without usage data.
- **Why:** Lifters get a materially broader local library while Unit keeps honest content, deterministic matching and the existing template model.

## 2026-08-13 — Expand the existing exercise picker with public-domain data

- **Decision:** Keep Unit's current searchable Add Exercise sheet and seed it with a broad offline exercise catalog. Preserve Unit's curated names and aliases when entries overlap, and never replace, rename, or unarchive a lifter's existing exercises.
- **Source:** Use exercise names and basic classification from `yuhonas/free-exercise-db`, released under the Unlicense. Do not copy Liftosaur's AGPL-3.0 exercise files into Unit.
- **Scope:** This is a selection library only. Do not add exercise recommendations, instructions, imagery, or a discovery feed.
- **Why:** Lifters can find the movement they already intend to log without licensing risk or extra setup, while Unit stays local-first and inside the current product boundary.

## 2026-08-13 — Treat the paywall as the payoff of program setup

- **Decision:** Lead the hard paywall with `Your program is ready`, a prominent completion mark, and the saved program name and context. Do not describe this state as merely `Matched to your answers`.
- **Personalization:** Keep the trial headline stable, but connect the supporting promise to the controlled onboarding goal: build strength, build muscle, or build both. Pasted programs use a neutral steady-progress promise.
- **Hierarchy:** Use 32pt between the hero and completed program, then 48pt between major purchase sections. Keep price, renewal, StoreKit behavior, and the sticky purchase action unchanged.
- **Benefits:** Keep the secondary feature matrix concise; use `Ready-made programs` so every benefit remains one line at standard text sizes.
- **Why:** The screen should celebrate completed setup and the user's intended outcome before asking for payment, rather than reading as a dense list of product mechanics.

## 2026-08-13 — Keep three program recommendations visible and disclose the rest

- **Decision:** Show the three highest-ranked schedule-compatible programs as the default onboarding shortlist.
- **Disclosure:** When more schedule-compatible catalog programs exist, add one quiet `Show all N matching programs` action below the shortlist. Expanding keeps the same ranking and full program cards; `Show top 3` restores the shortlist.
- **Scope:** Do not mix programs from other schedules into this disclosure. The selected training-day count remains a hard constraint while goal and experience determine rank.
- **Why:** Three choices keep the decision focused, while the disclosure makes the included catalog discoverable without adding a new page or overwhelming the initial results.

## 2026-08-13 — Default the ready-made schedule to three days

- **Decision:** Preselect three training days when the user first reaches ready-made-program question three. Do not skip the question.
- **Action:** Keep `Continue` enabled from the start and use it to advance to program matches. Preserve a different saved choice when the user returns.
- **Component:** Use the same `.weekday` `AppSegmentedControl` treatment as the schedule assignment page shown after program selection.
- **Control height:** Keep both the training-day count and weekday assignment uses on the shared 48pt `.weekday` size (`AppSpacing.xxl`) so neither selector feels compressed.
- **Why:** Three days is a useful default, removes an unnecessary required tap, and keeps the two day-selection surfaces visually consistent.

## 2026-08-13 — Keep onboarding progress counter-only

- **Decision:** Keep the existing `STEP NN / 05` counter without a progress bar on every onboarding page.
- **Nested questions:** Ready-made-program questions add only `Q 01 / 03`, `Q 02 / 03`, or `Q 03 / 03` at the top right. The results page has no nested status label.
- **Why:** A linear bar introduced a second progress language that Steps 1–2 do not use. The question counter communicates the nested sequence without adding new chrome.
- **System:** Remove the unused onboarding progress-fill token; do not replace the bar with another indicator.

## 2026-08-12 — Use an editorial marketing rhythm and preserve the native core

- **Marketing:** Replace repeated equal-weight feature cards with divided editorial rows, reserve uppercase mono labels for real metadata, and use 16px as the narrative-text floor.
- **Reliability:** Render available local marketing photos immediately and show a fallback only after a real image error; cached images must not remain hidden behind placeholders.
- **Responsive proof:** Stack trust statements cleanly on phones, remove forced-height review cards, and use a consistent audience grid.
- **iOS:** Keep the current active screen architecture. It already follows the shared tokens and reusable components, and a cosmetic rewrite would risk the three-second logging path without a verified usability gain.
- **Documentation:** The responsive website type ramp now lives in `DESIGN.md`; the complete audit and verification record lives in `docs/qa/design-evaluation/system-wide-impeccable-pass-2026-08-12.md`.

## 2026-08-12 — Show subscription timing on the paywall

- **Decision:** Replace the hidden `What happens next?` sheet with an on-page connected timeline that updates with the selected StoreKit tier.
- **Trial sequence:** Show `Day 0`, the cancel-before-renewal window, and the StoreKit-derived renewal day and price. Do not claim Unit sends a reminder until that feature exists.
- **Reminder:** Do not place a reminder toggle on the purchase screen. The visible cancellation window provides the necessary clarity without adding a notification decision before checkout.
- **Tier placement:** Keep plan selection on the same page. A separate pricing step would add friction and separate the selected amount from its renewal explanation.
- **Why:** Every local benchmark with a timeline makes the trial sequence visible before purchase. Unit adopts that clarity while keeping its flat, light, monochrome system and honest copy.
- **Supersedes:** The 2026-07-13 decision to keep `What happens next?` only in a small sheet; the rule to keep price details near the purchase action remains active.

## 2026-08-12 — Align the website and opener with progression

- **Marketing:** Lead with `Know what to lift next`. Explain the product in one sequence: log the work, see the reason, review one next target, then accept or edit it.
- **Control:** Keep one-tap logging and athlete control in the story. Never imply automatic program changes, generated programs, or a black-box coach.
- **Onboarding:** Use a black surface only for the two-second logo opener with `Progressive overload made simple.` The carousel and product remain light.
- **Why:** The verified 2.1 feature, onboarding, App Store listing, and website should make the same promise.

## 2026-08-12 — Match ready-made programs from three honest answers

- **Decision:** Keep two onboarding paths: `I have a program` opens paste import; `I need a program` asks goal, experience, and supported training days, then ranks up to three existing catalog programs.
- **Catalog:** Add one complete 2-day program and one complete 5-day program so the schedule question can offer 2–6 days without a dead answer. Training days are a hard match; goal and experience determine rank.
- **Trust:** Say `Matched to your answers`, never imply Unit generated a new plan. Do not ask about workout duration or equipment until those fields exist across the catalog.
- **Paywall and measurement:** Carry the three controlled answer buckets into the paywall and attach source, goal, experience, and days to trial/purchase events. Never send program names, exercises, weights, reps, or pasted text.
- **Infrastructure:** Keep matching local and deterministic. Supabase remains deferred until the catalog needs remote management or a cross-device user profile.

## 2026-08-12 — Tighten onboarding, screenshot, and ASO copy for 2.1

- **Decision:** Use a concrete progression story across onboarding and the App Store without duplicating the same screen. Onboarding says `Know what to lift next`, explains that Unit prepares the next target after the workout, uses the concrete `10 reps` / `5 lb` example, and keeps one-tap logging as the third value. The six App Store headlines are `Know what to lift next`, `Log a set in 3 seconds`, `Hit 10 reps. Add 5 lb.`, `Paste your plan or choose one`, `See your strength go up`, and `Rest timer on your Lock Screen`.
- **ASO:** Use the 97-byte keyword field `reps,barbell,sets,strength,lifting,weights,routine,history,rest,timer,personal,record,pr,load,1rm`. Keep name/subtitle terms out of the field so Apple can combine the remaining words into searches such as `rest timer`, `personal record`, `PR tracker`, and `1RM tracker`.
- **Why:** The copy is more concrete, scannable, and aligned with Unit's real double-progression behavior. RespectASO scores are directional evidence, not ground truth; keywords support discovery while screenshots explain benefits and conversion value.
- **Next:** Replace the editable 2.1 listing metadata and six screenshots with these canonical assets. This is listing-only work and does not require a new app binary or build number.

## 2026-08-10 — Build 67 replaces build 66

- **Decision:** Version 2.1 moves to build **67**. Build 66 will not be attached in App Store Connect.
- **Why:** No retained archive, upload log, tag, or commit proves what source produced build 66.
- **Next:** Add the private TelemetryDeck ID, inspect the archive, pass automated checks and the physical-device purchase test, then tag the exact commit `v2.1-build67`.
- **Also:** Use the verified Featurebase board at `https://unitlift.featurebase.app`. Workout content stays on-device.

## 2026-08-05 — Disclose paid access before setup

- **Decision:** Show `Paid plan required after setup. Prices and any eligible trial are shown before purchase.` below `Set up your program`.
- **Why:** People should know setup ends at a paywall before spending time building a program.
- **Limits:** This adds no screen, tap, analytics event, StoreKit behavior, or trial promise.
- **Test later:** After launch, test speed-first acquisition by swapping screenshots 1 and 2 only. Keep screenshots 3–6 and all other listing details fixed.

## 2026-08-05 — Add anonymous funnel analytics

- **Decision:** Version 2.1 uses TelemetryDeck for a strict allowlist of anonymous usage events. Analytics are on by default with a Settings opt-out.
- **Why:** Measure onboarding → paywall → purchase → workout → recommendation without adding accounts.
- **Privacy:** Never send exercise names, program text, weights, reps, notes, bodyweight, email, timestamps, raw IDs, or receipts.
- **Limits:** Supabase and CloudKit stay out. Unit still works offline and without analytics.
- **Release note:** This entry advanced the candidate to build 66; the 2026-08-10 entry later replaced it with build 67.

## 2026-08-04 — First-session values are Starting targets

- **Decision:** Saved sets, reps, and weights appear in the first matching workout as a **Starting target**.
- **Prefill order:** Accepted target → latest completed session → saved starting values → empty fields.
- **Why:** Planned data is useful, but it is not workout history.
- **Rule:** Use **Last time** only after a real set was completed. Show `No history yet` only when every prefill source is missing.

## 2026-08-04 — Add a seven-day trial

- **Decision:** Eligible customers get a seven-day free trial on Monthly and Yearly. Weekly and Lifetime have no trial.
- **Default:** Eligible new customers start on Monthly. Ineligible customers start on Weekly.
- **Why:** Let new customers test the full product without adding a permanent free tier.
- **Rule:** Show trial copy only when StoreKit returns a valid free offer and Apple confirms eligibility.
- **Next:** Configure the same offers in App Store Connect and verify them in Apple’s sandbox purchase sheet.
- **Supersedes:** The no-trial rule and the rule that Weekly is always selected by default.

## 2026-08-04 — Progression positioning ships in 2.1

- **Decision:** Ship transparent double progression in version 2.1, not 2.2.
- **App Store:** Name `Unit: Progressive Overload`; subtitle `Gym Workout Log & Tracker`. Home Screen name stays `Unit`.
- **Why:** The feature is verified, so the listing and the product can test the same promise together.
- **Next:** Replace the old screenshots with the progression-led English set. Do not publish stale localized metadata.

## 2026-08-03 — Unit becomes progression-guided

- **Decision:** Unit is a transparent progression-guided logger, not only a passive log.
- **Feature:** One opt-in double-progression rule suggests the smallest next-session change after the workout.
- **Control:** The user edits or accepts the suggestion. Nothing changes automatically.
- **Limits:** Keep the three-second Gym Test. Do not restore cycles, failure counters, deloads, recovery logic, or automatic program rewrites.

## 2026-07-27 — Build 59 replaces build 58

- **Status:** Superseded by later release builds.
- **Decision:** Use version 2.1 build 59 from tag `v2.1-build59`; do not submit build 58.
- **Why:** Build 58 could restore the paywall after a successful purchase because of a stale entitlement refresh.
- **Next:** Repeat the physical-device purchase test and archive only a clean, tagged `main` commit.

## 2026-07-23 — Add review and feedback prompts

- **Decision:** Ask for an App Store review after workout 1 and show one feedback card after workout 3.
- **Rule:** Count only new workout session IDs for this version. Never interrupt active logging.
- **Feedback:** Open the Unit feedback calendar or a prefilled email to `support@unitlift.app`.
- **Release note:** This entry set 2.1 build 58; later build decisions supersede that number.

## 2026-07-22 — Bind releases to clean main

- **Decision:** Recover the July 13–17 work, remove Debug-only forced onboarding, and make Debug and Release use the same saved state.
- **Why:** Version 2.0 build 35 was uploaded from older committed source while Xcode showed newer uncommitted work.
- **Rule:** Archive only from clean, tagged `main`. Record the tag and build number before upload.
- **Release note:** This entry set 2.1 build 36; later build decisions supersede that number.

## 2026-07-17 — Remove the simulated onboarding set

- **Decision:** Remove the `Try a set` card from program review. Do not move it elsewhere.
- **Why:** Review should confirm exercises, sets, reps, and weights. A fake set added confusion and looked like history.
- **Effect:** Program review now leads with the workout cards and one completion action.

## 2026-07-13 — Zero weight means bodyweight

- **Decision:** Entering `0` completes the set and classifies the exercise as bodyweight.
- **Display:** Show `BW`, never `0 kg`, across active workout, Today, History, and progress chips.
- **Rule:** Empty weight is still invalid for an unclassified weighted exercise.

## 2026-07-13 — Use the compact yearly savings badge

- **Decision:** The yearly badge says `Save N%`, not `Save N% vs weekly`.
- **Why:** The longer badge overpowered the plan card. The supporting price line already explains the comparison.
- **Effect:** Pricing math and purchase behavior do not change.

## 2026-07-13 — Keep price details near the purchase action

- **Decision:** Repeat the selected StoreKit price and renewal type in the sticky purchase area.
- **Why:** The amount must stay visible when the selected plan card scrolls away.
- **Also:** Keep `What happens next?` as a small sheet, not another page.
- **Source:** Uses RevenueCat’s repeatable clarity ideas, not its unproven success-story patterns.

## 2026-07-13 — Simplify the paywall hierarchy

- **Decision:** Use one flow: Unit proof → saved program → plan choice → sticky purchase button.
- **Removed:** Next-exercise teaser and repeated feature claims.
- **Why:** The old page mixed too many messages and made the plan cards feel disconnected.
- **Keep:** StoreKit pricing, savings math, Restore, Terms, Privacy, and purchase behavior.

## 2026-07-13 — Finalize four localized app names

- **Decision:** Use de `Unit: Trainingstagebuch`, es-MX `Unit: Registro de gym`, fr `Unit: Carnet de Muscu`, and tr `Unit: Antrenman Günlüğü`.
- **Open:** pt-BR `Unit: Diário de Treino` still needs a native review.
- **Rule:** Nothing goes to App Store Connect without the locale-specific founder approval.

## 2026-07-13 — Tighten in-app copy

- **Decision:** Remove warm-up coaching, shorten onboarding labels, simplify Today states, and centralize stable copy in `AppCopy`.
- **Why:** The app was explaining too much. Unit records training; it does not teach exercises.
- **Voice rule:** First-person singular prevents fake corporate `we`; it does not require `I` or `my` in every label.
- **Effect:** This supersedes the 2026-07-11 `Summary` / `Save my program` wording.

## 2026-07-13 — Allow honest conversion tactics on the paywall

- **Decision:** Use live savings, per-week equivalents, and the user’s program name to clarify the choice.
- **Rule:** Every number comes from StoreKit. No fake comparison price, countdown, scarcity, or unsupported trial claim.
- **Placement:** Badge the upsell tier, not the default tier.
- **Why:** Make the value ladder clear without breaking trust.

## 2026-07-11 — Replace style keywords with behavior keywords

- **Decision:** Target behaviors such as rest timer, set/reps counter, weights history, progressive overload, and training notes.
- **Removed:** Narrow style terms such as powerlifting, barbell, 5x5, hypertrophy, and squat.
- **Why:** Unit sells simple tracking behavior, not one training style.

## 2026-07-11 — Renumber release build 16 to 35

- **Status:** Historical release decision.
- **Decision:** Use version 2.0 build 35 because App Store Connect already had builds 24–34.
- **Why:** Those builds predated the launch-hang fix. Build 35 was the first clear post-fix candidate.

## 2026-07-11 — Add `simple` to keywords

- **Decision:** Remove redundant `rep` and generic `notes`; add `simple`.
- **Why:** `Simple workout tracker` matches Unit’s strongest user feedback and positioning.
- **Supersedes:** The same-day `planner` → `simple` edit against the older keyword list.

## 2026-07-11 — Freeze English App Store copy

- **Status:** Later progression-led listing decisions supersede parts of this freeze.
- **Decision:** Freeze `docs/app-store-copy.md` after changing `Paste any program` to `Paste your program` and removing an overclaim from What’s New.
- **Why:** App Store Connect still had stale v1 text and the localization work needed one stable source.
- **Release note:** The build-16 plan was later changed to build 35.

## 2026-07-11 — Use a colon in the App Store name

- **Decision:** Use `Unit: Gym Workout Log`, not the em-dash version.
- **Why:** The colon scans better and matches the App Store category pattern.
- **Status:** The words were later replaced by the progression-led name; the separator rule still applies.

## 2026-07-11 — Consolidate App Store copy

- **Decision:** `docs/app-store-copy.md` is the only source for App Store Connect text.
- **Why:** Three files had conflicting subtitles, promos, descriptions, and What’s New copy.
- **Rule:** Other docs point to the canonical file instead of copying its strings.

## 2026-07-11 — Launch metadata in five languages

- **Decision:** Localize metadata in German, Spanish (Mexico), Portuguese (Brazil), French, and Turkish.
- **Keep English:** Screenshots and in-app UI.
- **Pricing:** Let Apple convert the USD price ladder. Do not add custom storefront prices.
- **Deferred:** Japanese and Korean need paid native translation. Simplified Chinese waits for an ICP decision.

## 2026-07-11 — Rename the App Store listing

- **Status:** Superseded by `Unit: Progressive Overload` on 2026-08-04.
- **Decision:** Change the listing from `Unit — Gym Notebook` to `Unit — Gym Workout Log`; keep the Home Screen name `Unit`.
- **Why:** `Workout` and `log` had stronger search value.

## 2026-07-11 — Revise program preview

- **Status:** Superseded by the minimal-language pass on 2026-07-13.
- **Decision:** Use `Summary`, `Save my program`, and row-tap editing. Remove the separate pencil button.
- **Also:** Track defaulted sets/reps directly so an explicit `3×8` does not trigger a false warning.

## 2026-07-02 — Lower Weekly to $2.99

- **Decision:** Price Weekly at **$2.99**. Keep Monthly $4.99, Yearly $29.99, and optional Lifetime $44.99.
- **Why:** Weekly and Monthly at the same $4.99 price made the default look broken or manipulative.
- **Rule:** Every tier must have a clear role; no visible tier may strictly dominate another.
- **Next:** Change App Store Connect before submission. App prices remain StoreKit-derived.

## 2026-06-29 — Set the v2 price structure

- **Status:** Weekly price was changed to $2.99 on 2026-07-02. The other rules remain.
- **Decision:** Show Weekly, Monthly, and Yearly; show Lifetime only when StoreKit returns it. Select Weekly by default for customers without a trial.
- **Rule:** Never show fake fallback prices. Update `docs/pricing.md`, App Store Connect, then code.

## 2026-06-29 — Keep widget typography separate for v1

- **Decision:** Do not move widget typography into app `AppFont` tokens yet.
- **Why:** The widget target needs a proper shared token package, not a temporary bridge.
- **Next:** Revisit only when the app and widget share a real design-system package.

## 2026-06-18 — Simplify starter-program onboarding

- **Decision:** Show five clear programs: Full Body, Upper / Lower, 5/3/1, Power + Size, and Push Pull Legs.
- **Reuse:** Make onboarding use the same Level / Goal / Days filters and list components as the in-app library.
- **Remove:** Delete the 1RM input screen. Library users enter weights in program preview.
- **Why:** Insider program names and a true-1RM question were hard for most people to understand.
- **Effect:** Library onboarding drops from five steps to four. The unused 1RM calculation code stays available for later.

## 2026-06-18 — Remove the pre-onboarding price screen

- **Status:** The 2026-08-05 inline paid-access disclosure is the current solution.
- **Decision:** Delete the separate price-disclosure splash and return to one hard paywall after onboarding.
- **Why:** A price screen before setup hurt the first-run experience.
- **Accepted risk:** The App Store purchase label alone may not make a fully gated app obvious.

## 2026-06-17 — Lock onboarding, pricing tests, and paid-growth rules

- **Onboarding:** Use paste-first entry plus five starter programs. Remove the manual builder from first run.
- **Pricing test:** Measure conversion before raising Yearly. Use a clear rollback threshold.
- **Paid growth:** Do not scale ads until measured CAC is below LTV with payback under six months. A test up to $100 is allowed.
- **Target:** $11k MRR / $132k ARR is the practical milestone; the earlier $1M ARR framing is long-term.
- **Note:** The D0 price splash from this entry was removed the next day.

## 2026-06-16 — Move to a hard paywall

- **Decision:** Gate the full app after free onboarding. The paywall cannot be dismissed.
- **Users:** Existing v1 users are not grandfathered; the old `InstallProvenance` promise was removed.
- **Why:** The founder chose immediate revenue over the untested soft-paywall plan and accepted review and retention risk.
- **Supersedes:** The 2026-05-14 hybrid model and 2026-05-31 free-core model.
- **Note:** Later entries restored optional Lifetime, lowered prices, and added eligible trials.

## 2026-06-11 — Refine the Reddit plan

- **Decision:** Post feedback requests now in link-friendly communities while building karma for gated communities.
- **r/iosapps gate:** 25 community karma, verified email, ABC format, correct flair, and one promo per 30 days.
- **Rule:** Manual posting only. No comment automation.
- **Why:** Live rules showed the old blanket `link only in first comment` guidance was too broad.

## 2026-06-11 — Use identity-led training content

- **Decision:** Lead reels with training identity footage and one strong on-screen claim. Mention Unit in the caption and comment funnel.
- **Do not lead with:** Full app demos. A short app glimpse is optional.
- **Why:** The reference creator’s best posts showed no app and were easier to produce.
- **Risk:** Generic gym motivation may get views but few installs. Claims must point to tracking and simplicity.

## 2026-06-11 — Reduce marketing to one routine

- **Decision:** Cut active marketing docs from 56 files to 6 and archive the rest.
- **Daily:** One TikTok/Instagram reel, reply to comments, and write 1–3 Reddit karma comments.
- **Weekly:** Film a small clip library on Sunday.
- **Why:** One fixed routine is easier to execute than many channel plans.

## 2026-06-11 — Separate durable and tactical anti-patterns

- **Decision:** Mark legal, brand, and budget rules as durable. Treat algorithm and reach claims as testable.
- **Change:** Allow plain keyword-to-DM funnels; keep hollow engagement bait banned.
- **Why:** Live account data contradicted the compressed rule that banned both.

## 2026-06-11 — Increase posting volume

- **Status:** Later simplified to the one-daily-post routine.
- **Decision:** Target 1–4 posts per day across accounts with different identities. Never clone the same content across accounts.
- **Why:** The app was live, so more time could move from building to marketing.

## 2026-06-11 — Study proven Instagram accounts

- **Decision:** Create account studies that copy hooks, cadence, and formats, never a creator’s content, face, or captions.
- **Why:** Current winning accounts are more useful than invented content theory.
- **Open at the time:** Carousels, trial reels, editing workflow, posting volume, and account identity.

## 2026-06-11 — Add PR badges to History

- **Decision:** Show PR tags in session rows, the session summary, and set details.
- **Logic:** Calculate PRs from completed non-warm-up sets in completed sessions. Weight ranks first; reps break ties. The first log is not a PR.
- **Why:** This makes the `Every PR` screenshot claim true.
- **Rule:** Keep History and active-workout PR calculations aligned.

## 2026-06-11 — Switch the marketing site to launched state

- **Decision:** Make the live App Store URL the default and use git as the launch-state source.
- **Added:** Official App Store badge, approved screenshot crops, desktop QR code, Smart App Banner, `Download` CTA, and launch date.
- **Why:** Production should not depend on an unset Vercel environment variable.

## 2026-06-09 — Rename Ghost values to Last time

- **Decision:** Use **Last time** in the app and plain descriptions in marketing. Do not invent another feature name.
- **Why:** Users say `last time` or `previous`; nobody naturally says `ghost values`.
- **Keep internal:** `metricIsGhost` and the unrelated `AppGhostButton` names.
- **Marketing angle:** The user’s own history, not an AI recommendation.

## 2026-06-09 — Keep pasted weights for the first workout

- **Status:** Refined by the 2026-08-04 **Starting target** decision.
- **Decision:** Carry weights from a pasted program into the first workout instead of discarding them.
- **Why:** Losing data the user already entered broke trust.
- **Rule:** Percentages such as `@80%` stay blank until Unit can resolve them.

## 2026-06-03 — Remove Pro signals from v1.0

- **Decision:** Hide subscription controls and Export Pro UI; replace the Pro chip in screenshot 5.
- **Why:** Apple rejected build 12 because the app showed paid-feature signals but had no IAPs configured.
- **Next:** Upload build 13 or later with no purchase surface. Update screenshot 5 before resubmission.
- **Later:** The v2 hard-paywall decision superseded this free-launch setup.

## 2026-05-31 — Choose free core plus soft Pro

- **Status:** Superseded by the hard paywall on 2026-06-16.
- **Decision:** Keep core logging free and gate only export, Health, cloud, and Watch features. No weekly tier or onboarding paywall.
- **Also:** Grandfather pre-paywall installs through `InstallProvenance`.
- **Why:** The plan aimed to protect trust while monetizing off-path features.

## 2026-05-31 — Defer Pro to v1.1

- **Status:** Superseded by later monetization decisions.
- **Decision:** Ship v1.0 with no IAPs and hide every paywall entry point.
- **Why:** No real Pro feature was ready, so taking money risked App Review rejection.
- **Next at the time:** Re-enable Pro only after at least one paid feature existed.

## 2026-05-30 — Configure Pro for v1.0 review

- **Status:** Superseded the next day by the v1.1 deferral.
- **Decision:** Submit three IAPs with v1.0 instead of stripping Pro copy.
- **Risk:** The advertised Pro features were not built, so App Review could reject the purchase as incomplete.

## 2026-05-14 — Add a hybrid Pro upsell

- **Status:** Superseded by the hard paywall on 2026-06-16.
- **Decision:** Keep logging free and add quiet Pro entry points in Settings and History.
- **Planned Pro:** Export, Health, themes, analytics, Watch, and later cloud sync.
- **Why:** Test real conversion before gating core logging.

## 2026-05-12 — Change the bundle ID

- **Decision:** Use `app.unitlift` and `app.unitlift.UnitWidgetExtension`.
- **Why:** `com.unitlift.app` was unavailable and `app.unitlift` matches the owned `unitlift.app` domain.
- **Effect:** App Store Connect and provisioning must use the new IDs.

## 2026-05-10 — Redesign screenshot 5

- **Decision:** Replace the Settings screenshot with a simple three-row trust graphic: Storage, Account, and Export.
- **Why:** A literal Settings screen looked like settings, not a clear privacy message.
- **Later:** The 2026-06-03 App Review fix replaced the Export Pro row.

## 2026-05-10 — Add a Data section to Settings

- **Decision:** Add Storage, Account, and Export rows above Preferences.
- **Why:** Give data ownership a real product surface and a source for screenshot 5.
- **Later:** The 2026-06-03 decision hid Export Pro for the free v1.0 build.

## 2026-05-10 — Remove the History calendar

- **Decision:** History becomes one chronological list grouped by month.
- **Why:** Most days have one workout, so the calendar added taps and a large parallel UI implementation.
- **Future:** If date navigation becomes useful, add a filter instead of restoring the calendar.

## 2026-05-10 — Set iOS 18 as the deployment target

- **Decision:** Lower the app and widget deployment target from iOS 26 to iOS 18 and add availability fallbacks.
- **Why:** iOS 26 excluded too many devices for launch.
- **Bundle note:** This entry’s `com.unitlift.app` ID was replaced by `app.unitlift` on 2026-05-12.

## 2026-05-01 — Use continuous iOS corners everywhere

- **Decision:** Use iOS continuous corners for every rounded container. Use the web squircle equivalent where supported.
- **Why:** The app already mostly followed this shape; enforcement closed the remaining drift.
- **Rule:** Do not add a custom Squircle component.

## 2026-05-01 — Use first-person singular voice

- **Decision:** User-facing copy uses `I / me / my` or names Unit as the actor. Never use corporate `we / us / our`.
- **Why:** Unit is built by one person, Efe Bakir.
- **Rule:** Check this across app copy, App Store text, marketing, legal, support, and social posts.

## 2026-05-01 — Add the docs index

- **Decision:** Use `docs/INDEX.md` as the on-demand catalog and archive four stale docs.
- **Why:** Many useful docs were invisible to fresh sessions, while adding all of them to `CLAUDE.md` would add noise.
- **Rule:** Add new docs to the index, not the session-level guide.

## 2026-05-01 — Start the decision log

- **Decision:** Keep cross-session product, scope, design, and release decisions in this file.
- **Why:** Current-state docs explain what is true now; this log explains what changed and why.
- **Rule:** Keep entries short, dated, and newest-first. Mark replaced decisions as **Superseded**.


## 2026-10-19 — Add a private Profile progress tab

- **Decision:** The user requested Profile as the third native tab, alongside Today and Programs. It contains a 30-day training summary and exercise progress, with current accepted next targets labelled separately from completed performance.
- **Ownership:** Reuse existing primitives and `ExerciseProgressView` for Profile, session history and exercise-library progress. No new components, tokens, styles or visual variants.
- **Honesty:** Use valid completed working sets in finished workouts; compare sets within the same routine. Recorded load × reps has explicit units; BW volume uses total reps. No imputed workouts, composite strength score or claimed progress when load and reps both change.
- **Scope:** Personal local analytics are authorized; social profiles, accounts, new progression algorithms and active-logging decisions remain excluded. No persistence-schema or training-data changes.
- **Evidence:** `docs/research/2026-10-19-profile-progress.md`. Edits applied; builds and visual verification remain in the coordinator's queue.


### 2026-10-19 — Analytics tab and navigation cues

The user renamed the third private progress tab to **Analytics**. Existing internal root-tab identity remains unchanged; no data or navigation-stack migration is needed. The user also explicitly approved right-side chevrons on tappable navigation cards/rows and visible boundaries between grouped navigation rows. `PreviewListRow` owns optional disclosure/separator behavior; read-only previews retain their plain default. This supersedes the older blanket no-disclosure-chevron rule for these navigation consumers.


### 2026-10-19 — Celebrate the workout start

The user explicitly requested a more energetic Start Workout moment after trying build 71. Today now animates the dashboard-to-workout boundary with the existing spring and blur/scale transition, accompanied by one firm haptic after saving. This overrides quiet presentation for this deliberate action only. Session creation and logging stay immediate; resuming a session does not replay the launch. Reduce Motion and VoiceOver retain fades and haptic feedback. The active weight/reps target uses the existing 24pt productHeading font instead of 36pt numericInput. No new tokens, components, or root-routing changes.


### 2026-10-19 — Native material bars and defined edges

The user explicitly replaced the earlier soft-fade-only bar rule with native blurred material, defined vertical boundaries and subtle separators. Shared navigation/header/action-bar owners now use system `.bar` material; the canonical edge owner uses hard vertical edges on iOS26+ (including the connected iOS27 phone). Horizontal content clipping stays soft. System sheets keep their native background. No content-card material, sizing or typography changes. This supersedes transparent scroll-edge appearances, removed navigation separators, opaque custom bar fills and hand-drawn bar gradients.


### 2026-10-19 — Prepare targets without logging a set

The user clarified that entering initial weight/reps is preparation, not completion. The upcoming-set editor saves an unlogged, session-scoped target and routine starting values. Only the explicit Complete set action inserts a completed SetEntry, advances set progress, starts rest or emits set-success feedback. Existing completed-set chip editing remains an edit of recorded history. Preparation survives relaunch; notes transfer only when the set is actually completed. Explicit session preparation can override automatic prefill for that session, without changing accepted progression targets or labelling preparation as Last time.


### 2026-10-19 — Native bar visibility follows scrolling

The user corrected the always-visible material strips: the unscrolled header must blend into the page. SwiftUI `.automatic` owns navigation background visibility; UIKit standard/scroll-edge background overrides and forced `.bar`/`.visible` preferences are removed. Native hard edge styling remains for actual scrolling overlap. AppScreen’s nonoverlapping pinned sections use the page surface without always-visible separators. This supersedes the always-visible material parts of the earlier native-bars decision; no sizes, content-card surfaces or list separators change.


### 2026-10-19 — Advance automatically after the final set

The user requested automatic preparation of the next exercise after completing the current exercise’s planned sets. Reuse the existing2.5s saved confirmation before the shared blur/fade handoff. Rest continues across both automatic and manual completed-exercise advancement. Undo/manual navigation/open editors invalidate or suppress stale advancement. Only actual successfully saved sets trigger this path; preparing a target does not. The final workout still requires Finish workout.

### 2026-10-19 — Analytics R5

Approved the R5 Analytics content: one four-week status summary, Squat/Bench Press/Deadlift cards and plain Other exercise rows. A pure read-only engine compares valid completed working sets, retains real gaps, persists the status deterministically for three days and reads accepted targets without generating recommendations. No strength score, schema change or logging/progression edit.

Explicitly approved `AppStatusSummaryCard`, `AppMainLiftCard`, `AppTrendChart`, a 34pt status role, 96/120pt chart heights and missing SF Symbol tokens. Reuse native navigation, sheets and segmented controls. Keep the existing bottom navigation unchanged. Keep copy short and literal. Work stays local; delivery requires a later instruction from Efe.


## 2026-10-19 — Let SwiftUI own tab-bar backgrounds

Efe rejected the full-width background behind the floating bottom navigation and requested native SwiftUI defaults. Removed forced hard/soft scroll-edge styles from the shared compatibility modifier, the extra AppScreen content clip that cut off scrolling above the bar, and the UITabBarItem font override. This supersedes the earlier hard-edge styling decision. Native TabView, Analytics content, layout sizes, app palette and phone build remain unchanged. No replacement gradient, material, background or custom tab bar was added.


## 2026-10-20 — Use native exercise icons

The user rejected the supplied custom lifting figures and requested native SF Symbols for now. Reuse existing AppIcon roles, the exercise resolver, and shared tiles. Remove the six custom imagesets and asset-rendering branch. The active workout redesign awaits competitor benchmarks and the user’s wireframe choice; Analytics grouping and Programs navigation are separate review tasks. No version bump or phone install in this pass.


## 2026-10-20 — Blue accent only

The user chose blue actions over colors for six exercise families. Reuse `AppColor.accent`, `accentForeground`, and `accentSoft`; no new runtime color roles or components. The supplied Display P3 image’s blue converts to sRGB #1E86FC. Use deeper #0068E0 for actions and #EAF2FF for soft selections; Chalk #F6F6F6 on the action fill measures 4.79:1 contrast. Ink remains text/data. Native navigation action tint follows the same accent. This supersedes the prior Ink-only action rule; no new exercise category colors. Source checks only; visual pass and installation pending.


## 2026-10-20 — Benchmark-led movement artwork and small UI fixes

The user requested online library research, Mobbin MCP inspection, other-app art benchmarks and article review before applying changes, authorizing simple original icons if no suitable pack was found. A complete paid pack was too detailed at the existing 20/28pt sizes; the coherent free pack lacked exact coverage. Implement six original 24pt-grid, 2pt rounded-line movement vectors through the existing AppIcon/Glyph and tile owners. Native controls/fallbacks remain; names remain visible and blue stays in existing action/selection roles. This supersedes the temporary native-only exercise choice and the rejected supplied silhouettes. No new component, dependency, color role, schema or logging redesign. Also apply the previously requested Analytics explanation-card grouping and direct active-program Edit action, preserving inactive-program switching and all routine links. Benchmark and evidence: docs/research/2026-10-20-exercise-art-benchmark.md. Generic iOS compilation passed; in-app visuals/full QA/phone delivery remain pending.

## 2026-10-20 — Clarify Analytics comparison evidence

Efe requested documentation of the nine-metric AĞIRSAĞLAM video and authorized starting implementation. Keep performance primary and volume supporting. Clarify the latest-session label and show the exact current/previous four-week best sets in lift detail. This extends R5 copy/evidence presentation without changing metrics, comparison/status policy, main-lift selection, accepted targets, native navigation or logging. Body composition, readiness scores and cardiovascular tracking remain outside this pass. The scoped implementation brief and shared-owner follow-ups live in `docs/research/2026-10-20-analytics-nine-metrics.md`.

## 2026-10-20 — Final B whole-day active logging

Efe supplied and requested implementation of the Final B logging handoff, then
explicitly approved its seven shared logging owners and 30pt set-value role.
Replace the single command panel and 2.5-second confirmation dwell with one
expanded current row in the full exercise list, a 400ms duplicate-tap guard,
five-second inline Undo, inline target/edit fields and a fixed rest bar.
Preparation stays session-only; updating routine starting values requires an
explicit Finish decision. Bodyweight is chosen explicitly, never inferred from
zero. Retain existing SF fonts, approved blue action accent, native bars,
SwiftData schema and opt-in progression calculation. No phone installation is
implied by this source request; later explicit device delivery is coordinated
separately. Source brief: `docs/specs/2026-10-20-logging-final-b.md`.
## 2026-10-20 — Logged and editable main lifts

Efe's Analytics blue implementation brief supersedes the fixed three-slot presentation. Show logged Squat, Bench Press and Deadlift candidates from the twelve-week window, then fill up to three with recently trained lifts under the brief's compound-first ranking. Users may choose and order one to three historical exercises through the native Main lifts editor; Cancel discards edits and Use automatic restores the calculated selection. Persist only UUID choices in `unit.analytics.mainLiftIDs`.

The phone-data investigation confirmed that valid completed Bench Press history was excluded from Main lifts because its equipment was the model's default Other. Snapshot Other now means unspecified, while explicit dumbbell/machine/etc still exclude barbell slot matching. Pass exercise aliases and strip one approved trailing equipment/conventional qualifier; keep other variants out of the fixed slots. All shown main cards navigate and use the actual exercise name. No placeholder cards, history merging, stored equipment edits, schema changes or comparison/status calculation changes. Shared blue styling and Big 6 icon ownership remain with the main chat. Source checkpoints and runtime verification are coordinated centrally before phone installation.

## 2026-10-20 — Post-build85 gym feedback and JOI direction

Efe requests separate flat completed/upcoming exercise cards using one shared summary owner with completion at the trailing edge. This is an explicit workout-only exception to the old grouped-list rule, not authorization to restyle every list. Simplify starting-target setup and expand inline input/keyboard actions; preparation never logs a set. Rest progress becomes blue and smooth. Research the specifically named JOI calendar/task app before changing the shared visual language; preserve Unit blue plus grayscale, native navigation and data. New feedback is implemented in dedicated existing chats; no further phone install until Efe requests it. See docs/specs/2026-10-20-build85-gym-feedback.md.
