// Per-slug content for the /compare/[slug] route.
// Voice: peer-to-peer, calm, honest. Never bash a competitor.
// No em-dashes in body copy (use commas, semicolons, parens, periods).

export type CompareRow = {
  feature: string
  unit: string
  competitor: string
}

export type CompareSlug = {
  slug: string
  competitor: string
  // Used in the H1 / title / metadata.
  metaTitle: string
  metaDescription: string
  // Hero headline + single subhead line.
  heroSubhead: string
  // 4 to 6 row comparison.
  table: CompareRow[]
  // "When [competitor] is the right choice" (generous, short).
  whenCompetitor: string
  // "When Unit is the right choice" (concrete, no hype).
  whenUnit: string
  // Closing line above the CTA.
  closing: string
}

export const compareSlugs: Record<string, CompareSlug> = {
  "unit-vs-strong": {
    slug: "unit-vs-strong",
    competitor: "Strong",
    metaTitle: "Unit vs Strong: progression-guided gym logging",
    metaDescription:
      "Looking for a Strong app alternative? Unit combines one-tap gym logging with one transparent next-workout target. No account, local-first, under 3 seconds per set.",
    heroSubhead:
      "Both log sets. Unit is built around one clear next target after the workout.",
    table: [
      {
        feature: "Speed per set",
        unit: "Weight and reps from last time, already there. One tap to log.",
        competitor: "Manual entry per set, with templates and history nearby.",
      },
      {
        feature: "Account",
        unit: "None. No sign-up, no email required.",
        competitor: "Optional account for cloud sync and cross-device history.",
      },
      {
        feature: "Next target",
        unit: "One post-workout suggestion with the last result and reason beside it.",
        competitor: "History and charts help you decide how to progress.",
      },
      {
        feature: "Pricing",
        unit: "One subscription includes everything. $2.99/wk, $4.99/mo, or $29.99/yr. Setup is free.",
        competitor: "Free with a workout cap; Pro unlocks unlimited workouts.",
      },
      {
        feature: "Offline",
        unit: "Always offline. Data lives on your device.",
        competitor: "Works offline; Pro syncs through the cloud.",
      },
      {
        feature: "Programmability",
        unit: "Paste any routine from Notes. Unit parses sets and reps.",
        competitor: "Build routines in-app; broad library and editor.",
      },
    ],
    whenCompetitor:
      "If you want a deep stats screen with charts, body measurements, and cross-device sync that updates between phone and tablet, Strong is well-built and widely supported. It is the right choice if you like a richer dashboard and you do not mind making an account.",
    whenUnit:
      "Pick Unit if you want the log and the next decision in one quiet flow. Paste your program or choose a ready-made match, log each set in one tap, then see one transparent target for next time, with its reason.",
    closing:
      "Unit is the calmer Strong alternative for lifters who want fast logging and one clear next step.",
  },

  "unit-vs-hevy": {
    slug: "unit-vs-hevy",
    competitor: "Hevy",
    metaTitle: "Unit vs Hevy: private progressive overload tracking",
    metaDescription:
      "A Hevy alternative without the social feed. Unit logs sets in one tap and prepares one transparent progressive overload target for next time.",
    heroSubhead:
      "Both can log a set. Unit keeps the next target private, local, and separate from social.",
    table: [
      {
        feature: "Speed per set",
        unit: "Last session's numbers, already filled in. Tap Done.",
        competitor: "Type sets per workout; templates speed it up.",
      },
      {
        feature: "Social and feed",
        unit: "No social, no followers, no likes. Logging is private.",
        competitor: "Built-in social feed, followers, comments, likes.",
      },
      {
        feature: "Next target",
        unit: "One post-workout target with its reason, saved for you and easy to undo.",
        competitor: "History, charts, and routine tools support your own progression choices.",
      },
      {
        feature: "Account",
        unit: "None required. Local-only by default.",
        competitor: "Account required for sync and social.",
      },
      {
        feature: "Pricing",
        unit: "One subscription includes everything. $2.99/wk, $4.99/mo, or $29.99/yr. Setup is free.",
        competitor: "Free tier with limits; Pro unlocks routines and analytics.",
      },
      {
        feature: "Offline",
        unit: "Always works offline. No connection, no problem.",
        competitor: "Works offline; syncs when online.",
      },
    ],
    whenCompetitor:
      "If you train alongside a community, like seeing what friends lifted today, and want a discovery feed of routines from other people, Hevy is built for that. It is genuinely good at the social side and at sharing your workouts.",
    whenUnit:
      "Pick Unit if the feed is noise and the next decision matters. Log in under three seconds, keep raw workout details on your iPhone, then review one clear target without giving up control of your program.",
    closing:
      "Unit is the no-social Hevy alternative for lifters who want a private log and a clear next target.",
  },

  "unit-vs-jefit": {
    slug: "unit-vs-jefit",
    competitor: "Jefit",
    metaTitle: "Unit vs Jefit: simple progressive overload tracking",
    metaDescription:
      "A Jefit alternative built for simple progressive overload. Paste your program, log in one tap, and review one clear next-workout target.",
    heroSubhead:
      "A smaller logger focused on one clear next step.",
    table: [
      {
        feature: "Speed per set",
        unit: "Weight and reps from last time, already there. One tap.",
        competitor: "Manual entry with a routine player and rest cues.",
      },
      {
        feature: "Account",
        unit: "None. No sign-up, no profile, no password.",
        competitor: "Account required for routines and sync.",
      },
      {
        feature: "Exercise library",
        unit: "Built-in catalog with around 135 exercises.",
        competitor: "Large library with images and animations.",
      },
      {
        feature: "Next target",
        unit: "One post-workout target with a visible reason and one-tap undo.",
        competitor: "Plans, logs, and reports support broader training decisions.",
      },
      {
        feature: "Pricing",
        unit: "One subscription includes everything. $2.99/wk, $4.99/mo, or $29.99/yr. Setup is free.",
        competitor: "Free with ads; Elite removes ads and unlocks features.",
      },
      {
        feature: "Offline",
        unit: "Always offline. Data lives on the device.",
        competitor: "Works offline; cloud sync for premium tiers.",
      },
    ],
    whenCompetitor:
      "If you want exercise images, animations, and a deep library you can browse on the gym floor, Jefit has spent years building that. It is the right tool for a lifter who wants a coach-like reference inside the same app.",
    whenUnit:
      "Pick Unit if you want fast logging and a smaller next decision. No account and no ads. One target appears after the workout, with its reason, and you can change it in one tap.",
    closing:
      "Unit is the quieter Jefit alternative for one-tap logging and transparent next targets.",
  },
}

export const compareSlugList = Object.keys(compareSlugs)
