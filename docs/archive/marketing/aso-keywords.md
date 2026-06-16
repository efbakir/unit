# Unit — ASO keyword strategy

> 100-keyword candidate list categorized by intent + competition. Final 100-char Keywords field string at the end.
> Source: 2026-04-29 industry-tools research + competitor App Store metadata teardown (`docs/competitors.md`).
> Apple Keywords field rule: 100 chars total, comma-separated, NO spaces after commas. Trademarks (Hevy, Strong, Liftosaur, Fitbod, Jefit) are auto-rejected — use generic alternatives only.

---

## Methodology

Keywords scored on three axes:

| Tier | Search-volume | Competition | Indie-ownability |
|---|---|---|---|
| **High** | 50k+ monthly searches | Top 5 dominated by 4-figure-MRR apps | Impossible without paid ads |
| **Medium** | 5k–50k | Top 10 mixed indie + medium | Hard but possible with strong listing |
| **Low** | <5k | Top 10 has indie spots | Own-able for indie |
| **Unknown** | No reliable signal | — | Test post-launch |

**Placement rules**:
- **App Name** (≤30 chars): the single highest-impact keyword field. Apple weights it ~10× the Keywords field.
- **Subtitle** (≤30 chars): second-highest weight. Indexed as keywords.
- **Keywords field** (≤100 chars total): lower weight than App Name/Subtitle but still ranked. Use ONLY keywords NOT already in App Name or Subtitle (no double-dipping; Apple already indexes both).
- **Description body**: minimal direct ranking impact; matters for human conversion, not algorithm.

---

## Bucket 1 — High-intent direct-match (20 keywords)

These are the obvious "what is this app" search terms. High volume but high competition. Placement: usually App Name + Subtitle (already covered in `app-store-copy-variants.md`); the rest go in Keywords field selectively.

| # | Keyword | Volume | Competition | Placement |
|---|---|---|---|---|
| 1 | gym tracker | High | Hard | Keywords field |
| 2 | workout log | High | Hard | Keywords field |
| 3 | strength log | Medium | Medium | Keywords field |
| 4 | weight training log | Medium | Medium | Description |
| 5 | lifting tracker | Medium | Medium | Keywords field |
| 6 | set tracker | Medium | Medium | Keywords field |
| 7 | rep counter | Medium | Medium | Keywords field |
| 8 | gym logger | Medium | Medium | App Name (alternative) |
| 9 | workout tracker | High | Hard | Description (saturated) |
| 10 | strength tracker | Medium | Medium | Description |
| 11 | barbell tracker | Low | Low | Keywords field ✅ |
| 12 | lifting log | Medium | Medium | Keywords field |
| 13 | gym notes | Low | Low | Description |
| 14 | training log | Medium | Medium | Description |
| 15 | powerlifting tracker | Low | Low | Keywords field ✅ |
| 16 | bodybuilding tracker | Low | Medium | Description |
| 17 | workout history | Medium | Medium | Description |
| 18 | exercise log | Medium | Medium | Description |
| 19 | training tracker | Medium | Medium | Description |
| 20 | sets and reps | Low | Low | Keywords field ✅ |

---

## Bucket 2 — Long-tail differentiator (25 keywords)

Multi-word phrases that signal Unit's specific positioning. Lower volume per keyword but much higher conversion intent and own-able for indie.

| # | Keyword | Volume | Competition | Placement |
|---|---|---|---|---|
| 21 | fast gym logging | Low | Low | Description ✅ |
| 22 | one tap workout log | Low | Low | Description ✅ |
| 23 | offline gym tracker | Low | Low | Description ✅ |
| 24 | local gym app | Low | Low | Description ✅ |
| 25 | no social gym tracker | Low | Low | Description ✅ |
| 26 | simple workout log | Medium | Medium | Description |
| 27 | minimalist gym tracker | Low | Low | Description ✅ |
| 28 | gym notebook app | Low | Low | App Name (alt for Variant 1) ✅ |
| 29 | no account gym app | Low | Low | Description ✅ |
| 30 | program import workout | Low | Low | Description ✅ |
| 31 | paste workout from notes | Low | Low | Description ✅ |
| 32 | rest timer lock screen | Low | Low | Description ✅ |
| 33 | dynamic island gym timer | Low | Low | Description ✅ |
| 34 | ghost fill workout | Low | Low | Description ✅ |
| 35 | no AI workout app | Low | Low | Description ✅ |
| 36 | one-handed gym tracker | Low | Low | Description ✅ |
| 37 | intermediate lifter tracker | Low | Low | Description ✅ |
| 38 | advanced lifter app | Low | Low | Description ✅ |
| 39 | custom program tracker | Low | Low | Description ✅ |
| 40 | coach program logger | Low | Low | Description ✅ |
| 41 | lifting session log | Low | Low | Keywords field ✅ |
| 42 | fast set logging | Low | Low | Keywords field ✅ |
| 43 | workout template app | Low | Low | Description |
| 44 | paper notebook replacement | Low | Low | Description ✅ |
| 45 | set logging app | Low | Low | Keywords field ✅ |

