# Unit — 30-day X (Twitter) content schedule

> Window: 2026-04-29 → 2026-05-26 (W1 build → W2 TestFlight → W3 launch → W4 retro)
> Launch: **Wed 2026-05-13**
> Cadence: 4–5 tweets/week, ~16 tweets total. All times **ET**.
> Anchors: `templates/x/01-launch-tweet.md`, `templates/x/02-build-in-public-thread.md`, `templates/x/03-pricing-philosophy.md`, `research/viral-patterns-2026-04-29.md` §3, `launch-plan.md` §3, `pricing.md`, `product-compass.md`, `anti-patterns.md`.
> Pricing in this doc uses **$4.99 / $29.99 / $44.99** per `pricing.md`. Do NOT revert to historical $9.99/$49.99.

---

## How to read this doc

- Section A is the calendar — every tweet, slot, media, reply.
- Section B is the ready-to-fire copy: launch-day variants, BIP thread, pricing philosophy, retro thread, in-between standalones.
- Section C is the engagement protocol (pinning, reply windows, DM follow-ups).
- Section D is the X-specific anti-pattern list — re-read before each post.
- Section E is reply-protocol templates for the 3 most common questions.

Char counts are shown in parens after each tweet body. Counts include line breaks. Soft cap 280 chars (X limit). Anything above 280 is broken into a thread.

---

# A. Tweet schedule (W1–W4)

## W1 — build week (2026-04-29 → 2026-05-05)

> **Goal**: warm the timeline. Establish "indie iOS dev shipping a gym logger." Three to four posts. No App Store link (nothing to link yet).

| Day | Time (ET) | Slot | Anchor | Media | Reply | Why |
|---|---|---|---|---|---|---|
| Wed 04-29 | 10:00 AM | W1-T1 — "shipping next week" hint | standalone build progress | screen-record (12s) of logging a set with rest timer | none | Establishes a deadline. Calendar pressure performs on X. |
| Fri 05-01 | 11:00 AM | W1-T2 — micro-rant on logging friction | standalone micro-rant | side-by-side stills (paper notebook ↔ Hevy onboarding) | none | Frames the problem. Underdog framing per viral-patterns §1. |
| Sat 05-02 | 9:30 AM | W1-T3 — design decision call-out | standalone build progress | DesignSystem.swift `AppCard` + screenshot | none | Tech-stack one-liner. Devs upvote stack-recognition (Tony Dinh playbook). |
| Mon 05-04 | 10:00 AM | W1-T4 — "TestFlight tomorrow" | standalone build progress | TestFlight icon + "Day 90" still | none | Public deadline → Tuesday's TestFlight beat lands harder. |

## W2 — TestFlight beta (2026-05-06 → 2026-05-12)

> **Goal**: recruit testers. Build credibility. Warm the audience for next Wed's launch. Three to four posts. Tester recruitment goes in W2-T2.

| Day | Time (ET) | Slot | Anchor | Media | Reply | Why |
|---|---|---|---|---|---|---|
| Tue 05-05 | 10:30 AM | W2-T1 — TestFlight is live | standalone build progress | TestFlight install screen | none | Concrete "live thing today" beats abstract "coming soon". |
| Thu 05-07 | 11:00 AM | W2-T2 — tester recruitment | tester ask | 8s screen-record of ghost values pre-fill | "DM 'unit' and I'll send a TestFlight code." | DM-as-CTA outperforms link in beta. Generates real warm leads. |
| Sat 05-09 | 9:00 AM | W2-T3 — beta progress (count) | standalone build progress | dashboard still showing tester count | none | Small real numbers travel on X (viral-patterns §1). |
| Mon 05-11 | 10:00 AM | W2-T4 — "Wed launch" hint | launch hint | hero screenshot (App Store screen 1) | none | T-2 day reminder. Lets followers RSVP without explicit CTA. |

## W3 — launch week (2026-05-13 → 2026-05-19)

> **Goal**: ship, then defend the timeline for 48 hours. Five to six posts. Launch tweet pinned. BIP thread Thu. Pricing piece NOT here — saved for W4.

