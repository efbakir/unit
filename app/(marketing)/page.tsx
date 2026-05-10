import type { Metadata } from "next"
import FAQItem from "@/components/marketing/FAQItem"
import LayeredDeviceStack from "@/components/marketing/LayeredDeviceStack"
import FeatureShowcase from "@/components/marketing/FeatureShowcase"
import WaitlistForm from "@/components/marketing/WaitlistForm"
import AppStoreBadge from "@/components/marketing/AppStoreBadge"
import TrustBand from "@/components/marketing/TrustBand"
import FounderStory from "@/components/marketing/FounderStory"
import KW from "@/components/marketing/KW"
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
    "Unit is a fast, local-first iOS gym tracker and workout log. Log a set in under 3 seconds — ghost values pre-fill from your last session. No AI, no social, no account.",
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
      "Yes — completely free at launch. No ads, no account, no paywall on any logging feature. I may add a small Pro tier later for power-user extras; if I do, core logging stays free.",
  },
  {
    question: "How do ghost values work?",
    answer:
      "When you start a session, Unit pre-fills weight and reps from your most recent session for each exercise. Just tap Done to log the same values, or adjust them before tapping.",
  },
  {
    question: "Does Unit work offline?",
    answer:
      "Yes. All your data is stored locally on your device. No internet connection needed, no account required.",
  },
  {
    question: "How do I import my program?",
    answer:
      "During onboarding, choose 'Paste text' and paste your routine from Notes or WhatsApp. Unit reads exercise names, sets, reps, and weights automatically. You can also take a photo of your program or build from scratch.",
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
    question: "When does Unit launch?",
    answer:
      "Unit is in App Store review now. Join the waitlist above and I'll email you once at launch; no marketing follow-up.",
  },
]

const softwareLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Unit",
  applicationCategory: "HealthApplication",
  operatingSystem: "iOS",
  description:
    "Fast iOS gym tracker and workout log. Log a set in under 3 seconds. Ghost values pre-fill from your last session. Local-first, no account, no AI.",
  url: "https://unitlift.app/",
  keywords:
    "gym tracker, workout log, lifting log, strength log, ghost values, rest timer, local-first, no account",
  offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
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

const heroMockups: {
  foreground: HeroForegroundMockup
  background: HeroBackgroundMockup[]
} = {
  foreground: {
    alt: "Unit — Today screen",
    priority: true,
    sizes: "(min-width: 1024px) 460px, 360px",
  },
  background: [
    {
      alt: "Unit — History view",
      offsetX: -38,
      offsetY: -8,
      scale: 0.78,
      rotate: -7,
      z: 0,
    },
    {
      alt: "Unit — Active workout view",
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
      <section className="pt-32 md:pt-40 pb-unit-xxl md:pb-unit-xxxl">
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_minmax(0,420px)] xl:grid-cols-[1fr_minmax(0,460px)] gap-unit-xxl items-center">
            {/* Copy column */}
            <div className="stagger-hero max-w-2xl">
              <h1 className="h-display mb-unit-lg text-balance">
                <KW>Faster</KW> than paper.
              </h1>
              <p className="text-xl leading-snug mb-unit-xl max-w-xl text-unit-text-secondary">
                Log a set in one tap. Ghost values pre-fill from your last
                session. No typing. No menus. Under three seconds.
              </p>
              {PrimaryCTA}
              <div className="mt-unit-lg">
                <TrustBand count={waitlistCount} />
              </div>
            </div>

            <div className="relative w-full max-w-[400px] mx-auto lg:mx-0 lg:justify-self-end">
              <LayeredDeviceStack
                width={1206}
                height={2622}
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
            body="The core workflow stays predictable: bring your program, log with ghost values, rest, and review later."
            items={[
              {
                eyebrow: "One tap per set",
                title: "Ghost values do the typing.",
                body: "Weight and reps pre-fill from your last session. Tap Done. Move on. The Gym Test: one-handed, sweaty, under three seconds to log a set.",
                microStat: "Avg log: 2.4s",
                mockup: {
                  alt: "Unit — Active workout, ghost values pre-filled",
                  width: 1206,
                  height: 2622,
                  sizes: "300px",
                },
              },
              {
                eyebrow: "Bring your program",
                title: "Paste from Notes. Done.",
                body: "Paste your routine from anywhere and Unit reads exercises, sets, reps, and weights automatically. Or build from scratch in under two minutes.",
                children: (
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
                ),
                mockup: {
                  alt: "Unit — Program list with templates",
                  width: 1206,
                  height: 2622,
                  sizes: "300px",
                },
              },
              {
                eyebrow: "History · PRs",
                title: "Every set. Every PR.",
                body: "Calendar of every session. Heaviest set, best rep, and best volume PRs detected automatically. You decide when to add weight — Unit just remembers what you did.",
                mockup: {
                  alt: "Unit — History calendar with PR markers",
                  width: 1206,
                  height: 2622,
                  sizes: "300px",
                },
              },
              {
                eyebrow: "Rest timer",
                title: "Follows you to the Lock Screen.",
                body: "Auto-starts on Done. Lives in the Dynamic Island and on the Lock Screen. No need to reopen the app between sets.",
                mockup: {
                  alt: "Unit — Rest timer in the Dynamic Island",
                  width: 1206,
                  height: 2622,
                  sizes: "300px",
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
                title: "Not subscription-locked.",
                body: "Core logging is free. Your workout data is never held hostage.",
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
          <div className="flex justify-center">
            {isLaunched ? (
              <AppStoreBadge href={APP_STORE_URL} />
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
