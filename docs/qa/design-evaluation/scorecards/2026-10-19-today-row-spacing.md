# Today preview spacing

Date: 19 October 2026. Contextual, provisional review.
Evidence/anchor: user screenshot `/Users/efbakir/Downloads/Screenshot 2026-10-19 at 17.41.36.png`; current shared preview/card-list owners.

## Baseline

| Dimension | Weight | Score | Defect / owner | Blind spot |
|---|---|---|---|---|
| System fidelity | 25% | 7 | Container padding shortens canonical separator / PreviewListContainer | Other nested surfaces |
| Coherence | 20% | 7 | Good hierarchy, uneven repeated row rhythm | Scrolled states |
| Craft | 20% | 4 | Top-aligned 80pt rows leave asymmetric whitespace | Long names |
| Gym Test / UX | 25% | 6 | Targets readable, row boundaries weak | Timing not measured |
| Accessibility / evidence | 10% | 5 | Screenshot only | No manual VoiceOver or touch measurement |

Weighted baseline: 6.0/10. No revised official score.

## Work applied

- Existing PreviewListRow: centered identity-first content with symmetric vertical padding; 16pt horizontal inset for both recessed layouts. Stacked AppCardList rows retain their existing owner/insets.
- Existing PreviewListContainer: removed container padding; adjusted viewport calculation to the row-owned layout. Divider overlay now reaches each edge of the recessed surface.
- Existing AppDividedList: removed inset separator API; the sole training-week caller migrated to full-width separators.
- No new components, tokens or variants. Existing SF Pro, colors, radii, press feedback and motion retained.

## Hard gates

Source banned patterns/guard: checked before commit. Touch target: existing minimums retained; runtime measurement UNVERIFIED. Contrast/motion unchanged; no new manual measurement. Gym Test, final visual state differences and full sibling runtime: UNVERIFIED because the user stopped further tests. Light-only/portrait source policy retained. Compile/install/launch evidence is recorded in the delivery handoff, separate from visual proof.