| Day | Time (ET) | Slot | Anchor | Media | Reply | Why |
|---|---|---|---|---|---|---|
| Mon 05-12 | 10:00 AM | W3-T1 — "tomorrow at 10am" | launch hint | 5s clip of logging a set | none | Tight window. People plan to look. |
| Wed 05-13 | 10:00 AM | W3-T2 — **LAUNCH TWEET (pinned)** | template 01 (recommended variant) | hero screenshot OR 8s vertical video | "App Store: [URL]" | Single tweet + reply-link is the X launch shape. Algorithmically rewarded. |
| Wed 05-13 | 8:00 PM | W3-T3 — "Day 1 ICYMI" quote-RT of own launch | self-QT of W3-T2 | reuse hero shot | none | Re-surfaces launch tweet for ET evening + EU morning audiences without re-posting the link. |
| Thu 05-14 | 10:00 AM | W3-T4 — **BIP 5-tweet thread (pinned, replaces launch pin)** | template 02 | image per tweet (notebook, competitor, screen-record, RC dashboard, App Store) | none — App Store URL is in tweet 5 | Thread = product narrative. Per viral-patterns §3, the credibility anchor is the RC screenshot in T4. |
| Fri 05-15 | 11:00 AM | W3-T5 — early reaction quote-tweets | reactions | screenshot of 1–2 user replies (faces blurred) | none | Social proof. Re-amplifies users without astroturfing. |
| Sun 05-17 | 9:30 AM | W3-T6 — weekend wins | standalone build progress | small RC chart still + screenshot | none | Weekend = lower competition window on X. Numbers + transparency = shareable. |

## W4 — post-launch retro (2026-05-20 → 2026-05-26)

> **Goal**: convert attention into a narrative. Four posts. Pricing-philosophy piece **after** paywall flips. Retro thread caps the month.

| Day | Time (ET) | Slot | Anchor | Media | Reply | Why |
|---|---|---|---|---|---|---|
| Tue 05-19 | 10:30 AM | W4-T1 — first-week learnings | standalone build progress | small dashboard chart | none | Stops the "is this dead?" perception. Honest 1-week recap. |
| Thu 05-21 | 11:00 AM | W4-T2 — **pricing-philosophy tweet** | template 03 (recommended variant) | no media (text-only) | "App Store: [URL] (only if asked)" | Stake-in-ground. Per viral-patterns §1 — opinionated pricing posts compound. |
| Sat 05-23 | 9:30 AM | W4-T3 — "I made this decision because…" | product-compass decision log | none | none | Mines product-compass.md. Decision-log content is uniquely Unit. |
| Mon 05-25 | 10:00 AM | W4-T4 — **W1–W4 retro 5-tweet thread (pinned, replaces BIP pin)** | retro thread | one image per tweet (RC chart, install funnel, top quote, screenshot, App Store) | "App Store: [URL]" | Caps the month with numbers. Becomes the new pinned tweet for the next 4 weeks. |

---

# B. Ready-to-fire tweet drafts

## B.1 — W3 launch day tweet (3 expanded variants)

All three are launch-day candidates. Pick one, schedule for Wed 2026-05-13 10:00 AM ET, reply with App Store link within 30 seconds, pin to profile.

### Variant A — Notebook angle (recommended)

```
I tracked my last 200 sets in a paper notebook because every gym
app was too slow.

So I built one. 3 seconds per set. Free core logging, no AI coach,
no social feed.

Unit is live.
```

(196)

- **Media**: side-by-side still — paper notebook on the left, Unit "log a set" screen on the right. Vertical.
- **Reply**: `App Store: [App Store URL]`
- **Why this works on X**: notebook angle is concrete, anti-tech, instantly visualizable. Specific number (200 sets) > vague claim. "Built" hooks indie devs; "every gym app was too slow" hooks lifters. Per viral-patterns §1 — concrete number + underdog frame.

### Variant B — BIP framing

```
3 months. Solo. SwiftUI + SwiftData + RevenueCat.

Unit is live: a minimalist gym logger built around one rule —
log a set in under 3 seconds, one-handed, sweaty.
```

