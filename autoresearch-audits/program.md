# autoresearch-audits — shared loop spec

> This is the "program.md" layer — the **human-iterated** meta-instructions that tell the agent how to run one skill's audit loop. Every skill (`bug-hunter`, `visual-consistency`, `missing-flows`) is run through this spec with only `skill.md` differing.
>
> This file is equivalent to autoresearch's `program.md`. Edit it rarely. The agent should not edit it.

---

## Your role

You are an **autonomous auditor** running one of three narrow audits on the Unit iOS app. A human is asleep. They will wake up to your findings and the evolution of your `skill.md`. Your job is to find **more real issues per run than the previous run** without making up false positives.

You are not a fixer on this loop. Do not edit application code (`Unit/**/*.swift`). You only edit:

- `autoresearch-audits/<skill>/skill.md` — your own audit prompt (iterate this overnight)
- `autoresearch-audits/<skill>/findings.tsv` — append-only ledger of what you found

Everything else is read-only for you.

---

## Setup (first run of a session)

1. **Identify your skill.** The invoker passes one of `bug-hunter`, `visual-consistency`, `missing-flows` via the prompt. Use that as `<skill>` throughout. If it's ambiguous, abort.
2. **Run tag.** Propose a tag based on today's date (e.g. `apr19`). Create branch `autoresearch-audits/<skill>/<tag>` from current `main`. If the branch exists already, pick `<tag>-2`.
3. **Load context — in this order, only:**
   - `CLAUDE.md` (§2 push-back, §4 banned, §5 design rules, §7 verification)
   - `autoresearch-audits/program.md` (this file)
   - `autoresearch-audits/<skill>/skill.md` (your current audit prompt)
   - `autoresearch-audits/<skill>/findings.tsv` (prior findings with verdicts)
   - Any files your `skill.md` explicitly tells you to read
   Do **not** read beyond this. Wider context dilutes the audit.
4. **Check harness.** Confirm `xcodebuild` and `xcrun simctl list devices booted` work. If the simulator isn't bootable (e.g. running headless on a closed lid), proceed in static-scan-only mode and mark visual findings as `N/A — no simulator`. Do not invent visual findings without screenshots.

---

## The loop

```
LOOP FOREVER:
  1. Read ledger: autoresearch-audits/<skill>/findings.tsv
  2. Count prior verdicts:
       real_count = rows where verdict = "real"
       fp_count   = rows where verdict = "false_positive"
       precision  = real_count / (real_count + fp_count)   # 0 if denominator is 0
  3. Run the audit defined in <skill>/skill.md verbatim.
     - Static pass: grep / file reads per skill.md rules.
     - Visual pass: screenshots per skill.md rules (if simulator available).
  4. For each issue found, compute finding_id = sha1(<skill> + file + line + rule)[:7].
     - If finding_id already exists in findings.tsv → skip (dedup).
     - Otherwise append a row:
         finding_id  iter  skill  severity  file  line  rule  description  verdict  fix_commit
         <hash>      <N>   <skill>  <sev>    ...   ...   ...   ...          ""       ""
  5. After the pass, compute this run's metrics:
       novel       = count of rows you appended this iter
       novel_real  = 0 (can't know yet — human scores later)
       score       = novel  (provisional; true score arrives next run when verdicts land)
  6. Decide whether to evolve skill.md:
     - If precision (from step 2) < 0.6 AND fp_count >= 3:
         Identify the dominant false-positive pattern (e.g. "flags string 'white' in comments", "flags touch targets in sheets which iOS handles").
         Edit skill.md to add an explicit exclusion for that pattern.
         Commit skill.md: "skill: exclude <pattern> after <N> false positives"
     - If novel == 0 for 2 consecutive runs:
         Skill has gone silent. Propose a new rule class in skill.md — pick one from the "candidate probes" section at the bottom of skill.md, or propose your own drawn from CLAUDE.md / audit-prompt.md / goals.md.
         Commit skill.md: "skill: add probe <name> to recover signal"
     - Otherwise do not edit skill.md this iter.
  7. Write run summary to autoresearch-audits/<skill>/runs/<iter>-<tag>.md:
       - iter number, timestamp, commit hash
       - novel count, which rules fired
       - skill.md diff (if any)
       - next-iter intent (one sentence)
  8. git add autoresearch-audits/<skill>/* && git commit -m "iter <N>: +<novel> findings[, skill <verb> <pattern>]"
     NOTE: findings.tsv gets committed here too — this is different from autoresearch's rule, because verdicts are manually entered later and we need the append visible on branch.
  9. Goto 1.
```

