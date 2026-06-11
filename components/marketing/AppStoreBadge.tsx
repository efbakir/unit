import Image from "next/image"

// Official Apple "Download on the App Store" badge (US-UK, black) from
// Apple Marketing Resources. Apple brand guidelines require the unmodified
// artwork — no recoloring, no custom chrome around the mark. The interaction
// spring lives on the anchor, not the badge.
export default function AppStoreBadge({
  href,
  className = "",
}: {
  href: string
  className?: string
}) {
  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      aria-label="Download Unit on the App Store"
      className={`press-spring inline-flex items-center ${className}`}
    >
      <Image
        src="/app-store-badge.svg"
        alt="Download on the App Store"
        width={180}
        height={60}
        style={{ height: "var(--button-height-lg)", width: "auto" }}
      />
    </a>
  )
}
