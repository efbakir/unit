import type { Metadata } from "next"
import Image from "next/image"
import FAQItem from "@/components/marketing/FAQItem"
import LayeredDeviceStack from "@/components/marketing/LayeredDeviceStack"
import FeatureShowcase from "@/components/marketing/FeatureShowcase"
import WaitlistForm from "@/components/marketing/WaitlistForm"
import AppStoreBadge from "@/components/marketing/AppStoreBadge"
import TrustBand from "@/components/marketing/TrustBand"
import FounderStory from "@/components/marketing/FounderStory"
import { isLaunched, APP_STORE_URL } from "@/lib/launchState"
import { getWaitlistCount } from "@/lib/waitlist"

type HeroForegroundMockup = {
  src?: string
  alt: string
  priority?: boolean
  sizes?: string
}

type HeroBackgroundMockup = {
  src?: string
  alt: string
  offsetX?: number
  offsetY?: number
  scale?: number
  rotate?: number
  z?: number
}

export const metadata: Metadata = {
  description:
    "Unit is a fast, local-first iOS gym tracker and workout log. Log a set in under 3 seconds. Every set opens with what you did last time. No AI, no social, no account.",
  alternates: { canonical: "/" },
}

// Revalidate the page (and the waitlist count it shows) every minute so the
// counter stays roughly fresh without hammering Resend.
export const revalidate = 60

const faqs = [
  {
    question: "What kind of workout log app is Unit?",
    answer:
      "Unit is an iOS gym tracker for intermediate-to-advanced lifters who already know their program. It's local-first, ad-free, and built around one principle: log a set in under 3 seconds, one-handed, mid-workout.",
  },
  {
    question: "Is Unit free?",
    answer:
      "No. Setup is free — bring your program and see it built in the app — then a subscription unlocks logging. Weekly, monthly, and yearly plans; every price is shown in the app before you pay. No free trial, no ads, no account.",
  },
  {
    question: "How does Unit fill in my numbers?",
    answer:
      "When you start an exercise, Unit shows what you logged last time: same weight, same reps. Tap Done to log it again, or adjust before you tap.",
  },
  {
    question: "Does Unit work offline?",
    answer:
      "Yes. All your data is stored locally on your device. No internet connection needed, no account required.",
  },
  {
    question: "How do I import my program?",
    answer:
      "During onboarding, choose 'Paste my routine' and paste from Notes, WhatsApp, or anywhere else. Unit reads exercise names, sets, reps, and weights automatically. Or pick a proven starter program from the built-in library.",
  },
  {
    question: "What programs does Unit support?",
    answer:
      "Any program with a fixed split. PPL, Upper/Lower, Full Body, or custom splits. You define the exercises and days; Unit doesn't impose structure.",
  },
  {
    question: "What if Unit gets discontinued?",
    answer:
      "Your data lives on your iPhone. iCloud Backup covers it. Nothing depends on a Unit server. You'd lose the app; you wouldn't lose your history.",
  },
  {
    question: "Where can I download Unit?",
    answer:
      "Unit is live on the App Store as “Unit — Gym Workout Log”. Tap any download button on this page, or search the App Store directly. Free to download; a subscription unlocks logging after setup. No account needed.",
  },
]

const softwareLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Unit",
  applicationCategory: "HealthApplication",
  operatingSystem: "iOS",
  description:
    "Fast iOS gym tracker and workout log. Log a set in under 3 seconds. Every set opens with what you did last time. Local-first, no account, no AI.",
  url: "https://unitlift.app/",
  keywords:
    "gym tracker, workout log, lifting log, strength log, last session values, rest timer, local-first, no account",
  offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
  ...(isLaunched ? { installUrl: APP_STORE_URL } : {}),
}

const faqLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: faqs.map((f) => ({
    "@type": "Question",
    name: f.question,
    acceptedAnswer: { "@type": "Answer", text: f.answer },
  })),
}

const importSources = [
  "Notes",
  "WhatsApp",
  "paper",
  "CSV",
  "Markdown",
]

