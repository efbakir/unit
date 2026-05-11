import type { Metadata } from "next"
import Link from "next/link"
import { SUPPORT_EMAIL, DEVELOPER_NAME, LEGAL_LAST_UPDATED } from "@/lib/contact"

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "Unit privacy policy. Your workout data stays on your device. No account, no analytics, no tracking. Local-first iOS gym logger.",
  alternates: { canonical: "/privacy" },
}

export default function PrivacyPage() {
  return (
    <section className="pt-32 pb-unit-xxl md:pb-unit-xxxxl">
      <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
        <article className="prose-page">
          <h1>Privacy Policy</h1>
          <p className="last-updated">Last updated: {LEGAL_LAST_UPDATED}</p>

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
              <li><a href="#data-not-collected">Data I do not collect</a></li>
              <li><a href="#purchases">Purchases</a></li>
              <li><a href="#healthkit">HealthKit</a></li>
              <li><a href="#cookies">Cookies and web tracking</a></li>
              <li><a href="#children">Children&apos;s privacy</a></li>
              <li><a href="#rights">Your rights</a></li>
              <li><a href="#changes">Changes to this policy</a></li>
              <li><a href="#contact">Contact</a></li>
            </ul>
          </nav>

          <h2 id="summary">Summary</h2>
          <p>
            Unit is designed with privacy as a default. Your workout data stays
            on your device. I do not collect, transmit, or store your personal
            information on any server.
          </p>

          <h2 id="data-storage">Data Storage</h2>
          <p>
            All data you create in Unit — exercises, workout sessions, cycles,
            progression rules, and set entries — is stored locally on your
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
            <li>I do not use analytics or tracking frameworks</li>
            <li>I do not use advertising SDKs</li>
            <li>I do not sell, share, or transfer any data to third parties</li>
          </ul>

          <h2 id="purchases">Purchases</h2>
          <p>
            Unit offers in-app purchases processed entirely by Apple through the
            App Store. I do not receive or store your payment information.
            Purchase records are managed by your Apple ID.
          </p>

          <h2 id="healthkit">HealthKit</h2>
          <p>
            Unit does not currently integrate with Apple HealthKit. If HealthKit
            integration is added in a future update, this policy will be updated
            and you will be asked for explicit permission before any health data
            is accessed.
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
            Since Unit does not collect personal data, there is no personal data
            for me to delete, export, or modify. All your data is under your
            control on your device.
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
