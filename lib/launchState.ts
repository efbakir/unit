// Single source of truth for whether Unit has launched on the App Store.
// LIVE since 2026-06-11 — the listing URL is the hardcoded default so
// production flips without a Vercel env change. NEXT_PUBLIC_APP_STORE_URL
// still overrides; set it to an empty string to preview the pre-launch
// waitlist state locally.
export const APP_STORE_URL =
  process.env.NEXT_PUBLIC_APP_STORE_URL ??
  "https://apps.apple.com/us/app/unit-gym-notebook/id6775008893"
export const isLaunched = APP_STORE_URL.length > 0

// Trust band counter visibility. Below this threshold the band shows the
// founder line instead of "X lifters waiting" to avoid the "12 people on
// the waitlist" cringe.
export const COUNTER_VISIBILITY_THRESHOLD = 50
