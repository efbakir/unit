# Unit — Product Manifesto

> The longer story behind the one-liner. For the team, for investors, for anyone who wants to understand *why* Unit exists.
> Source of truth: `product-compass.md`.

---

## The problem we noticed

There's a lifter — let's call them the veteran — who trains 4–5 times a week, has for years, and knows exactly what they're doing today. They have a program. They know their numbers. They don't need an app to tell them what to lift.

And yet, their "tracker" is a Notes file. Or a scrap of paper. Or nothing at all — just memory.

Why? Because every serious gym app they've tried makes the same mistake: it assumes the lifter needs coaching, structure, or community more than they need speed. These apps are slower than the notebook they replaced. Dropdown menus. Mandatory onboarding wizards. Rigid 8-week plans that break the moment you skip a Tuesday. Social feeds that have nothing to do with the bar in front of you.

The veteran doesn't need more features. They need fewer taps.

---

## What we believe

**The gym is a hostile environment for software.** You're fatigued. Your hands are chalked or sweaty. You have 90 seconds of rest and your phone is balanced on a bench. If logging a set takes more than 3 seconds, the app has failed. This is our Gym Test — every feature must pass it.

**History is a better coach than an algorithm.** Show the lifter what they did last time. Let them decide whether today is a day to push or a day to hold. RPE, sleep, stress — these variables are invisible to software but obvious to the athlete. We trust the lifter.

**Templates, not plans.** A program is a collection of routines you repeat. It doesn't need to be an 8-week periodisation cycle with auto-increment rules and failure modes. "Push Day A" is enough. Pick it, do it, log it.

**The app should be invisible when you're lifting.** Last time pre-fills the weight and reps. The Done button is the biggest thing on screen. The rest timer auto-starts and appears on your Lock Screen. You shouldn't have to look at the app to know it's working.

**Your data is yours.** Local-first. No account required. No cloud sync at v1. The app works in airplane mode, in a basement, on a mountain. Unit never holds your training history hostage behind a login.

---

## What Unit is

A gym logging tool that fills the gap between a paper notebook and a bloated tracker app. I call it the "notebook gap."

Unit is for the lifter who already knows their program and wants a tool that executes at the speed of thought. One tap to start. One tap per set. Last time's weight and reps handle the rest.

---

## What Unit is not

Unit is not an AI coach. It doesn't generate workouts or adjust your program. The Progression Engine exists in the codebase as a future possibility, but v1 ships without it. The algorithm's job is to stay silent until the lifter asks for it.

Unit is not a social platform. There is no feed, no profile, no likes, no leaderboard. Training is personal.

Unit is not for beginners — yet. A lifter who doesn't know what exercises to do today will find Unit unhelpful. That's a deliberate scope choice, not a permanent one.

Everything flows from it. If a design adds a tap, it needs to justify that tap against the logging speed budget. If a feature is cool but slows the core loop, it waits.

Secondary metrics we track: taps to start a workout, template creation time, session completion rate, 7-day retention.

---

## Where the engine fits

The Progression Engine — auto-increment on success, repeat on failure, deload on three consecutive misses — was Unit's original differentiator. It's elegant. It's useful. And it's not in v1.

The pivot is not a rejection of the engine. It's a sequencing decision. You can't sell a smart coach if the logging experience underneath it is slower than a Notes file. Nail the logging. Earn the right to add intelligence on top.

The engine returns when: (a) v1 logging speed is validated as best-in-class, (b) user research confirms demand for auto-progression, and (c) it can be added without slowing the core loop.

---

## The voice

Direct. Honest. No hype.

We don't say "revolutionary." We say "one tap." We don't say "AI-powered." We say "shows what you did last time." We don't compare ourselves to competitors on the marketing site. We describe what Unit does, and let the lifter decide.

The app's personality is the quiet training partner who racks your plates and doesn't talk during your set.