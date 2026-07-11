# Unit — onboarding redesign research

> Research foundation for Phase B of the v2 plan (`~/.claude/plans/i-am-still-unsure-quiet-flame.md`). The current 548-line `OnboardingExercisesView` is the highest-friction surface in the app (~127 taps for a 4-day program; the user called it "insufferable"). v2 cannot submit to the App Store until this surface is redesigned, because the hard paywall now sits at the end of onboarding and the user has to perceive value before being asked to pay.
>
> Status: **in progress (Section 1 + Section 3 complete; Sections 2, 4, 5, 6 pending).** Updated 2026-06-17.

---

## 1. Brief — what we're optimizing for

### Persona

**Self-coached intermediate lifter.**

- Has lifted 1-5+ years.
- Runs a written program — PPL, 5/3/1, Stronglifts, Upper-Lower, custom — that they chose themselves or got from a friend / Reddit / YouTube / Stronger By Science.
- Owns the program. Doesn't want recommendations. Doesn't need a quiz. Already knows what they're doing.
- Trains 3-5x/week. Logs sets to track progressive overload over months.
- Pays for tools that respect their time. Annoyed by interfaces designed for beginners (Fitbod's quiz, MyFitnessPal's social graph).
- Willingness-to-pay: high for **logging speed**. Low for **recommendation features**.

### Why this persona (math)

