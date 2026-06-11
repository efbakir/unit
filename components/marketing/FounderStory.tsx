import Image from "next/image"
import { DEVELOPER_NAME } from "@/lib/contact"

// Editorial layout: photo left, prose right (stacked on mobile). Narrower
// max-width than the bento so reading rhythm shifts toward "letter from
// the founder," contrasting with the structured grid above.
export default function FounderStory() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-[260px_1fr] gap-unit-xl items-start">
      <div className="order-1">
        <div className="aspect-square w-full max-w-[260px] mx-auto md:mx-0 rounded-2xl bg-unit-muted overflow-hidden border border-unit-border">
          <Image
            src="/founder.jpg"
            alt={`${DEVELOPER_NAME} — maker of Unit, at his desk`}
            width={600}
            height={600}
            className="h-full w-full object-cover"
          />
        </div>
      </div>

      <div className="order-2 max-w-[600px] space-y-unit-md">
        <p className="eyebrow">From the maker</p>
        <p className="text-lg leading-relaxed">
          Trained for years with a paper notebook. Tried the gym apps. All
          of them slowed me down: too many menus, too much typing, screens
          designed for a desk, not a deadlift platform.
        </p>
        <p className="text-lg leading-relaxed text-unit-text-secondary">
          Built Unit instead. One tap per set. What you did last time is
          already there. Rest timer follows you to the Lock Screen.
          Everything stays on your phone. No social, no AI, no ceremony.
        </p>
        <p className="text-lg leading-relaxed text-unit-text-secondary">
          The app I wanted. If you know your program and you&rsquo;re tired
          of fighting your tracker between sets, might be the one you
          wanted too.
        </p>
        <p className="pt-unit-xs text-base font-semibold tracking-tight">
          — {DEVELOPER_NAME.split(" ")[0]}
        </p>
      </div>
    </div>
  )
}
