# Motion audit: 20-finding reconciliation

Reviewed build 69 source checkpoint `6e86955` on 2026-10-19. Original audit baseline: `27fdb7b70020ebb2437ea23f8eeda493bd202800`.

This is source/evidence reconciliation, not a new runtime pass. Main owns final combined iOS 27/iOS 18 verification and in-place phone delivery. Earlier build 68 results below are inherited regression evidence, not proof that the exact build 69 binary passed those routes. Main currently reports 204 unit tests and onboarding passed on integrated iOS 27; remaining combined UI/device results must be appended by main.

Statuses: **R** = fixed with recorded runtime regression evidence; **P** = fixed in source with an explicit proof limit; **D** = nonblocking refinement deferred. Paths below are repository-relative to the reviewed commit.

| # | Original finding | Status | Resolution and evidence / remaining limit |
|---|---|---|---|
| 1 | Toast replacement cancellation | R | `Unit/UI/DesignSystem.swift`, AppToast: cancellation returns, event UUID scopes dismissal, action consumes before callback. Build 68 feedback catalog explicitly exercised replacement; final standard-size catalog passed. Exact build 69 rerun belongs to main. |
| 2 | Toast accessibility | P | AppToast announces once, does not auto-dismiss under VoiceOver; errors persist and dismiss control exists. Source/policy evidence; full live VoiceOver reading/focus walkthrough pending. |
| 3 | Press feedback accessibility | P | ScaleButtonStyle reads both settings and allows scale only through AppMotion.allowsSpatialMotion. Existing actual Reduce Motion journeys passed on build 68; exhaustive control-by-control VoiceOver inspection pending. |
| 4 | Logged-set bounce | D | SetProgressIndicator now gates bounce for Reduce Motion and VoiceOver and removes symbol effects. Existing completed checks still share setLoggedSignal, so the optional refinement to animate only the newest result is deferred. Accessibility policy is fixed in source; targeted live setting-toggle inspection remains pending. This is a polish refinement, not a logging/data blocker. |
| 5 | Segmented selection motion | P | AppSegmentedControl uses native Picker where appropriate; retained fallback routes selection through shared accessibility-aware appAnimation. Focused iOS 27 native selection cases passed individually; aggregate isolated run was interrupted. Main must complete combined/iOS 18 fallback pass. |
| 6 | Toast entrance motion | P | AppToast selects opacity under either setting. Build 68 Reduce Motion journeys passed; dedicated VoiceOver transition observation pending. |
| 7 | Floating accessory travel | P | AppScreen uses shared motion policy for accessory transition. Source fix present; targeted scroll-hide/show verification with each setting remains a proof limit. |
| 8 | VoiceOver screen entrances | P | AppScreenEnter reads both settings, session memory prevents repeated reveals, spatial offset/blur are gated. Full manual VoiceOver walkthrough pending. |
| 9 | Onboarding step travel | P | Existing flow now uses shared step transition owner with accessibility gating. Build 68 onboarding journeys passed with actual Reduce Motion enabled; live VoiceOver flow pending. |
| 10 | Carousel auto-advance | P | OnboardingSplashView observes Reduce Motion, VoiceOver and scene phase in task identity; automatic advance respects shared motion eligibility. Source confirmed; manual VoiceOver pause/resume check pending. |
| 11 | Timer numeric motion | P | RestTimerControl switches to opacity when either accessibility setting is active; shared reveal timing retained. Source confirmed; dedicated per-second motion capture pending. |
| 12 | Stepper numeric motion | P | AppStepper uses appNumericValue, whose shared owner selects numericText or opacity using both settings. Source/policy confirmed; physical interaction feel pending. |
| 13 | Stacked PR haptics | P | WorkoutCommandCard has one success trigger for set logging; separate heavy PR trigger removed. Source confirmed; actual tactile arbitration requires phone review. |
| 14 | Haptic owner drift | P | AppHaptic now has seven approved intents; AppFeedbackState owns scene activity, strength ranking and 80ms admission for both delivery paths. Feedback policy unit tests passed; physical haptic feel remains unverified. |
| 15 | Raw option selection haptic | P | AppOptionTileCard.handleTap uses AppHaptic.select.fire(), admitted by shared scene owner. Guard checks passed; physical selection feel pending. |
| 16 | Toast action hit area | P | AppToastPill action has explicit minimum 44x44 frame and content shape; dismiss is separately accessible. Source fixed; standard-size Undo catalog passed, comprehensive enlarged-text hit-bound inspection pending. |
| 17 | Long toast truncation | P | AppToastPill replaces single-line clipping with ViewThatFits horizontal/vertical composition and wrapping text. Source fixed; no claim of complete enlarged-font layout verification. |
| 18 | Parallel splash timing | P | ParallaxEntry uses AppMotion.revealTravel and appReveal; per-index local travel/delay removed. Specialized splash composition retained. Normal onboarding runtime evidence exists; exhaustive splash motion observation pending. |
| 19 | Entrance contract conflict | P | AppScreenEnter documentation now names intro/staged/tab roles; legacy whole-screen calls are immediate and controls/errors do not hide. Source/doc conflict resolved; all-route replay audit is not claimed. |
| 20 | Missing review fixture | R | DEBUG AppComponentCatalog exists in DesignSystem.swift with feedback/Undo/error and shared control fixtures. Build 68 final catalog journeys passed; build 69 adds native selection cases, with combined final results owned by main. |

## Release meaning

All 20 findings have a disposition; this is **not 20/20 runtime-verified**. No currently demonstrated release-blocking defect follows from this audit. Row 4 retains one nonblocking polish refinement. Accessibility/manual proof limits remain explicit rather than being counted as passed tests.

Development delivery completion requires main's exact combined build 69 checks, successful signed in-place install and launch, and data-preservation comparison. Public store submission separately requires App Store Connect build/product verification and real Apple sandbox purchase/restore. Those store prerequisites must not block an otherwise successful development install.

Evidence: `docs/handoffs/2026-10-19-unit-motion-release.md` closing evidence (build 68), `docs/qa/native-controls-source-review.md` (focused native cases and interrupted aggregate status), and main release chat's current integrated build 69 report. This audit chat performed no build, Simulator operation, phone operation, or app-source edit.
