import Image from "next/image"
import { DEVELOPER_NAME } from "@/lib/contact"

// Editorial layout: photo left, prose right (stacked on mobile). Narrower
// max-width than the bento so reading rhythm shifts toward "letter from
// the founder," contrasting with the structured grid above.
export default function FounderStory() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-[260px_1fr] gap-unit-xl items-start">
      <div className="order-1">
        <div className="aspect-square w-full max-w-[260px] mx-auto md:mx-0 rounded-2xl bg-unit-muted overflow-hidden">
          <Image
            src="/founder.jpg"
            alt={`${DEVELOPER_NAME}, maker of Unit, at his desk`}
            width={600}
            height={600}
            className="h-full w-full object-cover"
          />
        </div>
      </div>

      <div className="order-2 max-w-[600px] space-y-unit-md">
        <p className="eyebrow">From the maker</p>
        <p className="text-lg leading-relaxed">
          I trained with a paper notebook for years. Gym apps added too many
          menus and too much typing.
        </p>
        <p className="text-lg leading-relaxed text-unit-text-secondary">
          I built Unit to do one job: log each set fast. Your last numbers are
          ready, the timer follows you, and your data stays on your phone.
        </p>
        <p className="pt-unit-xs text-base font-semibold tracking-tight">
          {DEVELOPER_NAME.split(" ")[0]}
        </p>
      </div>
    </div>
  )
}
