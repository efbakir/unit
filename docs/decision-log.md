# Unit — Decision Log

> Append-only chronological record of decisions, scope overrides, and direction shifts.
> One entry per decision. Newest at the top. Never edit or delete past entries — strike them through and write a new entry that supersedes.

**What goes here:**
- Scope decisions (added / cut / deferred)
- Design system overrides (the user explicitly green-lit a deviation from `CLAUDE.md` §3 / §4)
- Direction shifts (pivot, persona update, KPI change)
- Bets that did or did not pay off (so we don't redo the same experiment)
- Notable in-session course corrections that aren't captured elsewhere

**What does NOT go here:**
- Per-task work logs — that's git history
- Bug fixes — that's git history
- Code review notes — that's PRs
- Anything captured in `~/.claude/projects/.../memory/` (use the index there)

**Format:** `## YYYY-MM-DD — <one-line title>`, then 2–4 lines: *Decision*, *Why*, *Implication*. If superseded later, add `**SUPERSEDED by YYYY-MM-DD**` on the original.

---

## 2026-05-10 — Settings gets a "Data" section to carry App Store screenshot #5

**Decision:** Added a `Data` section as the first card in `Unit/Features/Settings/SettingsView.swift`, above Preferences. Three rows: `Storage → "On this iPhone"`, `Account → "None"`, `Export data → [PRO]` (accent-fill `AppTag(.compactCapsule)`). Reuses existing primitives only — no `DesignSystem.swift` edits. Export tap is intentionally a no-op stub at W3; a `// TODO at W5+` marks where the paywall + CSV export wire in once Pro flips on.
**Why:** App Store screenshot strategy slot #5 needs a "No account. Works offline." trust shot following the TypingMind pattern — *show* the trust mechanic, don't *claim* it. Exploration confirmed no existing onboarding screen carries the mechanic explicitly (every step is implicit-only — proof by absence of a sign-in field), and Settings had zero data-ownership language. Original brief preferred option (a) onboarding, but chose option (b) Settings because it's the most authentic mechanic *and* fixes a real product gap (today no in-app surface tells the user where their data lives or hints at export).
**Implication:** Slot #5 source asset is now Settings (Data section visible at the top), not an onboarding screen — `docs/marketing/research/screenshot-strategy-final.md` slot #5 updated accordingly. The PRO chip is the gentle upgrade hint; brief is explicit that no active paywall should appear in the screenshot, so the row is visually present but inert until W5+. When Pro flips on, replace the empty `Button { }` action with `if !store.isPurchased { /* present PaywallView */ } else { /* present CSV export sheet */ }`.

---

## 2026-05-10 — History is list-only; killed the Calendar tab

**Decision:** Removed the `Calendar` tab from `Unit/Features/History/HistoryView.swift`. History is now a single chronological list, grouped under quiet `Month YYYY` eyebrows above each `AppCardList` block. Dropped `SessionHistoryMode`, `CalendarDayStatus`, `CalendarDayCellModel`, `CalendarMonthHeader`, `CalendarGrid`, `CalendarDayCell`, plus the now-orphaned `MissedDay*` and `EmptyDay*` payload + sheet types and their helpers (`makeMissedDayPayload`, `isMissedDay`, `assignedWorkoutName`, `syncCalendarSelectionIfNeeded`). File shrank from 1,263 → 543 lines. Single external touchpoint updated: `TodayView.swift` no longer passes `initialMode:` to `RecentSessionsView`.
**Why:** Schema technically allows N workouts/day but in practice 95%+ of days have ≤1 — so the calendar was operating as a glorified date-picker over a one-event-per-day surface. Browsing N sessions cost N cell taps vs. one scroll on the list. Pattern audit: Apple Health Workouts, Streaks, Done all use list-only when the canonical event is "1 per day" without scheduled-vs-actual reconciliation. Heatmap/streak header alternative ruled out by `PRODUCT.md` line 54 ("no streaks, no engagement gamification"). The calendar code was also a 270-line parallel-implementation foothold outside `DesignSystem.swift` — direct CLAUDE.md §4 violation. The author's own header comment ("list-first … quiet calendar browser") already telegraphed the calendar was secondary.
**Implication:** No model changes — `WorkoutSession.date` still allows multiple sessions per day, the surface just doesn't call attention to that edge case. If date-jump becomes a real workflow later, add a search/date-range filter above the existing list rather than reviving a calendar tab. Month-section eyebrows reuse `AppFont.smallLabel` via `.appCapsLabel(.smallLabel)` — no new DS primitives.

---

## 2026-05-10 — Bundle ID `com.unitlift.app`, iOS 18 deployment target

**Decision:** App Store readiness audit before first submission. Renamed `PRODUCT_BUNDLE_IDENTIFIER` from `com.atlaslog.app` (and widget `com.atlaslog.app.UnitWidgetExtension`) to `com.unitlift.app` (and `com.unitlift.app.UnitWidgetExtension`) across all four pbxproj configs. Dropped `IPHONEOS_DEPLOYMENT_TARGET` from `26.0` to `18.0` across all four configs (main + widget × Debug + Release). Added iOS 26 availability gates inside `appScrollEdgeSoft(top:bottom:)` and `appExerciseSearchable(text:)` in `Unit/UI/DesignSystem.swift` so iOS 18 callers degrade gracefully (no soft scroll-edge fade; toolbar search field still visible but does not minimize on scroll). Cosmetic: aligned three `Logger(subsystem:)` fallback strings (`StoreManager.swift`, `UnitApp.swift`, `MarketingSeed.swift`) from `com.atlaslog.app` to `com.unitlift.app`.
**Why:** Bundle ID is locked to the App Store Connect listing at first submission — `com.atlaslog.app` was a leftover from an earlier name and would have permanently mismatched the marketing domain `unitlift.app`. iOS 26 deployment target excluded every device on iOS 25 and below, shrinking TAM unnecessarily for a launch indie app. Audit triggered by the question "is the build good to submit?" — see plan at `~/.claude/plans/whats-the-final-decision-immutable-willow.md`.
**Implication:** App Store Connect record must be created under `com.unitlift.app` (not `com.atlaslog.app`). Provisioning profiles need regeneration under the new ID. Phase 0 paywall hygiene confirmed clean (PaywallView is dead code, no Pro gates enforced). Remaining pre-submission gating items are operational, not code: support email MX live + tested, App Store screenshots captured, archive uploaded.

---

## 2026-05-01 — iOS-native squircle smoothing is the only corner shape

**Decision:** Every radius container — iOS app and marketing site — renders with iOS's native squircle corner smoothing (≈60% Figma corner smoothing). On iOS this is `RoundedRectangle(style: .continuous)` / `Capsule(style: .continuous)`, now hook-enforced via `.claude/hooks/ui-banned-list.sh` (bare `RoundedRectangle(cornerRadius:)` and `.cornerRadius(...)` modifier are blocked in feature code). On the web this is a global `corner-shape: squircle` (with a `superellipse(2.5)` fallback) under `@supports`, applied in `app/globals.css` `@layer base`. All 14 `Capsule()` instances in `Unit/UI/DesignSystem.swift` plus one stray in `TrainingWeekProgress.swift` migrated to `Capsule(style: .continuous)`.
**Why:** Efe asked for "60% smooth radius because iOS does that" and emphasized system-level + consistent + reuse-existing. Audit revealed iOS already used `.continuous` on all 23 `RoundedRectangle` callsites — so the gap was enforcement (no hook rule existed) and Capsule consistency (most omitted `style:`), not migration. The web side had no squircle implementation at all; the CSS Round Display Module's `corner-shape: squircle` is iOS-native equivalent and shipping into Chromium/Electron, so a single global @supports rule lights up squircles where supported and cleanly falls back to circular elsewhere. No per-component migration, no JS dependency, no bespoke `Squircle` shape (would conflict with CLAUDE.md §4 "iOS-native over custom").
**Implication:** Hook now enforces `style: .continuous` on every `RoundedRectangle` in feature code — regression closes silently. `AppRadius` docstring upgraded from recommendation to enforced contract. Marketing site verified live in preview (Electron 41 / Chromium): all 18 rounded elements compute `corner-shape: squircle`, border-radius values unchanged. For non-supporting browsers (older Safari / Firefox) the @supports block is a no-op — they get today's circular corners, no breakage.

---

## 2026-05-01 — First-person singular is the only voice

**Decision:** Every user-facing surface uses `I / me / my` (or **Unit** as the actor) — never `we / us / our / our team`. Applies to marketing site, legal pages (privacy/terms entity defined as `{DEVELOPER_NAME} ("I," "me," or "my")`), in-app copy, App Store description, support/contact, social posts.
**Why:** Unit is solo (Efe Bakir, `DEVELOPER_NAME` in `lib/contact.ts`). Corporate "we" is dishonest for a one-person product and conflicts with the calm-expert-honest brand voice. Caught on the changelog page on 2026-05-01 — Efe: *"I just realized here you use we language. Do not forget that I am the only one here working it Efe."* Solo-founder identity is a positioning asset, not something to hide.
**Implication:** Pre-ship grep on any user-facing surface: `\bwe\b|\bwe'|\bour\b|\b us \b`. Rule lives in `PRODUCT.md` §Brand Personality. Implemented across compare/programs/support/legal pages in commits `b6c1e8d` and `96e341f`.

---

## 2026-05-01 — Added `docs/INDEX.md` and archived 4 stale docs

**Decision:** Built `docs/INDEX.md` as on-demand catalog of all docs (loaded from CLAUDE.md §1 only when the agent doesn't know which doc applies). Moved `geminiresearch-1/2/mvp-pivot.md` and `cleanup-spec.md` to `docs/archive/`.
**Why:** ~15 of ~30 docs in `docs/` were invisible to fresh sessions because CLAUDE.md only routed to ~10 of them. Karpathy LLM-wiki pattern: thin always-loaded router → fuller on-demand index. Adds 1 line to CLAUDE.md, surfaces 30 docs, no per-session token cost for the catalog itself.
**Implication:** When extending the docs set, add a row to `INDEX.md`. Don't grow CLAUDE.md. Archived files stay readable for history but are deprioritized.

---

## 2026-05-01 — Started this decision log

**Decision:** Add `docs/decision-log.md` as the append-only record for cross-session decisions.
**Why:** Existing memory + `CLAUDE.md` capture *current state*; they don't capture *what changed and why*. Karpathy's LLM-wiki pattern points at the gap — decisions evaporate at session end unless they make it into a memory file. A flat log is cheaper than a full wiki overhaul.
**Implication:** Future sessions read this on any "why did we…" question. Pair with monthly `consolidate-memory` runs to keep `~/.claude/.../memory/` honest.

---

<!-- new entries above this line -->
