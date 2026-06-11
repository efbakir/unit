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
    metaTitle: "Unit vs Strong: a faster, local-first gym tracker",
    metaDescription:
      "Looking for a Strong app alternative? Unit is a minimalist gym tracker for fast gym logging. Last session's weights ready, no account, local-first, under 3 seconds per set.",
    heroSubhead:
      "Both log sets. The difference is how much they ask of you between sets.",
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
        feature: "Social and feed",
        unit: "None by design. No followers, no likes.",
        competitor: "No public feed; some sharing features exist.",
      },
      {
        feature: "Pricing",
        unit: "Core logging is free forever. Pro is $4.99/mo or $29.99/yr.",
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
      "Pick Unit if logging is the bottleneck. You already know your program, you train with one hand, and you want the set in the log before you re-rack the bar. No account, no cloud, just the numbers on your device.",
    closing:
      "Unit is the calmer Strong app alternative for lifters who already know what they are doing.",
  },

  "unit-vs-hevy": {
    slug: "unit-vs-hevy",
    competitor: "Hevy",
    metaTitle: "Unit vs Hevy: a no-social, offline gym tracker",
    metaDescription:
      "A Hevy alternative without the social feed. Unit is a no social gym tracker, offline gym tracker, where last time fills in weight and reps for one-tap logging. Calm by default.",
    heroSubhead:
      "Both can log a set. Only one is built around a feed.",
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
        feature: "Account",
        unit: "None required. Local-only by default.",
        competitor: "Account required for sync and social.",
      },
      {
        feature: "Pricing",
        unit: "Free for core logging. Pro is $4.99/mo or $29.99/yr.",
        competitor: "Free tier with limits; Pro unlocks routines and analytics.",
      },
      {
        feature: "Offline",
        unit: "Always works offline. No connection, no problem.",
        competitor: "Works offline; syncs when online.",
      },
      {
        feature: "Programmability",
        unit: "Paste from Notes or build in two minutes.",
        competitor: "Routine builder with shared community routines.",
      },
    ],
    whenCompetitor:
      "If you train alongside a community, like seeing what friends lifted today, and want a discovery feed of routines from other people, Hevy is built for that. It is genuinely good at the social side and at sharing your workouts.",
    whenUnit:
      "Pick Unit if the feed is noise. You want the set logged in under three seconds, your data on your device, and nothing else asking for your attention. Same effort as paper, smaller surface area than Hevy.",
    closing:
      "Unit is the no social gym tracker, an offline gym tracker, and a calmer Hevy alternative for solo lifters.",
  },

  "unit-vs-jefit": {
    slug: "unit-vs-jefit",
    competitor: "Jefit",
    metaTitle: "Unit vs Jefit: a no-account, local gym logger",
    metaDescription:
      "A Jefit alternative built for speed. Unit is a gym logger with no account and a local gym app footprint. Paste your program; last time handles the rest.",
    heroSubhead:
      "Same goal, smaller surface area.",
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
        feature: "Social and feed",
        unit: "None. Training stays personal.",
        competitor: "Community features, friends, and shared routines.",
      },
      {
        feature: "Pricing",
        unit: "Free for core logging. Pro is $4.99/mo or $29.99/yr.",
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
      "Pick Unit if you already know the lift and you want the log done. No account, no ads, no extras between you and the next set. A local gym app, in the literal sense.",
    closing:
      "Unit is the gym logger no account variant, a local gym app, a quieter Jefit alternative.",
  },
}

export const compareSlugList = Object.keys(compareSlugs)