Top 0.1% in fitness apps over 2 years ≈ $1M ARR. At a $60 annual ARPU (Unit's annual tier), that's **~17k paying annual subscribers**.

| Persona | Global TAM (est.) | Conversion needed | Feasibility |
|---|---|---|---|
| Self-coached intermediate | 5-10M (Reddit lifting subs: ~5M combined; gym-going lifters globally: tens of millions) | ~0.2-0.4% of TAM | Plausible. Indie precedent (Liftosaur, Boostcamp). |
| Coached lifter (pays $100-300/mo to a coach) | ~100-300k | 5-15% | Has never been done by an indie. |
| Beginner / returning ex-lifter | 50M+ | <0.1% | Hevy/Fitbod compete here with much bigger budgets. Indie loses. |
| Serious solo lifter (multi-year, multi-program) | ~500k-1M | 2-4% | Plausible but smaller pool. |

The self-coached intermediate has the largest TAM with realistic conversion math. Coached lifters are higher-ARPU per user but TAM is too small.

### Success metric

**Primary: highest perceived value at paywall.** Build to ONE memorable moment of "oh — this is different" before the wall hits.

**Secondary: minimize time-to-paywall.** Cap onboarding at ~120 seconds. Beyond that, attention falls off a cliff (per the cognitive-principles.md "reduced friction" principle).

The 2026-06-09 day-one pre-fill wedge ("on day one Unit already knows your numbers from your paste") is the first wow moment. The research below has to find or invent the second moment that makes the paywall feel earned.

### Anti-goals

- "Onboarding that handles every persona well." We deliberately make Unit worse for beginners and coached lifters to make it best for self-coached intermediates.
- "Onboarding that teaches the app." Self-coached lifters resent being taught what they already know. Show, don't teach.
- "Onboarding that asks lots of questions." Quiz funnels are for AI-plan apps (Fitbod). For Unit, every question is a tax that doesn't pay back.
- "Best onboarding ever invented." That's a moving target. We optimize for top 0.1% revenue, not design Twitter applause.

---

## 2. User-voice research (App Store reviews + Reddit)

**Method.** Reddit MCP was rate-limited; pivoted to Apple's `customerreviews` RSS feeds for Hevy / Strong / Fitbod / Liftosaur / Boostcamp (250+ recent reviews) + one r/Fitness RSS thread. Filter applied: keyword match on `onboard`, `setup`, `paywall`, `subscription`, `first time`, `manually enter`, `paste`, `spreadsheet`, `pushy`, `before you can`, `too many`, etc. All quotes are direct, dated, and sourced.

### The single most relevant quote for Unit's v2 strategy

> [Fitbod, 3★ 2026-06-11, "Paywall after onboarding"] **Waste of my time. This is an only paid app not "free with in app purchases". They offer a free 7 days with a mandatory subscription after they make you do an onboarding process. Would be nice to know that before starting to not waste time.** From what I can see app looks legit but I was under the assumption there was a free tier or version which is what I was looking for and this app did say it was free.

This is Unit v2's exact strategy — paid app + after-onboarding paywall — already getting punished in another app. Two takeaways:
1. **App Store listing must be unambiguous** that v2 is paid. The 2026-06-11 reviewer expected free, got walled. Reviewer notes (now canonical in `docs/app-store-copy.md` §Reviewer notes) already call this out; ASC product copy must reinforce it.
2. **Onboarding splash must hint at the paywall upfront.** Not as a sell — as honesty. "Set up your program (free) — start logging ($4.99/wk)." Removes the bait-and-switch perception.

### The "what NOT to do" canonical complaints

> [Boostcamp, 1★ 2025-10-13, "Pushy"] **Why do you show me offers before I even was able to see anything in the app? How can I pay for something that I have no idea.** Seems you are more interested about money than providing the value for your users. Also the start flow asks too many questions …

> [Boostcamp, 4★ 2026-05-19, "Good app, but too many hoops"] The only complaint I have is that they make it very hard to use the free version when you get started. **I swear I had to decline six offers before it let me start logging for free.**

> [Boostcamp, 1★ 2026-06-06, "Terrible"] An ad for "pro" pops up every time I touch the screen. 0/10 do not recommend

Boostcamp's downward-spiral pattern is two-fold: (a) pre-onboarding paywall ads ("offers before I see anything"), (b) interrupting paywall ads inside the app. **Unit v2's single-paywall-after-onboarding placement avoids both.** Do not stack paywall touches.

### The Liftosaur tells — closest indie peer (327 ratings, 4.86★, scriptable workouts)

> [Liftosaur, 5★ 2026-06-02, "In a league of its own!"] Tried every tracker over the years and abandoned them all — except this one. **Liftosaur lets you write your program as code (the Liftoscript DSL),** so tempos, RIR targets, supersets, decline angles, warmup sets, custom rest timers — all of it lives in one readable place. The workout view renders form-guide YouTube links clickably mid-set, which is the small detail I didn't know I needed. Sync across devices just works. There's an API if you want to automate things (I built a daily check-in agent on top of it). And **the dev is genuinely active on his Discord** — ask a question, get a real answer, of …

> [Liftosaur, 5★ 2026-04-08, "Good ui, good support"] Found Liftosaur looking for alternatives to Boostcamp because I didn't want to have to manage adjustments. **Easy to set up,** and every time I've had an issue it's has been user error but the dev has been responsive, friendly and helpful.

> [Liftosaur, 5★ 2026-03-28] This thing is a game changer for me with the progressive overload and **cool script language it comes with. The MCP tool with Claude makes it super easy for programming workout plans**

The Liftosaur playbook for the self-coached intermediate:
1. **Programmability is the wedge.** A DSL ("Liftoscript") lets serious lifters express their programs exactly. Mass-market apps can't compete here.
2. **"Easy to set up"** is the headline 5★ refrain — and "easy to set up" for Liftosaur means "the DSL is so expressive that ONE paste handles everything."
3. **Active solo dev presence** is itself a 5★ feature ("the dev is responsive on Discord"). Indie advantage that Hevy / Strong / Fitbod can't replicate.

The risk: 327 reviews total (vs Strong 108k, Fitbod 273k). Devout fans but small TAM. Unit must beat Liftosaur's onboarding while staying under their complexity ceiling — DSL is too much for a phone-first audience.

### The Hevy and Strong tells — mass-market 5★ refrains

> [Hevy, 5★ 2026-06-15, "Favorite workout app"] This is the best workout app I have ever used! **It's easy and quick to log your sets** and love that it syncs with my Apple Watch. Others felt too involved and clunky, but this app is amazing.

> [Hevy, 5★ 2026-06-15, "Finally!"] I never write reviews… but I've been looking for an app like this for a long time. **I wanted something easy, clean, and an app where I could input my OWN workouts** with the ability to plan and change reps/weight and save the workout for repeatability. Hevy does all of this!

> [Strong, 5★ 2026-06-04, "I am loving it"] It's a beautiful thing, this workout app. **Simple interface but yet it's so rich in experience.** Wide library of exercises, provision of custom exercises, body measurement recording option, etc.

> [Strong, 5★ 2026-06-10, "Best Workout App Hands Down"] I went through every workout app when I first started using smartphone workout apps. **Loved the simplicity from the beginning** and the ability to record everything I was focused on …

The repeated 5★ language is **"simple," "intuitive," "easy and quick."** Unit's "Log a set in 3 seconds" subtitle already aligns. The risk is that "simple" can mean two different things — (a) the **logging loop** is simple (Hevy / Strong wins here), or (b) the **program-entry onboarding** is simple (where Hevy/Strong let you build manually with a robust exercise picker; Unit's current ~127-tap manual path is worse than theirs). Unit must reach Hevy-grade onboarding simplicity in v2.

