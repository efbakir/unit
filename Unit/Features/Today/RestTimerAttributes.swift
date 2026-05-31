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

/// Attributes for the rest timer Live Activity.
/// Include this file in both Unit and UnitWidgetExtension targets so the same type is used.
public struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// When the rest period started — required by `Text(timerInterval:pauseTime:countsDown:)`
        /// so the system can clamp the display at 0:00 instead of counting up after `endDate`.
        public var startDate: Date
        /// When the rest period ends.
        public var endDate: Date
        /// Pre-formatted "what's coming next" hint: next exercise name, or `nil` for the
        /// last set of the workout. The host (`ActiveWorkoutView`) decides phrasing.
        public var upNext: String?

        public init(startDate: Date, endDate: Date, upNext: String? = nil) {
            self.startDate = startDate
            self.endDate = endDate
            self.upNext = upNext
        }
    }

    /// Fixed identity for this activity.
    public var kind: String = "rest"

    public init(kind: String = "rest") {
        self.kind = kind
    }
}
#endif
