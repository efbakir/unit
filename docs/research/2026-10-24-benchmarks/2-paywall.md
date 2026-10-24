# Unit benchmark 2: Paywall

Grok benchmark, 2026-10-24. The bot returned this one as a table image and a summary, not a file. Transcribed here as returned.

## 1. Downsides, worst first

| # | Where Unit is weaker | Who does it better | Fix for Unit |
|---|---|---|---|
| 1 | Lapsed users can't open History or their data, and there's no export | Strong ("You will never be locked out"), Alpha (logging stays usable), Savee ("Everything you saved is right where you left it.") | A "View my history" link on the lapsed paywall that opens History read-only, plus "Your workouts are safe on this phone." |
| 2 | The analytics switch is on the paywall and on by default. Apple 5.1.1(ii) asks for consent "even if such data is considered to be anonymous" | Jomo (a trust answer with no switch next to buying) | Remove it from the paywall, ask once after purchase with the default set to No, and keep it in Settings |
| 3 | The timeline says "Day 7" instead of a date | Headspace ("You'll be charged on September 1") | Show the real date on the Day 7 row |
| 4 | The trial end and next charge dates are never shown after purchase | Blinkist ("comes into effect on Apr 2, 2026" plus "Cancel free trial"), Opal | A "Trial ends [date]" or "Renews [date]" row at the top of Settings |
| 5 | No social proof | Ladder ("4.9 stars (over 25,000 reviews)"), Hevy | One line with the real rating, once real numbers exist |
| 6 | Nothing answers cancel or refund worries | Hevy (cancel and refund questions in its FAQ) | "Cancel anytime in iPhone Settings. Refunds are handled by Apple." |
| 7 | You pay before seeing a real workout | Peloton Strength+ ("Look around"), Fitbod (paywall after the first free workout) | A "See Day 1" tap on the program card that shows Day 1 read-only |
| 8 | Users with no trial get Weekly preselected | MacroFactor (no weekly plan, 12 months preselected). RevenueCat 2026: health and fitness leads yearly adoption | Preselect Yearly for everyone |
| 9 | "Save 80% vs weekly" compares against the plan fitness buyers pick least | Hevy ("SAVE 33%" against monthly) | "Save 49% vs monthly" ($59.88 vs $29.99) |

The biggest risk outside the table is the hard gate itself. RevenueCat 2025 puts hard paywalls at a 12.11% median conversion vs 2.18% for freemium (day 35), but warns they "risk higher churn if users feel locked in too early".

## 2. What Unit does better

- The billed price is the headline. Fitbod leads with "That's only $6.67 per month!"
- You can see and turn off the 2-day reminder, while Jomo only promises one 24h before.
- "Your program is ready" beats Hevy's and Ladder's generic feature lists.
- Monthly gets a trial too, while Alpha only offers one on Yearly.
- Lifetime costs $44.99, vs Hevy's $74.99.

## 3. Top 3 changes

1. Move the analytics switch: an App Review risk, and almost free to fix.
2. Keep History readable for lapsed users.
3. Show real charge dates.

## Gaps

- Mobbin doesn't show capture dates, and the Headspace screen looks like 2025.
- Strong and Alpha come from their own pages, with no screenshots. Boostcamp and Napper were not checked.
- No hard data found on whether real dates, refund lines or ratings raise conversion. The Blinkist "+23%" figure was left out because it is unverified.
- RevenueCat's 2026 fitness page calls the same 68% both yearly and monthly in different places.
- Reference screens (Mobbin, captured 2026-10-24): Headspace, Hevy, Fitbod, MacroFactor, Ladder, AllTrails, Blinkist, Savee, Strava, Peloton Strength+, Jomo. The board image is not stored in the repo (Mobbin content).
