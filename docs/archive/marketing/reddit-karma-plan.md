# Reddit pre-launch karma plan

> Three-week karma runway for the W3 BIP launch (~2026-05-13). The Reddit account fires the BIP post in `templates/reddit/01-launch-week.md` from a profile that already looks like a person — not a fresh account dropping a link.
> Source-of-truth: `docs/marketing/reddit.md`, `docs/marketing/anti-patterns.md`, `docs/marketing/research/viral-patterns-2026-04-29.md` §1 + §6.

## Why this exists

A Reddit account that fires its first post in r/SideProject as a build-in-public launch — with zero comment history, no karma in the surrounding subs, and an App Store link in the first comment — gets pattern-flagged. Even when the post itself is honest, the algorithm treats new-account-+-link-+-self-promo as the textbook spam shape. The post lands in /new with two upvotes, never breaks into /hot, and the launch is over before it starts.

The fix is unglamorous: spend 15-30 min/day for ~14 days commenting in the subs you'll later post into. Build a thin but real comment trail. Get to a karma threshold that signals "this account is a person who reads this sub" rather than "this account exists to promote one app."

This document is the playbook for those 14 days. The Unit name does not appear in any of these comments. We are not seeding, not pre-marketing, not warming an audience for the launch post. We are building one number — comment karma per subreddit — that lets the W3 launch post survive the spam filter.

---

## A. 3-week pre-launch schedule (W0 → W2)

> W0 starts Wed 2026-04-29. W3 launch fires Wed 2026-05-13. Time cap: 30 min/day max, ideally 15.
> Target rule: 1-3 comments/day, never more. Ten comments in one evening is a pattern; one comment per evening across two weeks is a person.
> Karma targets are cumulative across the whole runway, not per day.

### Week 0 (W0): Wed 2026-04-29 → Tue 2026-05-05 — warm the indie subs

The cheapest karma is in r/SideProject and r/microsaas because the audience is small, friendly, and reciprocal. Start there.

| Day | Date | Sub(s) | Thread type to find | Comments | Daily time | Cumulative karma target |
|---|---|---|---|---|---|---|
| Wed | 2026-04-29 | r/SideProject | "I built X, what would you build next?" / "first $N MRR" / "is my pricing too low?" | 2 | 20 min | 10-20 r/SideProject |
| Thu | 2026-04-30 | r/SideProject + r/microsaas | r/SP "feedback wanted" thread, r/microsaas churn/pricing thread | 2 | 20 min | 25-40 r/SP, 5-10 r/microsaas |
| Fri | 2026-05-01 | r/iOSProgramming | SwiftUI / SwiftData / RevenueCat technical questions in /new | 1-2 | 15 min | +5-10 r/iOSProgramming |
| Sat | 2026-05-02 | r/iOSProgramming | Showcase Saturday thread — comment, don't post | 1 | 15 min | +5-10 r/iOSProgramming |
| Sun | 2026-05-03 | r/homegym | Equipment-buying thread or training-frequency thread | 1 | 15 min | +2-5 r/homegym |
| Mon | 2026-05-04 | r/microsaas | Pricing teardown / "why nobody pays" thread | 1-2 | 20 min | 50-70 r/SP, 15-25 r/microsaas |
| Tue | 2026-05-05 | r/SideProject + r/iosapps | r/SP weekly feedback, r/iosapps "what app do you wish existed" | 2 | 25 min | 70-100 r/SP, 5-15 r/iosapps |

End of W0 target: ~70 karma r/SideProject, ~20 r/microsaas, ~10-15 r/iOSProgramming, ~10 r/iosapps, ~3 r/homegym.

### Week 1 (W1): Wed 2026-05-06 → Tue 2026-05-12 — cross the threshold

This is where you push r/SideProject past the unwritten "this account is real" karma threshold (~100), get r/microsaas above ~50, and start your slow burn in the gym subs.

