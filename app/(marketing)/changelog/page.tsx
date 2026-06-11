import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Changelog",
  description:
    "Unit release notes. Local-first iOS gym tracker, transparent shipping cadence.",
  alternates: { canonical: "/changelog" },
}

const releases = [
  {
    version: "v1.0",
    date: "June 11, 2026",
    notes: [
      "Initial App Store release.",
      "Ghost values pre-fill weight and reps from your last session.",
      "Rest timer with Lock Screen and Dynamic Island Live Activity.",
      "Paste-to-import: paste a routine from Notes or WhatsApp during onboarding.",
      "PR detection with quiet thresholds (no badges, no streaks).",
      "Full local history; no account, no sync.",
    ],
  },
]

export default function ChangelogPage() {
  return (
    <section className="pt-32 pb-unit-xxl md:pb-unit-xxxxl">
      <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
        <p className="eyebrow mb-unit-xs">Changelog</p>
        <h1 className="h-section mb-unit-lg">What&rsquo;s shipped.</h1>
        <p className="text-base text-unit-text-secondary mb-unit-xxl max-w-prose">
          Every Unit release, newest at the top. I post here whenever I ship,
          even small fixes.
        </p>

        <div className="space-y-unit-xl">
          {releases.map((r) => (
            <article key={r.version}>
              <header className="flex items-baseline gap-unit-md mb-unit-sm">
                <h2 className="text-xl font-bold tracking-tight">{r.version}</h2>
                <span className="eyebrow">{r.date}</span>
              </header>
              <ul className="space-y-unit-xs text-base text-unit-text-secondary list-disc pl-5">
                {r.notes.map((n, i) => (
                  <li key={i}>{n}</li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
