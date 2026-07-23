import type { MetadataRoute } from "next"

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Unit: Gym Logger & Workout Tracker",
    short_name: "Unit",
    description:
      "Fast iOS gym tracker and workout log. Log a set in under 3 seconds.",
    start_url: "/",
    display: "standalone",
    background_color: "#F5F5F5",
    theme_color: "#F5F5F5",
    icons: [{ src: "/icon.svg", sizes: "any", type: "image/svg+xml" }],
  }
}