| Day | Date | Sub(s) | Thread type to find | Comments | Daily time | Cumulative karma target |
|---|---|---|---|---|---|---|
| Wed | 2026-05-06 | r/SideProject | High-engagement post from earlier today (≤2hr old) on indie marketing or ASO | 2 | 25 min | 100-130 r/SP |
| Thu | 2026-05-07 | r/microsaas + r/iOSProgramming | r/microsaas churn data thread; r/iOSProgramming SwiftData migration thread | 2 | 25 min | 30-45 r/microsaas, 15-25 r/iOSProgramming |
| Fri | 2026-05-08 | r/iosapps | App-discovery thread or "underrated apps" thread | 1 | 15 min | +10-15 r/iosapps |
| Sat | 2026-05-09 | r/homegym + r/iOSProgramming | r/homegym equipment thread; r/iOSProgramming Showcase Saturday | 2 | 20 min | +5 r/homegym, +5-10 r/iOSProgramming |
| Sun | 2026-05-10 | r/Fitness OR r/weightroom | Form-check thread (pure value, zero app context) | 1 | 25 min | +2-5 r/Fitness/wr |
| Mon | 2026-05-11 | r/SideProject + r/microsaas | "What I learned" recap thread; r/microsaas pre-launch checklist thread | 2 | 25 min | 130-170 r/SP, 50-80 r/microsaas |
| Tue | 2026-05-12 | r/SideProject (light) — eve of launch | One last reciprocal comment on a fresh post; do NOT touch the W3 BIP post yet | 1 | 10 min | 150-200 r/SP holding |

End of W1 target: ~150-200 karma r/SideProject, ~50-100 r/microsaas, ~25-50 r/iOSProgramming, ~20-30 r/iosapps, ~8-10 r/homegym, ~5-8 r/Fitness OR r/weightroom.

### Launch day: Wed 2026-05-13 (W3)

- Don't comment in r/SideProject in the 6 hours before the post. The algorithm reads back-to-back activity from the same account on the same sub as engagement spam.
- Post per `templates/reddit/01-launch-week.md`. Link in first comment, not body.
- Clear the next 6 hours for replies. Reply to every top-level comment within ~10 min of receipt for the first hour, then ~30 min after.
- Do NOT cross-post the same launch post anywhere else on launch day. r/iosapps and r/microsaas posts are W4 and W5.

---

## B. 20 ready-to-paste comment drafts

> All drafts are 50-150 words. None of them mention Unit. None of them link to anything. None of them are templates copy-pasted across subs — every comment is sub-specific.
> "Why this adds value" is one line per draft, used to self-check before pasting.
> Timing rule: comment within the first 30-90 min of the parent thread. Late comments compound less karma.

### r/SideProject (5)

#### 1. Thread type: "I just hit my first $100 MRR — what should I focus on next?"

Best timed: ≤60 min after parent post, before the comment count crosses ~30.

```
Congrats — first $100 is the hardest hundred. Honest answer: at this stage I'd ignore "growth" advice for another month and instead spend the time talking to the first 10-20 paying users one by one. Ask them which feature they used most this week, what almost made them cancel, what they tried to do that didn't work. You'll get more product direction in three of those conversations than from any blog post about funnels. The growth playbook only works once you actually know which one feature pays back the marketing spend, and that's a question only your real users can answer.
```

Why this adds value: pushes back on premature growth-tactic advice; offers a concrete, no-fluff next action grounded in indie reality.

#### 2. Thread type: "Roast my landing page" / "feedback on my new app"

Best timed: ≤30 min after parent post.

```
Quick note on the hero — the headline is doing two jobs (saying what it is + selling the benefit) and neither is winning. If a stranger only reads the first line, would they know what the app does in concrete terms? "Save time on X" reads as marketing; "Y in under Z seconds" reads as a fact. Second pass: the screenshot below the fold is the one that should be at the top. The hero device-frame is decorative; the actual workflow shot is the proof. Move the proof up, cut the marketing line, and the page does the same job in 40% less scroll.
```

Why this adds value: specific, actionable feedback on landing-page hero structure — a known weak spot for indie founders.

#### 3. Thread type: "Should I keep building or pivot? My app has X users after Y months"

Best timed: ≤90 min after parent post.

```
Pivot questions usually mean "I'm tired" not "the data says quit." Two filters before deciding: (1) of the users you have, how many use the app three or more times a week unprompted? Not opens, not signups — repeat unsolicited use. (2) when you talk to those users, can they describe the problem the app solves in their own words, or do they parrot your marketing copy? If you have 5+ people in the first bucket and they describe the problem in language you didn't give them, you have a real product and the next move is distribution. If neither bucket is full after 6 months, that's a pivot signal. Otherwise it's a marketing problem dressed up as an existential one.
```

