# Unit saved-set confirmation — 2.1 (78)

- Existing WorkoutCommandCard dwell increased from1s to2.5s. Each successful saved set receives a fresh full dwell; the existing cancellation guard prevents old timeouts from dismissing a newer event.
- Existing AppPrimaryButton keeps the settle entrance and uses the280ms transition for its return, replacing the150ms exit. Reduce Motion/VoiceOver get the same smoother fade without scale.
- Logging and the next eligible CTA remain immediate. No sizes, typography, layout, components or tokens changed; no extra haptic.
- No tests or Simulator runs, per user instruction. Static guards/diff checks passed. Physical visual timing remains for review.
- Signed build succeeded; installed in place and launched normally. Before/after store hashes and checked preferences identical, integrity ok, 214 sets retained. Evidence, under `/private/tmp/unit-confirm-78/`; build log `/private/tmp/unit-confirm-78-build.log`. Development-only, no store submission. Local tag `unit-dev-2.1-78-20261019`.