(180)

- **Media**: 8-second vertical screen-record of logging a set, rest timer overlay.
- **Reply**: `App Store: [App Store URL]`
- **Why this works on X**: tech-stack one-liner is a Tony Dinh staple — devs upvote on stack-recognition alone. "Solo" + "3 months" + small numbers = underdog frame. Single rule framing > feature list.

### Variant C — Pricing-philosophy framing

```
Every gym app paywalls something on the path of "log a set under
fatigue." I shipped the opposite.

Core logging is free forever. Pro gates export, Health sync,
custom icons.

Unit is live.
```

(202)

- **Media**: clean Free vs Pro feature-table screenshot.
- **Reply**: `App Store: [App Store URL]`
- **Why this works on X**: stake-in-ground opinion. The Gym Test framing is uniquely Unit. Pro list is concrete, not vague.

### Recommendation

**Ship Variant A.** Highest contrast vs. competitor launch energy, easiest to visualize, hardest to mistake for another gym app. Save B for the BIP thread anchor (where the stack mention naturally belongs). Save C for W4-T2 (the dedicated pricing tweet) — don't double-dip pricing on launch day.

---

## B.2 — W3-T4 build-in-public 5-tweet thread (Thu 2026-05-14, 10:00 AM ET)

Post as a thread in X's native composer. All five drafted ≤280. Pin after posting (replaces launch tweet as pin until W4-T4 retro thread takes over).

### Tweet 1 — the hook

```
3 months ago I started building Unit — a gym logger.

I quit my notebook 4 times to try real apps. Every time, I came
back to paper because every tracker was slower under fatigue.

Here's what I learned trying to ship the opposite.
```

(231)

- **Media**: photo of the actual paper notebook, page open showing real set logs.

### Tweet 2 — the irritation

```
The bug: every gym app paywalls or bloats the path of logging a set.

Hevy: 4+ taps per set. Strong: dozens of templates to pick before
you start. Liftosaur: brilliant, but built for programmers, not
lifters at the bar.

Pen and paper beat all of them.
```

(252)

- **Media**: a screenshot of the most-tap-heavy competitor onboarding flow.

### Tweet 3 — the rule

```
The rule I built around: log a set in under 3 seconds, one-handed,
sweaty.

Ghost values from last session. Tap to confirm, tap to adjust, done.
Auto rest timer. Lock Screen Live Activity. Local-first.

No AI coach. No social feed. No "Day N of M".
```

(252)

- **Media**: 8-second vertical screen-record of logging a set, rest timer + Live Activity visible.

### Tweet 4 — the stack + the bet

```
Stack: SwiftUI, SwiftData, RevenueCat. Single target, light mode,
portrait. Solo build.

The bet: free core logging, forever. Pro gates export + Health
sync + custom icons.

Founding members in launch month keep their rate forever.

Day 1:
```

(247)

- **Media**: RevenueCat Charts screenshot from Day 1. Real numbers. Even at $0 trial-starts > $0 reads as honest. (Per template 02 — this is the credibility anchor.)

### Tweet 5 — the close

```
Unit is live on the App Store. Free.

If you've ever quit a gym app for a notebook, this one's for you.
```

(118)

- **Media**: optional — the App Store hero shot. Often stronger as text-only, since the link is the focus.
- **Inline link**: yes, App Store URL goes in tweet 5 since it's the close (X tolerates link in last tweet of a thread far better than in a single-tweet body — thread context is the mitigation).

---

## B.3 — W4-T2 pricing-philosophy tweet (Thu 2026-05-21, 11:00 AM ET)

### Recommended — Variant C from template 03 (founder commitment)

```
On launch day I committed: core logging in Unit is free, forever.

If I ever paywall set logging, every founding member can throw
this tweet in my face.

(Founding members in launch month keep their rate forever, too.)
```

(216)

