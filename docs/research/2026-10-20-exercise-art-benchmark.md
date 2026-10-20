# Exercise artwork and color benchmark — 20 October 2026

**Later October 20 artwork update:** The user replaced the six rounded-line figures below with their own abstract body-fold marks from [Figma Branding](https://www.figma.com/design/blqxXK1lBcyJxwzek2L3eH/Branding?node-id=1327-76). All six original vector outlines are retained. Only opaque white export backgrounds and canvas centring were adjusted, with no scaling or redrawing. Hinge maps to the existing deadlift asset; the other five retain their existing roles. The shared neutral tint, 20/28pt glyph sizes, blue actions and native fallback remain. See [current artwork preview](../qa/movement-icons-v3/artwork-review.png) and [source node IDs and adjustments](../qa/movement-icons-v3/source.json). The benchmark and earlier compilation below are historical evidence, not verification of these replacement assets. The replacement assets passed XML/path-preservation, transparent 20/28pt render and source-guard checks; no build, Simulator or device verification ran for this update.

**Current user correction:** Exercise icons appear only for the Big 6 in Analytics and exercise detail. The app-wide rollout has been removed: Today, workout logging, pickers, routines, onboarding and history summaries remain text-only. Complete canonical names/aliases are matched; other movements and equipment variants have no icon. All six marks use the same primary-text tint, including empty Big 3 cards. The shared navigation disclosure uses the existing 12pt indicator size, medium weight and subdued foreground while preserving its 44pt interaction area. This supersedes the broader movement-family/fallback recommendation below. The correction passed 78 Big 6/no-icon mapping checks, the source guard and a signed iPhone build (`/private/tmp/unit-big-six-only-build.log`), then was installed and launched on the user’s iPhone. Training record IDs and store integrity were preserved. In-app visual review remains pending.

## Decision

Implement six original, simple movement vectors after comparing libraries and inspecting real competitor screens through the Mobbin MCP. The user explicitly authorized a custom set if no suitable library was found. This replaces both the rejected supplied silhouettes and the temporary native-symbol-only mapping.

Keep native SF Symbols for controls and generic unmatched-exercise fallbacks. Keep blue for existing action/selection roles, with neutral exercise artwork and charts. No exercise-family colors, schema changes, new analytics metrics or logging redesign.

## Direct visual evidence

Mobbin previews were inspected, not inferred from search labels. These are reference screenshots, not Unit runtime evidence or proof of every current competitor state.

| Reference | Observed | Apply to Unit |
| --- | --- | --- |
| [Hevy exercise picker](https://mobbin.com/screens/bf8fb5d8-dc37-448c-baa8-a57ac13f00d2) | Small movement-specific illustrations beside names and muscle labels; blue filters and Add action | Distinguish movement artwork from action color; keep exercise names visible |
| [Hevy custom exercise example](https://mobbin.com/screens/5c6fc454-8ab5-4278-9221-4e5b14bbdcce) | Existing movement art and a custom photo coexist, with a named Custom badge | Do not invent a specific exercise image for an unknown exercise |
| [Fitbod exercise list](https://mobbin.com/screens/8034a0af-b551-4b79-b6d8-76999292beb2) | Photo thumbnails beside names and set details; colored action separate from neutral data | Borrow the name-first hierarchy, not photographs, branding, or layout sizes |
| [Bevel fitness cards](https://mobbin.com/screens/70391296-e949-458c-aa02-d4d0dd63df76) | White grouped cards, small contextual symbols and prominent values | Group related explanation content in existing cards; preserve data hierarchy |

This small sample does not establish a universal 2026 aesthetic. It supports the specific decisions above.

## Library comparison

Coverage means the actual movement, not a similarly named equipment icon. Original vendor/gallery previews were inspected. Prices and licenses reflect the pages accessed on this date; no purchase was made.

| Pack | Six movements | License / delivery | Decision |
| --- | --- | --- | --- |
| [PencilRick Fitness & Weight Training](https://graphicriver.net/item/fitness-weight-training-icon-set/32621959) | Squat, bench, deadlift, shoulder press, dumbbell row, pull-up explicitly listed | SVG/PDF. Browser offered $12 Regular and $35 Extended; Extended covers a charged end product | Complete, but anatomical faces, clothing and shoes become clutter at 20pt. Not used |
| [Workout Guide](https://bryllim.github.io/workout-guide/exercises/) | All six exact movements available | [Artwork CC BY-SA 4.0](https://github.com/bryllim/workout-guide/blob/main/LICENSE-ASSETS); code license is separate. Attribution, change disclosure and ShareAlike apply to adapted artwork | Instructional 512px illustrations, not tiny UI glyphs. Not used |
| [SVG Repo Exercise Pictograms](https://www.svgrepo.com/collection/exercise-pictograms/) | Squat, bench, overhead and pull-up confirmed; deadlift ambiguous, no exact bent-over row verified | Inspected asset pages label the SVGs CC0 | Cohesive silhouettes but incomplete for this purpose. Do not substitute cardio rowing for a barbell row |
| [Hugeicons fitness catalog](https://hugeicons.gitlab.io/i/hugeicons_list.pdf) | Squats and equipment bench press found; six movement coverage not verified | Broad UI/equipment library; exact six licensing/delivery not established | Not selected; availability of a generic dumbbell does not establish coverage |

Concrete SVG Repo examples inspected: [squat 87901](https://www.svgrepo.com/svg/87901/weightlifting), [bench 828](https://www.svgrepo.com/svg/828/weightlifting), [overhead 171586](https://www.svgrepo.com/svg/171586/weightlifting), [pull-up 84392](https://www.svgrepo.com/svg/84392/exercise). The seated 157290 figure is a curl, and 14886 is cardio rowing; neither was silently used for row.

## Articles and principles

- [NN/G: Icon Usability: When and How to Evaluate Digital Icons](https://www.nngroup.com/articles/how-to-test-digital-icons/) (4 October 2024): recognizing a shape and understanding its meaning are different problems. Keep explicit names and avoid arbitrary stars as movement identifiers.
- [NN/G: Icon Usability](https://www.nngroup.com/articles/icon-usability/) (27 July 2014): simple schematic shapes and visible text reduce ambiguity. This is longstanding guidance, not evidence of a new trend.
- [NN/G: Similarity Principle](https://www.nngroup.com/articles/gestalt-similarity/) (6 September 2020): consistent color signals related function. Keep blue tied to existing action/selection roles; no decorative rainbow of exercise colors.

The original vector set uses a 24×24 grid, 2pt rounded strokes, a filled head and minimal equipment. Each pose has a deliberate cue: crouched knees/bar at shoulders, bench with raised bar, low deadlift bar, overhead bar with straight legs, row with bent elbows/bar near torso, pull-up rail with bent legs. These are original Unit vectors, not traced vendor or competitor assets. No third-party art dependency or license added.

## Implementation owners

- `AppIcon` / its existing internal `Glyph`: six existing asset-name roles and one template-rendering branch. Native symbols remain the control/fallback path. Missing movement art asserts in DEBUG and falls back to the traditional strength symbol in release.
- `ExerciseIconResolver`: existing POSIX normalization and ordered whole-token rules. No main-lift alias/calculation change. Main slots remain Squat, Bench Press and Deadlift; six movement families do not create six main slots.
- `AppMainLiftCard.iconTile` / `AppIconCircle`: existing tile sizes, semantic tint and capped scaling retained. Icons remain decorative.
- `AppColor.accent`, `accentForeground`, `accentSoft`: previously approved #0068E0 / #F6F6F6 / #EAF2FF. No new runtime color roles. Measured declared pairs: Chalk on blue 4.79:1, blue text on Milk 4.75:1, blue text on the soft selection fill 4.60:1. These are token calculations, not rendered-screen contrast measurements.
- `AnalyticsView.explanationSheet`: two `AppCardList` groups with existing `AppListRow` stacked title/subtitle. Native sheet/Done and every string retained.
- `TemplatesView.activeProgramCard`: read-only active title/tag and existing `AppSecondaryButton` Edit action to the existing editor. Routine navigation, scrolling beyond seven routines and inactive-program switching retained.

## Verification and remaining work

- Browser-inspected the actual vector files at 20pt and 28pt, plus an enlarged detail column. [Artwork sheet](../qa/movement-icons-v2/artwork-review.png), [reproducible HTML](../qa/movement-icons-v2/artwork-review.html). This is an artwork review, not a SwiftUI screenshot or user recognizability test.
- One signed generic-iOS compilation succeeded with the integrated assets and UI changes. Log: `/private/tmp/unit-artwork-v2-build.log`. Only the toolchain's AppIntents metadata-extraction warning was found in this build.
- Source guard, changed-file banned-pattern checks, SVG XML checks and diff whitespace checks passed.
- No Simulator run, unit/UI test execution, full QA, phone installation, version change or public submission in this pass. Existing asset/resolver tests were updated for the replacement artwork but not executed.
- Remaining: in-app visual review of card/row/detail icons, wrapped explanation rows, long program names and direct Edit/back behavior. Logging redesign awaits the user's benchmark/wireframe choice. Full QA and release preparation remain separate work.
