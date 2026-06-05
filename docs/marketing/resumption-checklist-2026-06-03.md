# Resumption checklist — 2026-06-03 rejection fix

> What to do when you return. Sequential, async-safe. If anything below already happened automatically by the time you read this, mark it done and move to the next.

---

## TL;DR

Build 1.0 (12) was rejected by App Review under Guideline 2.1(b) because the binary AND the listing implied a Pro tier that doesn't exist (no IAPs configured in App Store Connect per the Decouple decision). I committed `ee8929e` to `main` which surgically strips the Pro UI from the binary, updates the screenshot strategy doc for Row 3 of Screenshot 5, and drafts your Apple reply. Three things left for you:

1. **Re-export Screenshot 5 from Figma** with the new Row 3 spec
2. **Replace it in App Store Connect**
3. **Post the Apple reply** + resubmit Build 13

Everything else is automated (Xcode Cloud builds the new archive; ASC processes it).

---

## Step 1 — Verify Build 13 is processing

By the time you read this, Xcode Cloud should already have triggered Build 13 from commit `ee8929e`.

- Open App Store Connect → your app → **Xcode Cloud** tab
- Look for **Build 13** in the list (commit message will start with "App Review fix: strip Pro UI…")
- Expected status:
  - ⏳ Still archiving → wait ~3 min
  - ✅ Green → archive succeeded, uploading to ASC now
  - ❌ Red → unlikely (the change is 3 lines, surgical). Paste the error in chat if so.

---

## Step 2 — Fix Screenshot 5 in Figma

The spec at `docs/marketing/research/screenshot-strategy-final.md` §Screenshot 5 has been updated. The change is in **Row 3 only** — rows 1 and 2 are unchanged.

### Old Row 3 (the one Apple rejected)

```
Icon:  square.and.arrow.up
Label: Export data
Value: [PRO chip — accent #0A0A0A, "PRO" in Geist Bold ~24pt #FFFFFF]
```

### New Row 3 (the fix)

```
Icon:  hand.raised.slash
Label: Tracking
Value: None  (Geist Regular 56pt, #595959)
```

### Figma edit steps

1. Open your Figma file for App Store screenshots
2. Navigate to Screenshot 5 ("No account. Works offline.")
3. Find Row 3 (currently shows "Export data" + PRO chip)
4. Replace the SF Symbol from `square.and.arrow.up` → `hand.raised.slash`
5. Change the label text from "Export data" → "Tracking"
6. Delete the PRO chip component
7. Add value text "None" in **Geist Regular 56pt, #595959**, baseline-aligned with the value text in rows 1 and 2
8. Re-export the frame at **1290 × 2796** as PNG, sRGB, no transparency

The other 4 screenshots are unchanged.

### If you can't get back into Figma easily

Alternative: take a fresh screenshot from the real app once Build 13 is installed on your phone. The new Settings → Data section will only show Storage + Account (no Export PRO row). A native screenshot of that view, framed appropriately, can replace the Figma version. Native phone screenshots at 1290×2796 (iPhone 16/17 Pro Max) are accepted by Apple.

---

## Step 3 — Replace Screenshot 5 in App Store Connect

1. App Store Connect → your app → **App Store** tab → **1.0 Prepare for Submission** (or whatever the version is currently called now that it's in review)
2. Scroll to **Previews and Screenshots**
3. Open **Media Manager** (top right link)
4. Find the 6.9" Display slot's Screenshot 5 position
5. Delete the old Screenshot 5
6. Drag in the new one
7. Confirm the order is correct (1 → 2 → 3 → 4 → 5)
8. Save / Done

---

## Step 4 — Attach Build 13 to the version

Once Apple finishes processing Build 13 (you'll get an email "Your build is ready"):

1. Return to the version page (**1.0 Prepare for Submission**)
2. Scroll to the **Build** section
3. Click the `+` next to Build
4. Select **1.0 (13)** from the dropdown
5. Confirm

The previously attached Build 12 will be replaced.

---

## Step 5 — Reply to Apple

1. App Store Connect → your app → **App Review** tab → **Messages**
2. Click **Reply to App Review**
3. Open `docs/marketing/app-review-reply-2026-06-03.md` in your editor
4. Copy the message inside the code block (from "Hello," through "support@unitlift.app")
5. Paste into the reply box
6. Send

The reply does NOT submit the app for re-review on its own. Apple's reviewer will see your reply and the updated submission, and continue the review.

---

## Step 6 — Resubmit if needed

Sometimes Apple's reply UI also requires you to manually click **Resubmit for Review** after sending the message. If you see a Resubmit button after attaching Build 13 and posting the reply, click it.

If you don't see one, the conversation alone is enough — Apple's reviewer will pick it back up from your reply.

---

## What I changed for you (commit `ee8929e`)

Already pushed to GitHub `main`:

| File | Change |
|---|---|
| `Unit/Features/Settings/SettingsView.swift` | Removed Subscription section from layout + filtered Export PRO row out of Data section |
| `docs/marketing/research/screenshot-strategy-final.md` | Screenshot 5 Row 3 spec rewritten + glyph rationale updated |
| `docs/decision-log.md` | 2026-06-03 entry documenting the rejection + fix |
| `docs/marketing/asc-submission.md` | Header note pointing at the new files |
| `docs/marketing/app-review-reply-2026-06-03.md` | The paste-ready Apple reply (new file) |

---

## What I did NOT touch (your stash + WIP)

You had 14 uncommitted files at the start. I touched only the Settings file (and docs). Everything else is preserved.

- **Stashed (`stash@{0}: parallel-agent-WIP-pause`)**: the larger Pro-gating refactor for `SettingsView.swift`, `PaywallView.swift`, `HistoryView.swift`. This adds the `LaunchConfig` pattern + `proSection` + `proGatedDataRow` + History PRO toolbar. It's the correct end-state for v1.1+ when Pro launches for real. To resume: `git stash pop` — you'll need to resolve a conflict in `SettingsView.swift` between my surgical fix and the larger refactor (the refactor wins — pop it and re-apply the v1.1 Pro plan).
- **Untracked**: 8 files (CLAUDE settings hooks, plan notes, monetization strategy, release-qa, etc.). All safe, none related to the rejection fix.

---

## Confidence

- **Binary fix**: high confidence. The change is 3 lines (one `filter`, one `subscriptionSection` removed from the layout). It compiles trivially.
- **Screenshot fix**: depends on you doing the Figma edit. Spec is precise.
- **Apple reply**: high confidence the wording is correct. Honesty + acknowledgment + four direct answers + commitment to fix.
- **Build 13 timing**: Xcode Cloud archive ~3 min + Apple processing ~15-30 min from when you read this.
- **Re-review timing**: typically 12-48 hours after you resubmit with the reply.

---

## If you want a comprehensive risk audit of OTHER potential rejection reasons

A parallel multi-agent audit was kicked off (workflow `wdx7n1597`) checking 6 dimensions: Pro residue, metadata mismatch, Guideline 4.3 spam-clone, 5.1.1 privacy, 4.0 design, and other rejection vectors. Results synthesize into a ranked action plan with confidence and a "next most likely rejection" prediction. Check chat when you return.

---

## Reference

- Rejection date: 2026-06-03 15:07
- Guideline cited: 2.1(b) — Information Needed
- Submission ID: `2b8f50d7-84fe-48fe-b4f2-b641a9bfd807`
- Review device: iPad Air 11-inch (M3)
- Fix commit: `ee8929e`
- Decision log: `docs/decision-log.md` §2026-06-03
- Apple reply: `docs/marketing/app-review-reply-2026-06-03.md`
