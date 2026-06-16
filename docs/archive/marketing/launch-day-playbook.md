# Unit — Launch-Day Playbook

> Single document covering hour-by-hour launch day (Wed 2026-05-13) and the four sub-playbooks: BetaList (W1 action), Show HN, Product Hunt, and iOS press. Companion to `docs/launch-plan.md` §3 and `docs/marketing/research/viral-patterns-2026-04-29.md` §8. When this conflicts with `launch-plan.md`, launch-plan wins — update there first, cascade here second.

**Use:** read once end-to-end during W1 prep. Re-read the relevant sub-playbook the day before each action. On launch day, the timeline (§E) sits open on a second monitor.

---

## A. BetaList submission (W1 action — submit Mon 2026-05-04)

BetaList still works in the pre-launch window. Per the 2026 viral-patterns research, expect **200–500 visitors and 15–20% email-to-signup conversion** on a clean submission. The whole point is to seed the first 50–100 TestFlight beta testers before Show HN / Product Hunt / Reddit go live in W3, and to get a permanent backlink for the marketing site.

### Timing

- **Submit:** Monday 2026-05-04 (W1 close, ~9 days before launch).
- **Why this date:** BetaList curators sit on submissions for 7–14 days. Submitting Mon 5/4 lands the listing live around Mon 5/11 to Wed 5/13 — overlapping the App Store launch window without colliding with Show HN.
- **Hard rule:** must submit **before** TestFlight goes public. The product must legitimately be in pre-launch when the curator opens the page.

### Tier — recommended: free

| Tier | Cost | Curator queue | Recommended? |
|---|---|---|---|
| Free | $0 | 7–14 days | **Yes** for Unit |
| Featured | $129 | Same-day | No — Unit's hook (calm/quiet/notebook-replacement) plays better as discovered than promoted; the paid badge cheapens it |

The "founding solo dev with a paper notebook" angle reads as authentic on the free tier and slightly mercenary if paid-promoted. Save the $129 for App Store Search Ads in W6 once retention data exists.

### Submission text (≈200 words — paste verbatim)

```
Unit — the gym logger that respects your program.

I'm an intermediate lifter who kept a paper notebook in the gym for six
years because every tracker felt slower than writing. Three months ago I
started building Unit — an iOS gym logger built around a single rule:
log a set in under three seconds, one-handed, sweaty, fatigued.

How it works: pre-fill the weight and reps from your last session as
ghost values. One tap confirms. The rest timer auto-starts and lives in
the Dynamic Island. No prescriptive AI coach. No social feed. No
algorithm telling you what to lift next. You bring the program — Unit
runs the loop.

Built solo in SwiftUI + SwiftData, local-first, no account required,
works in basement gyms with no signal. Light mode only. Portrait only.
Free core logging, forever — a Pro tier with CSV export, Apple Health
sync, custom icons, and Apple Watch (post-launch) is coming, with
founding-member pricing locked in for early signups.

I'm looking for the first hundred lifters who already know how to
train and want a tool that gets out of the way. TestFlight opens this
month. App Store ships in May.

Brutal feedback welcome. Reply if you want in.
```

### Image specs