- **Media**: none. Text-only. Per template 03 — naked text often outperforms images for opinionated content on X.
- **Reply**: do NOT pre-post a link reply. Only reply with App Store URL **if** someone asks where to download.
- **Why this works on X**: stake-in-ground commitment, public accountability hook ("throw this tweet in my face"). Frames as commitment, not announcement — paywall flip is conditional per `product-compass.md`. Avoids "we just turned on paywall" energy entirely. Per viral-patterns §1 — pricing philosophy + small real numbers = strongest indie X content.

### Why Variant C over A or B

- **A (counter-incumbents)** names competitors directly — risks reading as combative on launch month, and `anti-patterns.md` warns against tagging competitor founders. Can be saved for a W8 recap.
- **B (philosophy)** is good but generic. Doesn't anchor to founding-member promise.
- **C** locks in founding-member loyalty and gives the tweet a long tail — every future pricing-question reply can quote-link this.

---

## B.4 — W4-T4 retro 5-tweet thread (Mon 2026-05-25, 10:00 AM ET)

Real numbers go in `[brackets]`. Fill before posting. Pin after posting.

### Tweet 1 — the hook

```
12 days since Unit launched.

A retro: what worked, what didn't, what I'd do differently. Numbers
where I have them, honesty where I don't.
```

(155)

- **Media**: small dashboard chart — install funnel from launch day to T+12.

### Tweet 2 — the numbers

```
W1 (build): 0 installs. TestFlight beta with [insert real W2
TestFlight tester count] testers.

Launch week: [insert real W3 install count] installs, [insert real
W3 trial starts] trial starts, [insert real W3 paid conversions]
paid.

Below my goal. Above my fear.
```

(263)

- **Media**: RevenueCat Charts screenshot. Real numbers — even underwhelming reads as honest.

### Tweet 3 — what worked

```
What worked:

- The notebook angle. Best-performing tweet of the month.
- Reply-with-link discipline. Algo didn't suppress launch tweet.
- DM beta codes (W2). Highest-quality early feedback I got.
- Free core logging. Zero "where's the paywall" complaints.
```

(253)

- **Media**: still of the top-performing tweet (W3-T2), zoomed in.

### Tweet 4 — what didn't

```
What didn't:

- Saturday 05-09 post landed flat — nobody on X on Saturday morning.
- "Day N · Push" thread idea I scrapped because it sounded like every
  other launch.
- Pricing tweet on launch day (cut for the right reason: too early to
  earn the take).
```

(266)

- **Media**: none.

### Tweet 5 — looking forward

```
Next: Apple Watch companion, CSV export polish, and a W8 retro post
with whatever the next month teaches me.

Unit is live, free core logging forever.
```

(176)

- **Inline link**: yes, App Store URL in tweet 5 (same logic as BIP thread T5 — thread close tolerates link).

---

## B.5 — Standalone in-between tweets

Six tweets, ready to fire on the dates and times in the calendar above.

### W1-T1 — Build progress: shipping next week (Wed 04-29, 10:00 AM ET)

```
3 months ago I quit my paper notebook to build a real gym app.
Last 6 weeks every "real app" I tried sent me back to paper.

So I built mine. Shipping next Wednesday at 10am ET.
```

(204)

- **Media**: 12s screen-record — log a set, watch ghost values land, rest timer fires.
- **Why X**: deadline. Public commitment. Specific stack/timing > vague "soon."

### W1-T2 — Micro-rant: logging friction (Fri 05-01, 11:00 AM ET)

```
The reason I went back to a notebook 4 times: every gym app
treated logging like a form.

Logging is reflex. Form is the enemy of reflex. Every "make sure
to confirm" tap is a tax on the lift.

Building one that respects that.
```

(255)

- **Media**: side-by-side stills — paper notebook page (instant) ↔ a generic competitor's set-entry modal (multi-tap). Caption: "0 taps vs 4 taps."
- **Why X**: opinion. Frames problem. No competitor named directly — `anti-patterns.md` allows "naming carefully." The point is the *idea*, not the dunk.

### W1-T3 — Build progress: design decision (Sat 05-02, 9:30 AM ET)

```
Smallest decision I'm proud of:

Bodyweight rows show "BW", not "0 kg". Three-character difference.
Every reviewer told me it was nothing. Every lifter who saw it said
"oh yeah, finally."

A logger should never make a lifter look up "is 0 kg correct."
```

