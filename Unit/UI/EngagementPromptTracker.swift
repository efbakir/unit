//
//  EngagementPromptTracker.swift
//  Unit
//
//  Version-scoped, local-only engagement prompt state.
//

import Foundation

struct EngagementPromptTracker {
    static let bookingURL = URL(string: "https://calendar.notion.so/meet/efbakir/unit-feedback")!
    static let feedbackEmailAddress = "support@unitlift.app"
    static let feedbackEmailSubject = "Unit feedback"

    private enum Key {
        static let completedSessionIDs = "engagement.v2_1.completedSessionIDs"
        static let reviewRequestAttempted = "engagement.v2_1.reviewRequestAttempted"
        static let feedbackPromptShown = "engagement.v2_1.feedbackPromptShown"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var completedWorkoutCount: Int {
        completedSessionIDs.count
    }

    var shouldRequestReview: Bool {
        completedWorkoutCount >= 1 && !reviewRequestAttempted
    }

    var reviewRequestAttempted: Bool {
        defaults.bool(forKey: Key.reviewRequestAttempted)
    }

    var feedbackPromptShown: Bool {
        defaults.bool(forKey: Key.feedbackPromptShown)
    }

    @discardableResult
    func recordCompletedWorkout(sessionID: UUID) -> Int {
        var ids = completedSessionIDs
        let value = sessionID.uuidString

        guard !ids.contains(value), ids.count < 3 else {
            return ids.count
        }

        ids.append(value)
        defaults.set(ids, forKey: Key.completedSessionIDs)
        return ids.count
    }

    func shouldShowFeedback(for sessionID: UUID) -> Bool {
        let ids = completedSessionIDs
        return ids.count == 3
            && ids.last == sessionID.uuidString
            && !feedbackPromptShown
    }

    func markReviewRequestAttempted() {
        defaults.set(true, forKey: Key.reviewRequestAttempted)
    }

    func markFeedbackPromptShown() {
        defaults.set(true, forKey: Key.feedbackPromptShown)
    }

    static func seedCompletedWorkoutCountForUITesting(
        _ count: Int,
        defaults: UserDefaults = .standard
    ) {
        let safeCount = min(max(count, 0), 3)
        let ids = (0..<safeCount).map { _ in UUID().uuidString }
        defaults.set(ids, forKey: Key.completedSessionIDs)
    }

    static func feedbackEmailURL(
        appVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
        buildNumber: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
        systemVersion: String? = ProcessInfo.processInfo.operatingSystemVersionString
    ) -> URL? {
        var body = """
        What worked:

        What got in the way:

        What should improve:
        """

        let diagnosticParts = [
            appVersion.map { "Unit \($0)" },
            buildNumber.map { "build \($0)" },
            systemVersion
        ].compactMap { $0 }

        if !diagnosticParts.isEmpty {
            body += "\n\n\(diagnosticParts.joined(separator: " · "))"
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmailAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: feedbackEmailSubject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    private var completedSessionIDs: [String] {
        let values = defaults.stringArray(forKey: Key.completedSessionIDs) ?? []
        return Array(values.prefix(3))
    }
}
