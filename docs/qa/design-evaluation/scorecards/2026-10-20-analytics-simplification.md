# Analytics simplification scorecard

**Mode:** contextual. **Status:** provisional.
**Evidence:** user-supplied card/detail screenshots saved under
`docs/references/hevy-analytics-2026-10-20/`; source inspection of main during
build 87 delivery. Screenshots precede the typography trial.
**Anchor:** Hevy exercise detail `80f164aa-c011-4469-ba7a-158116427cab` on Mobbin:
one value/date and compact chart; no borrowing of unrelated social or anatomy UI.

## Baseline

| Dimension | Weight | Score | Evidence / defect / fix layer | Blind spot |
| --- | --- | --- | --- | --- |
| System fidelity | 25% | 7 | Shared cards/chart/type are used. Simplify at AppMainLiftCard and detail composition. | Current typography trial is not in supplied screenshots. |
| Coherence and restraint | 20% | 5 | Same result repeats as latest, comparison-window value, Best and Next. Overview should carry latest result and meaningful trend. | Repeated values may differ with richer history. |
| Craft | 20% | 5 | Large empty plot surrounds one point; long comparison metadata dominates. Hide uninformative overview graph and shorten context. | Full-screen crop and all data states unavailable. |
| UX judgment | 25% | 6 | Main result is legible, but user explicitly finds interpretation complicated. Keep supporting evidence in detail. | Interaction and logging not exercised in this pass. |
| Accessibility / verification | 10% | 5 | Source uses combined card label and chart descriptors. Simplified visible content needs equivalent accessible hierarchy. | VoiceOver, large type and contrast measurement unverified. |

**Weighted baseline:** 5.8/10. Preserve this baseline after changes.

## Hard gates

| Gate | Status | Evidence |
| --- | --- | --- |
| UI banned-list | PASS | Final changed source checks and static guards pass. |
| 44pt targets | UNVERIFIED | Screenshots alone insufficient. |
| Contrast | UNVERIFIED | New typography/color build still separate. |
| Meaning beyond color / reduced motion | UNVERIFIED | Existing text labels; runtime review pending. |
| Gym Test | UNVERIFIED | Session reordering must preserve active logging. |
| No misleading affordance | PASS | Card/detail navigation, reorder and Finish exercised by UI tests. |
| Distinct state rendering | PASS | Single-week, multi-week, missing lift, pounds and large text fixtures checked. |
| Light / portrait | PASS | Supplied evidence and source contract. |

## Priority fixes

1. Overview: keep exercise, latest set/date, meaningful comparison and multi-point
   trend. Remove Best/Next footer; these remain in detail.
2. Detail: suppress missing-baseline comparison block and duplicate current value;
   retain real previous/current evidence, best set, accepted target and history.
3. Shared owners: neutral toolbar actions, ±20-second rest controls and exercise
   drag-reorder, preserving data and current workout identity.

## Verification cases

No history; one weekly point; multiple weeks but no previous comparison window;
two comparison windows; old history only; kg/lb; bodyweight; differing latest and
best; accepted target; long exercise names and accessible Dynamic Type. Central
queue must check changed visible and spoken copy, navigation and chart selection.

## Work completed

Recovered historical brief; inspected and saved six high-resolution references;
documented which old presentation constraints today's feedback supersedes.
Applied Analytics delta `b369289` and workout delta `4ea76c3` to main after
coordination. Single-week charts and overview Best/Next repetition are removed;
comparison evidence remains for comparable windows. Added session-scoped order
persistence, long-press card drops and a native reorder sheet, plus ±20 controls.
Existing main neutral toolbar changes are preserved. Static guards and UI pattern
checks pass. Build and 25 distinct unit / 8 distinct UI checks passed on iOS18.
Reviewed final neutral back/toolbar, overview/detail, reordered logging and CTA
spacing captures are saved in [verification evidence](../../analytics-simplification-2026-10-21/README.md).
A native toolbar grouping issue hiding Finish was fixed and regression-tested.
iOS27 runtime attempts failed at the Simulator service; physical-device and
manual accessibility gates remain pending. No final numeric score is assigned
until those gates are reviewed.
