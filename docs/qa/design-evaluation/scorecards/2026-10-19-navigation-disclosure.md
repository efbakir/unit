# Today and Programs navigation disclosure

Date: 2026-10-19. Contextual, provisional; baseline from the two user-supplied 17:31/17:32 screenshots. Anchor: existing Unit recessed preview/list pattern; no external reference required for this bounded affordance correction.

## Baseline
| Dimension | Weight | Score | Evidence and fix | Layer | Blind spot |
|---|---:|---:|---|---|---|
| System fidelity | 25% | 7 | Shared preview rows already used; extend that owner | Molecule | Other row types |
| Coherence | 20% | 7 | Clear primary workout CTA; navigation lacks cues | Molecule | Empty state |
| Craft | 20% | 6 | Grouped rows have no visible boundaries | Molecule | Dynamic Type |
| Gym Test / UX | 25% | 5 | Individual tap destinations unclear | Molecule | Runtime gestures |
| Accessibility / verification | 10% | 5 | Text is readable in supplied captures; runtime unverified | Molecule | VoiceOver |

Weighted baseline: 6.1/10. This is not a post-change score.

## Hard gates
| Gate | Status | Evidence |
|---|---|---|
| Banned-list | UNVERIFIED | Raw glyph ban preserved; shared AppIcon used |
| 44pt targets | PASS | Preview row minimums 44/52/80; header floor 44 |
| Contrast | UNVERIFIED | Existing tokens retained, no measurement |
| Non-colour cues / reduced motion | PASS | Chevron and separator; no added motion |
| Gym Test | UNVERIFIED | No runtime test in this change |
| No misleading affordance | PASS | All seven PreviewListRow call sites checked as navigation destinations |
| Distinct state captures | UNVERIFIED | No new captures |
| Light / portrait | PASS | Appearance and orientation unchanged |

## Component reuse and completed work
AppListRow supports tappable/display/cardListContent styles; AppCardList owns divided card lists; PreviewListRow owns stacked/compactInline/identityFirst previews. Extend PreviewListRow with explicit showsDisclosure and showsSeparator; no new primitive or tokens. All existing navigating preview consumers opt in. Recessed Today/Programs previews separate adjacent rows with AppDivider. Program header uses the existing AppIcon.forward. Read-only defaults remain plain. Update obsolete no-chevron doctrine per direct user request; raw-glyph enforcement remains intact.

## Carry forward
Main owns build/install. No Simulator, build, or tests run here per current stop-testing instruction. Review Today row boundaries, Programs day counts/chevrons, long titles, and VoiceOver on the next visual pass. Today exercise taps still open the routine detail (existing destination), not an individual exercise detail.


## App-wide follow-up
Direct user request: apply the same treatment to every card/row opening a destination. Source base: integrated build 69 checkpoint `a2e114b`. Existing baseline above is unchanged; no new rendered score.

Reuse decision: extract the existing PreviewListRow disclosure layout into `View.appNavigationDisclosure` in DesignSystem.swift, and extend AppListRow with showsDisclosure. No separate View/ViewModifier type, token, or competing chevron style. This preserves Settings row insets and provides the same treatment for custom summary labels.

| Surface | Disposition |
|---|---|
| Today / Programs / program library / program details | Existing previews retain disclosure; program header now uses the same layout owner |
| Analytics | Exercise history, History, Settings rows opt in; static metrics remain plain |
| History list | Real session links opt in; unavailable-session fallback remains plain |
| Calendar summary | Completed exercise links opt in; read-only unfinished/missed summaries remain plain |
| Session detail | Exercise progress links opt in |
| Settings | Components, Manage subscription, feature request, legal links opt in; status, restore, unit picker, analytics toggle remain plain |
| Routine / onboarding preview editors | Name/target navigation labels opt in; remove and inline weight controls remain separate |
| Week overview | Sheet-opening strip opts in |
| Exercise library | Native List NavigationLink already supplies the system chevron; no duplicate added |
| Onboarding / purchase options | Selection tiles stay plain; advancement remains through Continue |
| Active workout / routine picker / calendar cells | Inline selection and logging actions retain existing semantics; not destination rows |
| Toolbar / CTA / footer text links | Existing control styles retained; not cards or rows |

Visual pass and phone installation remain pending for this follow-up. No build or Simulator launched.

Source verification: changed-code banned-pattern hook, Swift syntax parsing, and git diff whitespace checks passed. Full-file History hook reports a pre-existing broad AppCard/AppDividedList match; this change does not add that composition. Syntax parsing is not compilation or runtime verification.
