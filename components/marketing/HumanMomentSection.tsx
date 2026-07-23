import MarketingPhoto from "./MarketingPhoto"

const facts = [
  { value: "1 tap", label: "to log" },
  { value: "3 sec", label: "average goal" },
  { value: "0", label: "accounts" },
]

export default function HumanMomentSection() {
  return (
    <section className="border-t border-unit-border py-unit-xxl md:py-unit-xxxl">
      <div className="mx-auto max-w-6xl px-unit-md md:px-unit-lg">
        <div className="grid items-center gap-unit-xl lg:grid-cols-[1.16fr_0.84fr] lg:gap-unit-xxxl">
          <MarketingPhoto
            src="/people/unit-between-sets.webp"
            alt="Lifter checking Unit on an iPhone between sets"
            slotLabel="unit-between-sets.webp"
            sizes="(min-width: 1024px) 58vw, 92vw"
            className="aspect-[3/2] rounded-[32px]"
            imageClassName="grayscale"
          />

          <div className="max-w-xl">
            <p className="eyebrow mb-unit-md">Built for the gym floor</p>
            <h2 className="text-balance text-[36px] font-bold leading-[1.02] tracking-[-0.04em] md:text-[48px]">
              Training should be hard.
              <span className="editorial-display mt-unit-xs block">
                Logging should not.
              </span>
            </h2>
            <p className="mt-unit-lg text-lg leading-snug text-unit-text-secondary">
              Unit remembers the last set, starts your timer, and gets out of
              the way.
            </p>

            <dl className="mt-unit-xl grid grid-cols-3 gap-unit-md">
              {facts.map((fact) => (
                <div key={fact.label}>
                  <dt className="text-2xl font-bold tracking-tight tabular-nums">
                    {fact.value}
                  </dt>
                  <dd className="mt-unit-xs text-xs text-unit-text-secondary">
                    {fact.label}
                  </dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </div>
    </section>
  )
}