const secondaryFeatures = [
  { title: "Offline · local-first", body: "No account. No sync. Always works on the gym floor." },
  { title: "Lock Screen rest timer", body: "Live Activity in the Dynamic Island. Auto-starts on Done." },
  { title: "PR detection", body: "Heaviest set, best rep, best volume. Auto-flagged in history." },
  { title: "Calendar overview", body: "Every session at a glance. Streaks without the badges." },
  { title: "Quick Start", body: "Freestyle session, no template required. Tap, lift, log." },
  { title: "Eight starter programs", body: "5/3/1, GZCLP, Upper/Lower, PPL, more — pick one or paste your own." },
]

// Crops of the approved App Store listing screenshots: transparent-background
// exports (headline band removed, device bleeding off the bottom). The wider
// canvas carries the unclipped drop shadow (~184px per side); every mockup on
// the page shares this geometry so hero and cards render at one scale.
const HERO_W = 1658
const HERO_H = 2386

const heroMockups: {
  foreground: HeroForegroundMockup
  background: HeroBackgroundMockup[]
} = {
  // Hero layers use the transparent-background exports (hero-*.png) so the
  // foreground phone overlaps the back phones without painting a canvas
  // rectangle over them. Feature cards keep the tiled crops.
  foreground: {
    src: "/screenshots/hero-active-workout.png",
    alt: "Unit — active workout: Bench Press 80 kg × 8 from last time, one tap to complete the set",
    priority: true,
    sizes: "(min-width: 1024px) 460px, 360px",
  },
  background: [
    {
      src: "/screenshots/hero-history-calendar.png",
      alt: "Unit — history calendar with logged sessions",
      offsetX: -38,
      offsetY: -8,
      scale: 0.78,
      rotate: -7,
      z: 0,
    },
    {
      src: "/screenshots/hero-ghost-values.png",
      alt: "Unit — last session's weight and reps filled in",
      offsetX: 38,
      offsetY: 6,
      scale: 0.78,
      rotate: 7,
      z: 0,
    },
  ],
}

