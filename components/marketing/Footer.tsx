import Link from "next/link"
import Image from "next/image"
import { compareSlugs, compareSlugList } from "@/app/(marketing)/compare/data"
import { programSlugs, programSlugList } from "@/app/(marketing)/programs/data"

const compareLinks = compareSlugList.map((slug) => ({
  href: `/compare/${slug}`,
  label: `vs ${compareSlugs[slug].competitor}`,
}))

const programLinks = programSlugList.map((slug) => ({
  href: `/programs/${slug}`,
  label: programSlugs[slug].title,
}))

const resourceLinks = [
  { href: "/changelog", label: "Changelog" },
  { href: "/support", label: "Support" },
]

const legalLinks = [
  { href: "/privacy", label: "Privacy" },
  { href: "/terms", label: "Terms" },
]

type Column = { heading: string; links: { href: string; label: string }[] }

const columns: Column[] = [
  { heading: "Compare", links: compareLinks },
  { heading: "Programs", links: programLinks },
  { heading: "Resources", links: resourceLinks },
  { heading: "Legal", links: legalLinks },
]

export default function Footer() {
  return (
    <footer className="border-t border-unit-border">
      <div className="max-w-6xl mx-auto px-unit-md md:px-unit-lg py-unit-xxl">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-unit-xl md:gap-unit-lg">
          {columns.map((col) => (
            <div key={col.heading}>
              <p className="eyebrow mb-unit-md">{col.heading}</p>
              <ul className="flex flex-col gap-unit-sm">
                {col.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="text-sm text-unit-text-secondary hover:text-unit-text-primary transition-colors"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Legal strip separated by whitespace, not a second hairline.
            The outer footer border-t already marks the boundary; a second
            divider here adds chrome the page doesn't need. */}
        <div className="mt-unit-xxl flex flex-col md:flex-row md:items-center md:justify-between gap-unit-sm">
          <Link href="/" aria-label="Unit home" className="flex items-center">
            <Image
              src="/app-icon.png"
              alt="Unit"
              width={32}
              height={32}
              className="h-8 w-8 rounded-md"
            />
          </Link>
          <p className="font-mono text-[13px] tracking-[0.6px] text-unit-text-secondary">
            &copy; {new Date().getFullYear()} Unit
          </p>
        </div>
      </div>
    </footer>
  )
}