Why this adds value: gives a usable two-question retention/PMF heuristic instead of generic "trust the journey" platitudes.

#### 4. Thread type: "Building in public — week N update with screenshots"

Best timed: ≤60 min, while the post is in /new.

```
The dashboard shot is the right artifact for this kind of update — much more credible than another roadmap screenshot. One small thing: putting the actual MRR number on the screenshot beats a vague growth curve, even when the number is small. Readers project themselves onto specific numbers ("oh, $73, I could see myself there") and gloss past percentages. If you keep doing weekly updates, anchor each one in a single concrete number — installs, MRR, replies, whatever — and let the curve be implied by the sequence rather than shown as a graph.
```

Why this adds value: nudges OP toward a more credible weekly-update format with a research-backed reason (small concrete numbers > abstract curves).

#### 5. Thread type: "What's your #1 distribution channel?" / "How are you getting users?"

Best timed: ≤45 min after parent post.

```
Honest take from someone shipping solo: the channel that works is the one you'll actually run for 12 weeks straight. Most "best channel" advice fails because the founder picks the channel that promises the biggest lift, hates running it, and quits after three weeks. Better question: which channel can you stand to do 30 minutes of every weekday? For me that's been long-form Reddit comments — boring, low-leverage per touch, but I show up. The compound effect after three months is real, even if it never goes viral. Don't optimize for ceiling; optimize for the channel where your show-up rate is 90%+.
```

Why this adds value: reframes "best channel" as "channel you'll execute consistently" — useful advice the founder lives, no fake authority.

### r/microsaas (5)

#### 6. Thread type: "What's a fair pricing model for a small SaaS — $5/mo, one-time, freemium?"

Best timed: ≤60 min after parent post.

```
Two things that shape the answer more than the dollar amount: (1) does the user get value the first day they install, or after a week of use? Day-1-value products survive lower prices and freemium funnels; week-1-value products almost always need a free tier with a clear paid trigger because nobody trusts a paywall before they've felt the value. (2) Is your churn driver "I forgot it exists" or "it stopped solving the problem"? Forgetting-driven churn is a notification/habit problem and pricing won't fix it. Stopped-solving churn is a feature problem and pricing won't fix that either. Pick the price that lets you eat ramen and run the experiment for a year — exact dollars are a rounding error vs the underlying retention shape.
```

Why this adds value: reframes pricing as a function of value-onset and churn-cause rather than a number-picking exercise.

#### 7. Thread type: "Is my churn rate normal at X%?"

Best timed: ≤45 min after parent post.

```
Churn-rate-normal questions usually skip the more useful number: time-to-first-value. If new users hit a real "this saves me time" moment in their first session, monthly churn settles into single digits without much intervention. If first-value comes on day 4 or week 2, you're in a footrace against the calendar reminder of the credit-card charge — and no churn benchmark will save you. Run a quick test on your last 30 cancellers: how many of them used the core action more than five times before they cancelled? If it's <30%, your churn is an onboarding problem, not a pricing or feature problem.
```

Why this adds value: gives a falsifiable diagnostic (5-uses heuristic) instead of citing benchmarks.

#### 8. Thread type: "I built a SaaS with no users — what now?"

Best timed: ≤60 min after parent post.

```
The order that has worked for me: (1) the first 10 users come from your network and from one well-aimed Reddit/forum post, not from "marketing." Don't write a blog before you have those 10. (2) Talk to all 10 within a week — record the conversations if they let you. The patterns in what they actually do (not what they say) become your positioning. (3) Only after that, write the landing-page copy and the cold pitch. Most founders flip this order and end up with great copy describing a product nobody has stress-tested. Distribution before scale is fine, but talking-to-humans before distribution is the step everyone skips.
```

Why this adds value: ordered, sequential advice — solves the "what now" paralysis without prescribing a tool stack.

#### 9. Thread type: "Should I build for B2B or B2C?"

Best timed: ≤90 min after parent post.

