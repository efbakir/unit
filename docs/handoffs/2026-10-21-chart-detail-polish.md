# Chart detail polish

Reviewed with swiftui-pro and better-ui. No new components or tokens.

| Severity | Owner | Before | After | Why |
|---|---|---|---|---|
| Medium | AppSegmentedControl | All native segments forced large | Existing compact variant uses native regular sizing; weekday stays large | Removes heavy visual sizing at shared owner |
| Medium | AppMainLiftCard / ExerciseProgressView cards | 14pt overrides beside22pt list | Default AppCard radius22 throughout | Consistent sibling surfaces |
| Medium | ExerciseProgressView Recent | Date and long sets competing in horizontal row | Date first, monospaced sets below, both leading aligned | Predictable wrapping |
| Low | ExerciseProgressView chartCaption | Weekly best unclear | Metric-specific weekly explanation plus12-week period | Names what the graph actually plots |

Research: Hevy's official tutorial separates best set, one-rep max and session volume (https://www.hevyapp.com/hevy-tutorial). Strong distinguishes actual records from predicted lifts (https://help.strongapp.io/article/216-exercise-records-screen). Applied principle: name the measure explicitly without changing calculations. Weighted reps remain reps of the weekly top-weight set, not an invented maximum-reps series. Volume remains the selected best-set session volume.

Device build passed; diff whitespace passed. Updated existing caption expectations. Not verified: runtime picker density on iOS27, VoiceOver, large text, continuous motion or physical-device visuals. No installation/version bump. Approve source scope only; visual review remains pending.
