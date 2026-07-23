import type { Metadata } from "next"
import Image from "next/image"
import FAQItem from "@/components/marketing/FAQItem"
import LayeredDeviceStack from "@/components/marketing/LayeredDeviceStack"
import FeatureShowcase from "@/components/marketing/FeatureShowcase"
import AppStoreBadge from "@/components/marketing/AppStoreBadge"
import TrustBand from "@/components/marketing/TrustBand"
import FounderStory from "@/components/marketing/FounderStory"
import { APP_STORE_URL } from "@/lib/launchState"

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
    "Unit is a fast, local-first iOS gym tracker and workout log. Log a set in 3 seconds. Every set opens with what you did last time. No AI, no social, no account.",
  alternates: { canonical: "/" },
}

const faqs = [
  {
    question: "What kind of workout log app is Unit?",
    answer:
      "Unit is a simple, private workout log for iPhone. Paste a program or build one from scratch, then log each set in under 3 seconds with last time's weight and reps already filled in.",
  },
  {
    question: "Is Unit free?",
    answer:
      "Setup is free. A subscription unlocks logging. Weekly, monthly, and yearly prices appear before you pay. No trial, ads, or account.",
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
      "Paste a routine from Notes, WhatsApp, or anywhere else. Unit reads the exercises, sets, reps, and weights. You can also choose a starter program.",
  },
  {
    question: "What programs does Unit support?",
    answer:
      "PPL, Upper/Lower, Full Body, and custom splits. You choose the days and exercises.",
  },
  {
    question: "What if Unit gets discontinued?",
    answer:
      "Your data stays on your iPhone and can be included in iCloud Backup. It does not depend on a Unit server.",
  },
  {
    question: "Where can I download Unit?",
    answer:
      "Tap any download button on this page. Unit is free to download. A subscription unlocks logging after setup.",
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
  offers: {
    "@type": "Offer",
    price: "2.99",
    priceCurrency: "USD",
    description: "Weekly access. Monthly, yearly, and optional Lifetime plans are shown in the app.",
  },
  installUrl: APP_STORE_URL,
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
  { title: "Lock Screen timer", body: "Starts when you tap Done. Visible in Live Activities." },
  { title: "PR detection", body: "See your best weight, reps, and volume." },
  { title: "Calendar", body: "See every session at a glance." },
  { title: "Quick Start", body: "Start a session without a template." },
  { title: "Eight starter programs", body: "Choose one or paste your own." },
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
    alt: "Unit active workout: Bench Press 80 kg × 8 from last time, one tap to complete the set",
    priority: true,
    sizes: "(min-width: 1024px) 460px, 360px",
  },
  background: [
    {
      src: "/screenshots/hero-history-calendar.png",
      alt: "Unit history calendar with logged sessions",
      offsetX: -38,
      offsetY: -8,
      scale: 0.78,
      rotate: -7,
      z: 0,
    },
    {
      src: "/screenshots/hero-ghost-values.png",
      alt: "Unit last session's weight and reps filled in",
      offsetX: 38,
      offsetY: 6,
      scale: 0.78,
      rotate: 7,
      z: 0,
    },
  ],
}

