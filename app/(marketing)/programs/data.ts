// Per-slug content for the /programs/[slug] route.
// Each program has a public, widely-published structure. The paste templates
// below are written in a format Unit's onboarding parser reads (one exercise
// per line, sets x reps, optional weight). No copyrighted text, just the
// structure that any lifter could write into Notes.

export type ProgramSlug = {
  slug: string
  title: string
  // H1 + meta heading.
  h1: string
  metaTitle: string
  metaDescription: string
  // Description paragraph.
  description: string
  // Pre-formatted paste template, ready for Unit's onboarding paste flow.
  template: string
  // Three numbered onboarding steps. Keep each terse.
  importSteps: [string, string, string]
  // Closing line above CTA.
  closing: string
}

export const programSlugs: Record<string, ProgramSlug> = {
  ppl: {
    slug: "ppl",
    title: "PPL (Push Pull Legs)",
    h1: "PPL (Push Pull Legs) in Unit",
    metaTitle: "PPL in Unit: import push pull legs in 30 seconds",
    metaDescription:
      "PPL workout app for serious lifters. Paste a Push Pull Legs split into Unit and start logging in 30 seconds. Push pull legs tracker, last session's weights ready, no account.",
    description:
      "Push Pull Legs is a six-day split that hits each muscle group twice per week. Push days cover chest, shoulders, and triceps. Pull days cover back and biceps. Leg days cover quads, hamstrings, and calves. The split below is a common intermediate version with a flat top set followed by back-off work.",
    template: `Push A
Bench Press 4x6
Overhead Press 3x8
Incline Dumbbell Press 3x10
Cable Fly 3x12
Triceps Pushdown 3x12
Overhead Triceps Extension 3x12

Pull A
Deadlift 3x5
Barbell Row 4x8
Pull Up 3x8
Cable Row 3x10
Face Pull 3x15
Barbell Curl 3x10

Legs A
Squat 4x6
Romanian Deadlift 3x8
Leg Press 3x10
Leg Curl 3x12
Standing Calf Raise 4x12

Push B
Overhead Press 4x6
Bench Press 3x8
Dumbbell Shoulder Press 3x10
Lateral Raise 4x12
Close Grip Bench 3x8
Triceps Pushdown 3x12

Pull B
Barbell Row 4x6
Weighted Pull Up 3x6
Cable Row 3x10
Lat Pulldown 3x12
Face Pull 3x15
Dumbbell Curl 3x10

Legs B
Front Squat 4x6
Romanian Deadlift 3x8
Walking Lunge 3x10
Leg Extension 3x12
Seated Calf Raise 4x12`,
    importSteps: [
      "Open Unit and tap Get Started. On the import step, choose Paste text.",
      "Paste the template above. Unit reads each day, exercise, sets, and reps.",
      "Confirm and tap Done. Your first session opens with last time's numbers waiting.",
    ],
    closing:
      "PPL is a great fit for a push pull legs tracker that stays out of the way.",
  },

  "wendler-531": {
    slug: "wendler-531",
    title: "5/3/1",
    h1: "Wendler 5/3/1 in Unit",
    metaTitle: "5/3/1 in Unit: import Wendler 5/3/1 in 30 seconds",
    metaDescription:
      "5/3/1 app for the four-week wave. Paste your Jim Wendler 5/3/1 tracker template into Unit and start logging immediately. Local, fast, no account.",
    description:
      "5/3/1 by Jim Wendler is a four-week strength template built around four main lifts (squat, bench, deadlift, press). Each week prescribes top sets at 5, 3, then 5/3/1 reps based on a training max (usually 90% of your true max). Below is a single week of the classic main work; rotate weights using your training max each cycle.",
    template: `Day 1 Press
Overhead Press 5x65%, 5x75%, 5x85%
Dips 5x10
Chin Up 5x10

Day 2 Deadlift
Deadlift 5x65%, 5x75%, 5x85%
Good Morning 5x10
Hanging Leg Raise 5x12

Day 3 Bench
Bench Press 5x65%, 5x75%, 5x85%
Dumbbell Bench Press 5x10
Barbell Row 5x10

Day 4 Squat
Squat 5x65%, 5x75%, 5x85%
Leg Press 5x15
Leg Curl 5x10`,
    importSteps: [
      "Open Unit and tap Get Started. On the import step, choose Paste text.",
      "Paste the template above. Unit reads each day and main lift; percentages stay as notes you can interpret each week.",
      "Set your training max per lift in the exercise sheet and tap Done. Unit carries your last working weight forward.",
    ],
    closing:
      "Use Unit as a Jim Wendler 5/3/1 tracker that respects your time between sets.",
  },

  gzclp: {
    slug: "gzclp",
    title: "GZCLP",
    h1: "GZCLP in Unit",
    metaTitle: "GZCLP in Unit: import GZCLP in 30 seconds",
    metaDescription:
      "GZCLP tracker app built for the four-day linear progression. Paste GZCLP into Unit and start logging in 30 seconds. Last session's weights ready, local, no account.",
    description:
      "GZCLP by Cody Lefever is a four-day linear progression structured around three tiers: T1 main lifts (heavy 5x3 then AMRAP), T2 secondary (3x10), and T3 accessories (3x15 AMRAP on the last set). Run it three to four times per week, alternating Squat and Deadlift days against Bench and Press days.",
    template: `Day A1 Squat and Bench
Squat T1 5x3 then 1xAMRAP
Bench Press T2 3x10
Lat Pulldown T3 3x15

Day B1 OHP and Deadlift
Overhead Press T1 5x3 then 1xAMRAP
Deadlift T2 3x10
Dumbbell Row T3 3x15

Day A2 Bench and Squat
Bench Press T1 5x3 then 1xAMRAP
Squat T2 3x10
Lat Pulldown T3 3x15

Day B2 Deadlift and OHP
Deadlift T1 5x3 then 1xAMRAP
Overhead Press T2 3x10
Dumbbell Row T3 3x15`,
    importSteps: [
      "Open Unit and tap Get Started. On the import step, choose Paste text.",
      "Paste the template. Unit reads each day, lift, and rep target.",
      "On the AMRAP set, log the actual reps you hit; last time fills in the rest.",
    ],
    closing:
      "Run GZCLP with a tracker that stays quiet between sets.",
  },

  nsuns: {
    slug: "nsuns",
    title: "nSuns 5/3/1",
    h1: "nSuns 5/3/1 in Unit",
    metaTitle: "nSuns in Unit: import nSuns 5/3/1 in 30 seconds",
    metaDescription:
      "nSuns 5/3/1 app for high-volume training. Paste the nSuns tracker template into Unit and start logging fast. Local-first, no account, last session's weights ready.",
    description:
      "nSuns 5/3/1 is a high-volume linear-progression variant of Wendler's 5/3/1. Each main lift day runs 9 working sets at climbing then descending percentages of training max, followed by a secondary lift on the same plan plus accessories. The 4-day version below covers Bench, Squat, Overhead Press, and Deadlift weekly.",
    template: `Day 1 Bench and OHP
Bench Press 8x5 (75 to 95% TM, 9 sets)
Overhead Press 6x5 (50 to 80% TM, 8 sets)
Lat Pulldown 3x12
Barbell Row 3x12
Triceps Pushdown 3x12

Day 2 Squat and Sumo Deadlift
Squat 8x5 (75 to 95% TM, 9 sets)
Sumo Deadlift 6x5 (50 to 80% TM, 8 sets)
Leg Curl 3x12
Leg Extension 3x12
Standing Calf Raise 3x15

Day 3 OHP and Incline Bench
Overhead Press 8x5 (75 to 95% TM, 9 sets)
Incline Bench Press 6x6 (50 to 80% TM, 8 sets)
Cable Row 3x12
Face Pull 3x15
Barbell Curl 3x10

Day 4 Deadlift and Front Squat
Deadlift 8x5 (75 to 95% TM, 9 sets)
Front Squat 6x5 (50 to 80% TM, 8 sets)
Romanian Deadlift 3x10
Hanging Leg Raise 3x12
Standing Calf Raise 3x15`,
    importSteps: [
      "Open Unit and tap Get Started. On the import step, choose Paste text.",
      "Paste the template. Unit reads each day and lift; the percentage notes stay alongside.",
      "Enter your training max per lift, then tap Done. Unit carries the climbing sets across the week.",
    ],
    closing:
      "Use Unit as an nSuns tracker that keeps you focused on the next set.",
  },
}

export const programSlugList = Object.keys(programSlugs)
