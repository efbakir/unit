# Build 85 gym feedback — coordinated implementation

## User request
The user is reviewing installed 2.1 (85) while lifting. Accept further feedback incrementally. Do not install or bump the phone build until requested again.

- Completed exercise checks move to the far trailing edge. All exercise names share the leading alignment.
- Completed and upcoming exercises share ExerciseSummaryRow; upcoming exercises become separate flat AppCards rather than one divided card. This explicitly supersedes the older list-in-one-card rule only for workout exercise summaries.
- Simplify first-time starting-target preparation. Preparing must never log a set.
- Current action stays reachable while the keyboard is open. Keyboard actions fill the available width with comfortable targets. Weight/reps fields expand to use available width without a wide multiplication gap.
- Rest progress line is Unit blue and smoothly follows the actual deadline. Preserve timer state, notifications and persistence.
- Audit abrupt state transitions across the app; apply animation at canonical owners with stable identity. Keep immediate feedback, no blocked logging or artificial delays. Reduced motion and VoiceOver retain fades and static cues.
- JOI (J-O-I), a calendar/task app, is the requested visual reference. Confirm identity and inspect actual main/highlight screens before visual-language changes. User clarified the requested tool is Mobbin MCP (not mobile-device MCP). Use Mobbin as primary evidence and official JOI sources for identity/supporting context. Unit blue stays; other styling is grayscale.

## Dedicated visible chats
| Work | Chat | Owned scope |
| --- | --- | --- |
| Input / keyboard | Unit · Logging and rest redesign | ActiveWorkoutView editor/focus/keyboard, CurrentSetRow and existing field layout |
| Summary cards | Unit · Programs navigation | ActiveWorkoutView exercise composition, ExerciseSummaryRow only |
| Timer / logging motion | Unit · QA and release | RestBar, existing motion owners, proposed separate ActiveWorkoutView patch |
| JOI reference | Unit · Icons and color | Research first; shared-system changes assigned after evidence |
| Other app motion | Unit Analytics implementation | Read-only exact owner audit first |

Every chat starts from integrated main 8e3cf4d, uses its existing worktree and preserves work. Shared-file changes are restricted to assigned regions and integrated centrally. No independent builds, Simulator use, installs or version changes. No new component/token without approval; extend approved owners.

## Verification
Main schedules one focused integrated build and relevant interaction checks after final changes. Previous build85 evidence is a baseline, not proof of this feedback pass. Native tabs, SwiftData schemas, accepted targets and training data remain unchanged. Record source/build/Simulator/phone evidence separately.
