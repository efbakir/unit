//
//  RestTimerLiveActivity.swift
//  Unit
//
//  Live Activity view for rest timer (Lock Screen / Dynamic Island).
//  ActivityKit is iOS-only; this file is compiled only for iOS.
//

#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Lock Screen

struct RestTimerLiveActivityView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            UnitBrandMark(size: 26)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)

                Text(timerInterval: timerRange,
                     pauseTime: context.state.endDate,
                     countsDown: true,
                     showsHours: false)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText(countsDown: true))
            }

            Spacer(minLength: 8)

            if let upNext = context.state.upNext, !upNext.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Up next")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    Text(upNext)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Up next, \(upNext)")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var timerRange: ClosedRange<Date> {
        let start = context.state.startDate
        let end = context.state.endDate
        return start <= end ? start...end : end...end.addingTimeInterval(1)
    }
}

// MARK: - Dynamic Island

enum RestTimerLiveActivityIsland {
    static func dynamicIsland(context: ActivityViewContext<RestTimerAttributes>) -> DynamicIsland {
        let state = context.state
        let timerRange = state.startDate <= state.endDate
            ? state.startDate...state.endDate
            : state.endDate...state.endDate.addingTimeInterval(1)

        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                HStack(spacing: 8) {
                    UnitBrandMark(size: 22)
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)

                    Text("Rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
                .padding(.leading, 4)
            }

            DynamicIslandExpandedRegion(.trailing) {
                Text(timerInterval: timerRange,
                     pauseTime: state.endDate,
                     countsDown: true,
                     showsHours: false)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.trailing)
                    .contentTransition(.numericText(countsDown: true))
                    .padding(.trailing, 4)
            }

            DynamicIslandExpandedRegion(.bottom) {
                bottomRow(state: state)
                    .padding(.top, 6)
            }
        } compactLeading: {
            UnitBrandMark(size: 18)
                .foregroundStyle(.primary)
                .padding(.leading, 2)
                .accessibilityLabel("Unit")
        } compactTrailing: {
            Text(timerInterval: timerRange,
                 pauseTime: state.endDate,
                 countsDown: true,
                 showsHours: false)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 44)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityLabel("Rest timer")
        } minimal: {
            UnitBrandMark(size: 14)
                .foregroundStyle(.primary)
                .accessibilityLabel("Unit rest timer")
        }
        .keylineTint(.black)
    }

    @ViewBuilder
    private static func bottomRow(state: RestTimerAttributes.ContentState) -> some View {
        if let upNext = state.upNext, !upNext.isEmpty {
            HStack(spacing: 6) {
                Text("Up next")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)

                Text("·")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(upNext)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Up next, \(upNext)")
        }
    }
}

// MARK: - Brand Mark

/// The Unit brand mark — two tapered pillars (left shorter than right) drawn inline so
/// the widget extension doesn't need a separate asset catalog. Tints via the parent
/// `foregroundStyle(...)` so it adapts to Live Activity material automatically.
private struct UnitBrandMark: View {
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            UnitPillar(slant: .left)
                .frame(width: size * 0.42, height: size * 0.74)

            UnitPillar(slant: .right)
                .frame(width: size * 0.42, height: size)
                .offset(x: size * 0.58)
        }
        .frame(width: size, height: size)
    }
}

private struct UnitPillar: Shape {
    enum Slant { case left, right }
    let slant: Slant

    // `nonisolated` because this target builds with
    // SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, which would otherwise make
    // UnitPillar @MainActor and break `Shape`'s nonisolated `path(in:)`
    // requirement. The path is pure geometry — no main-actor state — so opting
    // this witness out of the actor is always safe.
    nonisolated func path(in rect: CGRect) -> Path {
        let topInset = rect.width * 0.22
        var path = Path()
        switch slant {
        case .left:
            path.move(to: CGPoint(x: topInset, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        case .right:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        path.closeSubpath()
        return path
    }
}
#endif