```
Less about market and more about the rhythm you can sustain. B2B usually means longer sales cycles, fewer customers, higher LTV, and a lot of email. B2C usually means many small payments, brutal CAC pressure, and a marketing engine that runs without you. Neither is easier. Honest filter: do you want to do customer development calls (B2B) or run content/SEO/social (B2C)? Pick the one whose grind doesn't make you want to quit, because you're going to do it for 18 months before you know if it works. Market opportunity is a smaller variable than founder-channel fit at this stage.
```

Why this adds value: frames the choice as channel-fit (founder grind tolerance), which is the actual decision driver for solos.

#### 10. Thread type: "My MRR plateau — same number for three months"

Best timed: ≤60 min after parent post.

```
Plateaus at low-MRR are almost always a top-of-funnel problem disguised as a churn problem. Quick check: how many new trial starts last month vs three months ago? If it's flat, the issue is acquisition, not retention — a product that doesn't grow installs grows MRR by raising prices on existing users (limited) or finding bigger plans (limited). If trial starts are up but MRR is flat, then it's an activation/conversion problem — fix the trial-to-paid flow before adding more channels. Treating plateaus as one phenomenon hides which dial to turn.
```

Why this adds value: separates funnel diagnostics so OP can stop guessing.

### r/iosapps (3)

#### 11. Thread type: "What's an iOS app you use every day that nobody knows about?"

Best timed: ≤60 min after parent post.

```
I keep three under-the-radar ones in my dock: a plain-text notes app from a solo dev that hasn't added a feature in two years (which is the point), a SwiftUI weather app whose entire UI is one screen of large numbers, and a focus timer that's just a single button with no settings. Pattern I notice in my own dock: the apps I keep are the ones that resist the urge to grow. The ones I delete are the ones that added a "social" tab in their second year. Whoever's reading this and shipping an indie app — that's the trade you're making. Restraint compounds.
```

Why this adds value: contributes to the thread's actual question (recommendations) without naming the founder's app, while reinforcing the calm/expert voice.

#### 12. Thread type: "Why do small indie apps charge subscription? Just charge once."

Best timed: ≤45 min after parent post.

```
Indie subs aren't usually a money-grab — they're a survival rationalization. Apple's $99/year dev fee, ongoing iOS-version maintenance (every September is a new SDK rewrite cycle), and the fact that one-time-purchase users still expect support and updates for years. A $4.99 one-time purchase from 2019 is now subsidizing five years of free engineering on Swift 5 → 6 migrations. Subs price the maintenance, not the initial download. The real complaint should be subs that gate the actual core feature (where one-time would have been fairer); subs that gate "nice to have" features while keeping the core free are a reasonable equilibrium for a solo dev.
```

Why this adds value: explains the indie-econ reality without being defensive; honest peer voice.

#### 13. Thread type: "App Store review wait times in 2026?"

Best timed: ≤45 min after parent post.

```
Mostly 18-36 hours for me on standard updates over the last 6 weeks. Faster on bug-fix-only releases that don't add metadata. Slower (3-5 days) when I touched the privacy nutrition labels or added a new in-app purchase product. If you have a deadline, lock the metadata two weeks before and only push code changes — that's the one variable that consistently keeps the review queue fast. Apple's queue is otherwise a black box, but the metadata-touch correlation is strong enough that it shows up in every dev I've talked to.
```

Why this adds value: shares a real pattern (metadata changes slow reviews) that lifts the conversation from anecdote to operational tip.

### r/iOSProgramming (2)

#### 14. Thread type: SwiftData migration question / `@Model` schema evolution

Best timed: ≤60 min after parent post.

```
SwiftData migration trip-wires I've stepped on: (1) renaming a stored property without a migration plan silently zeros out the data on first launch — the schema has to be versioned via `VersionedSchema` and the migration has to be wired into the `ModelContainer`. (2) Adding a new optional property is "free" only in the trivial case; if the property has a default value computed from another field, you need a custom migration step or you'll see crashes on existing user data the first time the field is read. (3) For deletion-tolerant testing, snapshot the persistent store from a previous build before running the migration — `Application Support/default.store` (and the -shm and -wal files). Without that, you can't prove the migration works on real user data.
```

Why this adds value: technical specificity that lifts the comment above generic forum chatter — establishes dev credibility.

#### 15. Thread type: Showcase Saturday — someone shows their app, comments are reciprocal feedback

Best timed: pick a post with <10 comments at time of writing, ≤2 hours after the thread's daily mega-thread is open.

