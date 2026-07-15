# Release QA — the gauntlet

> Walk this before every TestFlight build and every App Store submission.
> Roughly 30 minutes end-to-end on a fresh install. If anything fails, file a
> fix and re-walk the affected section.

The bug class this catches: **the things Claude can't see from reading code**.
Most regressions in Unit so far have been:
- View-local `@State` for user-entered data that resets on nav back/forward, sheet dismiss/re-present, or app backgrounding.
- Keyboard overlapping fixed chrome (back button, sticky CTA, customHeader).
- Empty/max data states unhandled at the screen.
- App-lifecycle gaps (force-quit mid-edit, background/foreground state).

A pass through this gauntlet is the only reliable way to surface those before the App Store does.

---

## Pre-flight

- [ ] Fresh install on a real device (not the simulator). Delete the app first.
- [ ] Light mode (Unit is light-only). Portrait.
- [ ] Connected to the internet (in case future code paths probe it).
- [ ] Battery > 30 %.
- [ ] One iPhone with **Dynamic Type → Larger Accessibility Sizes** turned all the way up. Another with **Reduce Motion** on.

---

## §1 Onboarding — state persistence

For each step (splash → unit → import method → paste/build → schedule → exercises):

- [ ] Tap **every input** on the step. Keyboard opens. No fixed chrome (back button, progress, title, sticky CTA) overlaps the input or each other.
- [ ] Type a value, hit **Continue**. On the next step, hit **Back**. The value is still there.
- [ ] At every step, **swipe-up to background** the app. Re-open. Lands on the same step with all values intact.
- [ ] At every step, **force-quit** (swipe up from app switcher). Re-open. Lands on the same step with all values intact.
- [ ] Paste step specifically: paste a long program (~30 lines). Scroll inside the editor. Tap **Read program**. Hit **Back**. Text is still there. Re-tap **Read program**. Parsed result matches.

