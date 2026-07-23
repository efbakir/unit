type FeatureVisual =
  | "local"
  | "timer"
  | "pr"
  | "calendar"
  | "quick"
  | "programs"

const features: {
  title: string
  body: string
  visual: FeatureVisual
}[] = [
  {
    title: "Stored on your iPhone",
    body: "No account, sync, or internet required.",
    visual: "local",
  },
  {
    title: "Lock Screen timer",
    body: "Your rest time stays visible between sets.",
    visual: "timer",
  },
  {
    title: "Automatic PRs",
    body: "See new weight, rep, and volume records.",
    visual: "pr",
  },
  {
    title: "Training calendar",
    body: "Find every completed session at a glance.",
    visual: "calendar",
  },
  {
    title: "Quick Start",
    body: "Start lifting without choosing a template.",
    visual: "quick",
  },
  {
    title: "Starter programs",
    body: "Choose a proven split or paste your own.",
    visual: "programs",
  },
]

function LocalVisual() {
  return (
    <div className="flex h-full items-end justify-center">
      <div className="w-full max-w-[240px] rounded-[22px] bg-unit-background p-unit-md">
        <div className="mb-unit-md flex items-center gap-unit-sm">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-unit-accent text-unit-accent-foreground">
            <svg
              viewBox="0 0 24 24"
              className="h-5 w-5"
              aria-hidden="true"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
            >
              <rect x="7" y="2.5" width="10" height="19" rx="2.5" />
              <path d="M10 5h4M11 18.5h2" />
            </svg>
          </span>
          <div>
            <p className="text-sm font-bold tracking-tight">On this iPhone</p>
            <p className="text-xs text-unit-text-secondary">Private by default</p>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-unit-xs text-center">
          {["Account", "Sync", "Tracking"].map((item) => (
            <div key={item} className="rounded-xl bg-unit-card px-unit-xs py-unit-sm">
              <p className="text-sm font-bold">No</p>
              <p className="mt-1 text-[10px] text-unit-text-secondary">{item}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function TimerVisual() {
  return (
    <div className="flex h-full items-end justify-center">
      <div className="w-full max-w-[260px] rounded-[28px] bg-unit-accent p-unit-lg text-unit-accent-foreground shadow-[0_20px_50px_rgba(10,10,10,0.14)]">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.16em] opacity-60">
              Rest timer
            </p>
            <p className="mt-unit-xs text-[34px] font-bold tabular-nums tracking-tight">
              01:57
            </p>
          </div>
          <div className="flex gap-unit-xs">
            <span className="flex h-10 w-10 items-center justify-center rounded-full bg-white/12 text-lg">
              −
            </span>
            <span className="flex h-10 w-10 items-center justify-center rounded-full bg-white/12 text-lg">
              +
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

function PRVisual() {
  return (
    <div className="flex h-full flex-col justify-end">
      <div className="mb-unit-md">
        <div className="flex items-end justify-between">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-unit-text-secondary">
              Back squat
            </p>
            <p className="mt-unit-xs text-[36px] font-bold tabular-nums tracking-tight">
              140 kg
            </p>
          </div>
          <span className="rounded-full bg-unit-accent px-unit-sm py-unit-xs text-[10px] font-bold uppercase tracking-[0.12em] text-unit-accent-foreground">
            New PR
          </span>
        </div>
      </div>
      <div className="grid grid-cols-3 gap-unit-xs">
        {[
          ["Weight", "+2.5 kg"],
          ["Reps", "+1"],
          ["Volume", "+4%"],
        ].map(([label, value]) => (
          <div key={label} className="rounded-xl bg-unit-background p-unit-sm">
            <p className="text-sm font-bold tabular-nums">{value}</p>
            <p className="mt-1 text-[10px] text-unit-text-secondary">{label}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

function CalendarVisual() {
  const days = [
    ["M", true],
    ["T", false],
    ["W", true],
    ["T", false],
    ["F", true],
    ["S", false],
    ["S", true],
  ] as const

  return (
    <div className="flex h-full items-end justify-center">
      <div className="w-full max-w-[270px] rounded-[22px] bg-unit-background p-unit-md">
        <div className="mb-unit-md flex items-center justify-between">
          <p className="text-sm font-bold tracking-tight">This week</p>
          <p className="text-xs text-unit-text-secondary">4 sessions</p>
        </div>
        <div className="grid grid-cols-7 gap-unit-xs">
          {days.map(([day, active], index) => (
            <div key={`${day}-${index}`} className="text-center">
              <p className="mb-unit-xs text-[10px] text-unit-text-secondary">{day}</p>
              <span
                className={`mx-auto block aspect-square w-full max-w-7 rounded-lg ${
                  active ? "bg-unit-accent" : "bg-unit-card"
                }`}
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function QuickVisual() {
  return (
    <div className="flex h-full items-end justify-center">
      <div className="w-full max-w-[250px] text-center">
        <div className="mb-unit-md flex items-center justify-center gap-unit-xs">
          {["Squat", "Press", "Row"].map((exercise) => (
            <span
              key={exercise}
              className="rounded-full bg-unit-background px-unit-sm py-unit-xs text-xs font-semibold"
            >
              {exercise}
            </span>
          ))}
        </div>
        <div className="rounded-xl bg-unit-accent px-unit-md py-unit-md text-sm font-bold text-unit-accent-foreground shadow-[0_16px_36px_rgba(10,10,10,0.12)]">
          Start workout
        </div>
        <p className="mt-unit-sm text-xs text-unit-text-secondary">No template needed</p>
      </div>
    </div>
  )
}

function ProgramsVisual() {
  return (
    <div className="flex h-full items-end justify-center">
      <div className="w-full max-w-[260px] space-y-unit-xs">
        {[
          ["PPL", "6 days"],
          ["Upper / Lower", "4 days"],
          ["5 / 3 / 1", "4 days"],
        ].map(([name, days], index) => (
          <div
            key={name}
            className={`flex items-center justify-between rounded-xl px-unit-md py-unit-sm ${
              index === 0
                ? "bg-unit-accent text-unit-accent-foreground"
                : "bg-unit-background"
            }`}
          >
            <p className="text-sm font-bold tracking-tight">{name}</p>
            <p
              className={`text-xs ${
                index === 0 ? "text-unit-accent-foreground/60" : "text-unit-text-secondary"
              }`}
            >
              {days}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}

function FeatureVisual({ visual }: { visual: FeatureVisual }) {
  if (visual === "local") return <LocalVisual />
  if (visual === "timer") return <TimerVisual />
  if (visual === "pr") return <PRVisual />
  if (visual === "calendar") return <CalendarVisual />
  if (visual === "quick") return <QuickVisual />
  return <ProgramsVisual />
}

export default function SecondaryFeatures() {
  return (
    <div>
      <div className="mx-auto mb-unit-xxl max-w-3xl text-center">
        <p className="eyebrow mb-unit-sm">Built in</p>
        <h2 className="h-section text-balance">Everything your log needs.</h2>
        <p className="mx-auto mt-unit-md max-w-xl text-lg leading-snug text-unit-text-secondary">
          Useful between sets. Quiet everywhere else.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-unit-md sm:grid-cols-2 lg:grid-cols-3">
        {features.map((feature) => (
          <article
            key={feature.title}
            className="lift-hover flex min-h-[320px] flex-col rounded-[32px] bg-unit-card p-unit-lg md:min-h-[340px]"
          >
            <div>
              <h3 className="text-xl font-bold leading-tight tracking-tight">
                {feature.title}
              </h3>
              <p className="mt-unit-xs max-w-[30ch] text-sm leading-relaxed text-unit-text-secondary">
                {feature.body}
              </p>
            </div>
            <div className="mt-unit-xl min-h-[150px] flex-1">
              <FeatureVisual visual={feature.visual} />
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}