---

## Bucket 3 — Generic competitor-category (10 keywords)

Generic category terms. **Literal trademarks (Hevy, Strong, Liftosaur, Jefit, Fitbod) are excluded** — Apple's algorithm rejects them at submission and risks the listing.

| # | Keyword | Volume | Competition | Placement | Notes |
|---|---|---|---|---|---|
| 46 | workout tracker app | High | Hard | Description | Saturated category term |
| 47 | gym log app | Medium | Medium | Description | Generic, safe |
| 48 | fitness tracker app | High | Impossible | Skip | Wrong vertical (cardio/health-app dominated) |
| 49 | weight lifting app | High | Hard | Description | Saturated |
| 50 | lifting app iphone | Medium | Medium | Description | Specific platform signal |
| 51 | strength app ios | Medium | Medium | Description | Specific platform signal |
| 52 | barbell workout app | Low | Low | Description ✅ | Niche, own-able |
| 53 | gym session app | Low | Low | Description ✅ | Lower competition |
| 54 | workout session tracker | Low | Low | Description ✅ | |
| 55 | fitness log app | Medium | Medium | Description | |

⚠️ **Do not include in Keywords field**: Hevy, Strong, Liftosaur, Jefit, Fitbod. Apple rejects literal trademarks. Mention in description body only with care ("a lighter alternative to apps like [generic phrasing]" rather than naming).

---

## Bucket 4 — Niche audience (25 keywords)

Targeted at specific lifter sub-niches. Each keyword has a small audience but high purchase intent — these convert better than the generic Bucket 1 terms for an indie app.

| # | Keyword | Volume | Competition | Placement |
|---|---|---|---|---|
| 56 | PPL tracker | Low | Low | Keywords field ✅ |
| 57 | push pull legs log | Low | Low | Description ✅ |
| 58 | powerlifting log | Low | Low | Keywords field ✅ |
| 59 | hypertrophy tracker | Low | Low | Description ✅ |
| 60 | RPE logging | Low | Low | Description ✅ |
| 61 | strength program tracker | Low | Low | Description ✅ |
| 62 | gym routine builder | Low | Low | Description |
| 63 | training template app | Low | Low | Description |
| 64 | custom routine tracker | Low | Low | Description ✅ |
| 65 | barbell program log | Low | Low | Description ✅ |
| 66 | wendler 531 log | Low | Low | Description ✅ |
| 67 | training week log | Low | Low | Description |
| 68 | exercise PR tracker | Low | Low | Description ✅ |
| 69 | personal best gym | Low | Low | Description |
| 70 | set history app | Low | Low | Description |
| 71 | program builder gym | Low | Low | Description |
| 72 | GZCLP tracker | Low | Low | Description ✅ |
| 73 | custom split tracker | Low | Low | Description |
| 74 | natural bodybuilding log | Low | Low | Description ✅ |
| 75 | bodyweight tracker | Low | Medium | Description (overlap w/ calisthenics apps) |
| 76 | competition prep tracker | Low | Low | Description |
| 77 | nsuns log | Low | Low | Description ✅ |
| 78 | reddit PPL tracker | Low | Low | Description ✅ |
| 79 | home gym tracker | Low | Low | Description ✅ |
| 80 | garage gym log | Low | Low | Description ✅ |

---

## Bucket 5 — Wrong-but-tempting (20 keywords NOT to chase)

These look like easy wins but conflict with Unit's positioning, ICP, or brand voice. Listed with reasons NOT to use.

