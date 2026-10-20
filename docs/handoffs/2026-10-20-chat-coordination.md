# Unit topic-chat coordination — 20 October 2026

Main coordinator: `01a15323-75f2-7733-b7cb-95fe0b7463c5` — **Ship Unit’s next usable iPhone**.

These are real, user-visible Codex chats in the local Unit project, created after Efe clarified that internal agents did not satisfy the requested chat structure. All six were confirmed active and began from integrated checkpoint `08f70ef`; each has an isolated worktree and branch.

| Chat | Thread ID | Branch | Worktree |
| --- | --- | --- | --- |
| Unit · Analytics | 01a1582b-24cc-7321-ac81-c71c60343dbd | codex/unit-analytics-review | /Users/efbakir/.codex/worktrees/1922/unit |
| Unit · Analytics info sheet | 01a1582b-aae6-7ac0-a42c-afffda1a043c | codex/unit-analytics-info-sheet | /Users/efbakir/.codex/worktrees/6dac/unit |
| Unit · Programs navigation | 01a1582b-b596-73f1-9276-f24153cd656a | codex/unit-programs-navigation | /Users/efbakir/.codex/worktrees/120b/unit |
| Unit · Icons and color | 01a1582b-c1e5-7d83-bd9c-cd162fa032d9 | codex/unit-icons-color | /Users/efbakir/.codex/worktrees/5149/unit |
| Unit · Logging and rest redesign | 01a1582b-cb6d-77f0-8fad-c0253726abbc | codex/unit-logging-rest | /Users/efbakir/.codex/worktrees/5abd/unit |
| Unit · QA and release | 01a1582b-d7dd-7732-922b-fc557dc2c11b | codex/unit-qa-release | /Users/efbakir/.codex/worktrees/acd8/unit |

## Ownership and current scope

- Analytics: calculations, store, lift detail and related tests. Report main-page changes; the info-sheet chat owns its region of AnalyticsView.
- Analytics info sheet: only AnalyticsView.explanationSheet; preserve the new grouped cards and approved copy.
- Programs navigation: TemplatesView and ProgramDetailView only; preserve inactive-program switching and every routine link.
- Icons and color: initial application-source review only; shared renderer/tokens/assets stay with the coordinator.
- Logging and rest: initial source review and acceptance checklist only. Do not choose a new layout before Efe brings the Grok benchmark/wireframes.
- QA and release: initial evidence/fixture/queue plan only; one centrally assigned build/Simulator/device queue.

Already implemented at the starting checkpoint: six original replacement movement vectors, blue action tokens, Analytics explanation card groups, and direct active-program Edit. Do not repeat these as new work. No fresh phone installation was performed for that checkpoint.

## Integration rules

Shared DesignSystem.swift, tokens, assets, project membership, build/version settings and all release operations remain centrally controlled. No parallel builds, Simulators or installations. Topic chats must report source checks and runtime limits accurately; no merge, push, store submission or app-data reset. Initial prompts prohibit messaging other chats; the main coordinator reads their reports with wait_threads and can send explicit queue assignments under Efe's authorization to coordinate.

The latest independently confirmed phone delivery was Unit 2.1 (84) from source 752870b, before checkpoint 08f70ef. Recheck device and source before any later delivery.


## Latest update — post-build85 gym feedback

The earlier ownership/status above is historical. Unit2.1(85) was subsequently installed/launched by Main with preserved existing history. New feedback is integrated in source only, with no new version/device operation. The same visible chats handled summary cards, keyboard inputs, rest/chart motion, app-wide motion audit and JOI Mobbin research in disjoint shared-file regions. Current exact result/evidence: docs/handoffs/2026-10-20-build85-gym-feedback.md. Main owns the single runtime queue. Further phone installation waits for Efe’s request.
