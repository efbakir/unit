# Ship Unit + Start App Store Submission — Week of May 11–17

## Context

Today is **Sunday May 10, 2026**. Per [launch-plan.md](docs/launch-plan.md), App Store submission was scheduled for Week 1 (Apr 19–26), and we should already be live by Week 3 (today). We are **~3 weeks behind plan** — but the gap is operational, not code.

**Current state (verified via codebase + repo audit):**
- Code is ~95% ship-ready: bundle ID locked to `app.unitlift` (canonical reverse-DNS of `unitlift.app` — see 2026-05-12 decision-log entry), iOS 18 deployment target, onboarding fully wired (no scaffolding), core logging path complete (timer, PR detection, haptics), paywall intentionally inert, no banned `ProcessInfo.environment["UNIT_*"]` shipped.
- 44 modified files uncommitted (WIP snapshot — must clean up before submission).
- Provisioning profiles for `app.unitlift` not yet generated (App Store Connect record doesn't exist).
- Privacy/terms URLs hardcoded ([SettingsView.swift:47–48](Unit/Features/Settings/SettingsView.swift)) but `unitlift.app/privacy` + `/terms` not verified live.
- `support@unitlift.app` not verified to round-trip.
- App Store screenshots: strategy locked ([screenshot-strategy-final.md](docs/marketing/research/screenshot-strategy-final.md)), zero built. Estimated 4.5 hrs Figma work.
- Landing page code ready to ship; `isLaunched` flag in `lib/launchState.ts` flips at go-live.
- One scope decision pending: WIP diff deletes `setSuggestion()` + `priorSessionSetCount()` from [ActiveWorkoutView.swift](Unit/Features/Today/ActiveWorkoutView.swift) — this is the progressive-overload "ghost suggestion" feature. Needs explicit keep / restore / scope-down decision Monday morning before commit.

**Week's success criteria:**
1. Submit to App Store by **EOD Thursday May 14** so Apple's 24–72hr review wraps by weekend.
2. App showing **"Ready for Sale"** OR **"In Review"** by EOD Sun May 17.
3. Landing page (unitlift.app) flips to `isLaunched: true` the moment the app goes live.
4. First content (founder vlog + demo footage) recorded by Saturday so Week 5 (May 18+) starts with a stocked Buffer.

**Docs consulted (per CLAUDE.md §1):** launch-plan, goals, product-compass, scope, decision-log, INDEX, PRODUCT, marketing/{README,cadence,content-engine,automation-map,anti-patterns,tools,ugc-brief,templates/01-tradesman-demo,templates/02-founder-vlog,research/screenshot-strategy-final}, plus codebase audit of project.pbxproj, ActiveWorkoutView, SettingsView, OnboardingShell, StoreManager, app/(marketing)/page.tsx.

---

## Pre-flight checklist (TONIGHT — Sun May 10 evening, ~45 min)

These need to be true before Monday morning, or Day 1 stalls.

- [ ] **Apple Developer account** is active, paid, team `R2BR5SX98Y` confirmed in Xcode signing settings.
- [ ] **Domain `unitlift.app`** DNS pointing to Vercel; SSL active. `curl -I https://unitlift.app` returns 200.
- [ ] **Email `support@unitlift.app`** MX configured (Google Workspace or alias). Send a test from your personal account → confirm receipt.
- [ ] **iCloud / Apple ID** capacity: per memory, you're at the 3-address cap. Confirm the Apple ID linked to App Store Connect is the right one and has no blockers.
- [ ] **Git stash** of current 44-file WIP if you want a safety net before tomorrow's commit work: `git stash push -u -m "pre-launch-week-snapshot-2026-05-10"`.

If any of these fail, the failing item moves to Mon morning and pushes Tue work right by the same amount.

---

## Day 1 — Mon May 11: Decision day + clean the WIP

The 44-file WIP delta is the biggest single risk. It must be committed in clean, reviewable commits before any signing/submission work happens.

**Morning (~3.5 hrs)**
- 09:00–09:30 — Re-verify pre-flight items in case anything regressed overnight.
- 09:30–10:30 — **Decision: progressive-overload suggestion feature.** Read the unstaged diff in [ActiveWorkoutView.swift](Unit/Features/Today/ActiveWorkoutView.swift). The 756-line change deletes `setSuggestion()` and `priorSessionSetCount()`. Three options:
  - **(a) Restore** — accidental deletion. `git checkout HEAD -- Unit/Features/Today/ActiveWorkoutView.swift` and re-apply only the polish changes you wanted.
  - **(b) Keep deletion** — intentional scope cut. Append entry to [decision-log.md](docs/decision-log.md) explaining why ghost suggestions are out for v1.
  - **(c) Scope down** — keep ghost-value prefill, drop the +5lb suggestion overlay only. Partial revert.
  - Default if unsure: **(a)** — ghost values are the primary logging mechanism per CLAUDE.md North Star. Do not silently regress this.
- 10:30–12:00 — Spot-check [DesignSystem.swift](Unit/UI/DesignSystem.swift) (the 1265-line WIP expansion). No new edits — read for banned-list violations per CLAUDE.md §4. Run `/page-audit` on TodayView, ActiveWorkoutView, OnboardingShell.

**Afternoon (~4 hrs)**
- 13:00–16:00 — Commit the 44-file WIP in **5–6 logical commits**, in this order (each commit must build on its own):
  1. `Settings: Data section for trust-signal screenshot #5` (per 2026-05-10 decision-log)
  2. `Onboarding: polish revisions across Splash/Splits/Exercises/Schedule/ImportMethod/SplitBuilder`
  3. `DesignSystem: [whatever the actual delta is — describe at atom level]`
  4. `Marketing: landing-page hero + DeviceFrame radii tuning` (web only, won't affect iOS submission)
  5. `Active workout: [decision per Monday morning]`
  6. `Docs: marketing playbooks + decision log + launch-plan updates`
- 16:00–16:30 — `xcodebuild -project Unit.xcodeproj -scheme Unit -configuration Release -destination 'generic/platform=iOS' build` — confirm Release builds clean. No simulator boot.
- 16:30–18:00 — Buffer / final `/page-audit` pass on every screen modified this WIP. Fix at atom layer in DesignSystem.swift if anything caught.

**EOD gate:** `git status` clean, Release build green, decision logged for ActiveWorkoutView.

---

## Day 2 — Tue May 12: Operational setup (signing + domain + legal)

Today is mostly off-codebase work. The goal: by EOD, an archive validates against a real ASC listing.

**Morning (~4 hrs)**
- 09:00–10:00 — **App Store Connect**: create new app under `app.unitlift`. Fill:
  - Name: `Unit`
  - Subtitle (30 chars): e.g. `Log a set in 3 seconds`
  - Primary category: Health & Fitness
  - Bundle ID: `app.unitlift`
  - SKU: `unit-ios-v1`
- 10:00–11:30 — **Apple Developer Portal**: regenerate distribution provisioning profiles for `app.unitlift` and `app.unitlift.UnitWidgetExtension`. Confirm capabilities (App Groups for widget, anything else needed by [Unit.entitlements](Unit/Unit.entitlements)).
- 11:30–12:00 — Xcode: select archive scheme, build for "Generic iOS Device" with Release config — confirm signing succeeds.

**Afternoon (~4 hrs)**
- 13:00–14:30 — **Domain & legal pages** at `unitlift.app/privacy` and `unitlift.app/terms`. Create [app/privacy/page.tsx](app/privacy/page.tsx) and [app/terms/page.tsx](app/terms/page.tsx) with template legal copy adapted for: local-first storage, no account, no third-party analytics (Plausible if you use it — disclose), Apple StoreKit for subscriptions, no PII collected. Deploy via Vercel. `curl -I https://unitlift.app/privacy` → 200.
- 14:30–15:00 — **Email `support@unitlift.app`**: send test from external account → reply round-trips → archived.
- 15:00–17:00 — **ASC privacy nutrition labels + age rating + compliance**: answer all questions. Most likely "Data Not Collected" (verify by reading Info.plist, then SettingsView's diagnostic email body — nothing PII leaves the device unless user manually emails support).
- 17:00–18:00 — **First archive validation attempt**: Xcode → Product → Archive → Validate App. Don't upload. Resolve any validation errors before tomorrow.

**EOD gate:** ASC listing exists, archive validates, `https://unitlift.app/privacy` + `/terms` return 200, support email round-trips.

---

## Day 3 — Wed May 13: Screenshots + Gym Test

Two parallel tracks: 4.5 hrs Figma in the morning, real gym in the afternoon.

**Morning (~4.5 hrs Figma)**
Per [screenshot-strategy-final.md](docs/marketing/research/screenshot-strategy-final.md):
- Tools: Figma + AppLaunchpad plugin + SmoothShadow (free)
- Typography: Geist Bold 110pt; colors `#F5F5F5` bg, `#0A0A0A` text; dimensions 1290×2796 (6.9")
- 09:00–11:00 — Screenshot 1 (Hero, no device frame): "Your gym notebook, upgraded" — <3s set logged moment.
- 11:00–13:30 —
  - Screenshot 2 (Core Loop): ghost-value prefill in active workout
  - Screenshot 3 (Ghost Values): prior-session prefill highlighted
  - Screenshot 4 (History): list view (no calendar — killed 2026-05-10 per decision-log)
  - Screenshot 5 (Trust): Settings Data section — "On this iPhone" + "No account" + "Export data [PRO]"
- Export 5 PNGs at 1290×2796.

**Afternoon — Gym Test (real-life, ~1.5 hrs at gym)**
Per launch-plan.md PRO-3:
- 14:30–16:00 — Real session: 10 sets across compound + isolation. Time each log end-to-end. Target ≤3s per set, one-handed, sweaty, screen at max brightness.
- Document any failure mode exactly: "ghost prefill didn't appear because exercise was new" etc. Do NOT refactor. Fix only what broke.

**Late afternoon (~1.5 hrs)**
- 16:30–17:30 — Resolve any Gym Test bugs at atom layer (CLAUDE.md §5).
- 17:30–18:00 — Drop 5 screenshots into ASC at 6.9". Reject anything that looks pixelated or off-brand.

**EOD gate:** 5 screenshots uploaded to ASC, Gym Test passed (10 sets ≤3s each, one-handed).

---

## Day 4 — Thu May 14: Submit

**Morning (~3 hrs)**
- 09:00–10:00 — Smoke test: clean simulator instance, fresh install, run onboarding end-to-end. Confirm Splash → Splits → Exercises → Schedule → Unit Picker → Import → first workout works. Then quit and reopen → confirm state persists.
- 10:00–10:30 — Final `/page-audit` on every screen one last time. No edits unless something violates.
- 10:30–11:30 — **Archive + upload**: Xcode → Product → Archive → Distribute → App Store Connect → upload. Wait 15–30 min for processing.
- 11:30–12:00 — **Final ASC copy polish** (all first-person singular per PRODUCT.md and decision-log 2026-05-01 — grep `\bwe\b` once more):
  - Promotional text (170 chars)
  - Description (4000 chars) — adapt from [app/(marketing)/page.tsx](app/(marketing)/page.tsx) hero/sub copy
  - Keywords (100 chars, comma-separated): start with "gym log workout tracker lifting strength sets reps"
  - Support URL: `https://unitlift.app`
  - Marketing URL: `https://unitlift.app`
  - Copyright: `2026 Efe Bakir` (or LLC if you have one)

**Afternoon (~2 hrs)**
- 13:00–14:00 — In ASC: select uploaded build, attach to listing, run final compliance check (encryption: No — confirmed in Info.plist `ITSAppUsesNonExemptEncryption = false`).
- 14:00–14:30 — Final review of every ASC field. Once satisfied: **Submit for Review**.
- 14:30–18:00 — Buffer for any last-minute ASC complaints (rare). Then start drafting Friday's marketing pieces in parallel.

**EOD gate:** ASC status = "Waiting for Review" or "In Review."

---

## Day 5 — Fri May 15: Buffer / first content

Branches based on what Apple does.

**Path A: No review feedback yet (most likely).** Use the day for marketing prep so weekend is light.
- 09:00–12:00 — **Founder vlog recording** per [02-founder-vlog.md](docs/marketing/templates/tiktok-ig/02-founder-vlog.md): 6 complaint variants (rotate hooks A–D from template).
- 13:00–16:00 — **Gym demo footage** per [01-tradesman-demo.md](docs/marketing/templates/tiktok-ig/01-tradesman-demo.md): hook variants, voiceover script, CTA.
- 16:00–18:00 — Submagic ingest (auto-captions + clip selection).

**Path B: Apple rejects.** Most first-time rejections are metadata polish (description, keyword, screenshot copy, age rating).
- Read rejection reason carefully.
- Metadata fix → resubmit (no new build needed).
- Binary fix → atomic-layer fix → archive → upload → resubmit.
- Do NOT panic and do NOT refactor. Fix only what blocked.

**EOD gate:** Either resubmitted with fix, OR ~3 hrs of raw content recorded for Buffer.

---

## Day 6 — Sat May 16: Landing page polish + content assembly

- 09:00–11:00 — Test [app/(marketing)/page.tsx](app/(marketing)/page.tsx) on real iPhone Safari + Chrome desktop. Verify FAQ schema, SoftwareApplication schema, OG image. Polish anything broken.
- 11:00–12:00 — Test the `isLaunched` toggle in [lib/launchState.ts](lib/launchState.ts): confirm `false` renders waitlist mode, `true` renders App Store badge mode. Stage `APP_STORE_URL` constant with placeholder for Sun flip.
- 13:00–17:00 — **CapCut assembly**: 3 first-week TikToks/IG drafts. Submagic captions baked. Hooks per template files.
- 17:00–18:00 — Buffer schedule prep: drafts queued for Mon/Wed/Fri of W5 (May 18/20/22).

**EOD gate:** 3 social drafts queued in Buffer, landing page final-checked.

---

## Day 7 — Sun May 17: Sunday checklist + ship reset

Per [docs/marketing/cadence.md](docs/marketing/cadence.md):
- 10:00–10:30 — Sunday checklist (cadence.md spec).
- 10:30–11:30 — **App Store status check.**
  - **If LIVE:**
    - Flip `isLaunched: true` in [lib/launchState.ts](lib/launchState.ts).
    - Set `APP_STORE_URL` to the live link.
    - Push to Vercel.
    - Live-site sanity check: real iPhone, App Store badge → tap → opens App Store → "Get" works.
  - **If still in review:** leave landing on waitlist mode. Patience.
- 11:30–12:00 — Tell the 5 closest people (mom + 4 lifters): the app is live (or close).
- 12:00–13:00 — **Week 5 reset**: paywall flip gate is "≥30 users at 3+ sessions/wk for 2 wks" — won't be there yet, that's expected. Per launch-plan, paywall stays dormant until Week 5 *and only if* gate hits, otherwise defers to Week 6.

**EOD gate:** App live (badge active) OR resubmission status; close people notified; W5 content stocked.

---

## End-of-week verification (EOD Sun May 17)

- [ ] ASC shows **Ready for Sale** (live) OR **In Review** (close call).
- [ ] All 44 WIP files committed in clean logical commits; `git status` clean.
- [ ] `https://unitlift.app/privacy`, `/terms`, `/` all return 200.
- [ ] `support@unitlift.app` round-trips.
- [ ] 5 App Store screenshots uploaded at 6.9".
- [ ] Gym Test passed (10 sets ≤3s, documented).
- [ ] No banned patterns in shipped code (`/page-audit` clean on every modified screen).
- [ ] First batch of founder + demo content recorded (Path A) or rejection resolved (Path B).
- [ ] Landing page ready (or already flipped) to `isLaunched: true`.

---

## Risk register

1. **Apple rejects on first review** — 60% likely. Buffer Friday for this. Most rejections are metadata copy.
2. **Provisioning / signing snag Tuesday** — could lose half a day. Keep Apple Developer support contact handy.
3. **DNS propagation slow** — handled by tonight's pre-flight; if not done tonight, slips Tuesday.
4. **Gym Test reveals a deeper bug** — only fix what broke. Defer everything else to v1.1.
5. **Decision drift on overload feature** — decide Mon morning and don't reopen.
6. **Marketing landing bugs surface late** — Sat is for that, in real conditions.

---

## Critical files (reference, not all edited)

| Path | What | When |
|---|---|---|
| [Unit/Features/Today/ActiveWorkoutView.swift](Unit/Features/Today/ActiveWorkoutView.swift) | Overload-suggestion decision | Mon AM |
| [Unit/UI/DesignSystem.swift](Unit/UI/DesignSystem.swift) | 1265-line WIP delta — review for atom-layer regressions | Mon AM |
| [Unit/Features/Settings/SettingsView.swift:47–48](Unit/Features/Settings/SettingsView.swift) | Privacy/terms URLs hardcoded | Tue (verify domain serves) |
| [Unit/Info.plist](Unit/Info.plist) | `ITSAppUsesNonExemptEncryption=false` | Thu (ASC compliance check) |
| [Unit/PrivacyInfo.xcprivacy](Unit/PrivacyInfo.xcprivacy) | Privacy manifest | Tue (ASC nutrition labels) |
| [app/privacy/page.tsx](app/privacy/page.tsx) | Create Tue | Tue PM |
| [app/terms/page.tsx](app/terms/page.tsx) | Create Tue | Tue PM |
| [lib/launchState.ts](lib/launchState.ts) | `isLaunched` flag flip | Sun (only if app is live) |
| [app/(marketing)/page.tsx](app/(marketing)/page.tsx) | Landing — read for ASC description copy | Thu AM |
| [docs/decision-log.md](docs/decision-log.md) | Append entries for any scope decision | Mon AM, ongoing |

---

## What we're NOT doing this week (per [scope.md](docs/claude/scope.md) banned list)

- ProgressionEngine, auto-increment, deload rules
- 8-week cycles, "Week N of M" UI
- Plate calculator
- Social, feeds, sharing, community
- **Paywall flip** (defers to Week 5 only if retention gate hits)
- CloudKit sync
- Pricing component on landing
- New components / parallel implementations in DesignSystem.swift
- Refactoring during Gym Test bug fixes
- Friday or Black Friday ship attempts (per launch-plan.md line 219 — Thursday is fine)