(266)

- **Media**: zoomed screenshot of the BW row in Unit, followed by a generic "0 kg" placeholder side-by-side.
- **Why X**: small, specific, opinionated. Designers + indies share micro-decisions hard.

### W1-T4 — TestFlight tomorrow (Mon 05-04, 10:00 AM ET)

```
Tomorrow: TestFlight beta opens. 90 days of solo build, 1 day
from real users in their real gyms.

If you train 3+ days/week and want a beta code, reply or DM "unit"
tomorrow morning.
```

(216)

- **Media**: TestFlight icon + the Unit icon on a Lock Screen mockup.
- **Why X**: deadline + DM-as-CTA. Generates warm leads.

### W2-T2 — Tester recruitment (Thu 05-07, 11:00 AM ET)

```
TestFlight beta of Unit is open. Looking for 50 lifters to log
their sessions for a week.

What I want from you: 5 sessions and one DM with what broke.

What you get: lifetime founding-member rate when I launch next week.

DM "unit" for a code.
```

(269)

- **Media**: 8s screen-record of Unit's ghost-value pre-fill in action.
- **Reply**: `DM "unit" and I'll send a TestFlight code.`
- **Why X**: clear ask, clear give, clear CTA. "Lifetime founding-member rate" is the hook (per `pricing.md` founding-member lock-in).

### W2-T3 — Beta progress (Sat 05-09, 9:00 AM ET)

```
[insert real W2 tester count] lifters in the Unit beta this week.

3 bugs found: rest timer drift on a Live Activity edge case, a
template duplication crash, a copy bug ("0 kg" sneaking back into
bodyweight rows).

All fixed. Launching Wednesday.
```

(258)

- **Media**: a Linear screenshot or a cropped TestFlight feedback list (faces/handles blurred).
- **Why X**: real bugs > sanitized progress. Underdog credibility.

### W3-T5 — Early reactions (Fri 05-15, 11:00 AM ET)

```
Two days in. Two reactions that pinned themselves to my fridge:

"first gym app I haven't deleted in week 1"
"the BW thing alone is worth the install"

Thanks to everyone who gave Unit a real shot under fatigue.
```

(230)

- **Media**: still of 1–2 real user replies/quote-tweets, faces and handles blurred unless you have explicit permission.
- **Why X**: social proof, specific quotes (not "great app"). Per `anti-patterns.md` — never invent quotes. These must be real.

### W3-T6 — Weekend wins (Sun 05-17, 9:30 AM ET)

```
Weekend Unit numbers, dashboard untouched:

[insert real W3 weekend installs]
[insert real W3 weekend trial starts]
[insert real W3 weekend paid]

Below the early-launch peak. Steady. Fine. Building for week 8,
not week 1.

Free core logging, forever.
```

(244)

- **Media**: small RevenueCat Charts still — weekend slice.
- **Why X**: numbers + long-game framing. Indie devs share the "building for the long term" stance.

### W4-T1 — First-week learnings (Tue 05-19, 10:30 AM ET)

```
One week post-launch.

What surprised me:
- Indie devs converted faster than lifters
- The 5-min "log a real set" demo video out-performed the polished
  hero clip
- Two installs from one Reddit comment > [insert real number] from
  paid ads I didn't run

Building, listening, free forever.
```

(269)

- **Media**: small bar chart — install source breakdown.
- **Why X**: counterintuitive findings travel. Indies forward to other indies.

### W4-T3 — Decision log: "I made this decision because…" (Sat 05-23, 9:30 AM ET)

```
I cut auto-progression from Unit before launch.

Every gym app's algorithmic "go up 2.5kg next session" is wrong
half the time, because no algorithm knows you slept 4 hours.

Ghost values stay. Lifters decide. The app's job is to log fast,
not to coach.
```

(257)

- **Media**: none.
- **Why X**: directly mined from `product-compass.md` decision log. Decision rationale > feature lists. Founders + designers quote-RT this kind of post.

---

# C. Engagement protocol