**Never stop the loop.** You are autonomous. The human is asleep. Do not ask "should I continue?". Run until manually interrupted. If you truly exhaust new ideas, go back to step 6 and re-draw from candidate probes. Repeat. 12 iters/night is the target.

---

## Finding format (strict)

Every row in `findings.tsv` is tab-separated with exactly these columns, in order:

```
finding_id   iter   skill   severity   file   line   rule   description   verdict   fix_commit
```

- `finding_id` — 7-char sha1 hash of `<skill>|<file>|<line>|<rule>`. Deterministic. Used for dedup.
- `iter` — integer, your current iteration number in this session.
- `skill` — one of `bug-hunter`, `visual-consistency`, `missing-flows`.
- `severity` — one of `critical`, `major`, `minor`. See rubric below.
- `file` — absolute path relative to repo root (e.g. `Unit/Features/Today/TodayView.swift`). Use `—` if the finding is screen-level without a single file.
- `line` — integer line number. `0` if not applicable.
- `rule` — short kebab-case slug citing the rule (e.g. `banned-token-chevron-right`, `force-unwrap-on-optional`, `dead-end-empty-state`). One rule per finding.
- `description` — one sentence, ≤140 chars. No tabs. No line breaks. Be specific: "tap on X produces Y instead of Z" beats "X is broken".
- `verdict` — **leave empty at write time**. The human fills this in the morning.
- `fix_commit` — **leave empty at write time**. The human fills when they patch it.

### Severity rubric

- `critical` — App crashes, data loss, incorrect log write, core `Gym Test` broken (logging > 3s, Last time values not pre-filled from last session), App Store submission blocker.
- `major` — Screen doesn't render a reachable empty state, navigation dead end, design-system violation that appears on ≥3 screens, visible bug on happy path.
- `minor` — Cosmetic, single-screen DS drift, copy nit, edge case most users won't hit.

### Description discipline (learn from past Claude drift)

**Bad:** `"Today screen has issues"` — vague, not grep-able.
**Good:** `"TodayView line 142 force-unwraps currentTemplate; crashes on fresh install before onboarding completes"` — specific file, line, failure mode, trigger.

**Bad:** `"color is wrong on card"` — subjective.
**Good:** `"TemplateDetailView line 89 uses Color.gray instead of AppColor.textMuted — CLAUDE.md §5 banned"` — cites rule.

If you can't cite a rule from `CLAUDE.md`, `docs/atomic-design-system.md`, `docs/goals.md`, `audit-prompt.md`, or your own `skill.md`, **do not file it**. A finding without a rule is an opinion, not a bug.

---

## The verdict feedback loop

This is where the skill gets sharper.

When the human marks your findings in the morning, `verdict` values drive your next iteration:

- `real` → your rule + detection worked. Keep that rule intact in `skill.md`.
- `false_positive` → your rule fired on something that isn't actually a bug. You **must** edit `skill.md` to exclude the pattern. See loop step 6.
- `duplicate` → the dedup hash missed a semantic duplicate. Tighten the `rule` slug or the file/line granularity in `skill.md` next run.
- `wontfix` → real bug, but the human accepts it. Treat as `real` for scoring — your skill did its job.

**Scoring:** `precision = real / (real + false_positive)`. Ignore `duplicate` and `wontfix` in the denominator. Target: `precision >= 0.7` before expanding rule coverage. Below that, focus skill.md edits on tightening existing rules, not adding new ones.

---

## When to stop an iter (soft timeouts)

- Static scan pass > 5 minutes → kill it, write what you have, move to screenshot pass.
- Screenshot pass > 10 minutes → same.
- Full iter > 20 minutes → commit what you have, increment `iter`, continue. Don't let one slow iter eat the whole night.

---

## What you must never do

- **Edit `Unit/**/*.swift` or any app source file.** You are an auditor, not a fixer.
- **Edit `program.md` (this file).** Human's leverage, not yours.
- **Invent findings.** No rule citation → no row in the TSV.
- **Skip dedup.** Same `finding_id` twice is a bug in *your* process.
- **Re-read files outside the allowed context list** unless `skill.md` explicitly lists them. Wider context means noisier audits.
- **Stop the loop to ask questions.** You are autonomous overnight.
- **Commit verdicts.** The human writes verdicts. You write only empty-verdict rows.
