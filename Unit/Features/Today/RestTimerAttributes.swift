//
//  RestTimerAttributes.swift
//  Unit
//
//  ActivityKit attributes for rest timer Live Activity (Lock Screen / Dynamic Island).
//  ActivityKit is iOS-only; this type is only compiled for iOS (shared by app and widget).
//

import Foundation

#if os(iOS)
import ActivityKit
import AppIntents

/// Attributes for the rest timer Live Activity.
/// Include this file in both Unit and UnitWidgetExtension targets so the same type is used.
///
/// `nonisolated` because this target builds with SWIFT_DEFAULT_ACTOR_ISOLATION =
/// MainActor, which would otherwise make this type @MainActor and produce a
/// "main actor-isolated conformance to 'ActivityAttributes'" error. ActivityKit
/// reads the attributes (and their `ContentState`) off the main actor, so the
/// conformance must be nonisolated & Sendable. Pure data — always safe.
public nonisolated struct RestTimerAttributes: ActivityAttributes {
    /// Rest step for the in-app rest bar and the Lock Screen buttons, one source
    /// for labels, VoiceOver and the timer (30 seconds since 2026-10-23).
    public static let stepSeconds = 30

    public struct ContentState: Codable, Hashable, Sendable {
        /// When the rest period started. Together with `endDate`, this gives SwiftUI
        /// the complete interval for a system-driven countdown that continues while
        /// the host app is suspended.
        public var startDate: Date
        /// When the rest period ends.
        public var endDate: Date
        /// Name of the next exercise (the current one while it has sets left),
        /// or nil when no set remains. Activities started before 2026-10-24
        /// hold "Name · Set N" here and no detail.
        public var upNext: String?
        /// The next set's line, e.g. "Set 2 · 135 lb × 10". Optional, so an
        /// activity that is running when the app updates still decodes.
        public var upNextDetail: String?

        public init(startDate: Date, endDate: Date, upNext: String? = nil, upNextDetail: String? = nil) {
            self.startDate = startDate
            self.endDate = endDate
            self.upNext = upNext
            self.upNextDetail = upNextDetail
        }
    }

    /// Fixed identity for this activity.
    public var kind: String = "rest"

    public init(kind: String = "rest") {
        self.kind = kind
    }
}

/// Lock Screen and Dynamic Island rest buttons. A `LiveActivityIntent` runs in
/// the app's process, which owns the rest timer; the widget only draws the
/// button. On a locked phone iOS asks for Face ID before it runs.
/// No parameters: a property-wrapped parameter can't be stored in a
/// `nonisolated` type here, and each button needs only its fixed step.
nonisolated struct AddRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Add rest"
    static let isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        RestTimerIntentHandler.adjust?(RestTimerAttributes.stepSeconds)
        return .result()
    }
}

nonisolated struct SubtractRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Subtract rest"
    static let isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        RestTimerIntentHandler.adjust?(-RestTimerAttributes.stepSeconds)
        return .result()
    }
}

nonisolated struct SkipRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip rest"
    static let isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        RestTimerIntentHandler.skip?()
        return .result()
    }
}

/// The app sets these at launch so both intents act on its one rest timer.
/// They stay nil in the widget process, which never runs the intents.
@MainActor
enum RestTimerIntentHandler {
    static var adjust: ((Int) -> Void)?
    static var skip: (() -> Void)?
}

/// `Activity<Attributes>` is an ActivityKit reference type whose methods
/// (`update`, `end`) are async and thread-safe per Apple's design, but the
/// iOS 26 SDK doesn't expose explicit Sendable conformance. Xcode Cloud's
/// complete strict-concurrency build flags any capture of an Activity into
/// a Task closure as "Sending value of non-Sendable type". Assert Sendable
/// here so callers can use Activity references the way ActivityKit's own
/// sample code does — capture, then `await activity?.update(content)` in a
/// detached Task — without per-call `@unchecked` ceremony.
///
/// Mirrors the `nonisolated(unsafe)` pattern already used in
/// `StoreManager.swift:50` for similar SDK-vs-strict-concurrency mismatches.
extension Activity: @retroactive @unchecked Sendable {}
#endif
