# Unit Profile and native controls delivery

## Starting point and ownership

Follow-on to installed Unit 2.1 (68), source tag `unit-dev-2.1-68-20261019`. Main integration remains in `/Users/efbakir/.codex/worktrees/unit-release-20261019/unit`, branch `codex/unit-release-20261019`. The original `/Users/efbakir/unit` dirty checkout and the Plate reference remain untouched.

The user authorized completing the two existing chats, integration, iOS 27 and iOS 18 testing, and an in-place iPhone upgrade. iOS 27 is the primary visual target; iOS 18 is the compatibility baseline. SF Pro, restrained tracking, standard-size layout, local data, and immediate logging are retained.

## Integrated behavior

- Profile is the third native tab. It shows the last 30 calendar days of completed workouts, valid working sets and reps, followed by actual exercise performance, same-routine comparisons and separately labelled accepted targets. It links to existing History and Settings.
- Exercise charts and calculations have one existing owner, `ExerciseProgressView`, reused by Profile, workout history and the exercise library. Warmups, unfinished sessions and malformed sets are excluded. Bodyweight uses reps rather than invented body-mass tonnage. Estimated 1RM is explicitly labelled and uses eligible 1–12-rep sets.
- `AppSegmentedControl` owns native segmented Pickers for existing exclusive selections on iOS 26 and later. The shared button implementation remains for unanswered choices, individually disabled choices and iOS 18 touch sizing. Existing screen defaults and bindings remain caller-owned.
- No new production components, tokens, visual variants, dependencies or schema were added. The existing DEBUG catalog contains the comparison fixtures. Dead segmented-control variants and duplicate exercise analytics were removed.

Research and detailed source maps: [Profile research](../research/2026-10-19-profile-progress.md), [Profile handoff](2026-10-19-unit-profile-progress.md), [native controls review](../qa/native-controls-source-review.md). Competitor and review evidence is bounded and dated; no installed competitor-app audit is claimed.

## Verification and delivery

Pending combined runtime results, final source checkpoint, build number, phone installation and row-preservation comparison. Branch-only evidence is distinguished from integrated-app evidence below.

## Release boundaries

Build 69 is development-only and unreserved until App Store Connect confirms the uploaded build list. No public upload or submission is authorized here. Local StoreKit tests are not Apple sandbox confirmation. Full physical haptic feel and a complete manual VoiceOver walkthrough remain separate review items.
