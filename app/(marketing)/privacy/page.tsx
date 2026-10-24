import type { Metadata } from "next"
import Link from "next/link"
import {
  SUPPORT_EMAIL,
  DEVELOPER_NAME,
  PRIVACY_LAST_UPDATED,
} from "@/lib/contact"

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "Unit privacy policy. Workout details stay on your device. Limited anonymous product analytics are off until you turn them on.",
  alternates: { canonical: "/privacy" },
}

export default function PrivacyPage() {
  return (
    <section className="pt-32 pb-unit-xxl md:pb-unit-xxxxl">
      <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
        <article className="prose-page">
          <h1>Privacy Policy</h1>
          <p className="last-updated">Last updated: {PRIVACY_LAST_UPDATED}</p>

          <p>
            Unit (&quot;the App&quot;) is developed and operated by{" "}
            {DEVELOPER_NAME} (&quot;I,&quot; &quot;me,&quot; or &quot;my&quot;).
            This Privacy Policy explains how I handle your information when you
            use Unit.
          </p>

          <nav aria-label="On this page" className="page-toc">
            <ul>
              <li><a href="#summary">Summary</a></li>
              <li><a href="#data-storage">Data storage</a></li>
              <li><a href="#analytics">Anonymous analytics</a></li>
              <li><a href="#data-not-collected">Data I do not collect</a></li>
              <li><a href="#feature-requests">Feature requests</a></li>
              <li><a href="#purchases">Purchases</a></li>
              <li><a href="#healthkit">Apple Health</a></li>
              <li><a href="#cookies">Cookies and web tracking</a></li>
              <li><a href="#children">Children&apos;s privacy</a></li>
              <li><a href="#rights">Your rights</a></li>
              <li><a href="#changes">Changes to this policy</a></li>
              <li><a href="#contact">Contact</a></li>
            </ul>
          </nav>

          <h2 id="summary">Summary</h2>
          <p>
            Unit is designed with privacy as a default. Your raw workout data
            stays on your device and Unit does not require an account. Unit sends
            limited anonymous product-usage events to help me understand where
            setup or workout flows fail, only if you turn analytics on.
          </p>

          <h2 id="analytics">Anonymous Analytics</h2>
          <p>
            Unit uses TelemetryDeck for limited product analytics. Analytics are
            off until you turn them on: on the first setup step, or under
            Settings → Anonymous analytics. Nothing is sent before that. You can
            turn analytics off at any time in the same places, and the paywall
            shows the switch while it is on. Turning it off stops future
            analytics events immediately. Unit remains fully functional offline
            and when analytics are off or unavailable.
          </p>
          <p>
            TelemetryDeck processes these events for Unit under its privacy
            safeguards. You can read the TelemetryDeck privacy FAQ at{" "}
            <a
              href="https://telemetrydeck.com/docs/guides/privacy-faq/"
              rel="noreferrer"
              target="_blank"
            >
              telemetrydeck.com
            </a>.
          </p>
          <p>
            Events describe product interactions using controlled categories
            and broad buckets, such as which onboarding slide was viewed,
            whether a program was pasted or selected, whether a trial or
            purchase completed, a broad workout-duration or set-count range,
            and whether a progression suggestion was accepted, repeated, or
            edited. These events are not linked to your identity and are not
            used for advertising or tracking across apps or websites.
          </p>
          <p>
            To count anonymous activity without an account, TelemetryDeck
            processes a privacy-preserving app-scoped identifier derived from
            the device&apos;s vendor identifier. It is not used to identify you,
            link analytics to an account, or track you across apps or websites.
          </p>
          <p>
            Analytics never include exercise names, program text, weights,
            repetitions, notes, bodyweight, email addresses, exact workout
            timestamps, raw workout identifiers, calendar details, or StoreKit
            receipts.
          </p>

          <h2 id="data-storage">Data Storage</h2>
          <p>
            All data you create in Unit, including exercises, workout sessions,
            routines, progression settings, and set entries, is stored locally on your
            device using Apple&apos;s SwiftData framework. This data is not
            transmitted to any external server.
          </p>
          <p>
            If you have iCloud Backup enabled on your device, Unit&apos;s local
            data may be included in those backups. iCloud Backup is operated by
            Apple under your Apple ID and is governed by Apple&apos;s privacy
            policy. I have no access to your iCloud account or its contents.
          </p>
          <p>
            If you delete the App, your locally stored data will be removed from
            your device.
          </p>

          <h2 id="data-not-collected">Data I Do Not Collect</h2>
          <ul>
            <li>I do not collect your name, email address, or contact information through the App</li>
            <li>I do not collect workout data or training history</li>
            <li>I do not use advertising identifiers, fingerprinting, or session replay</li>
            <li>I do not use advertising SDKs</li>
            <li>I do not use analytics for cross-app or cross-website tracking</li>
          </ul>

          <h2 id="feature-requests">Feature Requests</h2>
          <p>
            Settings includes an optional &quot;Request a feature&quot; link. It
            opens a public feedback portal operated by Featurebase (CORDNET OÜ).
            Unit does not send workout data, health data, device information,
            your identity, or analytics parameters when opening this link.
          </p>
          <p>
            Anything you choose to submit or upvote on the portal is handled by
            Featurebase and may be publicly visible. Do not include personal or
            workout information in a request. Featurebase may process technical
            information such as your IP address, browser details, and cookies
            under its{" "}
            <a
              href="https://help.featurebase.app/articles/4744036-privacy-policy"
              rel="noreferrer"
              target="_blank"
            >
              privacy policy
            </a>.
          </p>

          <h2 id="purchases">Purchases</h2>
          <p>
            Unit offers in-app purchases processed by Apple through the App
            Store. I do not receive or store your payment information or
            StoreKit receipt. Unit may send an anonymous event containing only
            the selected subscription tier and whether a verified trial or
            purchase completed. Purchase records are managed by your Apple ID.
          </p>

          <h2 id="healthkit">Apple Health</h2>
          <p>
            Starting with version 2.2, Unit can save your finished workouts to
            Apple Health. This stays off until you turn on Save to Apple Health
            in Settings, and iOS asks for your permission first. Unit saves each
            workout as strength training with its start and end time. Unit does
            not read any data from Apple Health, and nothing from Apple Health
            is sent to me or to anyone else. You can turn this off in Settings,
            or remove Unit&apos;s access in the Apple Health app, at any time.
          </p>

          <h2 id="cookies">Cookies and Web Tracking</h2>
          <p>
            This website does not use cookies, analytics scripts, or any form of
            visitor tracking.
          </p>

          <h2 id="children">Children&apos;s Privacy</h2>
          <p>
            Unit is not directed at children under the age of 13. I do not
            knowingly collect information from children.
          </p>

          <h2 id="rights">Your Rights</h2>
          <p>
            Unit does not maintain an account or server-side workout record for
            me to delete, export, or modify. Your workout data remains under
            your control on your device. Requests submitted through Featurebase
            are governed by Featurebase&apos;s privacy controls and policy.
          </p>
          <p>
            If you have questions about your data or wish to make a
            privacy-related request, email me at {SUPPORT_EMAIL}.
          </p>

          <h2 id="changes">Changes to This Policy</h2>
          <p>
            I may update this Privacy Policy from time to time. Changes will be
            posted on this page with an updated &quot;Last updated&quot; date.
            Continued use of the App after changes constitutes acceptance of the
            revised policy.
          </p>

          <h2 id="contact">Contact</h2>
          <p>
            If you have questions about this Privacy Policy, email me at:
          </p>
          <ul>
            <li>Email: {SUPPORT_EMAIL}</li>
            <li>Developer: {DEVELOPER_NAME}</li>
          </ul>

          <div className="mt-12">
            <Link
              href="/"
              className="text-sm text-unit-text-secondary hover:text-unit-text-primary transition-colors"
            >
              &larr; Back to home
            </Link>
          </div>
        </article>
      </div>
    </section>
  )
}
