# Reply to App Review — Guideline 2.1(b) Information Needed

> Paste-ready response to Apple's rejection of Build 1.0 (12) on 2026-06-03.
> Submission ID: `2b8f50d7-84fe-48fe-b4f2-b641a9bfd807`
> Where to post: App Store Connect → Unit — Gym Notebook → App Review tab → Messages → "Reply to App Review"
> Voice: respectful, direct, honest. No defensiveness. Acknowledge the mistake, explain the fix, answer all four questions.

---

## The reply (copy this verbatim)

```
Hello,

Thank you for the careful review and for clearly identifying the mismatch
between the marketing screenshots and the binary. You are right — Build
1.0 (12) sends conflicting signals about a Pro tier that does not actually
exist in this version. I apologize for the wasted review cycle.

Below are direct answers to the four questions, followed by what I have
changed to resolve the issue.

QUESTIONS

1. Who are the users that will use the paid subscriptions in the app?

   None. Build 1.0 (12) does not contain any paid subscriptions, in-app
   purchases, or paid digital content. The entire app is free.

2. Where can users purchase the subscriptions that can be accessed in
   the app?

   Nowhere. No In-App Purchase products are configured in App Store
   Connect for this version, and the binary does not present a paywall
   or any purchase flow. `Product.products(for:)` returns an empty
   collection at runtime.

3. What specific types of previously purchased subscriptions can a user
   access in the app?

   None. There are no purchasable products, and therefore no previously
   purchased products exist for any user to restore.

4. What paid content, subscriptions, or features are unlocked within
   the app that do not use In-App Purchase?

   None. Every feature in the binary — set logging, ghost values, rest
   timer (Live Activity / Dynamic Island), workout history, automatic
   PR detection, template builder, program import — is available to
   every user with no purchase, no account, and no sign-in.

WHAT WENT WRONG

The Settings screen in Build 1.0 (12) included two surfaces that
implied a Pro tier: a "Subscription" section with "Restore purchases"
and "Manage subscription" rows, and a Data section row labeled "Export
data" with a "PRO" badge. These were scaffolded for a future v1.1 Pro
launch and unintentionally shipped in v1.0.0. Additionally, the fifth
marketing screenshot in the App Store listing included the same "PRO"
badge on an "Export data" row.

I should have removed all of these from the v1.0.0 submission. They
created exactly the metadata-vs-binary mismatch your review caught.

WHAT I AM CHANGING

Binary (next Xcode Cloud archive, build 1.0 (13+)):

- The Subscription section is removed from Settings entirely.
- The "Export data" row with the PRO badge is removed from the Data
  section. The Data section now shows only "Storage: On this iPhone"
  and "Account: None" — both true statements about the local-first
  architecture, no purchase implications.
- No Pro surface, no paywall entry point, and no subscription chrome
  is reachable anywhere in the binary.

Listing (screenshot replacement):

- Screenshot 5 will be re-exported with row 3 changed from "Export
  data + PRO" to "Tracking: None". This is verifiable against the
  app's PrivacyInfo manifest, which declares only UserDefaults usage
  (reason CA92.1, app functionality) with no third-party analytics
  or tracking SDKs.

NEXT STEPS ON MY END

I will upload Build 1.0 (13) once Xcode Cloud finishes archiving,
replace Screenshot 5 in the listing, and resubmit for review. A Pro
tier may launch in a future update (v1.1+), at which point the IAP
products will be configured in App Store Connect, reviewed alongside
that submission, and only enabled in the binary when the underlying
features (CSV export, Apple Health sync, custom icons, custom theme
colors) are actually implemented and deliverable to a purchaser.

Thank you for the time you spent on this review and for the clarity
of your message. Please let me know if any of the answers above need
further detail.

Best regards,
Efe Bakir
support@unitlift.app
```

---

## Notes for Efe before posting

**Word count**: ~480 words. Apple's reply box is unlimited but reviewers prefer concise. This is below the wall-of-text threshold and still answers every question.

**Tone**: matches Apple's professional/neutral register. Acknowledges fault without grovelling. No "we" — uses "I" throughout per PRODUCT.md.

**Honesty**: every claim is verifiable from the next binary + listing. No promises about features that aren't built.

**Don't add**: marketing language, links to your website, a sales pitch for the app, an attempt to argue the decision. Reviewers read hundreds of these — sharp and bounded wins.

**Do**:
- Post this reply
- THEN upload Build 13 and replace Screenshot 5 BEFORE the reviewer responds
- That way when they re-engage, the new build is already attached and the listing is already corrected

**If the reviewer asks a follow-up**:
- Most common: "Can you confirm the new build is attached?" → answer yes once you've attached it
- Less common: "What is the future Pro pricing?" → that's optional to answer; you can say "TBD, to be configured in App Store Connect when v1.1+ submits the IAPs"
- Almost never: re-rejection on the same issue → if it happens, paste the rejection here and I'll iterate

**Timing**: Apple's first re-review after a reply is usually 12-48 hours, often faster than the original queue.

---

## Reference

- Rejection date: 2026-06-03 3:07 PM
- Guideline cited: 2.1(b) — Information Needed
- Submission ID: `2b8f50d7-84fe-48fe-b4f2-b641a9bfd807`
- Build reviewed: 1.0 (12)
- Review device: iPad Air 11-inch (M3)
- Reply drafted: 2026-06-03 (this file)
- Code fix: `Unit/Features/Settings/SettingsView.swift` (commit pending)
- Screenshot fix: `docs/marketing/research/screenshot-strategy-final.md` §Screenshot 5 Row 3 (committed in same change)
- Decision log: `docs/decision-log.md` 2026-06-03 entry
