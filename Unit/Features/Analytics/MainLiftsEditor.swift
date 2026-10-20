import SwiftUI

/// User-requested native editor; reuses existing icon tiles, fonts and buttons.
struct MainLiftsEditor: View {
    let output: AnalyticsEngine.Output
    let automaticIDs: [UUID]
    @Binding private var pinnedRaw: String
    @State private var draft: [UUID]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(output: AnalyticsEngine.Output, automaticIDs: [UUID], pinnedRaw: Binding<String>) {
        self.output = output
        self.automaticIDs = automaticIDs
        _pinnedRaw = pinnedRaw
        _draft = State(initialValue: output.mainIDs)
    }

    private var cutoff: Date { Calendar.current.date(byAdding: .day, value: -55, to: output.today) ?? output.today }
    private var available: [AnalyticsEngine.Lift] {
        AnalyticsEngine.rankedLifts(Array(output.lifts.values), since: cutoff).filter { !draft.contains($0.id) }
    }

    var body: some View {
        VStack {
            NavigationStack {
                VStack(spacing: AppSpacing.md) {
                    List {
                        Section {
                            ForEach(draft, id: \.self) { id in
                                if let lift = output.lifts[id] {
                                    HStack(spacing: AppSpacing.sm) {
                                        if let icon = AnalyticsView.icon(for: lift.exercise) {
                                            AppMainLiftCard.iconTile(icon, side: AppSpacing.xl)
                                        }
                                        Text(lift.exercise.name).font(AppFont.body.font)
                                            .foregroundStyle(AppColor.textPrimary).lineLimit(2)
                                    }
                                    .frame(minHeight: AppSpacing.xxl)
                                    .accessibilityIdentifier("analytics-shown-\(lift.exercise.name)")
                                }
                            }
                            .onMove { draft.move(fromOffsets: $0, toOffset: $1) }
                            .onDelete { draft.remove(atOffsets: $0) }
                        } header: {
                            Text("Shown").font(AppFont.caption.font)
                        } footer: {
                            Text("Up to 3.").font(AppFont.muted.font).foregroundStyle(AppColor.textSecondary)
                        }
                        Section {
                            ForEach(available) { lift in
                                Button { if draft.count < 3 { draft.append(lift.id) } } label: {
                                    HStack(spacing: AppSpacing.sm) {
                                        AppIcon.addCircle.image(size: AppIconSize.exercise)
                                            .foregroundStyle(draft.count < 3 ? AppColor.accent : AppColor.textDisabled)
                                        if let icon = AnalyticsView.icon(for: lift.exercise) {
                                            AppMainLiftCard.iconTile(icon, side: AppSpacing.xl)
                                        }
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text(lift.exercise.name).font(AppFont.body.font)
                                                .foregroundStyle(AppColor.textPrimary).lineLimit(2)
                                            let count = AnalyticsEngine.recentSessionCount(lift, since: cutoff)
                                            Text("\(count.formatted()) \(count == 1 ? "session" : "sessions") in 8 weeks")
                                                .font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                                        }
                                    }.frame(minHeight: AppSpacing.xxl)
                                }
                                .buttonStyle(.plain)
                                .disabled(draft.count >= 3)
                                .accessibilityLabel("Add \(lift.exercise.name)")
                                .accessibilityValue(draft.count >= 3 ? "Limit reached" : "")
                                .accessibilityIdentifier("analytics-add-\(lift.exercise.name)")
                            }
                            .moveDisabled(true).deleteDisabled(true)
                        } header: {
                            Text("Exercises").font(AppFont.caption.font)
                        }
                    }
                    .environment(\.editMode, .constant(.active))
                    .scrollContentBackground(.hidden)
                    .background(AppColor.background)
                    if draft != automaticIDs {
                        AppSecondaryButton("Use automatic") { draft = automaticIDs }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.bottom, AppSpacing.md)
                            .transition(.opacity.animation(AppMotion.reveal))
                    }
                }
                .appAnimation(AppMotion.collectionChange, value: draft != automaticIDs, reduceMotion: reduceMotion)
                .background(AppColor.background)
                .navigationTitle("Main lifts").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            pinnedRaw = AnalyticsEngine.storedMainIDs(draft, automatic: automaticIDs)
                            dismiss()
                        }
                    }
                }
                .appNavigationBarChrome()
                .tint(AppColor.accent)
            }
        }
        .presentationDetents([.large])
        .appBottomSheetChrome()
    }
}
