//
//  FreestyleSessionSupport.swift
//  Unit
//
//  Freestyle sessions (no program / no day template) are intentionally off the
//  Today surface for v1; this file holds the small set of helpers that create
//  + clean up the sentinel template behind them.
//
//  The template name is a sentinel — `FreestyleSessionSupport.templateName` is
//  the single source of truth. Don't write or compare against a literal
//  string; go through the constant so any future rename happens in one place.
//

import Foundation
import SwiftData

enum FreestyleSessionSupport {
    /// Sentinel `DayTemplate.name` that marks a freestyle (no-program) session.
    /// Read/written only via this constant — keeps the literal off feature code.
    static let templateName = "Freestyle"

    /// Removes empty unreferenced freestyle day templates left after aborted
    /// sessions (user opens a freestyle session, logs no sets, force-quits).
    static func cleanupOrphanedTemplates(
        modelContext: ModelContext,
        templates: [DayTemplate],
        sessions: [WorkoutSession]
    ) {
        let referencedTemplateIds = Set(sessions.map(\.templateId))
        for template in templates where template.name == templateName
            && !referencedTemplateIds.contains(template.id) {
            modelContext.delete(template)
        }
        try? modelContext.save()
    }

    /// Creates a fresh empty template and an in-progress session — the
    /// no-program counterpart to a planned-day session start.
    static func startEmptyWorkout(modelContext: ModelContext, activeSplit: Split?) {
        let template = DayTemplate(
            name: templateName,
            splitId: nil,
            orderedExerciseIds: []
        )
        modelContext.insert(template)

        let session = WorkoutSession(
            date: Date(),
            templateId: template.id,
            isCompleted: false
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}
