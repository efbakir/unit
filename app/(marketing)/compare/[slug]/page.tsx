import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"
import AppStoreBadge from "@/components/marketing/AppStoreBadge"
import { APP_STORE_URL } from "@/lib/launchState"
import { compareSlugs, compareSlugList } from "../data"

export function generateStaticParams() {
  return compareSlugList.map((slug) => ({ slug }))
}

type Params = Promise<{ slug: string }>

export async function generateMetadata({
  params,
}: {
  params: Params
}): Promise<Metadata> {
  const { slug } = await params
  const data = compareSlugs[slug]
  if (!data) return {}
  return {
    title: { absolute: data.metaTitle },
    description: data.metaDescription,
    alternates: { canonical: `/compare/${slug}` },
    openGraph: {
      title: data.metaTitle,
      description: data.metaDescription,
      url: `https://unitlift.app/compare/${slug}`,
      type: "website",
    },
  }
}

export default async function ComparePage({ params }: { params: Params }) {
  const { slug } = await params
  const data = compareSlugs[slug]
  if (!data) notFound()

  const breadcrumbLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: "https://unitlift.app/",
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Compare",
        item: "https://unitlift.app/compare",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: `Unit vs ${data.competitor}`,
        item: `https://unitlift.app/compare/${slug}`,
      },
    ],
  }

  const CTA = <AppStoreBadge href={APP_STORE_URL} />

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbLd) }}
      />

      {/* ── Hero ── */}
      <section className="pt-32 md:pt-40 pb-unit-xl">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <p className="eyebrow mb-unit-sm">
            <Link
              href="/"
              className="hover:text-unit-text-primary transition-colors"
            >
              Home
            </Link>
            <span className="mx-unit-xs">/</span>
            <span>Compare</span>
            <span className="mx-unit-xs">/</span>
            <span>Unit vs {data.competitor}</span>
          </p>
          <h1 className="h-section mb-unit-md text-balance">
            Unit vs {data.competitor}, a calmer alternative.
          </h1>
          <p className="text-xl leading-snug text-unit-text-secondary max-w-2xl">
            {data.heroSubhead}
          </p>
        </div>
      </section>

      {/* ── Comparison table ── */}
      <section className="py-unit-xl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <p className="eyebrow mb-unit-md">Side by side</p>
          <div className="rounded-md border border-unit-border bg-unit-card overflow-hidden">
            <div
              role="table"
              aria-label={`Unit vs ${data.competitor} comparison`}
            >
              <div
                role="row"
                className="hidden md:grid md:grid-cols-[1fr_1.2fr_1.2fr] gap-unit-md px-unit-lg py-unit-md border-b border-unit-border"
              >
                <span
                  role="columnheader"
                  className="text-[13px] font-mono font-medium uppercase tracking-[0.6px] text-unit-text-secondary"
                >
                  Feature
                </span>
                <span
                  role="columnheader"
                  className="text-[13px] font-mono font-medium uppercase tracking-[0.6px] text-unit-text-secondary"
                >
                  Unit
                </span>
                <span
                  role="columnheader"
                  className="text-[13px] font-mono font-medium uppercase tracking-[0.6px] text-unit-text-secondary"
                >
                  {data.competitor}
                </span>
              </div>

              {data.table.map((row, idx) => (
                <div
                  role="row"
                  key={row.feature}
                  className={`grid grid-cols-1 md:grid-cols-[1fr_1.2fr_1.2fr] gap-unit-sm md:gap-unit-md px-unit-lg py-unit-md ${
                    idx > 0 ? "border-t border-unit-border" : ""
                  }`}
                >
                  <div role="rowheader" className="md:hidden">
                    <p className="eyebrow mb-unit-xs">{row.feature}</p>
                  </div>
                  <div
                    role="rowheader"
                    className="hidden md:block text-base font-semibold text-unit-text-primary"
                  >
                    {row.feature}
                  </div>
                  <div role="cell" className="text-[15px] leading-relaxed text-unit-text-primary">
                    <span className="md:hidden eyebrow block mb-unit-xs">Unit</span>
                    {row.unit}
                  </div>
                  <div role="cell" className="text-[15px] leading-relaxed text-unit-text-secondary">
                    <span className="md:hidden eyebrow block mb-unit-xs">
                      {data.competitor}
                    </span>
                    {row.competitor}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ── When competitor is right ── */}
      <section className="py-unit-xl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <h2 className="text-xl font-bold tracking-tight mb-unit-sm">
            When {data.competitor} is the right choice
          </h2>
          <p className="text-base leading-relaxed text-unit-text-secondary">
            {data.whenCompetitor}
          </p>
        </div>
      </section>

      {/* ── When Unit is right ── */}
      <section className="py-unit-xl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <h2 className="text-xl font-bold tracking-tight mb-unit-sm">
            When Unit is the right choice
          </h2>
          <p className="text-base leading-relaxed text-unit-text-secondary">
            {data.whenUnit}
          </p>
        </div>
      </section>

      {/* ── Final CTA ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <h2 className="h-section mb-unit-md">
            Faster than paper.
          </h2>
          <p className="text-xl leading-snug mb-unit-xl text-unit-text-secondary max-w-xl mx-auto">
            {data.closing}
          </p>
          <div className="flex justify-center">{CTA}</div>
          <p className="mt-unit-md text-[13px] text-unit-text-secondary">
            <Link href="/" className="hover:text-unit-text-primary transition-colors">
              Back to home
            </Link>
          </p>
        </div>
      </section>
    </>
  )
}
