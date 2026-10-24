//
//  RestTimerLiveActivity.swift
//  Unit
//
//  Live Activity view for rest timer (Lock Screen / Dynamic Island).
//  ActivityKit is iOS-only; this file is compiled only for iOS.
//

#if os(iOS)
import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Lock Screen

struct RestTimerLiveActivityView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text("Rest timer")
                    } icon: {
                        Image(systemName: "timer")
                    }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    if context.isStale {
                        Text("Rest finished")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.textPrimary)
                    } else {
                        Text(timerInterval: timerRange,
                             countsDown: true,
                             showsHours: false)
                            .font(.title.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .contentTransition(.numericText(countsDown: true))
                        ProgressView(timerInterval: timerRange, countsDown: true)
                            .labelsHidden()
                            .tint(.accent)
                            .accessibilityLabel("Rest remaining")
                    }
                }
                .accessibilityElement(children: .combine)

                Spacer(minLength: 16)

                if let upNext = context.state.upNext, !upNext.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Up next")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Text(upNext)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.trailing)

                        if let detail = context.state.upNextDetail, !detail.isEmpty {
                            Text(detail)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(["Up next", upNext, context.state.upNextDetail]
                        .compactMap { $0 }.joined(separator: ", "))
                }
            }
            if !context.isStale {
                RestTimerLiveActivityControls()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var timerRange: ClosedRange<Date> {
        let start = context.state.startDate
        let end = context.state.endDate
        return start <= end ? start...end : end...end.addingTimeInterval(1)
    }
}

// MARK: - Rest buttons

/// −30 / +30 / Skip, the same steps as the in-app rest bar. Each button runs a
/// `LiveActivityIntent` in the app process.
struct RestTimerLiveActivityControls: View {
    private let step = RestTimerAttributes.stepSeconds

    var body: some View {
        HStack(spacing: 8) {
            control("−\(step)", label: "Subtract \(step) seconds", intent: SubtractRestIntent())
            control("+\(step)", label: "Add \(step) seconds", intent: AddRestIntent())
            control("Skip", label: "Skip rest", intent: SkipRestIntent())
        }
    }

    private func control(_ title: String, label: String, intent: some AppIntent) -> some View {
        // Same grey buttons and ink text as the in-app rest bar.
        Button(intent: intent) {
            Text(title)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(.controlBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
                Label {
                    Text("Rest")
                } icon: {
                    Image(systemName: "timer")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            }

            DynamicIslandExpandedRegion(.trailing) {
                if context.isStale {
                    Text("Rest finished")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                } else {
                    Text(timerInterval: timerRange,
                         countsDown: true,
                         showsHours: false)
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.trailing)
                        .contentTransition(.numericText(countsDown: true))
                }
            }

            DynamicIslandExpandedRegion(.bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    if !context.isStale {
                        ProgressView(timerInterval: timerRange, countsDown: true)
                            .labelsHidden()
                            .accessibilityLabel("Rest remaining")
                    }
                    bottomRow(state: state)
                    if !context.isStale {
                        RestTimerLiveActivityControls()
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 4)
            }
        } compactLeading: {
            Image(systemName: "timer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityLabel(context.isStale ? "Rest finished" : "Rest timer")
        } compactTrailing: {
            if context.isStale {
                Text("Rest finished")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text(timerInterval: timerRange,
                     countsDown: true,
                     showsHours: false)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 44)
                    .contentTransition(.numericText(countsDown: true))
            }
        } minimal: {
            Image(systemName: "timer")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityLabel(context.isStale ? "Rest finished" : "Unit rest timer")
        }
        .keylineTint(.primary)
    }

    @ViewBuilder
    private static func bottomRow(state: RestTimerAttributes.ContentState) -> some View {
        if let upNext = state.upNext, !upNext.isEmpty {
            HStack(spacing: 6) {
                Text("Up next")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(upNext)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                if let detail = state.upNextDetail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(["Up next", upNext, state.upNextDetail]
                .compactMap { $0 }.joined(separator: ", "))
        }
    }
}
#endif
