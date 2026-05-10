---
name: ui-visual-verify
description: Skeptic-first visual verification of a UI change in Unit. USER-INVOKED ONLY — never auto-trigger after a UI edit. Run only when the user explicitly asks ("/ui-visual-verify", "screenshot it", "verify", "did it work?", "looks right?", "is the change live?", "build and check"). Per AGENTS.md §6, the user runs multiple Codex agents in parallel and auto-triggering the simulator causes boot/install/screenshot conflicts. When invoked, the default assumption is that the modification has NOT been achieved until proven by a screenshot. If verification is waived (background run, lid closed, no simulator), this skill says so explicitly and skips, instead of faking success.
---

# /ui-visual-verify

**This skill is user-invoked only.** Do not run it automatically after a UI edit. Per `AGENTS.md` §6, simulator/screenshot commands conflict when multiple agents run in parallel — the user controls when to verify. If you reach for this skill on your own, you are violating the rule.

When the user does invoke it: default to disbelief. Until a screenshot proves the change, the change has not happened. Code that looks right is not evidence; the simulator output is.

## Trigger (user-initiated only)

- The user explicitly invokes `/ui-visual-verify`
- The user asks "did it work?", "looks right?", "is the change live?", "screenshot it", "verify", "build and check"
- A screenshot is part of the deliverable the user named

## Verification waiver

If the user has waived verification for this run (background/scheduled work, lid closed, no simulator access — see `feedback_unit_background_verification_waiver.md`), state that explicitly:

> "Verification waived per background-run rule. Edits applied, not yet visually verified. User should screenshot before declaring shipped."

Then exit. Do not fake screenshots. Do not infer correctness from the code.

## Process

### 1. State the claim
What specifically should the user see after this change? One sentence per claim. Examples:
- "TodayView's section headers should now use `AppFont.sectionTitle` weight, not `.semibold`."
- "ActiveWorkoutView's rest timer pill should sit 16pt above the bottom safe area, not 32pt."
- "OnboardingShell's continue button should now match the toolbar weight on the prior screen."

If you cannot state the claim in plain English, the change is too vague to verify.

### 2. Build + install + launch
```bash
xcodebuild -project Unit.xcodeproj -scheme Unit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build/ \
  build 2>&1 | tail -30
```

Then install and launch:
```bash
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Unit.app
xcrun simctl launch booted com.unit.gym  # adjust bundle id if different
```

If build fails: stop. Surface the build error. The change is not verified.

(If `feedback_unit_skip_build_checks.md` is current — the user catches compile errors themselves later — skip the build step here, but ONLY rely on screenshots from a build the user has already produced. Do not claim "build passed" without running it.)

### 3. Navigate to the affected screen
Use `xcrun simctl` deep-link if available, or describe the manual nav path the user should follow.

### 4. Screenshot
```bash
xcrun simctl io booted screenshot ~/Desktop/unit-verify-$(date +%Y%m%d-%H%M%S).png
```

### 5. Read the screenshot
Open the screenshot. Describe what you observe in plain English, claim by claim:

> "From the visual evidence, I observe: section headers in TodayView now read in regular weight, matching `AppFont.sectionTitle`. Spacing above the rest timer pill measures roughly 16pt. The orange #FF4400 accent is gone."

If a claim is NOT visible in the screenshot, state that clearly:

> "I cannot confirm the toolbar button weight change from this screenshot — the toolbar is occluded by the sheet. Need a second screenshot with the sheet dismissed."

### 6. Sibling-screen regression check (for atom/molecule fixes)
If the change was at the atom or molecule layer (per `/page-audit` fix-level), screenshot at least 2 sibling screens that use the same atom/molecule. Confirm no regression.

Example: a change to `AppCard` shadow → screenshot TodayView, HistoryView, and TemplatesView (all use AppCard). If any look wrong, the fix is not done — it created a regression.

### 7. Compare against the named reference (if applicable)
If `/page-audit` named a reference from `docs/references/`, open both side by side. Note where the implementation matches the reference and where it diverges. Divergence is fine if intentional — say so.

## Output format

```markdown
## Visual verification — [screen / change]

**Claim**: [one-sentence description of what should be visible]
**Build**: [pass / fail / skipped — if skipped, why]
**Reference**: [docs/references/<file>.png if applicable, or "no reference"]

### Primary screen
**Screenshot**: ~/Desktop/unit-verify-[timestamp].png

**Observed**:
- [bullet of what is visually present]
- [bullet]

**Verdict on claim**: [verified / not verified / partially verified]
[If partial: name what's missing and what additional screenshot would close the gap.]

### Sibling regression check
| Screen | Screenshot | Atom/molecule under test | Looks correct? |
|---|---|---|---|

### Reference comparison (if applicable)
- Match: [what aligns]
- Divergence: [what differs and whether intentional]

### Conclusion
[ONE of these three:]
- VERIFIED — change is visible in the simulator and matches the claim. Sibling screens unaffected.
- NOT VERIFIED — [specific reason, with what would need to happen to verify].
- WAIVED — [reason for waiver per `feedback_unit_background_verification_waiver.md`]; "edits applied, not yet visually verified."
```

## Strict rules

- **Never claim verified without a screenshot path in the report.** "Looks right based on the code" is not verification.
- **Never describe what you "expect to see"** — only what is *actually* in the screenshot.
- **If the simulator is not booted or the build failed**, the answer is NOT VERIFIED. Do not work around it.
- **One screenshot per claim minimum.** Don't aggregate multiple claims into one screenshot unless they're all visible at once.
- **The conclusion must be one of the three labels above.** No fourth option, no "probably verified", no "looks good".

## Why this works

AGENTS.md §7: *"Do not declare a task done based on the code looking right. Until you have verified, say: 'edits applied, not yet verified.' [...] If you cannot verify (tooling/build broken), say so plainly. Never fake it."*

The user has called out fake verification repeatedly: *"still buggy", "still containing the shadow", "i cant launch the app"* — every one was a turn that claimed success without screenshot evidence. This skill makes that failure mode mechanically impossible: no screenshot path, no verified conclusion.

Pattern adapted from the `ui-visual-validator` agent in wshobson/agents — skeptic-by-default, visual-evidence-first.