```
Like the typography choice — the shift from default body font to a tighter numeric face for the data-heavy view is doing a lot of work. One small thing: the spacing between rows in the list view feels uniform regardless of context, but visually-grouped runs (e.g., same-category items) usually benefit from tightening intra-group spacing slightly and giving the inter-group divider a hair more breathing room. Same total height on screen, much easier to scan. Otherwise this is the most readable variant I've seen of this pattern recently — the restraint is the feature.
```

Why this adds value: typographic + spacing critique that signals design literacy without being pedantic.

### r/homegym (3)

#### 16. Thread type: "What's the best Home gym setup for under $X?"

Best timed: ≤45 min after parent post.

```
Spent the last four years iterating on this. The hierarchy that's held up: (1) a real squat rack with safety arms — non-negotiable, because it determines whether you can train alone, (2) a 20kg barbell of decent quality and 100kg of plates including 2.5s and 1.25s, (3) an adjustable bench that's actually flat at flat, (4) a mat. Things I bought and don't use: bench-press attachments that bolted to the rack (the rack does it natively), specialty bars I thought I'd cycle in (haven't touched), branded plates (calibrated weights matter for a powerlifter, not for general training). Simpler is better; one good piece per category beats three so-so pieces.
```

Why this adds value: practical hierarchy from real experience, helps OP avoid common buying mistakes.

#### 17. Thread type: "Lifting alone — how do you stay safe without a spotter?"

Best timed: ≤60 min after parent post.

```
Three rules that have kept me safe lifting alone for years: (1) safety arms set at chest-touch depth on bench, even if it feels low — the failure mode is "bar pinned at chest," and inches matter. (2) On squats, set the safety arms 1-2 inches below the depth of your deepest rep — bail by sitting back, never forward. (3) Never miss a rep alone with collars on if you can help it; the open-end-roll-off is an old trick and it works. The bigger insight: most people overestimate the danger of failed reps and underestimate the danger of working out tired with bad bar path. Sleep is the bigger safety variable.
```

Why this adds value: real, practical safety knowledge from a lifter — credibility without product mention.

#### 18. Thread type: "Programming for home gym — push/pull/legs vs upper/lower?"

Best timed: ≤60 min after parent post.

```
Both work; the right one is the one you'll run consistently for 6-12 months. PPL gives you 6-day frequency and lets you push more total volume per muscle group, but you're locked into 6 sessions a week to get the full benefit and missing a day cascades. UL is more forgiving — 4 days a week, missing one still leaves you with adequate frequency. For most lifters with a job and a family, UL is the unsexy correct answer. PPL is for people who would otherwise be at the gym anyway and want a structure to make those sessions productive. Your schedule reliability matters more than the split's theoretical optimality.
```

Why this adds value: experienced training-economics view, recommends matching schedule to split rather than vice-versa.

### r/Fitness OR r/weightroom (2)

#### 19. Thread type: r/Fitness daily form-check thread (Mon-Fri)

Best timed: post in the daily thread within the first 4 hours of it being open.

```
Bar path is migrating forward over your mid-foot on the descent — you can see it clearly in the side view from rep 2 onward. The fix isn't "lean back more" (that usually creates a new problem at the lockout) — it's reinforcing the brace at the start of the descent. Try this: take a deep belly breath at the top, brace into your belt before unracking, hold that brace for the entire rep. Three working sets at 60-70% with this cue and the bar path tightens up. Don't add weight until the path is clean at the lighter loads — adding weight to a forward-drifting bar is how lower backs get tweaked.
```

Why this adds value: form-check value with a specific cue, no app mention, no link, pure community contribution.

#### 20. Thread type: r/weightroom programming Wednesday or training discussion thread

Best timed: ≤2 hours after the thread is opened by mods.

```
RPE-based programming gets pitched as "auto-regulating" but in practice the bigger benefit for intermediate lifters is honesty. Percentage-based templates let you grind a session that should have been deloaded ("the program says 85%, so I do 85%"); RPE forces you to confront how the lift actually feels today and adjust the load down when it's clearly not your day. The trade-off is calibration drift — most lifters undercall their RPE at the start (everything feels like a 9), and it takes 8-12 weeks to get accurate. If you're switching to RPE, expect the first month to feel slightly off and don't bail early.
```

