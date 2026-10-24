import type { Metadata } from "next"
import Image from "next/image"
import FAQItem from "@/components/marketing/FAQItem"
import FeatureShowcase from "@/components/marketing/FeatureShowcase"
import AppStoreBadge from "@/components/marketing/AppStoreBadge"
import FounderStory from "@/components/marketing/FounderStory"
import SecondaryFeatures from "@/components/marketing/SecondaryFeatures"
import EditorialHero from "@/components/marketing/EditorialHero"
import HumanMomentSection from "@/components/marketing/HumanMomentSection"
import AudienceStrip from "@/components/marketing/AudienceStrip"
import { APP_STORE_URL } from "@/lib/launchState"
import { SITE_URL } from "@/lib/site"

export const metadata: Metadata = {
  description:
    "Know what to lift next. Unit logs each set in one tap, then prepares one clear progressive overload target for your next workout.",
  alternates: { canonical: "/" },
}

const faqs = [
  {
    question: "What kind of workout log app is Unit?",
    answer:
      "Unit is a progression-guided workout log for iPhone. Paste your program or choose a ready-made match, log each set in one tap, then get one clear target for next time.",
  },
  {
    question: "Is Unit free?",
    answer:
      "Setup is free. A subscription unlocks logging. Eligible new customers may receive a 7-day free trial on Monthly or Yearly when Apple confirms the offer. Prices appear before you pay. No ads or account.",
  },
  {
    question: "How does progressive overload work in Unit?",
    answer:
      "Choose a rep range and your smallest available weight increase for an exercise. If every working set reaches the top of the range, the next target adds weight. Otherwise, it builds reps or repeats the target. The new target is saved when you finish your workout, and you can keep the previous one or edit it.",
  },
  {
    question: "How does Unit fill in my numbers?",
    answer:
      "Unit first uses an accepted target for that routine and exercise. If there is no target, it shows the latest completed set or your saved starting values. Tap Done to log it, or adjust before you tap.",
  },
  {
    question: "Does Unit work offline?",
    answer:
      "Yes. Your workout data is stored locally and logging needs no connection or account. Optional anonymous product analytics never block the app.",
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
    "Know what to lift next. Log each set in one tap, then get one clear progressive overload target for your next workout.",
  url: `${SITE_URL}/`,
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

// Crops of the approved App Store listing screenshots: transparent-background
// exports (headline band removed, device bleeding off the bottom). The wider
// canvas carries the unclipped drop shadow (~184px per side); every mockup on
// the page shares this geometry so hero and cards render at one scale.
const HERO_W = 1658
const HERO_H = 2386
const ONBOARDING_W = 1792
const ONBOARDING_H = 2377
const REST_TIMER_W = 1800
const REST_TIMER_H = 2377

export default function LandingPage() {
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

      <EditorialHero />

      <HumanMomentSection />

      {/* 2b. Published App Store reviews from the Türkiye storefront. */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-5xl mx-auto px-unit-md md:px-unit-lg">
          <div className="mb-unit-xl text-center">
            <h2 className="h-section">What lifters say.</h2>
          </div>
          <div className="grid grid-cols-1 divide-y divide-unit-border border-y border-unit-border md:grid-cols-2 md:divide-x md:divide-y-0">
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
                className="w-full py-unit-xl text-center md:px-unit-xl md:py-unit-xxl"
              >
                <p className="text-sm tracking-[0.14em]" aria-label="5 out of 5 stars">
                  ★★★★★
                </p>
                <blockquote
                  className="mx-auto my-unit-md max-w-[28ch] text-xl font-bold tracking-tight leading-snug"
                  title={review.original}
                >
                  {review.quote}
                </blockquote>
                <figcaption className="text-sm text-unit-text-secondary">
                  App Store review
                </figcaption>
              </figure>
            ))}
          </div>
        </div>
      </section>

      <AudienceStrip />

      {/* ── 3. Product showcase ── */}
      <section
        id="how-it-works"
        className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border"
      >
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          <FeatureShowcase
            title="From last time to next time."
            body="Log what you did. See why the target changed. Accept it only when it makes sense."
            items={[
              {
                eyebrow: "Last time",
                title: "Start with your last workout.",
                body: "Your previous weight and reps are already there. Tap Done or make a quick edit.",
                microStat: "One tap per set",
                mockup: {
                  src: "/screenshots/hero-ghost-values.png",
                  alt: "Unit active set showing last time: 3×5×140 kg, ready to confirm",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
              {
                eyebrow: "Your program",
                title: "Bring the routine you trust.",
                body: "Paste from Notes or choose a ready-made match. Unit keeps the exercises, sets, and reps clear.",
                mockup: {
                  src: "/screenshots/onboarding-2.png",
                  alt: "Unit turning a pasted Upper A workout into five exercises",
                  width: ONBOARDING_W,
                  height: ONBOARDING_H,
                  sizes: "380px",
                  className:
                    "md:origin-top md:translate-y-[10px] md:scale-[1.14]",
                },
              },
              {
                eyebrow: "Next target",
                title: "See progress you can trace.",
                body: "Review completed sessions and PRs, then see how today's work led to the next target.",
                mockup: {
                  src: "/screenshots/hero-history-calendar.png",
                  alt: "Unit history calendar, April 2026, logged days highlighted",
                  width: HERO_W,
                  height: HERO_H,
                  sizes: "380px",
                },
              },
              {
                eyebrow: "Between sets",
                title: "Keep the next set in focus.",
                body: "The timer starts when you tap Done and stays visible on the Dynamic Island or Lock Screen.",
                mockup: {
                  src: "/screenshots/rest-timer-figma.png",
                  alt: "Unit rest timer running at 1:57 with the set editor below",
                  width: REST_TIMER_W,
                  height: REST_TIMER_H,
                  sizes: "380px",
                  className:
                    "md:origin-top md:-translate-y-[90px] md:scale-[1.26]",
                  clipOverflow: true,
                },
              },
            ]}
          />
        </div>
      </section>

      {/* 4. Secondary features */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg">
          <SecondaryFeatures />
        </div>
      </section>

      {/* ── 5. Privacy slab ── */}
      <section className="py-unit-xxxl md:py-unit-xxxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <h2 className="h-section mb-unit-md">
            Your training stays on your iPhone.
          </h2>
          <p className="text-lg leading-snug text-unit-text-secondary max-w-xl mx-auto">
            No account or server sync. Your history stays on your iPhone and
            can be included in iCloud Backup.
          </p>
        </div>
      </section>

      {/* ── 6. What Unit is not ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <h2 className="h-section mb-unit-md">Progress without the black box.</h2>

          <div className="divide-y divide-unit-border">
            {[
              {
                title: "No hidden decisions.",
                body: "Every suggestion shows the last result, next target, and reason.",
              },
              {
                title: "No automatic changes.",
                body: "Accept, edit, or ignore each target. Your program stays yours.",
              },
              {
                title: "No social feed.",
                body: "No followers or likes. Training stays personal.",
              },
              {
                title: "No cloud dependency.",
                body: "Logging works offline and raw workout details stay on your iPhone.",
              },
            ].map((item) => (
              <div
                key={item.title}
                className="py-unit-lg md:py-unit-xl flex flex-col md:flex-row md:items-baseline md:gap-unit-xl"
              >
                <h3 className="text-lg font-bold tracking-tight leading-snug md:flex-1">
                  {item.title}
                </h3>
                <p className="mt-unit-xs text-base leading-relaxed text-unit-text-secondary md:mt-0 md:max-w-md md:flex-1">
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
          <h2 className="h-display mb-unit-md">
            Know what to lift next.
          </h2>
          <p className="text-lg leading-snug mb-unit-xl text-unit-text-secondary max-w-xl mx-auto">
            Log every set in one tap. Finish with one clear target for next time.
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
          <p className="mt-unit-md text-sm font-semibold text-unit-text-secondary">
            No account. No automatic changes. No social feed.
          </p>
        </div>
      </section>
    </>
  )
}
