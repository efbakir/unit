import Image from "next/image"

// Canonical marketing screenshot slot.
// Export final PNG mockups with any device chrome baked in, then pass `src`.
// Missing assets render a flat square image placeholder: no fake iPhone
// chrome, just the same muted media treatment used by the maker photo slot.
export default function DeviceFrame({
  src,
  alt,
  width,
  height,
  priority = false,
  sizes,
  className = "",
}: {
  src?: string
  alt: string
  width: number
  height: number
  priority?: boolean
  sizes?: string
  className?: string
}) {
  if (!src) {
    return (
      <div className={`relative ${className}`}>
        <div
          className="flex w-full items-center justify-center overflow-hidden rounded-2xl border border-unit-border bg-unit-muted"
          style={{ aspectRatio: "1 / 1" }}
        >
          <span className="eyebrow px-unit-md text-center">{alt}</span>
        </div>
      </div>
    )
  }

  return (
    <div className={`relative ${className}`}>
      <Image
        src={src}
        alt={alt}
        width={width}
        height={height}
        priority={priority}
        sizes={sizes}
        className="block h-auto w-full"
      />
    </div>
  )
}
