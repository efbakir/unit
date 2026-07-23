"use client"

import { useEffect } from "react"
import { SUPPORT_EMAIL } from "@/lib/contact"

// Quiet message for anyone who opens DevTools. Same voice as the rest of
// the page. Utility-first, peer-to-peer. Runs once on mount.
export default function ConsoleSignature() {
  useEffect(() => {
    if (typeof window === "undefined") return
    if ((window as { __unitConsoleSignaturePrinted?: boolean }).__unitConsoleSignaturePrinted) return
    ;(window as { __unitConsoleSignaturePrinted?: boolean }).__unitConsoleSignaturePrinted = true

    const styleHeading = "font: 600 14px/1.4 Geist, system-ui; color: #0A0A0A;"
    const styleBody = "font: 500 12px/1.4 Geist, system-ui; color: #595959;"

    // Single grouped log so the page console isn't noisy. No ASCII art,
    // no emoji or playful filler. Unit's voice is direct.
    /* eslint-disable no-console */
    console.log("%cUnit", styleHeading)
    console.log(
      "%cBuilt by one lifter, for lifters. Notebook fast, on-device, no AI.\nQuestions, bugs, or just want to say hi: " +
        SUPPORT_EMAIL,
      styleBody
    )
    /* eslint-enable no-console */
  }, [])

  return null
}
