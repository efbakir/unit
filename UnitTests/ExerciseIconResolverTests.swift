import XCTest
import SwiftUI
@testable import Unit

@MainActor
final class ExerciseIconResolverTests: XCTestCase {
    func testPatternsAndFalseFriends() {
        let groups: [(AppIcon, [String])] = [
            (.liftSquat, ["Squat", "Back Squat", "Front Squat", "Goblet Squat", "Hack Squat", "Box Squat", "Pause Squat", "Bulgarian Split Squat", "Leg Press", "Squat Jump", "Lunges", "Thruster", "SQUATS"]),
            (.liftBench, ["Bench", "Bench Press", "INCLINE BENCH", "Close-Grip Bench", "Dumbbell Bench Press", "bench-press", "Bench  Press ", "Floor Press", "Chest Press", "BÉNCH PRESS", "ＢＥＮＣＨ ＰＲＥＳＳ", "bench_press", "bench/press", "bench.press", "bench,press"]),
            (.liftDeadlift, ["Deadlift", "Deadlifts", "Romanian Deadlift", "Sumo Deadlift", "Trap Bar Deadlift", "RDL", "Stiff-Legged Deadlift", "Good Morning", "Rack Pull", "Hip Hinge"]),
            (.liftRow, ["Bench Row", "Bench Supported Row", "Pendlay Row", "Chest-Supported Row", "Seated Cable Row", "Rows", "Machine Row"]),
            (.liftPullup, ["Pull Up", "pull-up", "PULLUPS", "Weighted Pull-Up", "Chin-up", "Chinups", "Lat Pulldown", "Pull Downs", "Muscle Up", "Pullups"]),
            (.liftOverhead, ["Overhead Press", "OHP", "Military Press", "Shoulder Press", "Push Press", "Strict Press", "Arnold Press", "Landmine Press", "Seated Dumbbell Shoulder Press"]),
            (.deadlift, ["", "Rowing Machine", "Upright Row", "Overhead Triceps Extension", "Pullover", "Bench Dip", "Face Pull", "Hip Thrust", "Überzug", "Unknown"]),
            (.core, ["Plank", "Crunch", "Sit Up", "Abs", "Hollow Hold"]),
            (.dumbbell, ["Leg Curl", "DB Fly", "Kettlebell Swing"])
        ]
        for (expected, names) in groups {
            for name in names { XCTAssertEqual(ExerciseIconResolver.icon(name: name), expected, name) }
        }
        XCTAssertEqual(ExerciseIconResolver.icon(name: "Fly", equipment: "dumbbell"), .dumbbell)
        XCTAssertEqual(ExerciseIconResolver.icon(name: "Hold", muscleGroup: "core"), .core)
        XCTAssertEqual(ExerciseIconResolver.icon(name: "", muscleGroup: "core"), .deadlift)
    }

    func testRenameRecomputesIcon() {
        let exercise = Exercise(displayName: "Bench Press")
        XCTAssertEqual(exercise.icon, .liftBench)
        exercise.displayName = "Pull-Up"
        XCTAssertEqual(exercise.icon, .liftPullup)
    }

    func testIconDoesNotQualifyVariantAsMainLift() {
        let exercise = AnalyticsEngine.ExerciseInput(id: UUID(), name: "Front Squat", isBodyweight: false, equipment: "barbell", muscleGroup: "quads")
        XCTAssertNil(AnalyticsEngine.slot(for: exercise))
        XCTAssertEqual(ExerciseIconResolver.icon(name: exercise.name), .liftSquat)
    }

    func testMovementAssetsAndRenderedComparisons() throws {
        let icons: [AppIcon] = [.liftSquat, .liftBench, .liftDeadlift, .liftOverhead, .liftRow, .liftPullup, .core, .dumbbell, .deadlift]
        for icon in icons {
            let image = try XCTUnwrap(icon.isMovementAsset ? UIImage(named: icon.rawValue) : UIImage(systemName: icon.systemName))
            if icon.isMovementAsset { XCTAssertEqual(image.renderingMode, .alwaysTemplate) }
            XCTAssertGreaterThan(image.size.width, 0)
            let rendered = UIGraphicsImageRenderer(size: image.size).image { _ in image.draw(at: .zero) }
            let bytes = try XCTUnwrap(rendered.cgImage?.dataProvider?.data)
            XCTAssertTrue((0..<CFDataGetLength(bytes)).contains { CFDataGetBytePtr(bytes)[$0] != 0 })
        }
        for (name, scheme, type, contrast) in [("light", ColorScheme.light, DynamicTypeSize.large, ColorSchemeContrast.standard), ("dark", .dark, .large, .standard), ("AX3", .light, .accessibility3, .standard), ("contrast", .light, .large, .increased)] {
            let content = VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(icons, id: \.rawValue) { icon in
                    HStack {
                        AppMainLiftCard.iconTile(icon, side: AppSpacing.xl)
                        AppMainLiftCard.iconTile(icon, side: AppIconSize.exerciseDetailTile, detail: true)
                        Text(icon.rawValue).font(AppFont.caption.font).foregroundStyle(AppColor.textPrimary)
                    }
                }
            }.padding(AppSpacing.md).background(AppColor.background)
                .environment(\.colorScheme, scheme).environment(\.dynamicTypeSize, type)
            var preview: UIImage?
            UITraitCollection(accessibilityContrast: contrast == .increased ? .high : .normal).performAsCurrent {
                let renderer = ImageRenderer(content: content)
                renderer.scale = 2
                preview = renderer.uiImage
            }
            let attachment = XCTAttachment(image: try XCTUnwrap(preview))
            attachment.name = "movement-icons-v2-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
