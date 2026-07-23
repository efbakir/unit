import { ImageResponse } from "next/og"

export const runtime = "edge"
export const alt = "Unit: Your gym notebook, upgraded"
export const size = { width: 1200, height: 630 }
export const contentType = "image/png"

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: "#0A0A0A",
          fontFamily: "system-ui, -apple-system, sans-serif",
        }}
      >
        <div
          style={{
            fontSize: 72,
            fontWeight: 700,
            color: "#F5F5F5",
            letterSpacing: "-0.02em",
            marginBottom: 16,
          }}
        >
          Unit
        </div>
        <div
          style={{
            fontSize: 28,
            fontWeight: 400,
            color: "#999999",
            letterSpacing: "-0.01em",
          }}
        >
          Your gym notebook, upgraded.
        </div>
      </div>
    ),
    { ...size }
  )
}
