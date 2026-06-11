"use client"

import { useState } from "react"
import { flushSync } from "react-dom"
import { isValidEmail } from "@/lib/email"

type State =
  | { kind: "idle" }
  | { kind: "submitting" }
  | { kind: "success" }
  | { kind: "error"; message: string }

// Shared `view-transition-name` so the input pill and the success pill
// morph into each other instead of swapping. Browsers that don't support
// the View Transitions API (Firefox today) fall back to instant swap.
const VIEW_TRANSITION_NAME = "waitlist"

function withViewTransition(update: () => void) {
  if (
    typeof document !== "undefined" &&
    typeof (document as { startViewTransition?: unknown })
      .startViewTransition === "function"
  ) {
    ;(
      document as unknown as {
        startViewTransition: (cb: () => void) => void
      }
    ).startViewTransition(() => flushSync(update))
  } else {
    update()
  }
}

export default function WaitlistForm({
  size = "lg",
  caption,
}: {
  size?: "lg" | "md"
  caption?: string
}) {
  const [email, setEmail] = useState("")
  const [state, setState] = useState<State>({ kind: "idle" })

  const heightVar =
    size === "lg" ? "var(--button-height-lg)" : "var(--button-height-md)"
  const textClass = size === "lg" ? "text-[17px]" : "text-[15px]"
  const emailIsValid = isValidEmail(email)

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!emailIsValid || state.kind === "submitting") return
    setState({ kind: "submitting" })
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      })
      const data = await res.json().catch(() => ({}))
      if (!res.ok || data?.ok === false) {
        const message =
          typeof data?.error === "string"
            ? data.error
            : "Couldn't sign you up. Try again in a moment."
        setState({ kind: "error", message })
        return
      }
      withViewTransition(() => setState({ kind: "success" }))
    } catch {
      setState({
        kind: "error",
        message: "Couldn't reach the server. Try again in a moment.",
      })
    }
  }

  if (state.kind === "success") {
    return (
      <div
        className={`inline-flex items-center justify-center px-unit-lg rounded-xl bg-unit-card border border-unit-border ${textClass} font-semibold`}
        style={{
          height: heightVar,
          viewTransitionName: VIEW_TRANSITION_NAME,
        }}
        role="status"
      >
        You&rsquo;re on the list. I&rsquo;ll email you at launch.
      </div>
    )
  }

  return (
    <div
      className="w-full max-w-md"
      style={{ viewTransitionName: VIEW_TRANSITION_NAME }}
    >
      <form
        onSubmit={onSubmit}
        className="flex flex-col sm:flex-row gap-unit-xs sm:gap-unit-sm"
      >
        <label htmlFor="waitlist-email" className="sr-only">
          Email address
        </label>
        <input
          id="waitlist-email"
          type="email"
          required
          inputMode="email"
          autoComplete="email"
          placeholder="you@email.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          aria-invalid={state.kind === "error"}
          aria-describedby={
            state.kind === "error" ? "waitlist-error" : undefined
          }
          className={`flex-1 px-unit-md rounded-xl bg-unit-card border border-unit-border ${textClass} font-medium text-unit-text-primary placeholder:text-unit-text-secondary focus:outline-none focus:border-unit-accent transition-colors`}
          style={{ height: heightVar }}
        />
        <button
          type="submit"
          disabled={!emailIsValid || state.kind === "submitting"}
          className={`btn-primary px-unit-lg ${textClass}`}
          style={{ height: heightVar }}
        >
          {state.kind === "submitting" ? "Joining…" : "Join waitlist"}
        </button>
      </form>
      {state.kind === "error" && (
        <p
          id="waitlist-error"
          role="alert"
          className="mt-unit-xs text-[13px] font-medium text-unit-error"
        >
          {state.message}
        </p>
      )}
      {state.kind !== "error" && caption && (
        <p className="mt-unit-xs text-[13px] text-unit-text-secondary">
          {caption}
        </p>
      )}
    </div>
  )
}
