//
//  AddTemplateView.swift
//  Unit
//
//  Create a new day template inside a split.
//

import SwiftUI
import SwiftData

struct AddTemplateView: View {
    let split: Split

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSaving = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        AppSheetScreen(
            title: "New day",
            primaryButton: PrimaryButtonConfig(
                label: "Create Day",
                isEnabled: canSave,
                isLoading: isSaving,
                disabledReason: AppCopy.FormHint.dayNameRequired,
                action: save
            ),
            dismissLabel: AppCopy.Nav.close,
            onDismissAction: { dismiss() },
            usesOuterScroll: false
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                AppSectionHeader("Day name")

                TextField("e.g. Push", text: $name)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .textInputAutocapitalization(.words)
                    .appInputFieldStyle(height: 52)
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let template = DayTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            splitId: split.id
        )
        modelContext.insert(template)

        var ids = split.orderedTemplateIds
        ids.append(template.id)
        split.orderedTemplateIds = ids

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = PreviewSampleData.makePreviewContainer()
    let split = (try? container.mainContext.fetch(FetchDescriptor<Split>()))?.first

    return Group {
        if let split {
            AddTemplateView(split: split)
                .modelContainer(container)
        }
    }
}
