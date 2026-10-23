# Persona panel, MiroFish method — 2026-10-23

Synthetic product test of Unit 2.1 before submission. 20 simulated gym-goers walked through the real flows, then argued about Unit in a Reddit-style thread. Treat everything here as hypotheses to check with real data, not as user research.

## Why not the real MiroFish

- [MiroFish](https://github.com/666ghj/MiroFish) needs a Zep Cloud key (mandatory, self-hosting blocked in code) and an LLM key. Neither exists on this Mac, and creating accounts is not something I do for you.
- It also simulates public opinion on Twitter- and Reddit-like feeds. Its agents can't use an app, so it can't test onboarding or a paywall.
- So the method was copied with Claude agents: seed facts → personas with memory → simulated decisions → social rounds with an injected change → interviews → report. Clone and notes: `scratchpad/mirofish-src` (not in the repo).

## Setup

- Seed: the real 2.1 flows, App Store listing, paywall and pricing, competitors' public prices.
- 20 personas in 4 segments: beginners (US, UK, BR, TR, IN), intermediate program followers (Hevy, Strong, Sheets, Notes users), strength and coached lifters (5/3/1, GZCLP, RPE, a coach with 30 clients), busy and returning adults (post-baby, 55 with large text, privacy-minded, subscription-averse, traveller).
- Each persona walked: App Store page → setup → paywall → first workout → week 1 → day 7 → month 3, under two variables:
  - O-A current 5-step setup vs O-B 3-step setup (unit guessed, no weekday step).
  - P-A Monthly preselected vs P-B Yearly preselected.

SOCIAL_BLOCK

## What the panel said (all 4 segments)

**Variants**
- O-B (3-step setup) helped a little in every segment: 1.5 to 2.5 minutes faster, no "Rest day" on an unplanned first day. Nobody quit at the weekday step in O-A, so the gain is speed and the first-day trap, not completion. Risk: the region unit guess is wrong for lb lifters in metric regions (Canada) → shipped the review-screen switch that re-reads plain numbers.
- P-B (Yearly preselected) hurt or did nothing in all 4 segments: careful people switch back to Monthly or leave, fast tappers pay $29.99 by mistake on day 7 and ask for refunds. **Shipped P-A (Monthly).** The Yearly test stays built but off.

**Biggest frictions**
1. Hard paywall after setup, under a "Free" App Store label, with no free look beyond the trial. Every segment's main objection.
2. Weekly $2.99 read as a trap by most who saw it, worse when preselected for people who already used a trial; "Save 80%" read as a fake anchor.
3. Ready-made fixed-rep programs never showed "Suggested next" (26 of 27 programs), so the headline promise didn't appear.
4. Paste breaks on RPE, AMRAP, supersets and percent-based lines; coached lifters quit at review.
5. First workout on a ready-made program has blank weights ("Set weight and reps"); returners don't know their numbers.
6. "Use next workout" was read as "go to the next workout".

**Biggest delights**
1. "Suggested next" on the finished exercise card plus a written reason on the summary.
2. Lock Screen rest timer that starts by itself.
3. One-tap Complete set with last-time prefill and 5-second Undo.
4. Pasting a program from Notes when it parses.

**Churn reasons beyond price**: no history import from Hevy or Strong, no iCloud backup, no Apple Health or Watch, no percent-of-max or RPE support, no gentle restart after weeks off, no way to pause instead of cancel.

**Pricing**: Monthly is the plan people choose on purpose. Yearly only for planners who would pick it anyway. Lifetime is the plan subscription-averse people respect (one path: Monthly trial, cancel renewal, buy Lifetime). Price levels matched Strong; the objection was the hard paywall, not the numbers.

**Directional funnel** (agents' own estimates per 100 store-page viewers, wide error): 10 to 25 install, 7 to 15 finish setup, 3 to 5 start a trial, 1 to 3 pay, 0 to 2 still paying at month 3.

## What shipped in build 94 because of it

| Panel signal | Change |
|---|---|
| Yearly default hurts trust | Monthly preselected for everyone; Yearly test off |
| Weekly preselected for returners reads as a trap | Monthly default without a trial too; Weekly still listed |
| "Save 80%" fake anchor | "Save 49%" against Monthly |
| Fixed-rep programs show no suggestions | Standard rule on ready-made programs' weighted lifts |
| Reminder off looks sneaky | Trial reminder on by default |
| "Use next workout" misread | "Save for next workout" |
| Weekday step and first-day "Rest day" | 3-step setup, flexible rotation by default |
| Region unit wrong for some lifters | kg/lb switch on review re-reads unit-free numbers |

## Still open from the panel

- A free look before paying (a sample workout before the paywall) — conflicts with the hard-paywall decision; worth a real test later.
- History import from Hevy and Strong (CSV) for switchers.
- Percent-of-training-max and RPE in paste and logging (strength segment).
- Gentle restart after a gap; pause instead of cancel; "your history stays on your phone" at cancel.
- Remove Weekly entirely if real data shows nobody buys it.

## Caveats

- Personas are generated by the same kind of model that wrote the product, so they share its blind spots. They are biased toward people who already want a logger.
- Numbers are role-play estimates, not rates. Use the reasons and the ordering.
- Full transcripts (not in the repo): `journeys-beginners.md`, `journeys-intermediates.md`, `journeys-strength.md`, `journeys-returning.md`, `social.md` in this session's scratchpad.
