# Onboarding → Paywall — release QA report

- **Date:** 2026-07-01
- **Branch:** `release/onboarding-paywall-qa`
- **Scope:** onboarding splash → program setup → hard paywall (the flow gated by `ContentView`).
- **Environment:** Xcode 26.3, iOS Simulator. Mac in active use → simulator driven for screenshots only (no synthetic input), so deep interactive states are documented as a manual walk rather than machine-driven.

## A) Goal status

**Not fully complete — code/build/tests/onboarding-start verified; loaded-paywall on 3 sizes + purchase-unlock remain a documented ~10-min manual Xcode walk.**

The flow audits **clean** (no duplicate/unreachable CTAs, no misleading price/trial copy, no coaching language, StoreKit states all recoverable, design-system-conformant). Build and tests pass. Onboarding launch/render is screenshot-verified. The two criteria that need a running StoreKit purchase — **#6 paywall layout on small/normal/large** and **#8 purchase unlock** — are not machine-verified here (see §I) and are covered by the manual walk in `docs/release-qa.md` §9, which the now-wired `Unit.storekit` config makes trivial.

## B) Branch / commits

- Branch `release/onboarding-paywall-qa`, off local `main` (carries the 2 previously-unpushed `main` commits `bc39ce1`, `dcd588d`, per founder OK).
- Pushed to `origin`. See `git log` for the QA commit SHA.

## C) Files changed

Pre-existing uncommitted paywall work (included per founder decision — legitimate QA improvements):
- `Unit/Features/Subscription/PaywallView.swift` — load-failure recovery card, `hasNoLoadedProducts` state, clearer CTA/disabled copy, `visibleTiers` filters to loaded tiers.
- `Unit/Features/Subscription/StoreManager.swift` — auto-selects first available tier after load so the CTA is never stuck disabled.
- `Unit/UI/DesignSystem.swift` — tighter `AppSelectableTierCard` spacing so tiers + legal + CTA fit without clipping.

This QA pass:
- `Unit/Features/Onboarding/OnboardingProgramPreviewView.swift` — stale-comment fixes (CTA is "Choose a plan" → paywall; inline weight field renders empty, not "—").
- `Unit/Features/Onboarding/OnboardingViewModel.swift` — stale-comment fix (commit trigger).
- `Unit/Unit.storekit` — **new** dev-only StoreKit config (weekly/monthly/annual/lifetime, real prices).
- `Unit.xcodeproj/.../Unit.xcscheme` — wire the config into the **Run** action only (Release/Archive ignore it).
- `docs/release-qa.md` — new §9 manual paywall/StoreKit walk.
- `docs/qa/*.png` — onboarding-start screenshots (committed, not left in /tmp).

## D) Screens inspected

- **iPhone 17 Pro (regular), runtime screenshot:** onboarding splash carousel — `docs/qa/onboarding-01-splash.png` ("Last time is already there"), `docs/qa/onboarding-02-carousel.png` ("Your numbers, from day one"). App launches clean, carousel auto-advances, "Set up your program" CTA pinned + reachable, no clipping.
- **All flow screens, static/architecture review:** splash, unit picker, import method, paste (+ empty/parse-failure states), library picker, schedule, program preview, paywall (loading / unavailable / loaded / error), legal footer.
- **Device-matrix gap:** no iPhone SE simulator installed (smallest is 390pt; SE is 375pt). `release-qa.md` §9 has the one-line `simctl create` to add it.

## E) Bugs found

No user-facing bugs. Only stale comments contradicting the current hard-paywall flow (design-system QA checklist item):
1. `OnboardingProgramPreviewView.swift` header — described a "Start your first workout" CTA; the CTA is "Choose a plan" and leads to the paywall.
2. `OnboardingViewModel.swift` header — referenced a non-existent "Create My Program" button.
3. `OnboardingProgramPreviewView.swift` — claimed the inline weight field shows a "—" prompt; `AppInlineWeightField` actually uses an empty placeholder (verified — so the banned-list dash-placeholder concern was a false alarm).

## F) Fixes applied

- The three stale comments above, corrected to match the shipped flow.
- (Paywall/StoreManager/DesignSystem improvements were already in the working tree; validated and kept.)
- No behavioral/redesign changes — the flow was already release-quality.

## G) StoreKit / paywall verification

- **Config:** `Unit/Unit.storekit` created with the four real product IDs and prices; wired to the scheme **Run** action only. JSON validated, scheme XML validated.
- **Products loaded?** Not machine-verified (simulator `simctl launch` does not inject the scheme's StoreKit config). Verified by code review: `StoreManager.loadProducts` fetches all four IDs, auto-selects first available; `PaywallView` derives every price from `Product.displayPrice` (no fake fallbacks).
- **Purchase / restore / unlock?** Not machine-verified (see §I). Code-verified: `purchase()` re-derives entitlement from `currentEntitlements` (never assumes success), `restore()` calls `AppStore.sync()` then re-checks + surfaces "No purchases to restore", the transaction listener finishes verified transactions and re-checks (handles refunds), and `ContentView` reactively swaps to the tabs on `store.isPurchased`. Non-dismissible (root swap, no close/secondary button).
- **Legal:** footer always renders Restore · Terms of Service · Privacy Policy; reachable by scroll even while the CTA is disabled.

## H) Build / test result

- `xcodebuild ... build` → **BUILD SUCCEEDED** (Debug, iOS Simulator; includes the uncommitted paywall changes).
- `xcodebuild ... test` (iPhone 17) → **TEST SUCCEEDED** (ProgramImporterTests, ProgramImportParserTests).
- `git diff --check` → **clean**.

## I) Remaining release blockers

Nothing code-level. Two runtime verifications remain, both covered by `release-qa.md` §9:
1. **Paywall layout on iPhone SE / regular / Pro Max (#6)** — architecture makes clipping unlikely (`AppScreen` scrolls the body, CTA is a pinned bar, tier prices use `minimumScaleFactor(0.6)`), but it is not screenshot-verified on three sizes. Walk §9.
2. **Purchase → unlock, and Restore (#8, #9)** — code-verified, not run. Walk §9 (⌘R with the wired config).

**Why not machine-driven:** the Simulator can be booted + screenshotted safely, but driving the multi-step SwiftUI flow to the paywall needs either synthetic global input (unsafe while the Mac is in active use) or a UI-test target (none exists; adding one is beyond a "fix clear bugs" pass). A UI-test + `SKTestSession` harness that automates the paywall + purchase across device sizes can be built as a follow-up if wanted.
