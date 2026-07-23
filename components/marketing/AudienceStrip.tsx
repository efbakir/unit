import MarketingPhoto from "./MarketingPhoto"

const audiences = [
  {
    label: "Bodybuilders",
    src: "/people/lifter-bodybuilder.webp",
    file: "lifter-bodybuilder.webp",
    rotation: "-rotate-2",
  },
  {
    label: "Powerlifters",
    src: "/people/lifter-powerlifter.webp",
    file: "lifter-powerlifter.webp",
    rotation: "rotate-2",
  },
  {
    label: "New lifters",
    src: "/people/lifter-beginner.webp",
    file: "lifter-beginner.webp",
    rotation: "-rotate-1",
  },
  {
    label: "Strength athletes",
    src: "/people/lifter-strength.webp",
    file: "lifter-strength.webp",
    rotation: "rotate-1",
  },
  {
    label: "Hypertrophy lifters",
    src: "/people/lifter-hypertrophy.webp",
    file: "lifter-hypertrophy.webp",
    rotation: "rotate-2",
  },
  {
    label: "Home gym lifters",
    src: "/people/lifter-home-gym.webp",
    file: "lifter-home-gym.webp",
    rotation: "-rotate-2",
  },
  {
    label: "Program followers",
    src: "/people/lifter-program-follower.webp",
    file: "lifter-program-follower.webp",
    rotation: "rotate-1",
  },
  {
    label: "Routine builders",
    src: "/people/lifter-routine-builder.webp",
    file: "lifter-routine-builder.webp",
    rotation: "-rotate-1",
  },
]

export default function AudienceStrip() {
  return (
    <section className="border-t border-unit-border py-unit-xxl md:py-unit-xxxl">
      <div className="mx-auto max-w-6xl px-unit-md md:px-unit-lg">
        <div className="mx-auto mb-unit-xxl max-w-3xl text-center">
          <p className="eyebrow mb-unit-sm">Your training. Your way.</p>
          <h2 className="editorial-display text-balance text-[38px] leading-none text-unit-text-primary md:text-[52px]">
            For everyone who lifts.
          </h2>
        </div>

        <div className="flex flex-wrap justify-center gap-x-unit-xl gap-y-unit-lg md:gap-x-unit-xxl">
          {audiences.map((audience) => (
            <div
              key={audience.label}
              className="flex min-w-[180px] items-center gap-unit-sm"
            >
              <MarketingPhoto
                src={audience.src}
                alt={`${audience.label} training`}
                slotLabel={audience.file}
                sizes="72px"
                className={`h-[72px] w-[72px] shrink-0 rounded-2xl shadow-[0_12px_28px_rgba(10,10,10,0.1)] ${audience.rotation}`}
                imageClassName="grayscale"
              />
              <p className="text-sm font-bold tracking-tight">{audience.label}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