| Field | Spec |
|---|---|
| Logo | 240×240 PNG, transparent background (Unit app icon — `Unit/Assets.xcassets/AppIcon.appiconset/AppIcon.png` exported at 240) |
| Cover image | 1200×630 PNG or JPG (≤2 MB), light background, single device frame angled, ghost-fill in motion as the foreground moment, no marketing copy on the image itself |
| Screenshot 1 | 1290×2796 (iPhone 6.9") — the "<3s set logged" hero, identical to App Store Screenshot 1 |
| Screenshot 2 | 1290×2796 — ghost-fill annotated arrow + "tap to confirm" label |
| Screenshot 3 | 1290×2796 — Dynamic Island rest timer in a real gym shot |

Reuse what `capture-app-store-screenshots.sh` produces. Do not generate a separate set — the cross-channel consistency is the point.

### Expected results

- 200–500 visitors over the first 72h after the listing goes live
- 15–20% click → email signup ratio (so ~30–100 emails)
- 3–10 organic TestFlight invites converted to active testers
- 1 permanent backlink (DR-46) for the marketing site

If the listing goes live and pulls under 100 visitors after 72h, the issue is the hook — rewrite the first sentence and ask a curator for a refresh. Don't pay to promote a weak hook.

---

## B. Show HN preparation (Wed 2026-05-13, 06:00 ET)

### Title format

Format: `Show HN: [name] – [one-line value claim, ≤80 chars]`

Three candidate titles (pick one Tuesday night, A/B test in your head — the one that makes you slightly nervous to post is the right one):

```
1. Show HN: Unit – Log a gym set in under 3 seconds, ghost values prefill last session
2. Show HN: Unit – I built a gym logger because every tracker was slower than my paper notebook
3. Show HN: Unit – A quiet, local-first iOS gym tracker for lifters who already know how to train
```

**Recommendation: #2.** Vulnerable confession + concrete artefact (paper notebook) + comparative claim. This is the structural template the viral-patterns research §1 says wins on r/SideProject and HN. #1 is too dry; #3 reads as marketing copy.

### Tuesday vs Wednesday morning ET

- **Tuesday morning ET (06:00–07:30):** highest HN traffic of the week. Slightly more competitive front page.
- **Wednesday morning ET (06:00–07:30):** roughly 80% of Tuesday traffic, ~30% less competition. **Recommended for Unit.**

Wednesday is also `launch-plan.md` §8's "ship a boring Wednesday" rule. Aligning Show HN with the Reddit + X + App Store launch on the same Wednesday means one news cycle, one set of replies to manage. Splitting Show HN to Tuesday means two days of high-alert reply duty back to back — bad for solo execution.

**Decision: Wed 2026-05-13, 06:00 ET.**

### First-comment template (founder, ≈150 words — post within 60 seconds of submission)

```
Hey HN — Unit's solo dev here.

Stack: SwiftUI + SwiftData, local-first, no backend. RevenueCat for the
Pro subscription wired in last week. Light mode only, portrait only,
iPhone-only at v1. ~3 months of evenings and weekends to ship.

The single thing I built around: log a completed set in under 3
seconds, one-handed, fatigued. Pre-fill weight + reps from last session
as ghost values; one tap confirms. Rest timer auto-starts and surfaces
in Dynamic Island. No coach, no AI plan generator, no social feed — you
bring the program, Unit runs the loop.

Honest open questions I'd love HN to push on:
- Pricing: free core forever, $9.99/mo or $49.99/yr Pro with a 7-day
  trial. Too high for a single-platform indie? Too low?
- The decision to ship without CloudKit / Apple Watch at v1. Worth it?
- SwiftData in production at this scale — what's biting you?

Brutal feedback welcome. Won't argue, will read every reply.
```

### Pre-launch checklist (run Tuesday 5/12 evening, 18:00 ET)

- [ ] App Store listing live and approved (downloadable from a real iPhone — verify, don't trust the App Store Connect dashboard alone)
- [ ] App Store URL copied to clipboard and to launch-day notes file
- [ ] `support@tryunit.app` (or final domain) sends + receives a real email; auto-reply set to "I read every email — replies within 24h"
- [ ] RevenueCat dashboard logged in, subscription products live, sandbox purchase tested
- [ ] App Store Connect → Analytics + Sales and Trends accessible (mobile + desktop)
- [ ] HN account ≥1 year old with ≥10 karma — if fresh account, post anyway but expect throttling
- [ ] First-comment text in clipboard, ready to paste in <60s after submission
- [ ] Marketing site `#download` link points to real App Store URL (not the placeholder)
- [ ] `app/(marketing)/privacy/page.tsx` and `terms/page.tsx` show the final domain email
- [ ] Loom 60s product demo recorded and uploaded (URL ready for cold emails — see §D)

### Post-launch reply protocol

**First 2 hours (06:00–08:00 ET):** reply to every comment within 10 minutes. The HN front-page algorithm weights early reply depth heavily — comment activity in the first 90 minutes is what pushes a Show HN from page 3 to page 1.

**Hours 2–6 (08:00–12:00 ET):** reply within 30 minutes. Step away from Reddit and X during this window — HN is the priority while it's still moving.

**Hours 6–24:** reply within 2 hours. By hour 6, the post will either be on the front page (in which case, keep replying) or buried (in which case, see "doesn't make front page" below).

**Reply rules:**
- Don't argue. If a reply pushes back, restate their point in your own words and answer the question directly.
- "Why not Hevy?" gets a calm, factual answer about positioning and ICP, not a competitor takedown. Hevy's founder reads HN.
- Pricing questions: cite the free-core-forever commitment and the founding-member lock-in. Don't apologize for the Pro price.
- Bug reports in comments: ask for `support@` so the public thread doesn't fragment. Reply once publicly: "Sent you an email — fixing this tonight."

### What to do if it doesn't make the front page

This will likely happen — most Show HN posts do not. Plan for it.

- **Don't repost.** HN bans for it within a week.
- **Don't delete.** A page-3 Show HN with 8 thoughtful comments is a permanent backlink and a credible artefact for cold outreach to writers in §D. Keep it up forever.
- **Don't ask friends to upvote.** HN's vote-ring detection bans both your account and theirs. The damage to credibility is permanent.
- **Don't pay any "HN booster" service.** They exist; they all get banned within 90 days; your account goes with them.
- **Do** screenshot the post (with whatever upvote count it landed at) for the W3 retro. Even a 4-upvote Show HN is a useful artefact for the "I shipped publicly" narrative on X and Reddit.
- **Do** quote the most useful comment in your W3 metrics review and credit the commenter by handle when you respond to it on X.

The Show HN is a 4-hour bet, not a 4-day bet. Move on by lunchtime.

---

## C. Product Hunt prep

### Tuesday slot decision

Product Hunt launches happen on a 24h cycle starting at **00:01 PT (03:01 ET) daily**. Unit's "ship a Wednesday" rule means:

- **Tuesday slot (PT):** the listing actually goes live Mon 23:01 PT and runs until Tue 23:01 PT. Highest weekday traffic.
- **Wednesday slot (PT):** runs Tue 23:01 PT → Wed 23:01 PT. ~80% of Tuesday traffic but aligns with the App Store launch and Show HN.

**Decision: Wednesday slot.** Schedule the PH launch for 00:01 PT Wed 2026-05-13 (= 03:01 ET). By the time you're at the keyboard at 06:00 ET to post Show HN, PH has been live ~3 hours.

**Avoid Mondays** — the makers' rush plus weekend backlog plus PH staff catch-up means PH itself is buggy on Mondays and your launch competes with everything held over from the weekend.

### Hunter recruitment in 2026 — current best practice

Per the 2026 research (`viral-patterns-2026-04-29.md` §8): **a "famous hunter" carries far less weight in 2026 than 2020–2022.** The PH algorithm weights subscriber count of the maker's own audience and first-hour upvote velocity; a hunter with 50k followers but no engagement-history adds ~5–10% lift, not the 3× of the early years.

**Default: hunt yourself.** As the maker, list yourself as the hunter. This costs you nothing, is the honest framing, and avoids the awkward "thanks to [hunter] for hunting Unit!" intro that everyone now correctly reads as a paid favor.

**Only seek a hunter if:** you can get someone whose audience genuinely overlaps with intermediate lifters (rare in PH — most top hunters cover SaaS / dev tools). Tony Dinh, Jason Leow, Maker Lemon — none of these will move the needle for a fitness logger. Don't beg.

### First-comment template (≈150 words — post within 60 seconds of going live, ~03:01 ET)

```
Hey Product Hunt — Unit's maker here.

I've been a lifter for six years and a developer for ten. Every gym
tracker I tried was either a spreadsheet pretending to be an app or
a social feed pretending to be a tool. So I went back to a paper
notebook for two years before deciding to build the thing I actually
wanted.

Unit is a calm, local-first iOS gym logger. Pre-fill last session's
weight and reps as ghost values. One tap confirms. The Dynamic Island
runs the rest timer. No coach, no plan generator, no social feed.

Free core logging, forever. Pro is $9.99/mo or $49.99/yr with a 7-day
trial — adds CSV export, Apple Health sync, custom icons. Founding
members who subscribe this month keep their rate forever, even on
future price rises.

Built solo in 3 months. Honest feedback welcome. App Store link below.
```

### Tagline + description + first 3 lines (≤60 chars / ≤260 chars)

Tagline must be ≤60 chars, description ≤260. PH Best Practice 2026: load the tagline with the value claim, not the brand voice.

#### Variant 1 — "Speed-first" (recommended)

```
Tagline:     Log a gym set in under 3 seconds.
Description: Unit is a calm, local-first iOS gym logger. Pre-fill last
             session's weight and reps. One tap confirms. Dynamic
             Island rest timer. No coach. No social feed. Free core
             logging, forever. Built solo in 3 months.
First 3 lines (gallery caption / above-the-fold):
  1. Log a set in under 3 seconds, one-handed.
  2. Ghost values prefill from your last session.
  3. No AI coach. No feed. Just sets.
```

#### Variant 2 — "Notebook replacement"

```
Tagline:     Your gym notebook, upgraded.
Description: For lifters who already know how to train. Unit replaces
             the paper notebook and Notes app with sub-3-second set
             logging. Local-first iPhone app. Free core logging
             forever. Pro adds CSV export and Apple Health sync.
First 3 lines:
  1. The notebook is faster than every gym app — until now.
  2. One tap to confirm last session's weight and reps.
  3. Local. Quiet. Yours.
```

#### Variant 3 — "Anti-bloat"

```
Tagline:     The gym tracker that doesn't talk to you.
Description: No AI coach. No social feed. No streak guilt. Unit logs
             your sets in under 3 seconds and gets out of the way.
             Local-first iOS, built solo, free core logging forever.
First 3 lines:
  1. Every gym app got louder. Unit got quieter.
  2. Log a set in under 3 seconds. That's the feature.
  3. No coach, no feed, no algorithm. You bring the program.
```

**Recommendation:** Variant 1 for PH (PH audience indexes on speed claims). Variant 2 for Reddit and the marketing site. Variant 3 is for X reply-bait when someone asks "why another gym app?" — keep it in the X drafts file.

### Image gallery (5–10 images)

| # | Image | Source |
|---|---|---|
| 1 | Hero: "Log a set in <3s" — single device frame, ghost-fill mid-tap | App Store Screenshot 1 |
| 2 | Ghost values annotated — arrow pointing to prefilled weight + reps | App Store Screenshot 2 |
| 3 | Dynamic Island rest timer — real gym shot, iPhone in hand | App Store Screenshot 3 |
| 4 | Templates view — Push/Pull/Legs as a clean list, no "Day N" prefix | App Store Screenshot 4 |
| 5 | History calendar — month view, PRs marked subtly | App Store Screenshot 5 |
| 6 | App Store preview video (15s, Screen Studio) — autoplays muted | Video |
| 7 (optional) | Side-by-side: paper notebook vs Unit, same workout | DIY photo |
| 8 (optional) | "Built solo in 3 months — here's the stack" — text card with SwiftUI/SwiftData/RevenueCat logos | Designed in Figma |

Skip 9–10 unless there's something genuinely new. PH gallery scroll-depth drops off a cliff after image 5; padding hurts.

### Pre-launch nudge sequence (W2–W3)

PH counts subscribers. Subscribers get a notification when the launch goes live. **The PH first-hour upvote count is mostly subscriber conversion, not organic discovery.**

**W2 Mon 5/04** — set up the upcoming-launch page on Product Hunt. Post the URL once on:
- Personal X (one tweet — "if you hated every gym app, subscribe here, I'm shipping in 9 days")
- Personal LinkedIn (only if you have one with >300 connections; otherwise skip)
- Discord server when it opens (W2 mid-week)

**W2 Fri 5/08** — DM the 20 TestFlight beta testers. One personal sentence each plus the subscribe link. Goal: 20 subscribers from this list alone.

**W3 Mon 5/11** — post a Reddit r/SideProject build-update with "I'm launching Wed on Product Hunt — subscribe here so I don't tank" as the close. Per `docs/marketing/templates/reddit/01-launch-week.md`, this is a legitimate W3 use of the cap.

**W3 Tue 5/12 evening** — DM every TestFlight tester one more time. "Live in ~7h on PH. Upvote when you wake up if you've been using it daily." No begging, no "please" — direct and short.

**Realistic subscriber goal:** 50–100. That's enough for a PH "Top 10 of the Day" finish in the indie iOS / fitness category. **Top 5 is unrealistic; it requires a hunter with paid distribution networks.** Don't target it.

### Realistic expectations (set these before going live so the W3 retro is honest)

- 100–500 visitors to the PH page over 24h
- 5–25 click-throughs to App Store
- 0–4 paying subscriptions converted in the first 7 days
- 0 mentions in tech press from PH alone (PH press pickup is a 2020 phenomenon)
- 1 permanent badge for the marketing site (real value)

### Skip-this-launch criterion — when NOT to do PH

Skip Product Hunt entirely if **any** of these are true on Tuesday 5/12 evening:

- App Store rejected and not yet re-approved → push the entire launch +1 week (see §G)
- TestFlight beta count <15 active testers (you don't have a credible "founding members are using this" proof yet — the PH skeptics will sniff it out in 90 minutes)
- You're sick, exhausted, or otherwise unable to be at the keyboard for 12h on Wednesday — PH without continuous reply effort lands worse than no PH at all
- Show HN is already underway from Tuesday morning → **wait one week**, do PH solo on Wed 5/20

If skipping PH: keep the Show HN + Reddit + X path on Wednesday. PH is the most expendable channel in the four.

---

## D. iOS press contact list

### The 3-line email rule

Subject line specific to one Unit angle. Body **≤3 lines**. One Loom link. Email signature with name + role + Unit URL.

That's it. Anyone in tech press in 2026 receives 80–200 cold pitches a day. Anything over 3 lines gets archived in <2 seconds. Get the angle to the writer in the first 8 words of the subject line, the proof to them in 30 seconds of Loom.

### Outlets to pitch (15 outlets — verify writer names before sending)

| # | Outlet | URL | Best contact (verify) | What they cover | Recent indie iOS coverage |
|---|---|---|---|---|---|
| 1 | MacStories | macstories.net | Federico Viticci | Indie iOS apps, app reviews, Apple ecosystem | Strong indie coverage; club members get more attention |
| 2 | The Sweet Setup | thesweetsetup.com | Shawn Blanc | "Best app for X" reviews; productivity-leaning | Quarterly indie roundups; verify before sending |
| 3 | Six Colors | sixcolors.com | Jason Snell, Dan Moren | Apple ecosystem, indie dev features | Occasional indie features; flag verify |
| 4 | Daring Fireball | daringfireball.net | John Gruber (link blog only) | Apple ecosystem, link blog | Link only — no review pitches; one-line intro acceptable |
| 5 | 9to5Mac | 9to5mac.com | Chance Miller, Michael Potuck | Apple news, app launches, App Store | Regular indie iOS coverage; high-volume writer pool |
| 6 | iMore | imore.com | Daryl Baxter | iOS app reviews, ecosystem | Indie iOS section; verify writer is still there |
| 7 | AppAdvice | appadvice.com | Tyler Tschida | iOS app reviews, daily roundups | Daily indie roundups — easier hit than feature |
| 8 | Inputmag | inputmag.com (parent: Mic) | Joshua Topolsky-era alums | Tech + culture; indie product features | Rare but high-impact when it lands |
| 9 | TechCrunch (indie/iOS) | techcrunch.com | Sarah Perez (apps beat) | App launches, indie + early-stage | Indie iOS gets occasional coverage on slow news days |
| 10 | The Verge (apps) | theverge.com | Jay Peters, Wes Davis | Consumer tech, app launches | Rare for indie iOS; only worth a pitch if angle is sharp |
| 11 | App Store Stories (Apple Editorial) | apps.apple.com/story/... | n/a — apply via App Store Connect | Featured app stories | Slow, opaque, but the highest-conversion outlet on this list |
| 12 | Indie Hackers | indiehackers.com | Self-publish (no editor) | Founder stories, MRR transparency | Self-serve — write the post yourself |
| 13 | Out of Beta podcast | outofbetapodcast.com | Jason and Matt | Indie app dev, launch stories | Episode angle: "shipping a fitness logger solo in 3 months" |
| 14 | Indie Hackers Podcast | indiehackers.com/podcast | Courtland Allen | Solo founder journeys | Bar is high; need a sharp single-angle pitch |
| 15 | Fully Charged (relay.fm) | relay.fm/fullycharged | Federico Viticci, Myke Hurley | Apple ecosystem, productivity apps | Audience overlap is real but small |

**Flag — none of the "recent indie iOS coverage" cells should be trusted without a 5-min check on the outlet's homepage the day you send. Writers churn fast in tech press; the outlet's beat survives but the byline does not.**

**Outlets explicitly excluded and why:**
- **ATP (relay.fm)** — too big; they don't review indie apps for non-acquaintances
- **AppSliced, Appitalist** — low traffic, low domain authority; the backlink isn't worth the email
- **TechCrunch general** — different from "TechCrunch indie" — the general newsroom won't cover a $0 MRR launch

### Cold email templates

#### Template 1: "Shipped today" pitch

Use within 24h of App Store going live. Sent to: 9to5Mac, AppAdvice, MacStories (link blog candidates), iMore.

```
Subject: Shipped today: Unit, an indie iOS gym logger built around <3s sets

Hi [Name],

Solo dev — shipped Unit on the App Store today. It's a quiet, local-first
gym logger built around one rule: log a set in under 3 seconds, one-
handed, fatigued. 60s Loom: [LOOM_LINK]

Happy to answer any questions. Free download: [APP_STORE_LINK]

— [Your name]
Unit · [domain]
```

3 lines of body. One Loom. One App Store link. Done.

#### Template 2: "Feature angle" pitch

Use within 7 days of launch. Sent to: MacStories, Six Colors, The Sweet Setup. The angle here is not "we shipped" — it's a specific Unit-only thesis worth a feature.

```
Subject: Why every gym app got louder — and what a quiet one looks like

Hi [Name],

I built Unit because every gym tracker added an AI coach, a social feed,
and a streak system in the last 18 months — and I wanted the opposite. A
60s Loom shows the design philosophy in motion: [LOOM_LINK]

Worth 600 words on minimalism in fitness apps in 2026? Free download
here: [APP_STORE_LINK]

— [Your name]
Unit · [domain]
```

3 lines, one Loom, one App Store link, one specific editorial pitch ("600 words on minimalism in fitness apps").

#### Template 3: "Podcast guest" pitch

Use within 14 days of launch. Sent to: Out of Beta, Indie Hackers Podcast, Fully Charged.

```
Subject: Solo dev shipped indie iOS gym logger in 3 months — guest pitch

Hi [Name],

Built Unit alone in 3 months and shipped to the App Store [date]. Open
to walking through the SwiftUI/SwiftData/RevenueCat stack, the "free
core forever" pricing call, and what I cut from v1. 90s Loom intro:
[LOOM_LINK]

Pitching as a guest if there's a slot. Otherwise, App Store: [LINK].

— [Your name]
Unit · [domain]
```

3 lines, one Loom, one specific pitch ("guest if there's a slot"). The Loom should include 30s of you talking on camera at the start so the host can hear how you sound.

### Outreach pacing

- **Day of launch (Wed 5/13):** send Template 1 to outlets 5, 7 (high-volume, fast-cycle). Two emails total. Don't blast.
- **Day +2 (Fri 5/15):** send Template 2 to outlets 1, 2, 3 (slow-cycle, feature-track). Three emails.
- **Day +7 (Wed 5/20):** send Template 3 to podcasts (13, 14, 15). Three emails.
- **Day +14 (Wed 5/27):** if no replies, do **not** follow up — the silence is the answer. One follow-up to outlets that opened the email (track via Mixmax or Mailchimp tracking pixel) is acceptable; multi-touch sequences burn the relationship for v2.

Total emails over 14 days: ~12. Reply rate realistic: 1–3. Coverage realistic: 0–2 outlets. **The list is not the deliverable; the discipline is.**

---

## E. Launch-day timeline — Wed 2026-05-13 (Eastern Time)

All times Eastern. Set a phone alarm for each row. Treat this as the only document open between 06:00 and 20:00 — close Slack, close Discord, leave the laptop on the desk, no errands.

| Time (ET) | Action | Detail |
|---|---|---|
| 03:01 | Product Hunt goes live (auto, scheduled W2) | No action — it's already running |
| 05:30 | Wake up. Coffee. No social media yet | Wake. Eat. Don't open Twitter |
| 05:45 | Final pre-flight check | Re-verify §B checklist. App Store live? Loom URL still works? RevenueCat dashboard up? Support email working? |
| 06:00 | **Post Show HN** | Submit per §B. First comment in clipboard, paste within 60s |
| 06:15 | Confirm Show HN posted, first comment showing | Screenshot HN URL for the W3 retro file |
| 06:30 | Quiet window — eat, stretch | Don't refresh HN every 30s. Set a 30-min timer |
| 07:00 | First HN replies | Reply to anything that's posted. 10-min cadence |
| 08:00 | **Post Reddit r/SideProject** | Use `templates/reddit/01-launch-week.md` verbatim. Real RevenueCat dashboard screenshot at $0 MRR — that's the artifact |
| 08:15 | **Post launch tweet on X** | Use `templates/x/01-launch-tweet.md`. Pin to profile |
| 08:30 | App Store link in Reddit first-comment + X reply | Reddit body has no link; first comment by OP does. X first reply has the link |
| 08:30–09:00 | Cross-channel reply window | HN + Reddit + X simultaneously. 10-min cadence anywhere a comment lands |
| 09:00 | **Product Hunt status check** | PH is ~6h live. Note current upvote count, top 3 comments, any Maker comments to reply to. 5 min only — don't camp PH |
| 09:30 | First metrics snapshot | Open notes file. Log: HN upvotes, Reddit upvotes, X impressions, PH upvotes, App Store visits (will lag ~1h) |
| 10:00 | Continuous reply window | HN + Reddit + X + PH. 10-min cadence. The next 60 min is when most comments arrive |
| 11:00 | **First metrics check (real)** | RevenueCat: trial starts? App Store Connect: install count? App Analytics: impressions → conversion. Log to notes file. Don't tweet metrics yet |
| 11:30 | Send Template 1 cold emails | Two outlets only — 9to5Mac and AppAdvice (per §D pacing). Loom link + App Store link |
| 12:00 | **Post BIP X thread** | Use `templates/x/02-bip-thread.md`. Quote the earliest interesting HN/Reddit reply with credit. Image = real RevenueCat dashboard |
| 12:15 | Lunch — away from the desk for 30 min | Hard rule. The replies will keep landing. They survive 30 min |
| 12:45 | Resume reply cadence | HN replies, Reddit, X, PH. 10–15 min cadence (slowing from peak) |
| 13:00–17:00 | Continuous engagement window | Reply to everything. Move bug reports to support@ email. Move feature requests to Discord (open the channel if not already). Avoid arguing |
| 13:30 | Discord server open (if not already) | Pin the W3 launch summary. DM the link to TestFlight testers. Cap intake at 100 |
| 14:30 | First TikTok of the day (optional but high-leverage) | 30s screen-record of one ghost-fill confirmation, no music, no voiceover. Caption: "Day 1 on the App Store. [link in bio]" |
| 15:00 | LifeOS Türk crossover post (one — Turkish) | Per `launch-plan.md` §3 W2 — *"3 aydır geliştirdiğim spor uygulaması bugün App Store'da..."*. One paragraph, App Store link, that's it |
| 16:00 | Reply triage — close the loops | Anyone whose question you punted to support@: send the email now. Anyone whose feature request needs the 5-user-rule treatment: log it in the feature-requests file |
| 18:00 | **Second metrics check** | Same metrics as 11:00. Write the 1-line summary now. Format: "Day 1: [N] installs, [M] trial starts, [K] HN upvotes, [J] PH upvotes, [I] Reddit upvotes." File in W3 retro |
| 18:30 | Eat dinner away from screens | Hard rule. The replies survive 60 min |
| 19:30 | Final reply window | One pass through HN, Reddit, X, PH. Reply to anything from the last 4h |
| 20:00 | **Wind-down** | No new posts after 20:00 ET (reply only — no fresh threads). Plan W4: write tomorrow's 3 bullets in the Sunday-cadence notes file |
| 21:00 | Phone in another room. Sleep | Brain is going to want to check at 23:00 and 03:00. Don't |

**The discipline:** never post a fresh thread after 20:00 ET on launch day. The launch is a 14-hour window, not a 36-hour window. Sleep matters more than two more replies.

**The trap:** doom-refreshing HN at 21:30. The post is either on page 1 or page 4. Refreshing changes nothing. Phone goes in the other room.

---

## F. W3+1 day — Thursday 2026-05-14

The post-launch day matters almost as much as launch day. This is when Reddit's launch-week cap on r/iosapps actually fires (kept separate from r/SideProject per `templates/reddit/01-launch-week.md`).

| Time (ET) | Action | Detail |
|---|---|---|
| 06:00 | First check — light only | HN drift, Reddit thread depth, X reply count. 10 min total. No replies yet |
| 09:00 | **Post Reddit r/iosapps** | New post — *don't* recycle the r/SideProject body. Lead with "App Store launch yesterday, [N] installs in 24h, here's what I learned." Screenshot of App Store Connect Day-1 install graph |
| 09:30 | App Store Connect link in r/iosapps first comment by OP | Same pattern as r/SideProject |
| 10:00 | Continued X engagement | Reply to anyone in the launch tweet thread who's posted overnight. Quote-RT one or two interesting replies (not all) |
| 11:00 | **TestFlight tester DM follow-ups** | One personal DM to every TestFlight tester who logged ≥3 sessions. "App Store live yesterday — would love a 30-second review if you've got time." No begging |
| 12:00 | Day-2 metrics snapshot | Same fields as launch day. Compare to 24h-prior numbers. Log to W3 retro file |
| 14:00 | Send Template 2 cold emails | Three outlets — MacStories, Six Colors, The Sweet Setup (per §D pacing). Feature angle |
| 15:00 | First Discord reply pass | Reply to every post in #bugs, #feature-requests, #show-off-your-lifts. ≥1 reply per channel. Set the response-time tone for the next 60 days |
| 16:00 | One more TikTok | Different angle from Day 1. "Day 2: here's what broke." Honest, screen-record only, no music |
| 18:00 | Second metrics check + Day 2 summary | Append to W3 retro file. Format: "Day 2: [N] installs (delta vs Day 1), [M] trial starts, [K] Discord members, [J] reply-cycle median time." |
| 20:00 | Wind down — same rule as launch day | No fresh threads after 20:00. Phone in another room |

**Carryover into the rest of W3:**
- Fri 5/15: send Template 2 to remaining feature outlets, post one TikTok, reply pass on all channels
- Sat 5/16: rest. Reply only. No fresh threads
- Sun 5/17: weekly metrics review per `cadence.md`. Three questions. One thing to ship next week

---

## G. Failure-mode contingencies

Things that break, and the response. Read this in W2 so the playbook is in muscle memory by Tuesday 5/12.

### App Store rejected on Tue 2026-05-12

**Action:** push the entire launch +1 week to Wed 2026-05-20. Don't try to ship a half-launch.

- Cancel the Product Hunt launch immediately (PH allows pre-launch unscheduling without penalty if done 12h ahead)
- Don't post Show HN, Reddit, or the launch tweet on 5/13. Anything that goes out without a working App Store link burns the credibility once and forever
- Reply to the App Store reviewer within 4h with the fix
- Resubmit by Fri 5/15. Apple's average reapproval is 24–48h
- Re-schedule PH for the following Tuesday 5/19 night → live Wed 5/20
- Re-run the §B Tuesday-evening pre-flight checklist

The launch isn't ruined; it's delayed. Most iOS rejections are mechanical (privacy disclosures, IAP descriptions). The 2026-05-13 date is not sacred — the discipline of shipping cleanly is.

### App Store approved early but reviewer flags an issue post-approval

(E.g. Apple Developer Relations sends a "we noticed X" email between 5/12 evening and 5/13 morning.)

**Action:** patch + resubmit with expedited review request, but don't pause launch unless the issue is reachable from the user's first session.

- Triage the issue: is it user-visible in the first 30s? If yes, pause launch and resubmit. If no (e.g. Apple flagged a metadata description), proceed with launch and ship a patch on 5/14
- Document the call in the W3 retro file — Apple's post-approval flags are common and rarely launch-breaking, but they need to be answered

### Reddit launch shadowbanned

(Symptom: r/SideProject post still visible to you when logged in but invisible in incognito mode 30 min after posting.)

**Action:** **don't repost.** Move the Reddit launch volume to r/iosapps on Thu 5/14, and post once on r/homegym Thu evening with a different angle (per the `viral-patterns-2026-04-29.md` §6 finding that r/homegym is unusually app-friendly).

- Don't try to "fix" the shadowban by editing the post. Reddit doesn't unflag for edits
- Don't argue with mods in modmail unless you can show the post follows their self-promo rules verbatim. r/SideProject is famously lenient; if it shadowbans, the issue is account history (low karma + first post + URL = auto-flag)
- Don't repost from a different account. That's a permanent ban
- The r/SideProject loss is real. The launch isn't — Show HN + X + PH carry the day, Reddit fires Thursday from a different sub

### Show HN dies on page 4

**Action:** see §B "What to do if it doesn't make the front page." TL;DR: don't repost, don't delete, don't pay any boost service. Move on by lunchtime and document the post URL for the W3 retro.

### Zero installs in first 12h

(Definition: <5 installs visible in App Store Connect by 18:00 ET on 5/13.)

**Action:** **don't panic-edit the App Store listing.**

- Don't change the screenshots, description, or icon at 18:00 ET on launch day. The data is too thin to draw any conclusion
- Don't drop the price (not that there is one — but resist the impulse to add a "first 100 users free" promo — `launch-plan.md` §8 is explicit about not changing pricing without data)
- Do post a single calm reply to anyone in any channel asking "how's it going?" with the honest number: "Day 1 numbers are quiet — building over the week." Honest beats spinning
- Sunday 5/17 weekly review per `cadence.md` is when the Day-1 number gets interpreted, not Wednesday evening. Three questions: what did the metrics say, what was the loudest signal, what ships next week
- If Day 7 shows <30 installs total, the issue is distribution (per `launch-plan.md` §5) — double the content cadence in W4. Not a pricing or product issue at this scale

### Bonus: Day 1 goes too well (>500 installs, support@ overflow)

(Less likely but planning for it now is free.)

**Action:**
- Do not announce a "version 2" or new feature. Stay disciplined per `launch-plan.md` §8 — feature work waits on the 5-user rule and the Sunday review
- Reply to support@ with one canned response within 1h: "I'm a solo dev — I read every email. Replies within 24h." Then actually reply within 24h
- Cap Discord intake at 100 per the original plan. The 101st request gets a polite "Discord is at capacity for the first cohort — joining the waitlist."
- Do not raise prices. Do not retroactively pull the founding-member offer. Both burn credibility for a Day-1 dopamine hit

---

## Closing reminders

- **Wednesday 5/13 is one news cycle.** Show HN + Reddit + X + PH all on one day. Press emails staggered over 14 days.
- **The four channels are independent failure-mode wise.** PH can flop while Show HN works. r/SideProject can shadowban while r/iosapps lands. Plan for none of them and be surprised by any of them.
- **Sleep matters more than two more replies.** Hard wind-down at 20:00. Phone in another room at 21:00.
- **The discipline is the deliverable.** This document exists so you don't have to think during the 14 hours that matter. Reread §E the morning of 5/13. Don't improvise.

When this conflicts with `launch-plan.md`, launch-plan wins. When this conflicts with `templates/reddit/01-launch-week.md` or `templates/x/01-launch-tweet.md`, the templates win for copy — this document only sets the timing.
