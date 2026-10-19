# Unit — Decision Log

- Newest decisions come first.
- Each entry answers three questions: What changed? Why? What follows?
- **Superseded** means the entry is history, not current direction.
- Current product rules also live in `docs/product-compass.md` and `docs/pricing.md`.

<!-- Add new entries below this line. -->

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
