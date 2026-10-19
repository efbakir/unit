import Foundation
import Observation
import SwiftData

/// One revision cache per presentation. Models stay on their owning actor;
/// only immutable snapshots cross into the background calculation.
@Observable @MainActor
final class AnalyticsStore {
    private(set) var output: AnalyticsEngine.Output?
    private(set) var sessions: [WorkoutSession] = []
    private(set) var templates: [DayTemplate] = []
    private(set) var exercises: [Exercise] = []
    private var lastInput: AnalyticsEngine.Input?
    private var lastDay: Date?
    private var lastCalendar: Calendar?
    private var generation = 0

    func refresh(context: ModelContext, now: Date, calendar: Calendar, plannedDays: Int? = nil) async throws {
        generation += 1
        let request = generation
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.isCompleted }, sortBy: [SortDescriptor(\.date)])
        descriptor.relationshipKeyPathsForPrefetching = [\.setEntries]
        let sessions = try context.fetch(descriptor)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let templates = try context.fetch(FetchDescriptor<DayTemplate>())
        let splits = try context.fetch(FetchDescriptor<Split>(sortBy: [SortDescriptor(\.name)]))
        let split = ActiveSplitStore.resolve(from: splits)
        let routineIDs = Set(split?.orderedTemplateIds ?? [])
        let splitTemplates = templates.filter { split != nil && $0.splitId == split?.id }
        let ordered = splitTemplates.filter { routineIDs.contains($0.id) }
        // Match Today/TrainingWeekProgress: fall back to the split's routines
        // if a legacy ordered-ID list is empty or no longer resolves.
        let routineCount = ordered.isEmpty ? splitTemplates.count : ordered.count
        let input = AnalyticsSnapshot.make(sessions: sessions, exercises: exercises, templates: templates, plannedDaysPerWeek: plannedDays ?? (split == nil ? 0 : routineCount))
        let day = calendar.startOfDay(for: now)
        self.sessions = sessions; self.exercises = exercises; self.templates = templates
        guard input != lastInput || day != lastDay || calendar != lastCalendar else { return }
        let output = await Task.detached(priority: .userInitiated) {
            AnalyticsEngine.compute(input, now: now, calendar: calendar)
        }.value
        guard request == generation, !Task.isCancelled else { return }
        self.output = output
        lastInput = input; lastDay = day; lastCalendar = calendar
    }
}
