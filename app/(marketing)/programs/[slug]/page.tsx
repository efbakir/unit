import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"
import AppStoreBadge from "@/components/marketing/AppStoreBadge"
import { APP_STORE_URL } from "@/lib/launchState"
import { programSlugs, programSlugList } from "../data"

export function generateStaticParams() {
  return programSlugList.map((slug) => ({ slug }))
}

type Params = Promise<{ slug: string }>

export async function generateMetadata({
  params,
}: {
  params: Params
}): Promise<Metadata> {
  const { slug } = await params
  const data = programSlugs[slug]
  if (!data) return {}
  return {
    title: { absolute: data.metaTitle },
    description: data.metaDescription,
    alternates: { canonical: `/programs/${slug}` },
    openGraph: {
      title: data.metaTitle,
      description: data.metaDescription,
      url: `https://unitlift.app/programs/${slug}`,
      type: "article",
    },
  }
}

export default async function ProgramPage({ params }: { params: Params }) {
  const { slug } = await params
  const data = programSlugs[slug]
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
        name: "Programs",
        item: "https://unitlift.app/programs",
      },
      {
        "@type": "ListItem",
        position: 3,
        name: data.title,
        item: `https://unitlift.app/programs/${slug}`,
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
            <span>Programs</span>
            <span className="mx-unit-xs">/</span>
            <span>{data.title}</span>
          </p>
          <h1 className="h-section mb-unit-md text-balance">{data.h1}</h1>
          <p className="text-xl leading-snug text-unit-text-secondary max-w-2xl">
            Import in 30 seconds. Log a set in three.
          </p>
        </div>
      </section>

      {/* ── Description ── */}
      <section className="py-unit-xl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <p className="eyebrow mb-unit-sm">About the program</p>
          <p className="text-base leading-relaxed text-unit-text-secondary">
            {data.description}
          </p>
        </div>
      </section>

      {/* ── Paste template ── */}
      <section className="py-unit-xl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <p className="eyebrow mb-unit-sm">Copy paste this</p>
          <pre className="bg-unit-card rounded-md p-unit-md text-sm font-mono leading-relaxed text-unit-text-primary border border-unit-border overflow-x-auto whitespace-pre">
            {data.template}
          </pre>
        </div>
      </section>

      {/* ── Import steps ── */}
      <section className="py-unit-xl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg">
          <p className="eyebrow mb-unit-sm">Import this in 30 seconds</p>
          <ol className="space-y-unit-md">
            {data.importSteps.map((step, idx) => (
              <li key={idx} className="flex gap-unit-sm items-baseline">
                <span className="shrink-0 w-[18px] h-[18px] rounded-sm bg-unit-accent text-unit-accent-foreground text-[11px] font-bold inline-flex items-center justify-center self-start translate-y-[5px]">
                  {idx + 1}
                </span>
                <span className="text-base leading-relaxed text-unit-text-primary">
                  {step}
                </span>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* ── Final CTA ── */}
      <section className="py-unit-xxl md:py-unit-xxxl border-t border-unit-border">
        <div className="max-w-3xl mx-auto px-unit-md md:px-unit-lg text-center">
          <h2 className="h-section mb-unit-md">
            Bring your program. Unit logs it.
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
