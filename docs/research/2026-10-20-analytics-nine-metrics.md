# Nine fitness metrics and Unit Analytics

Use Analytics to explain recorded lifting progress: what changed, what evidence supports it, and which next target the user accepted. Keep training volume as supporting context. Preserve the approved R5 page structure while improving the clarity of its comparisons.

Efe requested this research and authorized implementation on 20 October 2026. This brief extends the [R5 handoff](../handoffs/2026-10-19-analytics-r5.md); it does not replace the calculation policy or authorize new health tracking.

## Video source

[AĞIRSAĞLAM, Kas Gelişiminde Ölçmen Gereken 9 Veri](https://www.youtube.com/watch?v=UwTFYiQmpLI). The full Turkish automatic captions were read through the [transcript reader](https://youtubetotranscript.com/transcript?v=UwTFYiQmpLI). Captions contain recognition errors. The table summarizes the creator's discussion; it is not independent validation of the video's medical claims or numerical thresholds.

## The nine metrics

| Starts | Metric | Video takeaway | Implication for Unit |
| --- | --- | --- | --- |
| [0:45](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=45s) | Body mass index or BMI | Broad weight relative to height. | Exclude from this pass; it cannot be derived from lifting logs. |
| [1:54](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=114s) | Body fat percentage | Consistent measurement trends matter; estimates can be noisy. | Do not infer body composition from logged strength. |
| [4:52](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=292s) | Fat free mass index or FFMI | A longer-term body-composition measure. | Requires additional measurements and a separate product decision. |
| [6:30](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=390s) | Ağırsağlam score | Their bodyweight-adjusted strength score depends on selected benchmark exercises. | Keep actual performances visible; missing benchmark lifts must not imply poor progress. |
| [8:29](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=509s) | Progressive overload | Track increased load or more reps with the same load. | Make recorded load and rep changes the primary evidence. |
| [10:38](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=638s) | Training volume | Adding sets raises workload without necessarily improving performance. | Keep volume secondary and label the calculation precisely. |
| [11:30](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=690s) | CNS fatigue or readiness | Discusses jump, grip, reaction and tapping tests. | Do not generate a readiness or recovery claim from lifting logs. |
| [15:10](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=910s) | VO₂ max | Cardiovascular fitness, including estimated values. | Requires a separate data source and scope decision. |
| [16:26](https://www.youtube.com/watch?v=UwTFYiQmpLI&t=986s) | Resting heart rate | Discusses personal fitness and stress trends. | Do not estimate heart rate or stress from completed sets. |

The product lesson is to match each claim to the measurement that supports it. Unit records performance and workload; those records do not establish measured muscle growth, body fat, or recovery.

## Analytics hierarchy

1. **Am I progressing?** Keep the four-week status and load/rep comparisons. More sets alone must not count as an improved best set.
2. **What changed?** Keep latest session, current four-week best, previous four-week best, and all-time best distinct. Show the actual compared sets, including a lower latest session after an earlier record.
3. **What is next?** Keep the accepted target and its routine visible. Analytics must not generate or accept a new target.

For example, a previous-window best of 80 kg × 6 and a current-window best of 80 kg × 8 supports a two-rep improvement even if the latest session was 75 kg × 6. The latest-session hero must not appear to be the basis of that two-rep claim.

## Implementation brief

Improve the existing lift detail using the pure AnalyticsEngine and existing SwiftUI compositions. Expose the exact current and previous window winners selected by the comparison calculation. Label the hero as the latest session, label the four-week comparison separately, and display its underlying performances. Missing evidence gets explicit text, never a zero or a fabricated comparison.

Keep the twelve-week series and metric calculations unchanged. Weight shows the weekly best set's load. Reps shows the reps in that same best set, not an independent maximum-reps search for weighted lifts. Volume shows this exercise's completed working-set volume in the session containing the weekly best set, not total weekly volume. Bodyweight charts show the weekly maximum reps and no metric picker.

Reuse AppCard, AppDivider, AppFont, AppSpacing and AppTrendChart. Add no new view type, token, style, asset or dependency. Preserve native navigation, the blue action roles, neutral charts, main-lift order, Other exercises, valid-set rules, epsilon/tie policy, status persistence and accepted-target selection. Do not change logging, progression, SwiftData schema, training data or release settings.

## Decisions for later work

- Consider prominent lifts drawn from the user's actual routine. Retain Squat, Bench Press and Deadlift for this pass; changing the approved main slots needs its own selection and migration rules.
- The shared AppMainLiftCard still pairs a latest-session value with a window comparison. Main-chat integration should clarify that shared composition using the same window evidence; do not fork it in AnalyticsView.
- AppTrendChart's shared scrub readout and Audio Graph title currently describe a best set for every weighted metric. Its owner should make those descriptions match Reps and Volume as well as Weight. Do not claim a caption change fixes those shared behaviors.
- Keep the nine-metric table as research, not a nine-card dashboard specification. Body measurements, readiness tests and cardiovascular integrations are separate work.

## Implementation status

The first source pass exposes `currentWindowBest` and `previousWindowBest` on the read-only lift result. ExerciseProgressView labels Latest session, shows the four-week comparison evidence with explicit previous/current ordering, handles missing comparison windows in words, and describes the selected Reps/Volume series. The earlier weighted-lift default fix is retained. AnalyticsEngineTests adds window-evidence, volume-only and bodyweight/missing-window cases, plus an assertion that epsilon selection matches the displayed evidence. Tests have not run in this topic chat.

Only AnalyticsEngine.swift and ExerciseProgressView.swift changed in app source. Shared components, AnalyticsView and its explanation sheet retain their assigned owners. The shared-owner changes above remain follow-ups for main-chat integration.

## Acceptance checks

- Previous best, current best, latest session and all-time best can differ without contradictory labels.
- The displayed comparison evidence uses the same valid sets, local-day windows, bodyweight mode and epsilon/tie selection as the status calculation.
- More sets at unchanged load/reps leave the performance comparison unchanged.
- Empty windows, mixed changes, bodyweight, added-load bodyweight and kg/lb have explicit, consistent output.
- Volume and Reps captions describe their actual series; accepted Next remains unchanged.
- Central verification runs AnalyticsEngineTests and AnalyticsR5UITests, then checks History and Analytics entry points, long values, AX5, VoiceOver, Reduce Motion and chart scrubbing on the integrated build.

Builds, tests, Simulator use and phone installation remain centrally queued. Source guards do not establish rendered layout or runtime behavior.
