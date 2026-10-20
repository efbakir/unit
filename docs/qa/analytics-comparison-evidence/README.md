# Analytics comparison verification

The updated Analytics main cards distinguish Latest session from the four-week comparison. Lift detail shows the exact compared sets. Weight, Reps and Volume render distinct series with captions describing their calculation. These visible changes were confirmed in real Simulator captures on 20 October 2026 using isolated sample workouts.

## Review captures

| View | iOS 27 | iOS 18.6 |
| --- | --- | --- |
| Main page | [Main](ios27/r5-main.png) | [Main](ios18/r5-main.png) |
| Other exercises | [Scrolled](ios27/r5-main-scrolled.png) | [Scrolled](ios18/r5-main-scrolled.png) |
| Weighted detail | [Weight](ios27/r5-detail.png) | [Weight](ios18/r5-detail.png) |
| Reps | [Reps](ios27/r5-detail-reps.png) | [Reps](ios18/r5-detail-reps.png) |
| Volume | [Volume](ios27/r5-detail-volume.png) | [Volume](ios18/r5-detail-volume.png) |
| Bodyweight detail | [Pull-Up](ios27/r5-detail-other.png) | [Pull-Up](ios18/r5-detail-other.png) |
| Explanation sheet | [Sheet](ios27/r5-summary-info.png) | [Sheet](ios18/r5-summary-info.png) |

Additional iOS 27 captures: [empty](ios27/r5-empty.png), [baseline](ios27/r5-baseline.png), [fewer sessions](ios27/r5-fewer.png), [missing main lift](ios27/r5-never-logged-scrolled.png), [pounds](ios27/r5-pounds.png), [AX3](ios27/r5-ax3.png).

The native floating tab bar on iOS 27 and flat tab bar on iOS 18 are preserved. Scrolling content can pass behind native chrome; the captures show the current viewport, not the entire scrollable page. The long Volume caption wraps to two lines without clipping in the standard-size captures.

## Source and test runs

Frozen source: `578376d` on `codex/unit-analytics-review`, equivalent to main's `4edf2c4` after integrating the Analytics checkpoint (`25eac39`, main equivalent `4564c16`). No logging-redesign changes are included. Version/build settings were not changed.

| Run | Destination | Result | Local evidence |
| --- | --- | --- | --- |
| iOS 27.0 | Dedicated Unit Analytics R5 iOS27, iPhone 16 | 21 AnalyticsEngineTests + 3 AnalyticsR5UITests passed, zero failures | `/private/tmp/unit-analytics-evidence-ios27-final.log`, `/private/tmp/unit-analytics-evidence-ios27-final.xcresult` |
| iOS 18.6 | iPhone 16 | 21 AnalyticsEngineTests + normal Analytics UI journey passed, zero failures | `/private/tmp/unit-analytics-evidence-ios18.log`, `/private/tmp/unit-analytics-evidence-ios18.xcresult` |

Both runs built and tested the same frozen integrated source. The first iOS 27 invocation was interrupted while resolving shared-checkout metadata permission; it is not a passing run. Only the `-final` result above is acceptance evidence. Xcode's temporary logs/result bundles may be cleaned by the OS; the named captures are stored in this repository.

The tests cover exact current/previous-window evidence, separation from latest/all-time best, invalid/warm-up/future exclusions, volume-only changes, bodyweight, accepted-target selection, epsilon/ties, status persistence and the existing read-only snapshot contract. The normal UI journey asserts the new comparison labels and evidence, switches all three metrics and checks accepted Next and bodyweight detail. Existing unrelated actor-isolation warnings in EngagementPromptTrackerTests and AppIntents metadata-extraction warnings remain; the result summaries report no runtime warnings.

## Visual observations

- Main cards show a prominent latest result with a labelled Latest session date, then a separate four-week comparison line. Best and accepted Next remain in the footer.
- Weighted detail displays `77.5 kg × 5 → 80 kg × 5` with Previous → Last 4 weeks and a `+2.5 kg` comparison. The latest session is labelled above a divider.
- Reps shows a flat five-rep series for the fixture; Volume shows the exercise's best-set-session volume rising to 1,200. Neither changes the four-week strength comparison.
- Pull-Up shows BW and a rep-based comparison, with no weighted metric picker or estimated maximum. Summary-sheet cards, native Done/back actions and exercise artwork remain visible.

## Hard gates

This is a contextual verification record, not an official blind design scorecard. Each gate is scoped to the evidence below.

| Gate | Status | Evidence |
| --- | --- | --- |
| Existing source guards and UI banned list | PASS | Source guards, affected Swift checks and whitespace checks passed before checkpoints. |
| Every interactive target at least 44 pt | UNVERIFIED | Existing native controls and shared targets retained; no complete runtime hit-area measurement. |
| Text contrast AA | UNVERIFIED | Existing semantic colors retained; no new rendered contrast measurement in this pass. |
| Non-color meaning and Reduce Motion | UNVERIFIED | Labels carry comparison meaning; system Reduce Motion was not exercised. |
| Gym Test under fatigue | UNVERIFIED | Active logging source unchanged; no physical timing exercise. |
| No dead or misleading affordance | PASS for exercised Analytics flow | Main/detail navigation, sheet Done/back and metric switching succeeded. |
| Different states render differently | PASS | Weight/Reps/Volume hashes are distinct on both OS versions; main/empty/baseline/fewer hashes are distinct on iOS 27. See each folder's `sha256.json`. |
| Light-only and portrait-only | PASS for captured configurations | Both OS captures are light and portrait; orientation configuration is unchanged. |

Manual VoiceOver audio/Audio Graph navigation, held chart-scrub/cancel interaction, AX5 detail, long-name/localization screenshots and physical iPhone performance remain unverified. The Audio Graph's metric-specific axis update was source-reviewed and compiled; no claim of manual audio verification follows.

**VERIFIED:** the stated latest-session/comparison copy, compared-set evidence and distinct metric series are visible in the saved captures. This is Simulator evidence, not phone delivery or full release QA. No user workout store was reset or modified, no phone install occurred, and nothing was pushed or publicly submitted.
