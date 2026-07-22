export default function TrustBand() {
  return (
    <div className="flex flex-wrap items-center gap-x-unit-sm gap-y-unit-xxs">
      <span className="inline-flex items-center gap-unit-xxs">
        <span className="block h-[6px] w-[6px] rounded-full bg-unit-success" aria-hidden="true" />
        <span className="eyebrow">Built by a lifter</span>
      </span>
      <span className="text-unit-text-secondary opacity-50" aria-hidden="true">·</span>
      <span className="eyebrow">Available on the App Store</span>
    </div>
  )
}
