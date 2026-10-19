# Design system — start here

All runtime tokens and shared UI live in [`Unit/UI/DesignSystem.swift`](../Unit/UI/DesignSystem.swift). Feature views compose these owners; they do not define parallel chrome.

| Need | Owner |
| --- | --- |
| Brand and hierarchy | [`DESIGN.md`](../DESIGN.md), [`visual-language.md`](visual-language.md) |
| Component inventory and composition | [`atomic-design-system.md`](atomic-design-system.md) |
| Colors, type, spacing, radius | `AppColor`, `AppFont`, `AppSpacing`, `AppRadius` |
| Icon scale and chart viewports | `AppIconSize`, `AppChartMetrics` |
| Primary, supporting, quiet actions | `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton` |
| Toggle and menu filter chips | `AppFilterChip`, `AppDropdownChip`; private `AppFilterChipSurface` owns shared chrome |
| Cards and divided rows | `AppCard`, `AppCardList`, `AppListRow` |
| Native modal layout | `AppSheetScreen`; leading X calls the existing dismissal handler |
| Working-target editor | `AppSetRepEditorSheet`; save returns `Bool`, dismisses only after success |
| Pressed state | `ScaleButtonStyle` |
| Motion and accessibility policy | `AppMotion`, `AppScreenEnter`, `AppBlurVisibility` |
| Result feedback | `AppToastEvent`, `AppToast`, private `AppToastPill`, `AppHaptic` |
| Celebration rendering | `AppCelebrationMoment`, `AppCelebration` |

## Inspect the system

Debug build → Settings → Design system → Components (`AppComponentCatalog`). Release builds contain neither the route nor the catalog.

Samples use production components. Press and hold for pressed feedback; disabled/loading samples remain fixed. Large text and fade-only switches change only the preview. The target editor can simulate save failure to inspect its retained input and native alert. Actions change local sample state and never write workout or template data or invoke purchases.

The catalog stays light under a dark system appearance. System Reduce Motion or VoiceOver always wins over the preview switches: fades only, without travel, blur, scale, bounce or confetti. Haptics remain enabled by the shared policy.

## Review after integration

Main owns compilation and device checks. Check large text, actual VoiceOver/Reduce Motion, dark-system appearance, filter menus, cancel/discard handlers, swipe dismissal, and failed-save retry. The catalog is a review surface, not proof of runtime correctness.