export default async function LandingPage() {
  const fetchedCount = await getWaitlistCount()
  const waitlistCount = fetchedCount ?? undefined

  const PrimaryCTA = (
    <div className="space-y-unit-sm">
      {isLaunched ? (
        <AppStoreBadge href={APP_STORE_URL} />
      ) : (
        <WaitlistForm
          size="lg"
          caption="I'll email you once. No spam, no marketing list."
        />
      )}
    </div>
  )

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqLd) }}
      />

      {/* ── 1. Hero (layered) ── */}
      {/* overflow-x-clip: the rotated background layers may poke past the
          viewport on lg screens; clip the bleed instead of growing the page
          scroll width. */}
      <section className="overflow-x-clip pt-32 md:pt-40 pb-unit-xxl md:pb-unit-xxxl">
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          {/* Device column sized so the phone inside the hero export (61% of
              the canvas width; the rest is shadow margin) renders at the same
              visual size the old margin-less exports had at 420/460px. */}
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_minmax(0,500px)] xl:grid-cols-[1fr_minmax(0,560px)] gap-unit-xxl items-center">
            {/* Copy column */}
            <div className="stagger-hero max-w-2xl">
              <h1 className="h-display mb-unit-lg text-balance">
                Faster than paper.
              </h1>
              <p className="text-xl leading-snug mb-unit-xl max-w-xl text-unit-text-secondary">
                Log a set in one tap. Every set opens with what you did last
                time. No typing. No menus. Under three seconds.
              </p>
              {PrimaryCTA}
              <div className="mt-unit-lg">
                <TrustBand count={waitlistCount} />
              </div>
            </div>

            <div className="relative w-full max-w-[480px] mx-auto lg:mx-0 lg:justify-self-end">
              <LayeredDeviceStack
                width={HERO_W}
                height={HERO_H}
                foreground={heroMockups.foreground}
                background={heroMockups.background}
              />
            </div>
          </div>
        </div>
      </section>

      {/* ── 2. One-line positioning ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <h2 className="h-section">
            Built for lifters who already know their program.
          </h2>
        </div>
      </section>

      {/* ── 3. Product showcase ── */}
      <section
        id="how-it-works"
        className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border"
      >
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          <FeatureShowcase
            eyebrow="How it works"
            title="Designed for the bench, not your desk."
            body="The core workflow stays predictable: bring your program, log against last time, rest, and review later."
            items={[
              {
                eyebrow: "One tap per set",
                title: "Last time does the typing.",
                body: "Weight and reps from your last session are already there. Tap Done. Move on. The Gym Test: one-handed, sweaty, under three seconds to log a set.",
                microStat: "Avg log: 2.4s",
                mockup: {
                  src: "/screenshots/hero-ghost-values.png",
                  alt: "Unit — active set showing last time: 3×5×140 kg, ready to confirm",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
              {
                eyebrow: "Bring your program",
                title: "Paste from Notes. Done.",
                body: "Paste your routine from anywhere and Unit reads exercises, sets, reps, and weights automatically. Or build from scratch in under two minutes.",
                children: (
                  <>
                    <div className="mt-unit-lg flex flex-wrap items-center gap-x-unit-md gap-y-unit-xs">
                      <span className="eyebrow">Imports from</span>
                      {importSources.map((src, i) => (
                        <span key={src} className="flex items-center gap-x-unit-md">
                          <span className="text-base font-semibold tracking-tight">
                            {src}
                          </span>
                          {i < importSources.length - 1 && (
                            <span className="text-unit-text-secondary opacity-50">·</span>
                          )}
                        </span>
                      ))}
                    </div>
                    {/* A pasted-program snippet instead of a device mockup —
                        the paste flow's "before" state is a note, not an app
                        screen. flex-1 keeps the card height level with its
                        image-card siblings. */}
                    <div className="mt-unit-lg flex-1 rounded-[24px] border border-unit-border bg-unit-background p-unit-lg">
                      <p className="eyebrow mb-unit-sm">Pasted from Notes</p>
                      <p className="whitespace-pre-line font-mono text-sm leading-relaxed text-unit-text-secondary">
                        {"push day\nbench press 5x5 @ 80kg\nohp 3x8 @ 40kg\nincline db 3x10 @ 24kg\nlateral raise 3x12"}
                      </p>
                    </div>
                  </>
                ),
              },
              {
                eyebrow: "History · PRs",
                title: "Every set. Every PR.",
                body: "Calendar of every session. Heaviest set, best rep, and best volume PRs detected automatically. You decide when to add weight — Unit just remembers what you did.",
                mockup: {
                  src: "/screenshots/hero-history-calendar.png",
                  alt: "Unit — history calendar, April 2026, logged days highlighted",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
              {
                eyebrow: "Rest timer",
                title: "Follows you to the Lock Screen.",
                body: "Auto-starts on Done. Lives in the Dynamic Island and on the Lock Screen. No need to reopen the app between sets.",
                mockup: {
                  // Background-keyed crop of listing screenshot 2, padded to
                  // the same 1658×2386 geometry as the hero exports so all
                  // cards render at one scale.
                  src: "/screenshots/rest-timer-transparent.png",
                  alt: "Unit — rest timer running at 1:57 with the set editor below",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
            ]}
          />
        </div>
      </section>

      {/* ── 4. And that's not all — secondary features grid ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          <div className="mx-auto mb-unit-xl max-w-3xl text-center">
            <p className="eyebrow mb-unit-sm">And that's not all</p>
            <h2 className="h-section">
              Quiet features doing real work.
            </h2>
          </div>
          <div className="grid grid-cols-1 gap-x-unit-xl gap-y-unit-lg sm:grid-cols-2 lg:grid-cols-3">
            {secondaryFeatures.map((f) => (
              <div key={f.title} className="border-t border-unit-border pt-unit-md">
                <h3 className="text-base font-bold tracking-tight leading-snug mb-unit-xs">
                  {f.title}
                </h3>
                <p className="text-sm leading-relaxed text-unit-text-secondary">
                  {f.body}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── 5. Privacy slab ── */}
      <section className="py-unit-xxxl md:py-unit-xxxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <p className="eyebrow mb-unit-md">Built for privacy</p>
          <h2 className="h-section mb-unit-md">
            Local-first. Stays on your phone.
          </h2>
          <p className="text-xl leading-snug text-unit-text-secondary max-w-xl mx-auto">
            No account. No sync. No internet. Your full workout history and PRs
            live on-device, where they belong. iCloud Backup covers your data
            the same way it covers your photos — no Unit account needed.
          </p>
        </div>
      </section>

      {/* ── 6. What Unit is not ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <p className="eyebrow mb-unit-md">What Unit is not</p>

          <div className="divide-y divide-unit-border">
            {[
              {
                title: "Not an AI coach.",
                body: "Unit doesn't tell you what to lift. You bring the program; Unit makes logging instant.",
              },
              {
                title: "Not a social platform.",
                body: "No feed. No followers. No likes. Training is personal.",
              },
              {
                title: "Not for beginners.",
                body: "Unit assumes you know your way around a barbell. That's a feature, not a limitation.",
              },
              {
                title: "Not free.",
                body: "Setup is free; logging is a subscription. That's the entire business model — no ads, no selling your data, no feature bait.",
              },
            ].map((item) => (
              <div
                key={item.title}
                className="py-unit-lg md:py-unit-xl flex flex-col md:flex-row md:items-baseline md:gap-unit-xl"
              >
                <h3 className="text-xl font-bold tracking-tight leading-snug md:flex-1">
                  {item.title}
                </h3>
                <p className="mt-unit-xs md:mt-0 text-base leading-relaxed text-unit-text-secondary md:flex-1 md:max-w-md">
                  {item.body}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── 7. Founder Story ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <FounderStory />
        </div>
      </section>

      {/* ── 8. FAQ ── */}
      <section
        id="faq"
        className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border"
      >
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <h2 className="h-section mb-unit-xl">
            Common questions
          </h2>
          <div>
            {faqs.map((f, i) => (
              <FAQItem
                key={f.question}
                question={f.question}
                answer={f.answer}
                isLast={i === faqs.length - 1}
              />
            ))}
          </div>
        </div>
      </section>

      {/* ── 9. Footer CTA — emotional close ── */}
      <section
        id="download"
        className="py-unit-xxxl md:py-unit-xxxxl border-t border-unit-border"
      >
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <p className="eyebrow mb-unit-md">Ready when you are</p>
          <h2 className="h-display mb-unit-md">
            Log faster. Keep your data. Train.
          </h2>
          <p className="text-xl leading-snug mb-unit-xl text-unit-text-secondary max-w-xl mx-auto">
            One tap per set. Everything stays on your phone. The notebook,
            upgraded.
          </p>
          <div className="flex flex-col items-center gap-unit-lg">
            {isLaunched ? (
              <>
                <AppStoreBadge href={APP_STORE_URL} />
                {/* Desktop visitors can't tap the badge on their phone —
                    the QR bridges the gap. Hidden on mobile, where the badge
                    itself is the direct path. */}
                <div className="hidden md:flex items-center gap-unit-md rounded-[24px] border border-unit-border bg-unit-card p-unit-md">
                  <Image
                    src="/qr-app-store.svg"
                    alt="QR code linking to Unit on the App Store"
                    width={104}
                    height={104}
                    className="h-[104px] w-[104px]"
                  />
                  <p className="max-w-[16ch] text-left text-sm leading-snug text-unit-text-secondary">
                    Point your iPhone camera here to get Unit.
                  </p>
                </div>
              </>
            ) : (
              <WaitlistForm size="lg" />
            )}
          </div>
          {isLaunched && (
            <p className="eyebrow mt-unit-md">Free. No account. No ads.</p>
          )}
        </div>
      </section>
    </>
  )
}
