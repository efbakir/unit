import DeviceFrame from "./DeviceFrame"

type Layer = {
  src?: string
  alt: string
  // Translation in % of the foreground frame's width / height. The
  // foreground sits at (0, 0); positive offsetX pushes a layer right,
  // positive offsetY pushes it down.
  offsetX?: number
  offsetY?: number
  // Scale relative to the foreground (1 = same size).
  scale?: number
  // Rotation in degrees. Negative = counter-clockwise.
  rotate?: number
  // Stack order. Higher z = closer to viewer. Foreground stays on top
  // unless any background layer overrides with a higher z.
  z?: number
}

// Bevel-style depth composition: one foreground mockup in focus, with
// 2-3 background images staggered behind it (offset, scaled down,
// gently rotated). On mobile, the background layers collapse so only
// the foreground remains. The depth illusion needs lateral room.
//
// Reuses DeviceFrame for every layer so placeholder and real-image behavior
// stay canonical.
export default function LayeredDeviceStack({
  foreground,
  background = [],
  width,
  height,
  className = "",
}: {
  foreground: { src?: string; alt: string; priority?: boolean; sizes?: string }
  background?: Layer[]
  width: number
  height: number
  className?: string
}) {
  return (
    <div className={`relative w-full ${className}`}>
      {/* Background layers are hidden on mobile so the depth doesn't crowd
          the narrow viewport. Each layer is absolutely positioned
          relative to the wrapper; the foreground frame defines the box
          via its own intrinsic size. */}
      <div className="hidden lg:block">
        {background.map((layer, i) => {
          const tx = layer.offsetX ?? 0
          const ty = layer.offsetY ?? 0
          const scale = layer.scale ?? 0.7
          const rotate = layer.rotate ?? 0
          const z = layer.z ?? 0
          return (
            <div
              key={`${layer.alt}-${i}`}
              className="absolute inset-0 pointer-events-none"
              style={{
                transform: `translate(${tx}%, ${ty}%) scale(${scale}) rotate(${rotate}deg)`,
                transformOrigin: "center center",
                zIndex: z,
                opacity: 0.92,
              }}
            >
              <DeviceFrame
                src={layer.src}
                alt={layer.alt}
                width={width}
                height={height}
                sizes="320px"
              />
            </div>
          )
        })}
      </div>

      {/* Foreground is always on top by default (z-10). */}
      <div className="relative z-10">
        <DeviceFrame
          src={foreground.src}
          alt={foreground.alt}
          width={width}
          height={height}
          priority={foreground.priority}
          sizes={foreground.sizes}
        />
      </div>
    </div>
  )
}
