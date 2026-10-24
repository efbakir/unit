//
//  ReadOnlyHistorySheet.swift
//  Unit
//
//  History for a lapsed subscriber, opened from the paywall (founder
//  decision 2026-10-24): the list, workout detail and exercise pages, plus
//  Export. Nothing starts, saves or changes here. Today, Programs, Analytics
//  and Settings stay behind the paywall.
//

import SwiftData
import SwiftUI

struct ReadOnlyHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("unitSystem") private var unitSystem = "kg"

    var body: some View {
        NavigationStack {
            RecentSessionsView(showsCloseButton: false, isReadOnly: true)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Group {
                            Button { dismiss() } label: {
                                Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName)
                                    .labelStyle(.iconOnly)
                            }
                            .accessibilityLabel(AppCopy.Nav.close)
                        }
                        .tint(AppColor.textPrimary)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: WorkoutCSVFile(container: modelContext.container, unitSystem: unitSystem),
                            preview: SharePreview(AppCopy.DataTransfer.exportPreviewTitle)
                        ) {
                            Text(AppCopy.DataTransfer.exportAction)
                                .appToolbarTextStyle()
                        }
                        .accessibilityIdentifier("read-only-history-export")
                    }
                }
        }
        .tint(AppColor.accent)
    }
}
