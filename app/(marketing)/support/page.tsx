import type { Metadata } from "next"
import Link from "next/link"
import FAQItem from "@/components/marketing/FAQItem"
import { SUPPORT_EMAIL } from "@/lib/contact"

export const metadata: Metadata = {
  title: "Support",
  description:
    "Unit support and FAQ. Restore purchases, troubleshoot the rest timer, import programs, and contact help. Local-first iOS gym tracker.",
  alternates: { canonical: "/support" },
}

export default function SupportPage() {
  return (
    <section className="pt-32 pb-unit-xxl md:pb-unit-xxxxl">
      <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
        <h1 className="text-3xl font-bold tracking-tight mb-unit-sm">
          Support
        </h1>
        <p className="text-base mb-unit-xxl leading-relaxed text-unit-text-secondary">
          Need help with Unit? Check the common questions below or reach out
          directly.
        </p>

        {/* Contact */}
        <address className="not-italic block rounded-xl p-unit-lg border border-unit-border bg-unit-card mb-unit-xxl">
          <h2 className="text-lg font-semibold mb-unit-xs">Contact me</h2>
          <p className="text-[15px] mb-unit-md text-unit-text-secondary">
            I typically respond within 24 hours.
          </p>
          <a
            href={`mailto:${SUPPORT_EMAIL}?subject=Unit%20support%20request`}
            className="text-[17px] font-bold"
          >
            {SUPPORT_EMAIL}
          </a>
        </address>

        {/* FAQ */}
        <h2 className="text-xl font-semibold mb-unit-lg">Common questions</h2>
        <div className="mb-unit-xxl">
          <FAQItem
            question="How do I restore my purchase?"
            answer="Open Unit, go to Settings, and tap Restore Purchase. Your unlock is tied to your Apple ID and can be restored on any device signed into the same account."
          />
          <FAQItem
            question="I accidentally deleted the app. Is my data gone?"
            answer="If you deleted the app, your locally stored workout data is removed from the device. Unit stores all data on-device. I recommend using iCloud device backups to protect your data."
          />
          <FAQItem
            question="How do I see what I logged last time?"
            answer="When you start an exercise, Unit shows what you logged last time: same weight, same reps. Tap Done to log it again, or adjust before you tap."
          />
          <FAQItem
            question="Can I change my program after setup?"
            answer="Yes. Go to the Programs tab to edit your split, rename days, add or remove exercises, and reorder them. Your workout history is always preserved."
          />
          <FAQItem
            question="Does Unit require an internet connection?"
            answer="No. Unit works entirely offline. All data is stored locally on your device. An internet connection is only needed to download the app and restore purchases."
          />
          <FAQItem
            question="What iOS version does Unit require?"
            answer="Unit requires iOS 18 or later."
          />
          <FAQItem
            question="How do I request a refund?"
            answer={
              <>
                Purchases are processed by Apple. To request a refund, visit{" "}
                <a
                  href="https://reportaproblem.apple.com"
                  target="_blank"
                  rel="noreferrer"
                  className="underline underline-offset-2"
                >
                  reportaproblem.apple.com
                </a>{" "}
                and select the Unit purchase.
              </>
            }
          />
          <FAQItem
            question="How do I delete my data?"
            answer="Unit stores all data on-device. Deleting the app removes every workout, program, and setting. Unit has no account and no server-side data to delete."
          />
          <FAQItem
            question="I found a bug. How do I report it?"
            answer={
              <>
                Email me at{" "}
                <a
                  href={`mailto:${SUPPORT_EMAIL}?subject=Unit%20bug%20report`}
                  className="underline underline-offset-2"
                >
                  {SUPPORT_EMAIL}
                </a>{" "}
                with a description of the issue, your iOS version, and your
                device model. Screenshots help.
              </>
            }
          />
        </div>

        {/* Troubleshooting */}
        <h2 className="text-xl font-semibold mb-unit-md">Troubleshooting</h2>
        <div className="space-y-unit-lg mb-unit-xxl">
          <TroubleshootItem
            title="The app is not showing my purchase"
            steps={[
              "Make sure you are signed into the correct Apple ID.",
              "Go to Settings in Unit and tap Restore Purchase.",
              "If the issue persists, restart the app and try again.",
            ]}
          />
          <TroubleshootItem
            title="Rest timer is not showing on Lock Screen"
            steps={[
              "Make sure Live Activities are enabled in your device Settings > Unit.",
              "Check that you have iOS 18 or later.",
              "Start a rest timer from the active workout screen.",
            ]}
          />
          <TroubleshootItem
            title="Last-time numbers look wrong"
            steps={[
              "The numbers come from your most recent session for each exercise.",
              "If a previous session was logged incorrectly, edit or delete the set in your session history.",
              "They update automatically after your next session.",
            ]}
          />
        </div>

        <div className="mt-unit-xl">
          <Link
            href="/"
            className="text-sm text-unit-text-secondary hover:text-unit-text-primary transition-colors"
          >
            &larr; Back to home
          </Link>
        </div>
      </div>
    </section>
  )
}

function TroubleshootItem({
  title,
  steps,
}: {
  title: string
  steps: string[]
}) {
  return (
    <div>
      <h3 className="text-base font-semibold mb-unit-xs">{title}</h3>
      <ol className="list-decimal pl-5 space-y-1 text-[15px] leading-relaxed text-unit-text-secondary">
        {steps.map((step, i) => (
          <li key={i}>{step}</li>
        ))}
      </ol>
    </div>
  )
}
