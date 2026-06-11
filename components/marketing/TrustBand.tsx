import { COUNTER_VISIBILITY_THRESHOLD, isLaunched } from "@/lib/launchState"

export default function TrustBand({ count }: { count?: number }) {
  // Waitlist counter is a pre-launch mechanic; once live, the only honest
  // second fact is that the app is on the App Store.
  const showCounter =
    !isLaunched &&
    typeof count === "number" &&
    count >= COUNTER_VISIBILITY_THRESHOLD

  return (
    <div className="flex flex-wrap items-center gap-x-unit-sm gap-y-unit-xxs">
      <span className="inline-flex items-center gap-unit-xxs">
        <span className="block h-[6px] w-[6px] rounded-full bg-unit-success" aria-hidden="true" />
        <span className="eyebrow">Built by a lifter</span>
      </span>
      <span className="text-unit-text-secondary opacity-50" aria-hidden="true">·</span>
      {showCounter ? (
        <span className="eyebrow">
          {count!.toLocaleString()} on the waitlist
        </span>
      ) : (
        <span className="eyebrow">
          {isLaunched ? "Now on the App Store" : "Coming soon to iOS"}
        </span>
      )}
    </div>
  )
}