| # | Keyword | Why NOT |
|---|---|---|
| 81 | AI personal trainer | Anti-positioning — Unit is explicitly anti-AI |
| 82 | calorie counter | Wrong vertical (nutrition, not strength) |
| 83 | HIIT timer | Overlapping but wrong context, dominated by HIIT-specific apps |
| 84 | step counter | Wrong category entirely (activity tracking) |
| 85 | workout planner | Implies prescriptive — Unit doesn't tell you what to lift |
| 86 | diet tracker | Wrong vertical |
| 87 | yoga tracker | Wrong audience |
| 88 | running log | Wrong sport, dominated by Strava/Nike Run |
| 89 | CrossFit tracker | Niche with dedicated apps (BTWB, etc.); not Unit's positioning |
| 90 | weight loss app | Wrong ICP |
| 91 | beginner workout | Anti-persona (Unit is for intermediate-to-advanced) |
| 92 | personal trainer app | Implies coaching — banned from positioning |
| 93 | transformation app | Lifestyle-marketing framing, breaks brand voice |
| 94 | fitness challenge | Gamification — anti-pattern per `PRODUCT.md` |
| 95 | bodybuilding app | Branded/saturated; Jefit owns this term |
| 96 | gym membership tracker | Wrong product category entirely |
| 97 | workout reminder | Feature not product; confusing intent signal |
| 98 | protein tracker | Wrong vertical |
| 99 | macro tracker | Wrong vertical |
| 100 | fitness journal | Close but dominated by generic apps; low conversion |

---

## Final Keywords field string (100 chars)

```
gym tracker,workout log,strength log,lifting log,rest timer,gym notebook,set tracker,rep counter
```

`97 chars` ✅ (3-char buffer for any future tweak)

### Per-keyword justification

- `gym tracker` (11) — high-volume direct-match, must include
- `workout log` (11) — high-volume direct-match, must include
- `strength log` (12) — medium-volume, signals lifter-specific (vs generic fitness)
- `lifting log` (11) — variant on workout log, captures different searcher phrasing
- `rest timer` (10) — feature-specific differentiator (Lock Screen + Dynamic Island angle)
- `gym notebook` (12) — anchors the Variant 1 positioning if Variant 1 ships
- `set tracker` (11) — direct-match niche term, lower competition
- `rep counter` (11) — paired with set tracker, captures both halves of the loop

**Total**: 97 chars including separators. Apple will parse each comma-separated entry as a discrete keyword + index 2-grams within multi-word entries.

**NOT in this string but in App Name / Subtitle** (so already indexed):
- App Name: "Unit" (or longer App Name variant decided in `app-store-copy-variants.md`)
- Subtitle: depends on chosen variant (notebook / no-coach / under-3-seconds)

**Why these 8 vs alternatives**:
- Picked direct-match + feature-specific + variant-anchor mix
- Excluded all literal competitor names (Apple-rejection risk)
- Excluded "fast" and "quick" prefixes (subjective; not strong search anchors)
- Excluded "AI", "no AI" (negative phrasing doesn't index well)
- Excluded numerals / programs (5x5, 531, etc. — they go in description, not Keywords)

---

## What to test post-launch

**AppFigures monitoring** (set up W3 per `tools.md`):
- Track ranking on each of the 8 Keywords field entries weekly
- Track ranking on each Bucket 1 keyword (gym tracker, workout log, etc.) weekly
- Track ranking on the 5-10 Bucket 2 long-tails most likely to convert (no account gym app, gym notebook app, minimalist gym tracker, fast set logging)

**Trigger conditions for keyword changes**:
- A Keywords field entry not in top 50 after 4 weeks → swap for a Bucket 2 long-tail
- A Keywords field entry already in top 10 → consider rotating out (you're already discoverable for it; freeing the slot may yield more)
- A Bucket 2 long-tail converting unusually well (high tap-through ratio in App Store Connect) → promote to Keywords field, swap a weaker direct-match out

**Quarterly review**:
- Update the Keywords field at most once per quarter (Apple counts metadata changes against review priority; minimize)
- Each change is logged in `docs/marketing/research/aso-keyword-experiments.md` (file to be created when first change happens) with date, before/after rankings, and reasoning

---

## Don't ever do

- ❌ Stuff Keywords field with literal competitor trademarks (auto-reject + listing-risk)
- ❌ Use Keywords field as a thesaurus dump ("track,tracker,tracking,logged,logging" — Apple ignores after 2-3 stems)
- ❌ Repeat words from App Name / Subtitle in Keywords field (waste of slot)
- ❌ Include emoji or special chars (Apple ignores them and they count toward the 100-char limit)
- ❌ Hand-translate keywords to other languages — Apple has separate per-locale Keywords fields; localize when you actually localize the listing
- ❌ Use "best" / "top" / "fastest" superlatives — Apple's review team rejects superlative-stuffed keyword fields

---

## See also

- `docs/marketing/app-store-copy-variants.md` — the listing copy these keywords pair with
- `docs/marketing/research/industry-tools-2026-04-29.md` §4 — ASO tools recommendation (AppFigures)
- `docs/marketing/research/viral-patterns-2026-04-29.md` §7 — App Store conversion research
- `docs/competitors.md` — competitor App Store metadata for comparison
