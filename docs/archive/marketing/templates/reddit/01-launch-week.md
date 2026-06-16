# Reddit template — launch week BIP post

> **When**: Week 3 of launch (~2026-05-13)
> **Where**: r/SideProject (primary)
> **Format**: build-in-public, vulnerable confession + tiny win
> **Time investment**: 30 min to write + 6 hours of replies after posting

---

## Title (pick one — A/B in your head before posting)

**Option A** (frustration → ship):
> I built a 3-second gym logger because Hevy felt like a spreadsheet

**Option B** (notebook angle, fits Unit's defining claim):
> I logged my last 200 sets in a paper notebook because every gym app was too slow. So I built one.

**Option C** (solo dev journey):
> 3 months solo, no marketing, just shipped my gym logger to the App Store. Here's the dashboard on day 1.

---

## Body (≤200 words)

```
[Hook — one line restating title.]

I'm an intermediate lifter who kept a paper notebook for years because every
tracker felt slower than writing. Three months ago I started building Unit —
a gym logger designed around one rule: log a set in under 3 seconds,
one-handed, sweaty.

Ghost values prefill your last session so you tap once to confirm. No AI
coach. No social feed. No algorithm telling you what to lift.

Built solo with Swift 6, SwiftUI, SwiftData. RevenueCat for subs.
Free core logging — never paywalled. Pro is $4.99/mo or $29.99/yr.

[Insert RevenueCat Charts screenshot here — Active Subs / MRR / Revenue card.
Even at $0 MRR / 0 subs on day 1, it reads as honest.]

Brutal feedback welcome. What would you build next?
```

---

## Image

**RevenueCat Charts → Overview dashboard screenshot.**

- Crop to the Active Subs / MRR / Revenue card stacked vertically
- Real numbers. $0 / 0 / 0 is fine on day 1 — it reads as honest
- No Photoshop, no annotations, no overlays

Alternative if RevenueCat is not yet wired: App Store Connect → Analytics → Sales and Trends, line graph view (NOT spreadsheet).

---

## First comment (link goes here, NOT in body)

```
App Store: [App Store URL — drop in the moment after posting]

If you want to chat or break the app, my DMs are open. I'll respond to
every comment in this thread.
```

---

## Pre-post checklist

- [ ] Title sounds like a friend texting, not a press release
- [ ] Body ≤ 200 words
- [ ] Real screenshot from RevenueCat or App Store Connect (not edited)
- [ ] App Store link in clipboard ready for first comment
- [ ] Tuesday or Wednesday morning ET (8-11am)
- [ ] No US holiday this week
- [ ] 6 hours after post time blocked on calendar for replies

---

## Post-time discipline

| Time | Action |
|---|---|
| **T+0** | Post manually. Drop link in first comment immediately. |
| **T+0 to T+1h** | Reply to every comment within ~10 min. **Critical window** — first hour determines breakout. |
| **T+1h to T+6h** | Reply within ~30 min. Slow down but don't disappear. |
| **T+24h** | Log views, upvotes, comments, profile visits, App Store install spike (Apple App Analytics referrer). Add to weekly metrics in `cadence.md`. |

---

## Variants for other subreddits (stagger ≥1 week apart)

**For r/microsaas** (smaller, friendlier, higher signal):
- Same body. Adjust title to lead with the number: *"3 months solo, day 1 of my gym logger on App Store. Here's RevenueCat at $0."*

**For r/iOSProgramming** (Showcase Saturday only — strict):
- Lead with technical angle: *"Shipped my first SwiftUI app — minimalist gym logger using SwiftData + RevenueCat."*
- Audience is devs not customers; lower install conversion but builds credibility

**For r/iosapps** (W4 follow-up, not W3):
- *"My minimalist gym logger has been live for 1 week. Here's what I've learned."*
- Update with W3-W4 numbers, not day-1

---

## Why this template works (research-backed)

Per `research/viral-patterns-2026-04-29.md` §1:

- Vulnerable confession + specific tiny win + concrete number = breakout pattern
- 150-400 words almost always (this is 130 — tight)
- RevenueCat Overview dashboard is the most-replicated artifact in r/SideProject
- One genuine ask ("what would you build next?") resets the trust transaction
- No CTA in body — comments organically request the link

## Don't do

- ❌ "Introducing Unit" or "Just launched my new app" — pitchy, dies
- ❌ "Day 1 of building in public 🚀" — slop signal
- ❌ Round-numbered fake-feeling MRR
- ❌ AI-generated hero image
- ❌ "Please try it 🙏"
- ❌ URL in title or body — the auto-filter removes the post

---

## See also

- `docs/marketing/reddit.md` — full Reddit playbook
- `docs/marketing/cadence.md` — Reddit-post-day timing
- `docs/marketing/anti-patterns.md` — Reddit anti-patterns