Why this adds value: programming-philosophy take that respects the sub's level — engages with RPE on its own terms, no shortcut.

---

## C. Anti-pattern reminders

> If you find yourself about to do any of these, close the tab and walk away from the keyboard.

| Don't | Why |
|---|---|
| Drop "Unit" in any comment, even when "naturally relevant" | The W3 launch post is the first time the name appears. Earlier mentions get the account flagged or shadowbanned in r/Fitness/r/weightroom and pattern-flagged on Reddit's wider spam classifier. |
| Reply with "great point!" / "totally agree" / "this!" | These contribute zero karma in modern Reddit (algo down-weighted them years ago) and signal sock-puppet. Comment only when you have something specific to add. |
| Use the same comment template across subs | Cross-subreddit pattern detection is real. Each comment in this doc is sub-specific by design. If you must adapt a draft, change the opening sentence and at least one example. |
| Argue with strangers | Wins zero karma, costs hours, leaves a hostile-comment trail any future reader will check. If a comment annoys you, close the tab. The 30-min/day cap exists partly to prevent rabbit-holes. |
| Downvote-stalk competitors (Hevy, Strong, Liftosaur founders) | Reddit detects vote pattern correlations; you'll lose karma instead of gain it, and any user-report of "competitor stalking" can perma-ban the account. |
| Recommend other gym trackers in r/Fitness/r/weightroom | Even mentioning "Hevy and Strong are the standard" reads as a setup for promoting a third option. In the gym subs, the comments here say zero about apps. Period. |
| Link to your own past comments / "as I said in my other thread" | Cross-thread self-citation is a sock-puppet flag. Each comment stands on its own. |
| Edit comments more than once after posting | Reddit logs every edit; multiple edits look like an account trying to hide its trail. Get the comment right before pasting; minor typo fixes only. |
| Use a brand-new account | The account firing the W3 BIP post must be ≥30 days old at launch. If the founder's existing account is younger than that, *use* this 14-day plan to also age the account organically; don't create a new one in W2. |
| Comment in r/SideProject ≥6 hours before the W3 launch post | Same-account back-to-back activity right before launch reads as engagement spam. Quiet morning before posting. |
| Buy upvotes / use a friend network to seed | Algo detects unusual upvote velocity in first 30 min from low-karma accounts. Tanks the post. |
| Touch r/Bodybuilding, r/StrongerByScience | Out-of-scope for this 14-day plan. Wiki-contributor path is 6+ months and not relevant pre-launch. |

---

## D. Karma checkpoint table

> Minimum karma per subreddit by W3 launch day (Wed 2026-05-13). If any row is short, the launch fires anyway — but the W3 BIP post in the short sub is delayed by a week to let the karma trail catch up.

| Subreddit | Floor for launch | Comfortable | Stretch | What to post in W3-W5 |
|---|---|---|---|---|
| r/SideProject | 100 | 150 | 200+ | W3 BIP launch post (Wed 2026-05-13). |
| r/microsaas | 50 | 80 | 100+ | W4 free-tier philosophy post. |
| r/iOSProgramming | 25 | 40 | 60+ | W5 Showcase Saturday — show the SwiftData/RevenueCat stack. |
| r/iosapps | 15 | 25 | 40+ | W4-W5 secondary post (1 week after r/SideProject). |
| r/homegym | 8 | 15 | 25+ | No BIP post pre-launch. Comment-only for first 6 months per `reddit.md`. |
| r/Fitness OR r/weightroom | 5 | 10 | 20+ | No BIP post ever pre-launch. Comment-only, wiki-contributor path is 6+ months. |

The floor numbers are not rules from Reddit — they're calibration based on the comment-history shape that survived the 2025-2026 spam-filter tightening. A profile with 100+ karma in r/SideProject and visible 7-30 day comment history reads "real person who reads this sub" to the algorithm and to human moderators clicking the profile.

If by Tue 2026-05-12 the r/SideProject count is <80, push the BIP post by 4-7 days and use that week to add 5-10 more comments. Better to launch with 100 than fire and get auto-removed.

---

## E. Filtered-launch recovery plan

> What to do if the W3 BIP post lands and immediately disappears (or never breaks /new). Read this *before* launch so you don't panic-react.