## Pinning order over the month

| Phase | Pinned tweet |
|---|---|
| W1 (04-29 → 05-04) | nothing (or W1-T1 if engagement is non-zero) |
| W2 (05-05 → 05-12) | W2-T2 (tester recruitment) |
| W3-T2 → W3-T3 (05-13 launch day) | W3-T2 launch tweet |
| W3-T4 onward | W3-T4 BIP thread (replaces launch tweet pin) |
| W4-T4 onward | W4-T4 retro thread (replaces BIP pin) |

**Rule**: keep the most recent thread as pin. Threads beat single tweets for the visit-profile-then-decide flow.

## Reply windows

- **First 2 hours after any pinned-slot tweet (W2-T2, W3-T2, W3-T4, W4-T2, W4-T4)**: reply to every quote-tweet, mention, and DM within 30 minutes. The first hour decides whether X amplifies the post.
- **Standard tweets**: check + reply within 4 hours. No need to camp the timeline.
- **Reply with substance, not "thanks!"**: answer their question, offer a TestFlight code, link a docs page (in reply, not body), or ask one follow-up.

## DM follow-ups

- W2 TestFlight DMs: every tester gets a personal "thanks for trying — what broke?" DM at T+5 days.
- W3 launch-week subscribers: identify the first 20 paid via RevenueCat, DM each: "you're a founding member, your rate is locked forever. What's broken or annoying?"
- Never auto-DM. Never use a DM tool. Manual.

## Thread-shape rule (single tweet vs thread)

- **Single tweet**: launch (W3-T2), pricing philosophy (W4-T2), short opinion (W1-T2, W4-T3), standalone numbers post (W3-T6, W4-T1).
- **Thread (≤5)**: build narrative (W3-T4 BIP), retro (W4-T4). Never more than 5. Per template 02 — engagement drops past 5.
- **Never**: launch-day thread. Single tweet hits harder on launch day. Thread on Thu (T+1) carries the narrative.

## Cross-channel timing

- X launch tweet (W3-T2 Wed 10am ET) is paired with the Reddit launch post (per `launch-plan.md` §3). Same day. The two audiences barely overlap, so cross-pollination is a non-concern.
- TikTok/IG demo videos (per `templates/tiktok-ig/`) lift their best clip into X's W2-T2 and W3-T6 slots — repurpose, don't double-post the same caption.

---

# D. X-specific anti-patterns (re-read before each post)

**No hashtags.** Anywhere. X de-prioritizes hashtagged posts in 2025–26. Tag a topic in the body if you must.

**No links in tweet body.** Links go in a reply within 30 seconds of posting (W3-T2, W2-T2). Exceptions: BIP thread T5 close, retro thread T5 close — link in last tweet of a thread is fine because thread context is the mitigation.

**No "Hi guys" / "Hey friends" / "Today I'm going to" intros.** Cut the throat-clear. Open with the claim.

**No engagement-bait.** Banned: "RT if you've ever quit Hevy", "tag a lifter who needs this", "reply with your last lift", "one like = one rep". Per `anti-patterns.md`.

**No tagging influencers.** No `@`-ing big indie devs asking for a boost. Mutuals can amplify on their own.

**No "🚨 LAUNCHING TODAY 🚨"**. No emoji-stuffed launch headers. The notebook angle is the launch energy. Per template 01 — slop signal.

**No "1/10" thread numbering**. X auto-numbers visually via the thread shape. Manual numbering reads forced.

**No "please retweet" calls.** Per template 02. Audiences who'd amplify do it without being asked; the rest never will.

**No competitor tagging.** Naming Hevy/Strong/Liftosaur in the body of a comparison is fine. `@`-ing their founders is combative — `anti-patterns.md`.

**No fake numbers.** Every metric in this calendar is `[insert real X]`. Never invent. Honest small > inflated big — per viral-patterns §1.

**No quote-tweeting your own old tweets multiple times.** W3-T3 (the "ICYMI" QT of W3-T2) is the only self-QT in this calendar. Don't overdo it.