**Empty / edge data:**
- [ ] Paste step: leave empty → CTA disabled, no crash on tap.
- [ ] Paste step: paste 7+ days of programs → parser caps at 6. Confirm the cap is communicated (today it's silent — flag if so).
- [ ] Paste step: paste with emoji / non-Latin characters in day or exercise names → no crash, characters survive into Templates.
- [ ] Split builder: max 6 days, each name → 30+ characters of text → no truncation / layout break.
- [ ] Exercises step: 0 exercises on a day → CTA disabled, gate caption explains.

---

## §2 Active workout — every screen with input

- [ ] Start a workout. Tap **Log set** (the AdjustResultSheet). Type a weight and reps. **Swipe down to dismiss the sheet**. Re-open the same set's sheet. Typed values either survive or the sheet warns before discarding — not silent loss.
- [ ] Same sheet: type a note. Background the app mid-typing. Re-open. Note survives or warns.
- [ ] **Post-workout rename alert** (freestyle): start typing a name. Background the app. Re-open. Draft survives or warns.
- [ ] Log a set, then tap the chip to **edit** it. Change weight. Swipe-dismiss. Re-open the edit sheet. Either the in-progress edit survives, or the original value is shown cleanly (no half-merged state).
- [ ] Mid-set, force-quit the app. Re-open. Active workout resumes on the same exercise / set / rest timer state.
- [ ] Rest timer running, background the app for 30 seconds, re-open. Timer reflects real elapsed time (does not pause silently).
- [ ] Phone call interrupts mid-set. Workout state intact when call ends.
- [ ] Confirm there are no **+1 rep** / **+ weight** suggestion chips. Current-set logging should use the last-time/planned prefill or open AdjustResultSheet for manual entry.
- [ ] Finish a workout with an empty day (no sets logged). Confirm finish flow handles it (no save crash, history shows or omits cleanly).

---

## §3 Templates — sheet drafts

- [ ] Open **Add exercise** sheet. Fill in name, aliases, bodyweight flag, muscle group. **Swipe-dismiss**. Re-open. Drafted fields either survive or warn — not silent loss.
- [ ] Open **Add day** sheet inside a template. Type a name. Swipe-dismiss. Re-open. Draft survives or warns.
- [ ] Edit a template's day. Add 1 exercise. Reorder. Navigate away. Return. Order persists.
- [ ] Exercise name with 100+ characters → confirm UI doesn't break in History / Today / templates list.

---

## §4 History & data integrity

- [ ] First-run state: 0 sessions, 0 templates → empty states render with copy that points the user forward.
- [ ] Many sessions (50+): scroll the list, open one, return → no jank, no state loss.
- [ ] Open a session, tap a set, edit weight. Confirm change persists across:
  - back / forward navigation
  - app backgrounding
  - force-quit + relaunch
- [ ] Delete a session. Force-quit. Re-open. Session stays deleted.
- [ ] Delete a template that has historical sessions. Confirm sessions still readable (no FK violation, no crash).

**v1 → v2 store migration (BLOCKER class — every existing user hits this on update):**
- [ ] On a device/simulator holding a **real v1.0 App Store `Unit.store`** (not a churned dev store), install the v2 build over it. Confirm: app opens the *persistent* store — **no "Training data unavailable" alert**, `PersistenceRecoveryState.noticeKey` stays false — and all v1 history/templates load. A silent fall-back to the in-memory store here = shipped data-loss for real users.
- [ ] If no clean v1 store exists: build the last released v1 tag, run it to seed a store, then install v2 over it. This is the only faithful reproduction; a dev device that has run mid-development schemas can fail migration for reasons production never sees (`UnitApp.makeSharedModelContainer` fallback exists exactly for this, and it does NOT auto-delete — a failure is recoverable, not a crash).

---

## §5 Keyboard — every screen with input

For every TextField / TextEditor in the app:

- [ ] Tap to focus. Keyboard opens without **anything** overlapping the focused field, the fixed top chrome (nav bar / back button / progress / title), or the sticky CTA below.
- [ ] Swipe-down the keyboard (or tap outside). Keyboard dismisses cleanly. No accessory pill stays floating.
- [ ] Type → submit (Return key) → confirm submitLabel and onSubmit do the right thing.
- [ ] Type → tap a CTA → confirm CTA fires AND keyboard dismisses (no stuck keyboard).
- [ ] On screens with `usesOuterScroll: false` plus a TextEditor (currently only the paste step), focus the editor and confirm the customHeader stays pinned to the top — this is the `OnboardingProgramImportView` regression class.

---

## §6 Accessibility quick pass

- [ ] **Dynamic Type at AX5**: every screen renders. Buttons don't crop. CTA labels don't truncate. No layout collisions.
- [ ] **VoiceOver**: every input has a label. Sticky CTAs are reachable. Order of focus is left-to-right, top-to-bottom.
- [ ] **Reduce Motion**: onboarding step transitions become cross-fade. Active workout chip transitions don't slide. No nausea-inducing motion.
- [ ] **Touch targets ≥ 44×44pt** on every tappable element (a quick visual scan).

---

## §7 App lifecycle — final pass

- [ ] **Background / foreground** every screen at least once. No state loss. No phantom presentations (e.g. a sheet that re-opens after returning).
- [ ] **Force-quit + relaunch** at every screen. App resumes at a reasonable state — same screen or one step back, never the splash unless that's truly correct.
- [ ] **Airplane mode** (Unit is local-first, so most flows should work): start a workout, log sets, finish. Toggle airplane mode mid-workout. Nothing breaks. Nothing waits for a network call.
- [ ] **Low memory warning** (simulator → Hardware → Simulate Memory Warning): no crash, no view loss.
- [ ] **Locale switch to a non-decimal-comma locale** (e.g. German `de_DE`). Weight inputs accept `60,5`. Parser handles both `.` and `,`.

---

## §8 Sign-off

- [ ] Every box above checked OR a follow-up issue filed with a link in the release notes.
- [ ] CHANGELOG / release-notes draft mentions the gauntlet pass.
- [ ] If any §1–§7 finding is **critical** (data loss), it blocks the release. Fix and re-walk only the affected section.

---

## §9 Paywall & StoreKit — local dev config

`Unit/Unit.storekit` is a **development-only** StoreKit configuration, wired into the scheme's
**Run** action only. Archive/Release ignore it, so it never ships. It lets the paywall load real
prices and complete test purchases in the Simulator without a sandbox Apple ID.

If Xcode shows the config as missing: **Product → Scheme → Edit Scheme → Run → Options →
StoreKit Configuration → select `Unit.storekit`.**

Walk this on a fresh install, from Xcode (⌘R), on **iPhone SE (3rd gen)**, a regular iPhone, and
a **Pro Max**, at default Dynamic Type and one AX size:

- [ ] Complete onboarding (paste a routine OR pick a starter program → schedule → preview →
      **Save my program**). The app saves the program and lands on **PaywallView**, not the tabs.
- [ ] Paywall shows **Weekly / Monthly / Yearly** with real prices ($2.99/week, $4.99/month,
      $29.99/year — ladder authority: `docs/pricing.md`), Weekly pre-selected. Lifetime ($44.99)
      appears only if returned by StoreKit.
- [ ] No clipped tier card; no CTA below the fold (CTA is pinned, body scrolls). The legal footer
      (**Restore Purchases · Terms of Service · Privacy Policy**) is reachable by scrolling even
      while the CTA is disabled.
- [ ] Tap **Continue with Weekly** → complete the StoreKit test purchase → the app enters the main
      tabs (unlock). Re-launch → still unlocked.
- [ ] Delete + reinstall → **Restore Purchases** re-unlocks. With no purchase, Restore shows
      "No purchases to restore."
- [ ] Force a load failure (delete the products from the config, or Editor → StoreKit → fail
      transactions): paywall shows the "Couldn't load subscriptions" card with **Try again**; the
      CTA reads "Subscribe to continue" and is disabled with a reason. No fake prices, no trial copy.

No iPhone SE simulator installed? `xcrun simctl create "iPhone SE (3rd gen)" "iPhone SE (3rd generation)"`
— 375pt wide, the real narrow-screen clipping test (installed sims start at 390pt).

---

## Where the bug classes come from

When this checklist catches something, the fix usually lives at one of:
- **`OnboardingViewModel.swift`** — for any onboarding step state.
- **An `@Observable` view-model owned by the parent screen** — for active workout and edit sheets.
- **`@AppStorage`** — for anything that should survive force-quit.
- **`OnboardingPreferences.save/load`** — for snapshotting onboarding-only state to UserDefaults.
- **`Unit/UI/DesignSystem.swift`** — for keyboard / chrome / layout patterns (fix at the atom layer, not the screen).

Per CLAUDE.md §5: when a bug shows on one screen, ask "would this appear on sibling screens if I patched only this file?" Move the fix up a layer if yes.

---

## Automation backstop

`/state-audit` (skill at `.claude/skills/state-audit/`) runs a code-level sweep for the bug class this gauntlet covers. Run it before each release as a complement, not a replacement, for walking the gauntlet on a device.
