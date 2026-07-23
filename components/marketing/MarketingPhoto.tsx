"use client"

import { useState } from "react"
import Image from "next/image"

export default function MarketingPhoto({
  src,
  alt,
  slotLabel,
  sizes,
  className = "",
  imageClassName = "",
  priority = false,
}: {
  src: string
  alt: string
  slotLabel: string
  sizes: string
  className?: string
  imageClassName?: string
  priority?: boolean
}) {
  const [loaded, setLoaded] = useState(false)

  return (
    <div className={`relative overflow-hidden bg-unit-card ${className}`}>
      <div
        className={`absolute inset-0 flex items-center justify-center px-unit-lg text-center transition-opacity duration-200 ${
          loaded ? "opacity-0" : "opacity-100"
        }`}
        aria-hidden={loaded}
      >
        <div>
          <p className="eyebrow">Photo slot</p>
          <p className="mt-unit-xs font-mono text-xs text-unit-text-secondary">
            {slotLabel}
          </p>
        </div>
      </div>
      <Image
        src={src}
        alt={alt}
        fill
        priority={priority}
        sizes={sizes}
        onLoad={() => setLoaded(true)}
        onError={() => setLoaded(false)}
        className={`object-cover transition-opacity duration-300 ${
          loaded ? "opacity-100" : "opacity-0"
        } ${imageClassName}`}
      />
    </div>
  )
}