**No "rethink" posts after a flop.** If W4-T2 pricing tweet flops, don't post a follow-up explaining or softening. Move on. Per template 03.

**No deletes.** If a tweet flops, leave it. Deleting reads as panic.

**No paywall-flip announcement framing.** Per `product-compass.md` — paywall-on is conditional, and the W4 pricing tweet must read as commitment, not announcement.

---

# E. Reply-protocol templates (3 ready-to-fire)

## E.1 — "What's your tech stack?"

```
SwiftUI + SwiftData + RevenueCat. Single target. Light-mode only,
portrait only. ~135-entry exercise library bundled. Local-first,
no CloudKit yet.

Built solo over 3 months. Happy to dig into any specific part.
```

(232)

- **When**: any reply or quote-tweet asking about stack. Most common question on X.
- **Why**: matches Tony Dinh playbook one-liner. Devs upvote the recognition. Inviting "any specific part" opens a sub-thread, which is engagement gold.

## E.2 — "Is this open source?"

```
Not open source. It's a paid app — $4.99/mo or $29.99/yr or
$44.99 lifetime, with a 7-day free trial. Core logging is free
forever, no trial gate.

Happy to share specific patterns (design system, ghost values
logic) on request — DM me.
```

(259)

- **When**: any "is this OSS" / "is the source available" / "GitHub link?" reply.
- **Why**: direct, honest, leaves no ambiguity. Re-states pricing inline (saves a follow-up). Offers a softer give ("share patterns") — preserves goodwill with the open-source crowd without lying.

## E.3 — "Why not Android?"

```
Solo dev, one OS at a time. iOS first because Apple Health, Live
Activities, and Lock Screen widgets are a big part of the
"3 seconds per set" UX.

Android is on the roadmap if Unit hits sustained traction. Not
promising a date.
```

(252)

- **When**: any "Android version?" / "any plans for Android?" / "what about Pixel?" reply.
- **Why**: honest scope-fence. Names the technical reason (Health/LA/widgets) — not "I'm lazy." Conditional roadmap framing matches `product-compass.md` style. Don't promise.

---

# F. Pre-post checklist (run before each tweet)

Tape this above your monitor for launch week.

- [ ] Body ≤ 280 chars (count visible in composer).
- [ ] No hashtags.
- [ ] No link in body (unless this is the close tweet of a thread).
- [ ] Media attached (or "no media" was deliberate, like W4-T2 pricing tweet).
- [ ] If pinned slot: reply with App Store link drafted, ready to send within 30s.
- [ ] No emoji-stuffed header.
- [ ] No "please retweet" / "tag a friend" / "RT if".
- [ ] No `@`-tagging of competitor founders.
- [ ] If thread: ≤5 tweets, image on T1–T4, link on T5 if needed.
- [ ] Numbers are real (no `[insert]` left in body).
- [ ] If pricing mentioned: $4.99 / $29.99 / $44.99 (NOT $9.99 / $49.99).
- [ ] If launch-day or BIP slot: 2 hours blocked after post for replies.

---

# G. See also

- `docs/marketing/templates/x/01-launch-tweet.md` — anchor for B.1
- `docs/marketing/templates/x/02-build-in-public-thread.md` — anchor for B.2
- `docs/marketing/templates/x/03-pricing-philosophy.md` — anchor for B.3
- `docs/marketing/research/viral-patterns-2026-04-29.md` §3 — Tony Dinh playbook (the reason this calendar leans on screen-records, stack one-liners, and small-real-numbers)
- `docs/launch-plan.md` §3 — launch-day channel ranking, market table
- `docs/pricing.md` — authoritative pricing source. Any change to $4.99 / $29.99 / $44.99 lives there first.
- `docs/product-compass.md` — decision log mined for W4-T3 ("I made this decision because…")
- `docs/competitors.md` — context for W1-T2 micro-rant and W3-T4 BIP thread T2
- `docs/marketing/anti-patterns.md` — read before launch week. The "no `@`-ing competitor founders" rule is in there.
- `PRODUCT.md` — voice guardrails. Launch-day variants A/B/C all conform; if you rewrite, re-check against PRODUCT.md voice.
