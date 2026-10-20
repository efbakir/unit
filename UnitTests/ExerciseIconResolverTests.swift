import XCTest
import SwiftUI
@testable import Unit

@MainActor
final class ExerciseIconResolverTests: XCTestCase {
    func testPatternsAndFalseFriends() {
        let groups: [(AppIcon?, [String])] = [
            (.liftSquat, ["Squat", "Back Squat", "Barbell Back Squat", "Back Squat (BB)", "High Bar Squat", "SQUAT"]),
            (.liftBench, ["Bench", "Bench Press", "Bench Press (BB)", "Barbell Bench Press", "bench-press", "Bench  Press ", "BÉNCH PRESS", "ＢＥＮＣＨ ＰＲＥＳＳ", "bench_press", "bench/press", "bench.press", "bench,press"]),
            (.liftDeadlift, ["Deadlift", "Conventional Deadlift", "Deadlift (Conv)", "Sumo Deadlift", "Barbell Deadlift"]),
            (.liftRow, ["Row", "Barbell Row", "Bent-Over Barbell Row", "Bent Over Row (BB)"]),
            (.liftPullup, ["Pull Up", "pull-up", "PULLUPS", "Weighted Pull-Up"]),
            (.liftOverhead, ["Overhead Press", "OHP", "OHP (BB)", "Military Press", "Shoulder Press", "Barbell Overhead Press"]),
            (nil, ["", "Front Squat", "Goblet Squat", "Leg Press", "Lunges", "Step-Up", "Thruster", "Incline Bench", "Close-Grip Bench", "Dumbbell Bench Press", "Push-Up", "Floor Press", "Chest Press", "Romanian Deadlift", "RDL", "Good Morning", "Kettlebell Swing", "DB Row", "Bench Row", "Machine Row", "Seated Cable Row", "Face Pull", "Upright Barbell Row", "Pulldown", "Lat Pulldown", "Chin-Up", "Muscle Up", "Arnold Press", "Landmine Press", "Overhead Triceps Extension", "Plank", "Crunch", "Leg Curl", "DB Fly", "Unknown"])
        ]
        for (expected, names) in groups {
            for name in names { XCTAssertEqual(ExerciseIconResolver.icon(name: name), expected, name) }
        }
        XCTAssertNil(ExerciseIconResolver.icon(name: "Fly", equipment: "dumbbell"))
        XCTAssertNil(ExerciseIconResolver.icon(name: "Hold", muscleGroup: "core"))
        XCTAssertNil(ExerciseIconResolver.icon(name: "Bench Press", equipment: "dumbbell"))
        XCTAssertNil(ExerciseIconResolver.icon(name: "Row", equipment: "machine"))
        XCTAssertEqual(ExerciseIconResolver.icon(name: "Bench Press", equipment: "barbell"), .liftBench)
        XCTAssertEqual(ExerciseIconResolver.icon(name: "Squat", equipment: "other"), .liftSquat)
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
        XCTAssertNil(ExerciseIconResolver.icon(name: exercise.name))
    }

    func testMovementAssetsAndRenderedComparisons() throws {
        let icons: [AppIcon] = [.liftSquat, .liftBench, .liftDeadlift, .liftOverhead, .liftRow, .liftPullup]
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
