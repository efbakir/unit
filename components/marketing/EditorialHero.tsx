import Image from "next/image"
import AppStoreBadge from "./AppStoreBadge"
import MarketingPhoto from "./MarketingPhoto"
import TrustBand from "./TrustBand"
import { APP_STORE_URL } from "@/lib/launchState"

export default function EditorialHero() {
  return (
    <section className="overflow-x-clip pb-unit-xxl pt-28 md:pb-unit-xxxl md:pt-32">
      <div className="mx-auto max-w-6xl px-unit-md md:px-unit-lg">
        <div className="grid items-center gap-unit-xxl lg:grid-cols-[0.86fr_1.14fr] lg:gap-unit-xxxl">
          <div className="stagger-hero max-w-xl">
            <p className="eyebrow mb-unit-lg">Your program. Logged fast.</p>
            <h1 className="text-balance text-[48px] font-bold leading-[0.96] tracking-[-0.045em] text-unit-text-primary sm:text-[64px] lg:text-[76px]">
              Log a set
              <span className="editorial-display mt-unit-xs block">
                in 3 seconds.
              </span>
            </h1>
            <p className="mb-unit-xl mt-unit-lg max-w-lg text-xl leading-snug text-unit-text-secondary">
              Your last weight and reps are ready. Tap Done and keep lifting.
            </p>
            <AppStoreBadge href={APP_STORE_URL} />
            <div className="mt-unit-lg">
              <TrustBand />
            </div>
          </div>

          <div className="relative mx-auto w-full max-w-[620px] lg:justify-self-end">
            <MarketingPhoto
              src="/people/unit-hero-lifter.webp"
              alt="Lifter between sets in a gym"
              slotLabel="unit-hero-lifter.webp"
              sizes="(min-width: 1024px) 56vw, 92vw"
              priority
              className="aspect-[4/5] rounded-[36px]"
              imageClassName="grayscale"
            />

            <div className="absolute -bottom-8 -left-6 w-[210px] overflow-hidden rounded-[28px] bg-unit-background p-unit-sm shadow-[0_24px_64px_rgba(10,10,10,0.16)] sm:-left-10 sm:w-[260px] lg:-left-16">
              <Image
                src="/screenshots/hero-ghost-values.png"
                alt="Unit workout screen with the last weight and reps ready"
                width={1658}
                height={2386}
                sizes="260px"
                className="block h-auto w-full"
              />
            </div>

            <div className="absolute right-unit-md top-unit-md rounded-full bg-unit-background px-unit-md py-unit-sm shadow-[0_12px_30px_rgba(10,10,10,0.1)]">
              <p className="eyebrow text-unit-text-primary">One tap per set</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
