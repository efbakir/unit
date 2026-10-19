# Unit instant-change audit — 2.1 (82)

Detailed provisional source audit: `docs/qa/design-evaluation/scorecards/2026-10-19-logging-instant-changes.md` (13 areas, exact build81 references, changes, consumer scope and proof limits).

## Changed
- AppPrimaryButton keeps label and circular confirmation icon mounted with directly bound280ms fades. Reuses existing checkmark.circle.fill in monochrome, leaving the tick as negative space. Same icon/button/font sizes; no new drawing/token/component. Loading and disabled states share the same smoother content treatment; press behavior unchanged.
- Last-set completion event now reports whether the parent advanced. The outgoing card keeps its saved mark during that handoff, avoiding an old-label flash. Ordinary sets crossfade to their label. Existing2.5s dwell, immediate logging and rest continuity retained.
- SetProgressIndicator uses one scroll hierarchy instead of switching layouts when chips overflow. Native centering for short rows; collectionChange scrolling keeps the current/final chip visible. Edited chip values also animate layout changes. Existing44pt height and chip styles retained.
- Mixed target/history/performance copy crossfades at280ms rather than using fast numeric text. Empty-target control swaps blur/fade within their existing reserved slot. Timer play/pause uses native symbol replacement and280ms chrome fades; weight suffixes fade. Adjust and supporting captions have locally bound fades and retain their hierarchy through completion. Native keyboard/sheet/alert behavior untouched. No new haptic or storage schema.

## Evidence and delivery
Static source guards/whitespace checks passed. Final signed compilation succeeded. Build82 installed in place and launched normally. Before/after table hashes and checked preferences match; prepared-target data matches. Integrity ok, 220 recorded sets retained. Final evidence uses final-before/final-after and final-install/final-launch files. No new tests or Simulator runs, per user instruction; no current visual/interaction verification claimed. Evidence `/private/tmp/unit-instant-audit-82/`; log `/private/tmp/unit-instant-audit-82-build.log`. Local tag `unit-dev-2.1-82-20261019`. Development-only; no store submission.