### The Hevy paywall framing — pricing model that works

> [Hevy, 5★ 2026-06-15, "Fantastic workout"] **The paywall in functionality, it sat in a good place, there's a lot of value without it, but premium is definitely worth the money.**

Hevy's praised paywall pattern: **free-tier basics + Pro for advanced features.** Their 4.92★ / 74k ratings prove it works at scale. Unit's hard paywall is a different bet — higher day-1 revenue but harder long-term love. Validate before committing further: a 7-day refund offer at the paywall would soften the wall without breaking the model (still no trial, but money-back if they bounce in week 1).

### The Strong / Fitbod / Boostcamp pain — what users complain about MOST

Cross-app recurring complaints (verbatim):
- **Slow exercise search** — Strong shipped a search fix in May 2026; pre-fix reviews are angry.
- **Apple Watch sync bugs** — Strong: "I'll mark a set on phone, watch won't see it, I do it there, then phone has lost 5 sets." Unit defers Watch (Phase C2 of the morning's plan, now superseded), so this isn't an immediate risk — but when it ships, this is the bar.
- **Aggressive feature paywalling mid-product** — Liftosaur 3★ "Greedy": "New update put graphs behind paywall when it was free a week ago." Unit's hard-paywall-from-launch v2 avoids retroactive paywall-shifting — but the InstallProvenance deletion (broken v1 grandfather) IS exactly this risk for the small v1 install base.
- **Lost workout history** — Boostcamp 2★: "I feel locked in because all my old workout history is stored here … I wasted near an hour today trying to edit a program, then opening it reverted everything." Local-first + immediate persistence is Unit's defense.
- **Bot customer service** — Fitbod 1★: "customer service is all AI and is useless." Indie advantage (one human responds on email) is a 5★ amplifier for Unit.

### r/Fitness signal — self-coached lifters want a spreadsheet

> [r/Fitness 2016-03-19, /u/BigBootyBear, "I cant stand all the complicated fitness apps. Is there a simple lifting log app?"] **I have downloaded 10 lifting apps and they are all disappointing. I just want an excel sheet in my phone where I can input weight into A/B/A templates but all the apps are too complicated.** The closest app to what I want is 5X5 app but it does not allow you to customize the exercises (no power cleans and cant deadlift two workouts in a row - I am doing SS). Is there an app like 5x5 that allows customization and is not biased towards a particular program, or just a simple log that does not suck?

The 2016 quote still resonates — the persona has not changed. The self-coached intermediate wants: spreadsheet flexibility + zero complexity. "An excel sheet in my phone" is the mental model. Onboarding should feel like opening an empty spreadsheet, not building a database. Unit's `OnboardingExercisesView` (548 lines, drag-drop, picker sheets, undo toasts) is the OPPOSITE of this mental model.

### Synthesis — the user-voice consensus

| Theme | Frequency | Implication for Unit v2 onboarding |
|---|---|---|
| "Easy and quick to log sets" — repeated 5★ refrain | High | Log surface is already aligned (Gym Test ≤3s). Onboarding has to ladder up to it. |
| "Simple interface" — Strong's headline win | High | Don't add screens. Cut the manual builder if the paste/library can replace it. |
| "Paywall after onboarding without warning" — Fitbod 3★ | Direct hit on Unit's strategy | Disclose paid model in App Store listing AND on the very first onboarding screen. |
| "Pushy / too many offers" — Boostcamp 1★ | Direct anti-pattern | Single paywall instance only. Never interrupt during onboarding. |
| "Excel sheet in my phone" — r/Fitness 2016 | Persistent persona signal | Mental model = spreadsheet, not flowchart. Paste-from-Notes is the gateway. |
| "DSL / scriptable" — Liftosaur 5★s | Niche but devoted | Programmability is the indie wedge. Unit's paste-to-template parser is the lighter version of this. |
| "Lost workout history" — Boostcamp 2★ | Major churn driver | Local-first persistence (Unit) is already a tell-able win. |
| "Bot customer service" — Fitbod 1★ | Indie amplifier | Hand-replied support@unitlift.app is a 5★ catalyst. |

---

## 3. Cognitive principles applied to onboarding

Source: [docs/cognitive-principles.md](cognitive-principles.md) + [docs/mental-models.md](mental-models.md). Both already in the repo; the user did not need to provide new URLs.

For each principle, the question is: **where does the current onboarding violate it, and what would honoring it look like?**

### From cognitive-principles.md (8 principles)

#### 1. Reduced friction

**Current violation:** OnboardingExercisesView is ~127 taps for a 4-day, 6-exercise-per-day manual build. Each add-exercise interaction is 2 taps + 1 keyboard session. Compounds across 24 exercises.

**Honored:** Strip the manual builder to ≤25 taps OR replace it entirely with paste/library funnels that produce a full program in ≤7 taps. The paste path already does this — only manual is broken.

#### 2. Clarity of value

**Current violation:** Splash → Unit picker (kg/lb) → Import method tile picker → Schedule → Exercises. The user doesn't see any *concrete* value (their actual program, populated, ready to log) until the very last screen — and by that point, the paywall is about to hit.

**Honored:** The first screen *after the user pastes or picks a program* should show them their populated program with weights pre-filled and a callout: "**You logged 80kg on bench last Monday. Unit already knows.**" That's the wow moment. The current flow buries this under three more taps.

#### 3. Commitment and consistency

**Current violation:** Nothing in the current onboarding makes the user verbalize their commitment ("I'm a lifter who logs every set"). The persona signal is implicit.

**Honored:** A single soft prompt at hand-off: "Ready to log set #1?" — names the commitment, signals the loop, builds the identity. Probably one line in the existing splash flow, not a new screen.

#### 4. Predictability

**Current violation:** First-time users don't know what to expect from the paywall. The flow ends with "Start your first workout" → tap → paywall. Surprise. Per Apple Guideline 3.1.2(b) reviewers also dislike this.

**Honored:** Show the subscription tile (price + period) once at the END of onboarding, before the paywall. Not as a hard sell — as predictability. "Unit is $4.99/wk, $9.99/mo, or $59.99/yr. Set up your program first, then choose." Removes the surprise.

#### 5. Loss aversion

**Current violation:** The user has spent 60-180s setting up. If they bounce at the paywall, that effort is "lost." Loss aversion says they should hate losing it more than gaining the paywall savings — but only if we *make the loss visible*.

**Honored:** Paywall copy that names the loss: "Your program is set up. Subscribe to log set #1." Not "Subscribe to unlock features." The lift is already done; locking up its result is the loss.

#### 6. Clear CTAs

**Current violation:** Already mostly honored. "Start workout" is clear.

**Honored:** Keep. The paywall CTA in v2 is just "Subscribe" — also clear.

#### 7. Ability + motivation (Fogg behavior model)

**Current violation:** Manual program entry requires HIGH ability (knowing your full week of exercises, sets, reps, weights from memory under cognitive load while tapping). Most users have the motivation (they downloaded the app) but lack the ability in the moment.

**Honored:** Move the cognitive work to PASTE (user did the typing already, in Notes, before opening Unit) or LIBRARY (one tap, no recall). Manual stays as the escape hatch but never the default.

#### 8. Light social proof

**Current violation:** None visible (per `PRODUCT.md` no-social rule).

**Honored:** Keep absent. Self-coached intermediates explicitly resent social-graph apps. Anti-goal.

### From mental-models.md (7 models)

#### 1. Identity change

**Current violation:** Onboarding doesn't name the identity ("a lifter who logs"). Implicit only.

**Honored:** Name it once at hand-off: "You're set up. Let's log your first set."

#### 2. Process over goals

**Current violation:** No goal-setting in onboarding (good — we don't want it). But also no process visibility — the user can't see the logging loop until they hit Today and start a workout.

**Honored:** Demonstrate the loop ONCE in onboarding. After program populates, a 5-second "here's what logging a set looks like" preview (or just an animated highlight on the first exercise row). Not a tutorial; a peek.

#### 3. Simplicity

**Current violation:** Onboarding has 7 distinct screens. Manual path has ~127 taps. Even the paste path has 5 screens.

**Honored:** Collapse where possible. UnitPicker (kg/lb) could move to Settings; Schedule could be auto-derived from program (most pastes already say "Monday: push, Tuesday: pull"). Aim for ≤4 screens for the paste path.

#### 4. Next Step

**Current violation:** Mostly honored — buttons are clear.

**Honored:** Keep.

#### 5. Breakdown goals

**Current violation:** The "your program" goal is one big lift. Breaking it down: "Step 1: paste your routine. Step 2: confirm what we got. Step 3: log your first set." Three small wins.

**Honored:** The paste path already does this. Reinforce.

#### 6. High agency

**Current violation:** The library/recommend approach reduces agency (we're telling you what to do). The paste/manual approach preserves it. Mixed — depends on the design direction picked in §5.

**Honored:** Default to high-agency framing: "Your program, logged." Not "Our recommendations for you."

#### 7. First principles

**Current violation:** None — Unit's first principle is "user has a program and needs to log fast under stress." Onboarding has to deliver that program ↔ app handshake.

**Honored:** Every step in onboarding must answer "does this get us closer to the first logged set?" If not, cut it.

### Synthesis

The 2-3 principles that matter most for the v2 redesign:
1. **Reduced friction** — current manual path is unacceptable; paste/library wins
2. **Clarity of value** — the "wow" moment has to land BEFORE the paywall, not after
3. **Loss aversion** — paywall copy names the loss ("your program is set up; subscribe to log set #1"), not the feature gain

Everything else is honored or minor.

---

## 4. Competitor onboarding analysis

**Method.** Apple `lookup` API for app descriptions + ratings count; `customerreviews` RSS for user-voice (§2); App Store listing text for positioning + onboarding hints. Direct install impossible (user has not walked through any flow personally). Gaps marked explicitly.

### The competitor table

| App | Rating | # Ratings | Price | Persona | Onboarding strategy (inferred from listing + reviews) | Verdict for Unit |
|---|---|---|---|---|---|---|
| **Hevy** | 4.92★ | 74,879 | Free + Pro | Mass-market lifters (10M+ users) | Account required → exercise library picker → social graph opt-in. "Hundreds of exercises with free high-quality videos." User-flow built around "input my OWN workouts" with picker. | Hevy owns mass-market. Unit cannot win on quantity (exercise library, video, social). Win on speed of program entry instead. |
| **Strong** | 4.86★ | 108,415 | Free + Pro ($30/yr) | Beginner to powerlifter (CNBC, The Verge press) | "Simplest interface in App Store." Exercise picker + reusable routines. "Use the history to perform the workout again, no need to re-enter exercises." Strong is the "spreadsheet of apps" the r/Fitness quote was looking for. | Strong is Unit's direct mass-market competitor on the "simple log" axis. The history-replay flow is the key precedent. Unit's paste-import is the new wedge Strong doesn't have. |
| **Fitbod** | 4.81★ | 273,766 | Paid (free trial) | Beginner / coach-style ("AI workouts") | Heavy onboarding quiz — equipment, goals, fitness level, training days/week. Then AI generates plan. Apple Editor's Choice. Beginner-friendly positioning. | Different category. Unit's "user owns the program" wedge is the explicit anti-Fitbod. Use them as the example of "what Unit will never do" in marketing. |
| **Liftosaur** | 4.86★ | 327 | Free + Pro (lifetime $50ish) | Serious self-coached lifter (DSL nerds) | Pre-built programs (GZCLP, 5/3/1, BBR) OR write your own program in Liftoscript DSL. Programmability is the entire wedge. Active solo dev on Discord. | Closest spirit-cousin to Unit. Same persona. Unit needs to be at Liftosaur's ease-of-paste but without the DSL learning curve. Steal the "easy to set up" 5★ refrain. |
| **Boostcamp** | declining (3.5-4★ trend) | ~?? | Free + Pro (aggressive) | Beginner to intermediate (program library focus) | Library-first ("pick a program, follow it") + custom builder. Recently 1★/2★ trend due to "every update worse," pre-onboarding paywall pushes ("decline six offers before logging"), feature regressions. Cautionary tale. | Don't be Boostcamp. The starter-library direction (D1 below) is what Boostcamp does well — but their paywall + UI degradation is what Unit must NOT replicate. |

### Onboarding flow archetypes (inferred from listings + reviews)

The 5 competitors collapse to **3 archetypes**:

#### Archetype A — Picker-first ("Hevy, Strong")
Empty program → user adds exercises one-by-one from a searchable library → groups into routines. Inherits the Apple Health onboarding pattern. Pros: maximum flexibility, no parser needed, large exercise library is the differentiator. Cons: high tap count for 4+ day programs (~127 taps per Unit's audit), gated on user knowing every exercise name + sets/reps from memory under cognitive load. **Hevy and Strong both win at scale because their picker + exercise library is exceptionally well-tuned**, not because the flow itself is good.

#### Archetype B — Quiz / AI-generated ("Fitbod")
Tell us your goals → equipment → fitness level → days/week → AI generates plan. Pros: zero recall required from user, plan appears as if by magic. Cons: doesn't give the user agency (they didn't write the program), requires either a large library + recommendation algorithm OR an LLM call (Fitbod uses both). Mass-market beginner persona only. **Anti-goal for Unit** — self-coached intermediates resent being told what to do.

#### Archetype C — Library + customize ("Boostcamp, Liftosaur")
Show pre-built programs → user picks one → user can swap exercises / adjust weights / rebuild in DSL. Pros: instant value (program populated), agency preserved (user owns the program after edits). Cons: requires good library curation + good edit flow. Boostcamp does the library well; their UI/paywall hurt the rest. Liftosaur does the DSL well; the learning curve is too steep for phone-first audience. **Best directional pattern for Unit** — collapse to ~5 named programs + paste-as-fallback.

### Cross-cutting onboarding patterns Unit can steal

1. **Strong's "re-perform a past workout"** — when the user opens a session, the previous performance is loaded as the default. Unit's "Last time" pre-fill is the same primitive at a different layer.
2. **Liftosaur's "start with a template OR write your own"** — both paths present on first screen, user picks based on intent. Unit's `OnboardingImportMethodView` is the same pattern; needs sharpening.
3. **Fitbod's "no equipment? home variant"** — equipment-aware exercise substitution. Unit doesn't have this; defer.
4. **Hevy's "your friend just hit a PR"** — anti-pattern for Unit per `PRODUCT.md` no-social rule. Skip.

### What's missing from this analysis (gaps)

- **First-run carousel screenshots from each app** — would clarify exact step ordering. Apple's `screenshotUrls` field in `lookup` could be pulled next turn for visual reference.
- **Direct walkthrough video evidence** — YouTube has "[app name] first time setup" reviews; pulling 2-3 per app would close the inference gap. Skipped this turn for time.
- **Conversion-rate data** — no app publishes "% of installs who complete onboarding." Inferred indirectly via ratings count / "this is the only app I stuck with" 5★ refrains.

These gaps don't change the direction of the recommendation in §5 below — they would refine the implementation detail.

---

## 5. Design directions

Refined post-research. Three directions remain plausible. The voice-first and coach-link starting hypotheses are deprioritized (iOS Whisper API reliability + niche TAM, respectively). A new direction **D0** is added as a prerequisite to all three.

### D0 (prerequisite, ships regardless of D1/D2/D3) — Pre-onboarding price disclosure

Direct response to the Fitbod 3★ "Paywall after onboarding without warning" complaint. **A 1-screen splash before the existing onboarding** that names the pricing model:

> Unit is a paid app. Set up your program first (free) — start logging from $4.99/wk.
> [Continue setup] [Restore purchases]

- **Cognitive principles**: §3 #4 Predictability ("removes the paywall surprise"), §3 #6 Clear CTAs (one primary action: Continue setup).
- **Time cost**: +5-10 seconds (one tap to continue).
- **Wow moment**: none — this isn't a wow moment, it's a trust mechanism. Honesty over hype.
- **Anti-goal served**: the "bait and switch" perception. App Store review risk reduced.
- **Risk**: users who refuse to pay drop here (saves their time AND ours, but increases install→onboard drop). Net positive — a no-pay user who completes onboarding then bounces at the paywall is no less lost.
- **Build cost**: ≤1 day. New SwiftUI screen, no logic, two CTAs.

**Recommendation: ship D0 in v2 regardless of which deeper direction we pick.**

### D1 — Paste-first, manual-banished (recommended)

Eliminate `OnboardingExercisesView` (548 lines, ~127 taps) entirely. The first program-entry screen offers only two choices:

> 1. **Paste your routine** (Notes, WhatsApp, screenshot via OCR, anywhere)
> 2. **Pick a starter program** (5 named programs — PPL, 5/3/1, Stronglifts, Upper-Lower, GZCLP)

No manual builder. After paste/pick, an **editable program preview** shows the parsed week with weights pre-filled (the 2026-06-09 day-one ghost wedge). User can edit inline before tapping "Done." Then the paywall.

- **Cognitive principles**: §3 #1 Reduced friction (24 taps max, not 127), §3 #2 Clarity of value (program visible after 1-2 taps, weights pre-filled), §3 #7 Ability+motivation (shifts cognitive work from "recall 24 exercises" to "paste / pick"), §3.7 First principles ("user has a program + needs to log fast" — entry path = paste or library; manual was overhead).
- **Time-to-paywall**: 30-45s for paste, 20-30s for library.
- **Wow moment**: the populated program preview with pre-filled weights — "Last Monday: bench 80kg. We already know."
- **Anti-goal served**: the manual builder. The r/Fitness 2016 "I just want an excel sheet, not complicated apps" persona is the exact persona we're optimizing for.
- **Risk**: a lifter who has a custom program too weird to parse AND not in the library is stuck. Mitigation: a **"refine manually"** entry path appears AFTER paste/pick when the parser flags low-confidence sections — manual lives as the edge-case repair tool, not the default.
- **Build cost**: 3-5 days. Tighten `ProgramImportParser` for English presets, harden the parsed-program preview, build the 5 starter programs into the binary, delete `OnboardingExercisesView`.

### D2 — Inverted construction (sample-and-edit)

Default to a populated 3-day full-body program on first run (Push / Pull / Legs OR Upper / Lower / Full-body — research preferred starter for self-coached intermediates). User edits / swaps / deletes before hitting paywall. No build-from-blank path at all.

- **Cognitive principles**: §3 #2 Clarity of value (instant populated program), §3 #7 Ability+motivation (editing is lower-ability than creating), §mental-models #6 High agency (user shapes it after).
- **Time-to-paywall**: 60-90s typical.
- **Wow moment**: the program is THERE on screen, ready to use, before any user input.
- **Risk**: feels like a different app's program until user shapes it — first impression is "this isn't mine." Self-coached intermediates resent "we picked for you" framing.
- **Build cost**: 2-3 days. One canonical seed program + a robust edit flow.

### D3 — Starter library only (no manual, no paste)

5 curated programs. One-tap pick → populated → paywall. No paste path. No manual builder.

- **Cognitive principles**: §3 #1 Reduced friction (3 taps max), §3 #2 Clarity of value (program visible in 2 taps).
- **Time-to-paywall**: 15-30s.
- **Wow moment**: shortest path to "I have a program."
- **Risk**: doesn't fit lifters with custom programs or coach-given routines. **TAM-killing.** A self-coached intermediate with their own program will bounce. r/Fitness 2016 quote ("not biased toward a particular program") names this exact failure mode.
- **Build cost**: 2 days. Library + populate.

### Side-by-side comparison

| Direction | Time-to-paywall | Wow moment strength | Persona fit | Build cost | TAM risk |
|---|---|---|---|---|---|
| D0 (price disclosure) | +5s | none (trust play) | universal | 1 day | none — saves bad-fit time |
| **D1 (paste + 5 programs)** | 25-45s | high (populated program + ghost weights) | best (matches Liftosaur tells + r/Fitness quote) | 3-5 days | low |
| D2 (sample-and-edit) | 60-90s | medium (program appears) | mixed (loses "this is MY program" agency) | 2-3 days | medium |
| D3 (library only) | 15-30s | low-medium | poor (excludes custom-program lifters) | 2 days | high |

### Recommendation

**Ship D0 + D1.** D0 is a free win against the documented "paywall after onboarding without warning" risk. D1 is the highest-ceiling direction that matches the self-coached intermediate persona, takes the wedge already shipped in v1 (paste-import parser), and ladders to the Liftosaur 5★ refrain of "easy to set up" without the DSL learning curve.

The next decision point is whether you want to ship D1 alone or also evaluate D2 (which has a different risk profile but lower build cost). That's §6.

---

## 6. Decision (2026-06-17)

**Direction picked: D0 + D1.**

- **D0 (pre-paywall price disclosure splash)** — 1-screen splash before the existing splash naming the pricing model + giving the user a "continue setup" CTA. Direct response to the sourced Fitbod 3★ "Paywall after onboarding" review. Ships in v2 regardless of deeper direction.
- **D1 (paste-first, manual deleted)** — the first program-entry screen offers only two paths: **Paste your routine** or **Pick one of 5 starter programs.** No manual builder. After paste/pick, an editable program preview shows the parsed week with last-time weights pre-filled. The "refine this section" rescue path appears only when the parser flags low-confidence sections.

**Why this combo**:
- D0 is documented free win against a real risk pattern (sourced § 2).
- D1 matches the self-coached intermediate persona (§ 1) + the cognitive-principle stack (§ 3 #1 Reduced friction, #2 Clarity of value, #7 Ability+motivation) + the closest indie peer's success pattern (Liftosaur, § 2 + § 4).
- The 2026-06-09 day-one ghost-weight wedge is the wow moment naturally — no new feature needed, just a moved surface.

**What was rejected**:
- D2 (sample-and-edit) — lower build cost but loses agency framing. Self-coached intermediates push back on "we picked for you" messaging.
- D3 (starter library only) — fastest ship but excludes lifters with custom programs. Directly violates the r/Fitness 2016 persona quote.

**Implementation plan**: lives in `~/.claude/plans/v2-phase-b-onboarding-redesign.md` (to be written next turn). High-level scope:

1. **D0 screen** — `OnboardingPriceDisclosureView.swift`. Static content, 2 CTAs (Continue / Restore Purchases). New SwiftUI file added to Xcode project.
2. **D1 entry rewrite** — `OnboardingImportMethodView.swift` collapses from 3 choices (Paste / History / Manual) to 2 choices (Paste / Library). The "History" branch becomes implicit in the library or paste flows.
3. **5 starter programs** — new `OnboardingStarterProgram` static catalog: Push/Pull/Legs (6d), 5/3/1 BBB (4d), Stronglifts 5×5 (3d), Upper/Lower (4d), GZCLP (4d). Each as a hardcoded `DayTemplate` struct array.
4. **Paste flow** — unchanged from v1 (ProgramImportParser already handles English and Turkish per v2 commit `fc42fa2`). Refine for "low-confidence section" detection to drive the rescue path.
5. **Editable program preview** — replaces 548-line `OnboardingExercisesView`. Inline editable rows over the parsed/picked program. Pre-fills last-time weights from paste OR from a small built-in "starter weights for this program at your bodyweight" defaults.
6. **Delete `OnboardingExercisesView`** — and its 8 supporting types. Estimated -400 to -500 LOC net.
7. **Hand-off** — at end of preview tap "Start your first workout" → hard paywall (v2 commit `f35180c`).

Estimated total: 3-5 days. /component-reuse-check before any new DS primitive. /page-audit on the new screens before they ship.

### Anti-goals (don't drift)

- Adding back the manual-build-from-blank path. (Self-coached lifters paste; beginners pick from library. Manual is repair-only.)
- Adding equipment / goals / level quiz questions. (Anti-Fitbod.)
- Adding social / sharing / community surfaces. (Anti-Hevy.)
- Adding a DSL or scripting language. (Anti-Liftosaur — they own that niche; trying to compete on programmability is a TAM cap.)
- Adding "premium" copy / interrupting paywall ads inside onboarding. (Anti-Boostcamp.)