### Step 1 — Detect shadowban / filter (within first 30 min of posting)

Open a logged-out browser (private window, not signed into Reddit). Navigate to:
- `reddit.com/user/[your-handle]` — if your post is visible here but not on the subreddit feed, your account is fine but the post got filtered.
- `reddit.com/r/SideProject/new` — if your post doesn't appear in /new even after 5 min, the subreddit's spam filter caught it.
- `reddit.com/r/SideProject/comments/[post-id]` — direct link. If logged-out you can see it but it's not in /new, the post is shadow-removed.

Cross-check: if you have a friend or alt account, ask them to check whether your post appears in their /new. If they see it, you're fine — your client just hasn't refreshed. If they don't, it's filtered.

### Step 2 — Don't delete and repost. Ever.

Deleting and reposting within the same day:
- Triggers Reddit's "post-and-delete" pattern flag (used to detect spam evasion).
- Most subreddits ban same-content reposts within 24-48h regardless of delete history.
- Doubles the chance of a permanent shadowban on the account.

The W3 BIP launch post is **one shot**. If it's filtered, leave it filtered and pivot to the alternative.

### Step 3 — Pivot to the alternative subreddit (within 2-4 hours)

- If r/SideProject filtered: post the same launch content (with a refreshed title to avoid duplicate-detection) to **r/microsaas** by Wed evening US time. Smaller audience, friendlier moderation, lower-but-real signal.
- If r/microsaas also filters: wait 7 days and post a revised version to **r/iosapps** as the W4 secondary post.
- If all three filter on the first launch day: do not post again for 14 days. The account is being throttled. Go quiet.

### Step 4 — Message the moderators (only if filtered, never if just low-engagement)

Mod-mail a short, polite message:

> Hi mods — I posted a build-in-public update earlier today and it doesn't appear on /new. Could you check whether it's stuck in the filter? Happy to revise if it's against the rules. Thanks.

Two notes:
- Mods get hundreds of these. Be concise. Don't argue. Don't claim the filter is broken.
- Some mods will simply approve the post if it's a false positive. Most will not respond. Wait 24 hours; if no response, accept the filter.

### Step 5 — Account-rest period

If the post is confirmed filtered:
- Stop posting BIP content for 14 days.
- Continue commenting at the W0/W1 cadence (~1 comment/day) — this rebuilds account trust.
- After 14 days of clean activity, pivot to the **r/iosapps W4 secondary** post (revised) as your effective launch.
- Treat the originally filtered W3 attempt as a failed dress rehearsal, not a launch.

### Step 6 — If you're permanently shadowbanned

If multiple posts and comments are invisible to logged-out users for 14+ days:
- Reddit's `r/ShadowBan` subreddit has a self-check tool. Run it.
- Appeal to Reddit admins via the help center — about 30% of shadowbans get reversed within a week if you make a calm, factual case ("I posted a build-in-public update; here's the post; here's my comment history; please review").
- If the appeal fails: do **not** create a new account to post the same content. The IP is flagged. Wait 90 days and use a different angle (a non-Unit project, a personal account that organically mentions Unit only after months of activity).

The 14-day pre-launch karma plan in this doc exists specifically to make the recovery plan unnecessary. Do the karma work. The launch post will land on a profile that reads as a real human who has been quietly contributing for two weeks — and that profile shape is what gets through the filter.

---

## Summary

- **W0-W1 (14 days)**: 15-30 min/day, 1-3 comments/day, never the same template across subs, zero mention of Unit.
- **W3 launch day**: post per `templates/reddit/01-launch-week.md`. Account already has 100+ karma in r/SideProject, 50+ in r/microsaas, real human-shaped comment trail in 4+ subs.
- **If filtered**: don't delete, don't repost, pivot to r/microsaas same day or r/iosapps next week, rest the account 14 days.
- **Gym subs (r/Fitness, r/weightroom, r/homegym)**: never mention the app pre-launch. The 6-month wiki-contributor path is the only legitimate route; pre-launch comments here are pure community deposits with no withdrawal expected.

The whole runway costs ~5 hours of the founder's time across 14 days. The alternative is a launch post that nobody sees because the algorithm filters it before any human ever loads /new. Five hours is the cheapest insurance the launch will get.