export default function LandingPage() {
  const PrimaryCTA = (
    <div className="space-y-unit-sm">
      <AppStoreBadge href={APP_STORE_URL} />
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
                Log a set in 3 seconds.
              </h1>
              <p className="text-xl leading-snug mb-unit-xl max-w-xl text-unit-text-secondary">
                Your last weight and reps are ready. Tap Done and keep lifting.
              </p>
              {PrimaryCTA}
              <div className="mt-unit-lg">
                <TrustBand />
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
            A gym notebook, not a platform.
          </h2>
        </div>
      </section>

      {/* 2b. Published App Store reviews from the Türkiye storefront. */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-5xl mx-auto px-unit-md md:px-unit-lg">
          <div className="mb-unit-xl text-center">
            <p className="eyebrow mb-unit-sm">From the App Store</p>
            <h2 className="h-section">What lifters say.</h2>
          </div>
          <div className="grid grid-cols-1 gap-unit-md md:grid-cols-2">
            {[
              {
                quote: "\u201CThe gym tracker app I\u2019ve been looking for for years.\u201D",
                original: "Yıllardır aradığım gym tracker app",
              },
              {
                quote: "\u201CPractical and fast.\u201D",
                original: "Pratik ve hızlı",
              },
            ].map((review) => (
              <figure
                key={review.original}
                className="flex min-h-[240px] w-full flex-col items-center justify-between rounded-2xl bg-unit-card p-unit-lg text-center md:min-h-[280px] md:p-unit-xl"
              >
                <p className="text-sm tracking-[0.2em]" aria-label="5 out of 5 stars">
                  ★★★★★
                </p>
                <blockquote
                  className="my-unit-lg max-w-[28ch] text-xl font-bold tracking-tight leading-snug"
                  title={review.original}
                >
                  {review.quote}
                </blockquote>
                <figcaption className="eyebrow">
                  App Store review
                </figcaption>
              </figure>
            ))}
          </div>
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
            body="Bring your program. Log each set. Review your progress."
            items={[
              {
                eyebrow: "One tap per set",
                title: "Last time does the typing.",
                body: "Your last weight and reps are ready. Tap Done. Keep lifting.",
                microStat: "Average log: 2.4s",
                mockup: {
                  src: "/screenshots/hero-ghost-values.png",
                  alt: "Unit active set showing last time: 3×5×140 kg, ready to confirm",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
              {
                eyebrow: "Bring your program",
                title: "Paste from Notes. Done.",
                body: "Paste a routine or build one. Unit reads the exercises, sets, reps, and weights.",
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
                    {/* A pasted-program snippet instead of a device mockup:
                        the paste flow's "before" state is a note, not an app
                        screen. flex-1 keeps the card height level with its
                        image-card siblings. */}
                    <div className="mt-unit-lg flex-1 rounded-[24px] bg-unit-background p-unit-lg">
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
                body: "See every session and PR. You decide when to add weight.",
                mockup: {
                  src: "/screenshots/hero-history-calendar.png",
                  alt: "Unit history calendar, April 2026, logged days highlighted",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
              {
                eyebrow: "Rest timer",
                title: "Follows you to the Lock Screen.",
                body: "Starts when you tap Done. Check it on the Dynamic Island or Lock Screen.",
                mockup: {
                  // Background-keyed crop of listing screenshot 2, padded to
                  // the same 1658×2386 geometry as the hero exports so all
                  // cards render at one scale.
                  src: "/screenshots/rest-timer-transparent.png",
                  alt: "Unit rest timer running at 1:57 with the set editor below",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
            ]}
          />
        </div>
      </section>

      {/* 4. Secondary features */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          <div className="mx-auto mb-unit-xl max-w-3xl text-center">
            <p className="eyebrow mb-unit-sm">More features</p>
            <h2 className="h-section">
              More, without the clutter.
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
            No account or server sync. Your history stays on your iPhone and
            can be included in iCloud Backup.
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
                title: "No coaching.",
                body: "You choose the program. Unit logs it.",
              },
              {
                title: "No social feed.",
                body: "No followers or likes. Training stays personal.",
              },
              {
                title: "No clutter.",
                body: "Only what you need to log and review.",
              },
              {
                title: "No ads.",
                body: "Setup is free. A subscription unlocks logging.",
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

      {/* 9. Footer CTA */}
      <section
        id="download"
        className="py-unit-xxxl md:py-unit-xxxxl border-t border-unit-border"
      >
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <p className="eyebrow mb-unit-md">Ready when you are</p>
          <h2 className="h-display mb-unit-md">
            Log a set in 3 seconds.
          </h2>
          <p className="text-xl leading-snug mb-unit-xl text-unit-text-secondary max-w-xl mx-auto">
            One tap per set. Everything stays on your phone. The notebook,
            upgraded.
          </p>
          <div className="flex flex-col items-center gap-unit-lg">
            <AppStoreBadge href={APP_STORE_URL} />
            {/* Desktop visitors can't tap the badge on their phone.
                the QR bridges the gap. Hidden on mobile, where the badge
                itself is the direct path. */}
            <div className="hidden md:flex items-center gap-unit-md rounded-[24px] bg-unit-card p-unit-md">
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
          </div>
          <p className="eyebrow mt-unit-md">No account. No ads. No social feed.</p>
        </div>
      </section>
    </>
  )
}
