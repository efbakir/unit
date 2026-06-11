import type { ReactNode } from "react"
import DeviceFrame from "./DeviceFrame"

type FeatureShowcaseItem = {
  eyebrow?: string
  title: string
  body: string
  microStat?: string
  mockup?: {
    src?: string
    alt: string
    width: number
    height: number
    sizes?: string
  }
  children?: ReactNode
}

export default function FeatureShowcase({
  eyebrow,
  title,
  body,
  items,
}: {
  eyebrow?: string
  title: string
  body?: string
  items: FeatureShowcaseItem[]
}) {
  return (
    <div>
      <div className="mx-auto mb-unit-xxl max-w-3xl text-center">
        {eyebrow && <p className="eyebrow mb-unit-sm">{eyebrow}</p>}
        <h2 className="h-section text-balance">{title}</h2>
        {body && (
          <p className="mx-auto mt-unit-md max-w-2xl text-lg leading-snug text-unit-text-secondary">
            {body}
          </p>
        )}
      </div>

      <div className="grid grid-cols-1 gap-unit-md md:grid-cols-2">
        {items.map((item) => (
          <article
            key={item.title}
            className="lift-hover flex min-h-[280px] flex-col overflow-hidden rounded-[32px] border border-unit-border bg-unit-card"
          >
            <div className="flex flex-1 flex-col p-unit-lg md:p-unit-xl">
              {item.eyebrow && <p className="eyebrow mb-unit-sm">{item.eyebrow}</p>}
              <h3 className="text-[24px] font-bold leading-[1.12] tracking-tight text-unit-text-primary">
                {item.title}
              </h3>
              <p className="mt-unit-sm max-w-xl text-base leading-relaxed text-unit-text-secondary">
                {item.body}
              </p>
              {item.microStat && (
                <p className="eyebrow mt-unit-md">{item.microStat}</p>
              )}
              {item.children}
            </div>

            {item.mockup && (
              <div className="mt-auto px-unit-lg pb-unit-lg md:px-unit-xl md:pb-unit-xl">
                <div className="mx-auto max-w-[var(--marketing-feature-device-width)]">
                  <DeviceFrame
                    src={item.mockup.src}
                    alt={item.mockup.alt}
                    width={item.mockup.width}
                    height={item.mockup.height}
                    sizes={item.mockup.sizes}
                  />
                </div>
              </div>
            )}
          </article>
        ))}
      </div>
    </div>
  )
}
