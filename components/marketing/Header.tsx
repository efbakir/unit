"use client"

import { useState, useEffect, useRef } from "react"
import Link from "next/link"
import Image from "next/image"
import { compareSlugs, compareSlugList } from "@/app/(marketing)/compare/data"
import { programSlugs, programSlugList } from "@/app/(marketing)/programs/data"
import { APP_STORE_URL } from "@/lib/launchState"

const ctaLabel = "Download Unit"

type DropdownKey = "compare" | "programs"
type DropdownState = DropdownKey | null

const compareItems = compareSlugList.map((slug) => ({
  href: `/compare/${slug}`,
  label: `vs ${compareSlugs[slug].competitor}`,
}))

const programItems = programSlugList.map((slug) => ({
  href: `/programs/${slug}`,
  label: programSlugs[slug].title,
}))

// Intent delay before hover-leave closes the menu — long enough to traverse
// the trigger→panel gap without flicker, short enough to feel snappy.
const HOVER_CLOSE_DELAY = 140

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false)
  const [openDropdown, setOpenDropdown] = useState<DropdownState>(null)
  const dropdownRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (!openDropdown) return
    const onClick = (e: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(e.target as Node)
      ) {
        setOpenDropdown(null)
      }
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpenDropdown(null)
    }
    window.addEventListener("mousedown", onClick)
    window.addEventListener("keydown", onKey)
    return () => {
      window.removeEventListener("mousedown", onClick)
      window.removeEventListener("keydown", onKey)
    }
  }, [openDropdown])

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-unit-background border-b border-unit-border">
      <nav className="max-w-6xl mx-auto px-unit-md md:px-unit-lg flex items-center justify-between h-16">
        <Link
          href="/"
          aria-label="Unit — home"
          className="flex items-center"
        >
          <Image
            src="/app-icon.png"
            alt="Unit"
            width={32}
            height={32}
            priority
            className="h-8 w-8 rounded-md"
          />
        </Link>

        {/* Desktop nav */}
        <div
          ref={dropdownRef}
          className="hidden md:flex items-center gap-unit-lg"
        >
          <DesktopDropdown
            itemKey="compare"
            label="Compare"
            isOpen={openDropdown === "compare"}
            setOpenDropdown={setOpenDropdown}
            items={compareItems}
          />
          <DesktopDropdown
            itemKey="programs"
            label="Programs"
            isOpen={openDropdown === "programs"}
            setOpenDropdown={setOpenDropdown}
            items={programItems}
          />
          <Link href="/support" className="eyebrow-link">
            Support
          </Link>
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noreferrer"
            className="btn-primary h-11 px-unit-md text-[13px]"
          >
            {ctaLabel}
          </a>
        </div>

        {/* Mobile hamburger */}
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="md:hidden flex flex-col gap-[5px] p-3 -mr-3"
          aria-label="Toggle menu"
          aria-expanded={menuOpen}
        >
          <span
            className={`block w-5 h-[1.5px] bg-unit-text-primary transition-transform duration-200 ${
              menuOpen ? "rotate-45 translate-y-[6.5px]" : ""
            }`}
          />
          <span
            className={`block w-5 h-[1.5px] bg-unit-text-primary transition-opacity duration-200 ${
              menuOpen ? "opacity-0" : ""
            }`}
          />
          <span
            className={`block w-5 h-[1.5px] bg-unit-text-primary transition-transform duration-200 ${
              menuOpen ? "-rotate-45 -translate-y-[6.5px]" : ""
            }`}
          />
        </button>
      </nav>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden border-t border-unit-border bg-unit-background">
          <div className="max-w-6xl mx-auto px-unit-md py-unit-lg flex flex-col gap-unit-lg">
            <MobileSection label="Compare" items={compareItems} onItemClick={() => setMenuOpen(false)} />
            <MobileSection label="Programs" items={programItems} onItemClick={() => setMenuOpen(false)} />
            <Link
              href="/support"
              onClick={() => setMenuOpen(false)}
              className="eyebrow-link py-2"
            >
              Support
            </Link>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noreferrer"
              onClick={() => setMenuOpen(false)}
              className="btn-primary text-[15px] px-unit-lg mt-unit-xs"
              style={{ height: "var(--button-height-lg)" }}
            >
              {ctaLabel}
            </a>
          </div>
        </div>
      )}
    </header>
  )
}

type NavItem = { href: string; label: string }

function DesktopDropdown({
  itemKey,
  label,
  isOpen,
  setOpenDropdown,
  items,
}: {
  itemKey: DropdownKey
  label: string
  isOpen: boolean
  setOpenDropdown: React.Dispatch<React.SetStateAction<DropdownState>>
  items: NavItem[]
}) {
  const closeTimer = useRef<number | null>(null)

  const cancelClose = () => {
    if (closeTimer.current !== null) {
      window.clearTimeout(closeTimer.current)
      closeTimer.current = null
    }
  }

  const open = () => {
    cancelClose()
    setOpenDropdown(itemKey)
  }

  const scheduleClose = () => {
    cancelClose()
    closeTimer.current = window.setTimeout(() => {
      setOpenDropdown((prev) => (prev === itemKey ? null : prev))
      closeTimer.current = null
    }, HOVER_CLOSE_DELAY)
  }

  const closeNow = () => {
    cancelClose()
    setOpenDropdown((prev) => (prev === itemKey ? null : prev))
  }

  useEffect(() => () => cancelClose(), [])

  return (
    <div
      className="relative"
      onMouseEnter={open}
      onMouseLeave={scheduleClose}
    >
      <button
        type="button"
        onClick={() => (isOpen ? closeNow() : open())}
        aria-expanded={isOpen}
        aria-haspopup="true"
        className="eyebrow-link inline-flex items-center gap-1.5 py-2"
      >
        {label}
        <Caret open={isOpen} />
      </button>
      {isOpen && (
        // pt-unit-xs (instead of mt-unit-xs on the chrome below) keeps the
        // hover surface continuous from trigger → panel — the visual gap is
        // padding inside the hoverable element, not an empty layout gap.
        <div role="menu" className="absolute right-0 top-full pt-unit-xs">
          <div className="min-w-[200px] rounded-md border border-unit-border bg-unit-background py-unit-xs shadow-sm">
            {items.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                role="menuitem"
                onClick={closeNow}
                className="block px-unit-md py-2 text-sm text-unit-text-secondary transition-colors hover:text-unit-text-primary hover:bg-unit-muted"
              >
                {item.label}
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function MobileSection({
  label,
  items,
  onItemClick,
}: {
  label: string
  items: NavItem[]
  onItemClick: () => void
}) {
  return (
    <div className="flex flex-col gap-unit-sm">
      <p className="eyebrow">{label}</p>
      {items.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          onClick={onItemClick}
          className="text-base text-unit-text-secondary py-1"
        >
          {item.label}
        </Link>
      ))}
    </div>
  )
}

function Caret({ open }: { open: boolean }) {
  return (
    <svg
      width="9"
      height="9"
      viewBox="0 0 10 10"
      fill="none"
      aria-hidden="true"
      className={`transition-transform duration-150 ${open ? "rotate-180" : ""}`}
    >
      <path
        d="M2 4l3 3 3-3"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}
