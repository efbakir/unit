# Reddit template — Week 4 free-tier philosophy post

> **When**: Week 4 of launch (~2026-05-20)
> **Where**: r/microsaas or r/SaaS (primary), r/SideProject (if you skip it for the W8 recap)
> **Format**: opinionated take + numbers, framed as a philosophy not a pitch
> **Time investment**: 30 min to write + 6 hours of replies

---

## Title (pick one)

**Option A** (philosophy hook):
> I gave away the core of my gym app forever — here's why I'm not worried about money

**Option B** (counterpoint to industry):
> Hevy gates basic logging behind a paywall. I shipped the opposite — and got 50 installs week 1.

**Option C** (founder commitment):
> I promised on my landing page that core logging will never be paywalled. Here's why I think that's a moat, not a mistake.

---

## Body (≤220 words)

```
[Hook — one-line restating title.]

Most gym apps in 2026 paywall something on the Gym Test path —
template count, history depth, PR detection. I shipped Unit with the
opposite bet: every set-logging feature is free forever, and Pro
gates only off-path stuff (CSV export, Apple Health sync, custom icons).

The math:

- Free tier: full set logging, ghost values, rest timer + Lock Screen
  Live Activity, all templates, full history, PR detection, custom
  exercises. None of that ever moves behind a paywall.
- Pro ($4.99/mo, $29.99/yr): export, Health sync, custom app icons,
  custom template colors, founding-supporter badge. Future v2
  features (Apple Watch, ProgressionEngine opt-in, cloud backup) all
  ship inside Pro — no second paywall ever.

Why I think this is a better business, not worse:

1. Free-tier users still talk. The Gym Test win is what gets shared
   — and it's free, so it gets shared.
2. The 1-star reviews on Hevy / Strong / Liftosaur are mostly about
   aggressive paywalls. Closing that complaint is a positioning
   moat, not a give-away.
3. Pro is for the lifters who want export + Health sync. Those users
   self-select. They convert hard.

[Insert RevenueCat Charts screenshot — Week 4 numbers, real,
including trial starts if any.]

Curious what you think — would you pay for export + Health if logging
itself was free? Or does this feel like leaving money on the table?
```

---

## Image

RevenueCat Charts → 28-day trend or current week. Show:
- Active subs (real number, even if small)
- Trial starts (if W4 hit any)
- Revenue (real, even at $0)

Alternative: a labeled "Free vs Pro" feature table you've designed in Figma — 1 image, clear, no decoration.

---

## First comment

```
App Store: [App Store URL]

The free-tier promise lives on my landing page and in privacy policy.
If I ever flip on a paywall for core logging, you can throw it in my
face. Founding members in launch month keep their rate forever.
```

---

## Pre-post checklist

- [ ] Title takes a position, doesn't just announce
- [ ] Body ≤ 220 words
- [ ] Real numbers (no faking trial counts or MRR)
- [ ] Tue/Wed morning ET
- [ ] 6h after post blocked

---

## Why this template works

Frames pricing philosophy as a *belief*, not a feature list. The audience on r/microsaas / r/SaaS is opinionated about pricing — a clear position is more shareable than a feature list. The image proves you have skin in the game (real numbers).

The post invites disagreement (last line). Disagreement → comments → algo signal.

## Variants

**For r/iOSProgramming** (Showcase Saturday): retitle as *"How I structured a free-forever subscription gym app with RevenueCat — and why I'm not paywalling core features"*. Heavier on the StoreKit/RevenueCat technical detail.

**For r/EntrepreneurRideAlong**: more journey-flavored — *"Week 4 update: I bet on a free-forever core for my indie gym app. Here's whether the bet looks like it'll pay."*

---

## Don't do

- ❌ Bash specific competitors by name *too* hard. Mention them as the contrast, not the villain. r/SaaS will downvote pure mockery.
- ❌ Promise revenue numbers you don't have
- ❌ Frame as "I'm so generous" — frame as "I think this is a better business"

---

## See also

- `docs/marketing/reddit.md`
- `docs/marketing/research/viral-patterns-2026-04-29.md` §1
- `docs/pricing.md` — the actual pricing structure
