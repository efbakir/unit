# Unit Profile and native controls delivery

## Starting point and ownership

Follow-on to installed Unit 2.1 (68), source tag `unit-dev-2.1-68-20261019`. Main integration remains in `/Users/efbakir/.codex/worktrees/unit-release-20261019/unit`, branch `codex/unit-release-20261019`. The original `/Users/efbakir/unit` dirty checkout and the Plate reference remain untouched.

The user authorized completing the two existing chats, integration, iOS 27 and iOS 18 testing, and an in-place iPhone upgrade. iOS 27 is the primary visual target; iOS 18 is the compatibility baseline. SF Pro, restrained tracking, standard-size layout, local data, and immediate logging are retained.

## Integrated behavior

- **Analytics** is the third native tab (renamed from Profile at the user’s request). It shows the last 30 calendar days of completed workouts, valid working sets and reps, followed by actual exercise performance, same-routine comparisons and separately labelled accepted targets. It links to existing History and Settings.
- Exercise charts and calculations have one existing owner, `ExerciseProgressView`, reused by Profile, workout history and the exercise library. Warmups, unfinished sessions and malformed sets are excluded. Bodyweight uses reps rather than invented body-mass tonnage. Estimated 1RM is explicitly labelled and uses eligible 1–12-rep sets.
- `AppSegmentedControl` owns native segmented Pickers for existing exclusive selections on iOS 26 and later. The shared button implementation remains for unanswered choices, individually disabled choices and iOS 18 touch sizing. Existing screen defaults and bindings remain caller-owned.
- No new production components, tokens, dependencies or schema were added. The existing DEBUG catalog contains the comparison fixtures. Dead segmented-control variants and duplicate exercise analytics were removed. The user subsequently approved navigation chevrons and grouped-row boundaries: the existing `PreviewListRow` gained `showsDisclosure` and `showsSeparator` opt-ins, reused by all seven applicable navigation consumers. Read-only rows retain their plain default; the active-program header reuses `AppIcon.forward`.

Research and detailed source maps: [Profile research](../research/2026-10-19-profile-progress.md), [Profile handoff](2026-10-19-unit-profile-progress.md), [native controls review](../qa/native-controls-source-review.md). Competitor and review evidence is bounded and dated; no installed competitor-app audit is claimed.

## Verification and delivery

**Delivered: Unit 2.1 (69), installed in place and launched normally on the connected iPhone.** Final application source is `612d3b7`; this includes Analytics naming plus approved navigation cues. Signed Debug compile reports **BUILD SUCCEEDED**. No test launch flags, uninstall or preference reset were used.

| Evidence | Result / precise limit |
|---|---|
| Integrated iOS 27 unit tests | **204 passed, 0 failed**, including analytics filtering, same-routine comparisons, persistence, migration, entitlement and motion/haptic policies. Application source at that runtime pass was `6e86955`. |
| Integrated iOS 27 UI cases | **5 passed**: ready-made onboarding, native History/chart selection, empty Analytics, full progression/Analytics/kg-lb/next-workout journey, exact set Undo/interrupted relaunch. |
| Two UI test-navigation failures | Clear action was offscreen; exercise search was collapsed on iOS 27. Test navigation was corrected in `6bd2afe`. Those two corrected checks were **not rerun**. The aggregate run is not reported as passing. |
| Test interruption | The user explicitly instructed stopping tests and prioritizing phone installation through the Moments chat. Remaining work stopped. Xcode result finalization was interrupted; the retained log is the individual-test evidence, and the `.xcresult` is unfinalized. |
| iOS 18 | Build 68 had recorded runtime checks. **Final combined build 69 was not run on iOS 18** after the user stopped testing. No build-69 compatibility pass is claimed. |
| Final naming/navigation refresh | `9896245` adds approved shared navigation cues; `612d3b7` names the tab/page Analytics. This final source **compiled, installed and launched**. No new UI test or screenshot pass was run after those changes. |
| Phone store | Final pre-refresh/post-launch comparison is **row-for-row equal across all five tables**: 9 templates, **12 workouts, 208 sets**, 951 exercises, 1 split. SQLite integrity OK; kg and `persistenceRecoveryNotice=false` retained. |
| Shared guards | 26 mutation fixtures passed before the source checkpoints and final documentation commit. |
| Original checkout | Final status matched the original pre-work snapshot. All implementation remains isolated on the release branch. |

Evidence root: `/Users/efbakir/.codex/worktrees/unit-release-20261019/evidence/follow-on/`. It contains final install/launch JSON, `phone-final-preservation.json`, `build-provenance.json`, and individual-test summary. Full test/build logs remain in `/private/tmp/unit-combined-69-*`; signed-build logs are not copied into repository documentation because private configuration was used. The signed application is retained as `Unit-2.1-69-development.zip`.

### Subchat closeout

Chats 1, 2, 4, 5 and 6 supplied the audit/foundation/moments/design/guard work already integrated in build 68 and retained in build 69. Their branches and commits are recorded in the previous motion handoff. The [20-finding reconciliation](../qa/motion-audit-20-reconciliation.md) assigns every audit row a disposition; **it does not claim 20/20 manual runtime verification**. One nonblocking newest-check-only bounce refinement and the stated manual accessibility/tactile proof limits remain. Native controls and Profile source are integrated; their branch-only and combined evidence remain distinct.

### Safe visual and tactile review on the iPhone

1. Switch Today / Programs / Analytics rapidly; check for blank or stuck content and immediate taps.
2. Open a routine or history detail and return; scroll away/back without repeated entrances or vibrations. Review navigation chevrons and the boundaries between tappable rows.
3. During the next real workout, complete a set: one crisp success cue, saved values and rest timer immediately. A PR should not add a second buzz.
4. Finish that real workout: completion feedback once; reopening history must not replay it. Accept a next target only if actually wanted; dismissing leaves it unchanged.
5. Use the DEBUG component catalog’s isolated Success / Error / Undo samples; check readable messages, one-use Undo and persistent errors. Do not remove real sets or reset onboarding for this review.
6. Separately enable Reduce Motion and VoiceOver for safe navigation/catalog samples: fades without travel/blur/bounce/confetti, haptics retained. Actual spoken labels, focus order, announcements and reachable Undo/Close need a manual VoiceOver walkthrough; source and automated policies are not narration proof.

## Release boundaries

Build 69 is development-only and unreserved until App Store Connect confirms the uploaded build list. No public upload or submission is authorized here. Local StoreKit tests are not Apple sandbox confirmation. Full physical haptic feel and a complete manual VoiceOver walkthrough remain separate review items.


## Subsequent screenshot correction — build 70

The user’s Today/Programs feedback is now applied and installed as **2.1 (70)**: symmetric shared preview padding, full-width preview/divided-list separators, taller 64pt grouped day targets and lighter existing-token chevrons. Source `62fef5c`; signed build/install/normal launch passed, training tables remained row-identical. No further tests or Simulator pass was started. See [the row-spacing handoff](2026-10-19-unit-row-spacing.md).
