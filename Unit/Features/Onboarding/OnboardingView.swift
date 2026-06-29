//
//  OnboardingView.swift
//  Unit
//
//  Root coordinator for the onboarding flow.
//
//  Routing is state-driven: ContentView shows this view when there is no
//  program data (new user) or when the user explicitly requests a restart
//  from Settings. The view never sets a "hasCompletedOnboarding" boolean —
//  instead, the commit writes real data (Split, DayTemplate, etc.) and
//  ContentView derives the next screen from that data.
//
//  Step **swapping** uses `OnboardingFlow` (defined below) — never a
//  `NavigationStack` push, which would slide the whole view as one opaque
//  rect and make the Milk page appear to translate between steps.
//  `OnboardingFlow` owns one fixed Milk surface and slides only the step
//  content (header + body + sticky CTA) over it via the canonical `.appEnter`
//  curve. The single `NavigationStack` at this view's root is a *chrome*
//  host only — it gives every step's `OnboardingShell` a real
//  `UINavigationBar` to render its iOS-native back-button `ToolbarItem`
//  into. No `.navigationDestination` push ever happens.
//

import SwiftUI
import SwiftData

enum OnboardingPreferencesKeys {
    static let dayCount = "onboarding.dayCount"
    static let dayNames = "onboarding.dayNames"
    static let startOption = "onboarding.startOption"
    static let customStartDate = "onboarding.customStartDate"
    static let dayWeekdays = "onboarding.dayWeekdays"
    static let useFlexibleSchedule = "onboarding.useFlexibleSchedule"
    static let importMethod = "onboarding.importMethod"
    static let dayExercises = "onboarding.dayExercises"
    static let pastedProgramText = "onboarding.pastedProgramText"
    static let currentStep = "onboarding.currentStep"
    static let stepHistory = "onboarding.stepHistory"
}

/// Persists the in-flight onboarding state to UserDefaults so a quit-and-relaunch
/// (notably mid-paste, after the Vision OCR parse has populated the viewmodel)
/// doesn't reset the user to the splash with empty hands. `OnboardingView` writes
/// a snapshot on every step transition and on commit success.
enum OnboardingPreferences {
    static func save(
        from viewModel: OnboardingViewModel,
        currentStep: OnboardingStep,
        history: [OnboardingStep],
        defaults: UserDefaults = .standard
    ) {
        defaults.set(viewModel.dayCount, forKey: OnboardingPreferencesKeys.dayCount)
        defaults.set(viewModel.dayNames, forKey: OnboardingPreferencesKeys.dayNames)
        defaults.set(rawStartOption(from: viewModel.startOption), forKey: OnboardingPreferencesKeys.startOption)
        defaults.set(viewModel.customDate.timeIntervalSince1970, forKey: OnboardingPreferencesKeys.customStartDate)
        defaults.set(viewModel.dayWeekdays, forKey: OnboardingPreferencesKeys.dayWeekdays)
        defaults.set(viewModel.useFlexibleSchedule, forKey: OnboardingPreferencesKeys.useFlexibleSchedule)
        defaults.set(rawImportMethod(from: viewModel.importMethod), forKey: OnboardingPreferencesKeys.importMethod)
        defaults.set(viewModel.pastedProgramText, forKey: OnboardingPreferencesKeys.pastedProgramText)
        defaults.set(currentStep.rawValue, forKey: OnboardingPreferencesKeys.currentStep)
        defaults.set(history.map(\.rawValue), forKey: OnboardingPreferencesKeys.stepHistory)

        if let exercisesData = try? JSONEncoder().encode(viewModel.dayExercises) {
            defaults.set(exercisesData, forKey: OnboardingPreferencesKeys.dayExercises)
        }
    }

    static func loadNavigation(defaults: UserDefaults = .standard) -> (step: OnboardingStep, history: [OnboardingStep]) {
        let step = defaults.string(forKey: OnboardingPreferencesKeys.currentStep)
            .flatMap(OnboardingStep.init(rawValue:)) ?? .splash
        let history = defaults.stringArray(forKey: OnboardingPreferencesKeys.stepHistory)?
            .compactMap(OnboardingStep.init(rawValue:)) ?? []
        return (step, history)
    }

    static func clear(defaults: UserDefaults = .standard) {
        [
            OnboardingPreferencesKeys.dayCount,
            OnboardingPreferencesKeys.dayNames,
            OnboardingPreferencesKeys.startOption,
            OnboardingPreferencesKeys.customStartDate,
            OnboardingPreferencesKeys.dayWeekdays,
            OnboardingPreferencesKeys.useFlexibleSchedule,
            OnboardingPreferencesKeys.importMethod,
            OnboardingPreferencesKeys.dayExercises,
            OnboardingPreferencesKeys.pastedProgramText,
            OnboardingPreferencesKeys.currentStep,
            OnboardingPreferencesKeys.stepHistory
        ].forEach { defaults.removeObject(forKey: $0) }
    }

    static func load(into viewModel: OnboardingViewModel, defaults: UserDefaults = .standard) {
        let storedDayCount = defaults.integer(forKey: OnboardingPreferencesKeys.dayCount)
        if storedDayCount > 0 {
            viewModel.updateDayCount(storedDayCount)
        }

        if let names = defaults.stringArray(forKey: OnboardingPreferencesKeys.dayNames), !names.isEmpty {
            viewModel.updateDayCount(names.count)
            for index in viewModel.dayNames.indices {
                if index < names.count {
                    viewModel.dayNames[index] = names[index]
                }
            }
        }

        if let weekdays = defaults.array(forKey: OnboardingPreferencesKeys.dayWeekdays) as? [Int],
           !weekdays.isEmpty {
            for index in viewModel.dayWeekdays.indices {
                if index < weekdays.count {
                    viewModel.dayWeekdays[index] = weekdays[index]
                }
            }
        }

        if defaults.object(forKey: OnboardingPreferencesKeys.useFlexibleSchedule) != nil {
            viewModel.useFlexibleSchedule = defaults.bool(forKey: OnboardingPreferencesKeys.useFlexibleSchedule)
        }

        if let rawMethod = defaults.string(forKey: OnboardingPreferencesKeys.importMethod) {
            viewModel.importMethod = importMethod(from: rawMethod)
        }

        if let pastedText = defaults.string(forKey: OnboardingPreferencesKeys.pastedProgramText) {
            viewModel.pastedProgramText = pastedText
        }

        if let exercisesData = defaults.data(forKey: OnboardingPreferencesKeys.dayExercises),
           let decoded = try? JSONDecoder().decode([[OnboardingExercise]].self, from: exercisesData),
           !decoded.isEmpty {
            // Stored shape wins: dayCount may have been bumped after exercises
            // were arranged on a smaller split, so resize first then drop in.
            viewModel.updateDayCount(decoded.count)
            for index in viewModel.dayExercises.indices {
                if index < decoded.count {
                    viewModel.dayExercises[index] = decoded[index]
                }
            }
        }

        if let rawOption = defaults.string(forKey: OnboardingPreferencesKeys.startOption) {
            viewModel.startOption = startOption(from: rawOption)
        }

        if defaults.object(forKey: OnboardingPreferencesKeys.customStartDate) != nil {
            let timestamp = defaults.double(forKey: OnboardingPreferencesKeys.customStartDate)
            viewModel.customDate = Date(timeIntervalSince1970: timestamp)
        }
    }

    private static func rawStartOption(from option: OnboardingViewModel.StartOption) -> String {
        switch option {
        case .today:
            return "today"
        case .nextMonday:
            return "nextMonday"
        case .custom:
            return "custom"
        }
    }

    private static func startOption(from rawValue: String) -> OnboardingViewModel.StartOption {
        switch rawValue {
        case "nextMonday":
            return .nextMonday
        case "custom":
            return .custom
        default:
            return .today
        }
    }

    private static func rawImportMethod(from method: OnboardingViewModel.ImportMethod) -> String {
        switch method {
        case .paste: return "paste"
        case .library: return "library"
        }
    }

    private static func importMethod(from raw: String) -> OnboardingViewModel.ImportMethod {
        switch raw {
        case "paste": return .paste
        // Legacy v1 persistence values map forward to .library — both
        // "manual" (the old build-from-blank path) and "history" (the
        // freestyle-conversion path) were removed in v2 Phase B-3.
        case "library", "manual", "history": return .library
        default: return .library
        }
    }
}

// MARK: - Step

enum OnboardingStep: String, Hashable {
    case splash
    case unitPicker
    case importMethod
    case programImport
    case libraryPicker
    case splitBuilder
    case schedule
    case exercises
}

// MARK: - Root View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("unitSystem") private var storedUnitSystem: String = "kg"

    @State private var vm = OnboardingViewModel()
    @State private var step: OnboardingStep = .splash
    @State private var history: [OnboardingStep] = []
    @State private var direction: OnboardingSlideDirection = .none
    @State private var commitError: Bool = false
    @State private var didLoadPreferences = false
    @State private var isCommitting: Bool = false

    var body: some View {
        // Single `NavigationStack` wraps the whole flow so each step's
        // `.toolbar { ToolbarItem(.topBarLeading) { Back } }` (declared inside
        // `OnboardingShell`) registers with the same long-lived
        // `UINavigationBar`. iOS swaps the toolbar items in place on step
        // change — no per-step UIKit nav-controller mount/unmount fighting
        // `OnboardingFlow`'s slide transition. The page surface still lives
        // on `OnboardingFlow` so step swaps slide only the content layer.
        NavigationStack {
            OnboardingFlow(step: step, direction: direction) { current in
                stepView(current)
            }
        }
        .tint(AppColor.accent)
        .environment(vm)
        .alert("Save failed", isPresented: $commitError) {
            Button(AppCopy.Nav.tryAgain, role: .cancel) { }
        } message: {
            Text("Try again in a moment.")
        }
        .onAppear {
            guard !didLoadPreferences else { return }
            vm.unitSystem = storedUnitSystem
            OnboardingPreferences.load(into: vm)
            let navigation = OnboardingPreferences.loadNavigation()
            step = navigation.step
            history = navigation.history
            didLoadPreferences = true
        }
    }

    // MARK: - Step → View

    @ViewBuilder
    private func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .splash:
            OnboardingSplashView {
                push(.unitPicker)
            }

        case .unitPicker:
            OnboardingUnitPickerView(
                progressStep: 1,
                progressTotal: totalRequiredSteps,
                onSelect: { unit in
                    vm.unitSystem = unit
                    push(.importMethod)
                },
                onBack: pop
            )

        case .importMethod:
            OnboardingImportMethodView(
                progressStep: 2,
                progressTotal: totalRequiredSteps,
                onSelect: { method in
                    vm.importMethod = method
                    switch method {
                    case .library:
                        push(.libraryPicker)
                    case .paste:
                        push(.programImport)
                    }
                },
                onBack: pop
            )

        case .programImport:
            OnboardingProgramImportView(
                progressStep: 3,
                progressTotal: totalRequiredSteps,
                onContinue: { push(.schedule) },
                onBack: pop
            )

        case .libraryPicker:
            OnboardingLibraryPickerView(
                progressStep: 3,
                progressTotal: totalRequiredSteps,
                onPick: { template in
                    vm.applyPickedProgram(template)
                    push(.schedule)
                },
                onBack: pop
            )

        case .splitBuilder:
            OnboardingSplitBuilderView(
                progressStep: 3,
                progressTotal: totalRequiredSteps,
                onContinue: { push(.schedule) },
                onBack: pop
            )

        case .schedule:
            OnboardingScheduleView(
                progressStep: 4,
                progressTotal: totalRequiredSteps,
                onContinue: { push(.exercises) },
                onBack: pop
            )

        case .exercises:
            OnboardingProgramPreviewView(
                progressStep: exercisesProgressStep,
                progressTotal: totalRequiredSteps,
                isCommitting: isCommitting,
                onContinue: commitProgram,
                onBack: pop
            )
        }
    }

    /// Both paths use five stable steps. Library programs now review their
    /// supplied weekdays in the same schedule screen instead of changing the
    /// progress denominator halfway through onboarding.
    private var totalRequiredSteps: Int { 5 }

    private var exercisesProgressStep: Int { totalRequiredSteps }

    // MARK: - Step navigation

    private func push(_ next: OnboardingStep) {
        history.append(step)
        direction = .forward
        step = next
        // Snapshot on every transition: a quit-and-relaunch (notably mid-paste,
        // after the Vision OCR parse populated the viewmodel) restores the
        // user's work on the next entry instead of dropping them at splash.
        OnboardingPreferences.save(from: vm, currentStep: step, history: history)
    }

    private func pop() {
        // The splash is the root step, so an empty history means we're already
        // there and there is nowhere to go back to.
        guard let previous = history.popLast() else { return }
        direction = .back
        step = previous
        OnboardingPreferences.save(from: vm, currentStep: step, history: history)
    }

    // MARK: - Commit

    private func commitProgram() {
        guard !isCommitting else { return }
        performCommit()
    }

    private func performCommit() {
        isCommitting = true
        do {
            try vm.commit(modelContext: modelContext)
            storedUnitSystem = vm.unitSystem
            OnboardingPreferences.clear()
            dismiss()
        } catch {
            isCommitting = false
            commitError = true
        }
    }

}

// MARK: - Flow container

/// Direction of the most recent step swap. Drives the asymmetric slide so a
/// forward push enters from the trailing edge and a back pop enters from the
/// leading edge — matching the platform mental model the user already has
/// from native push/pop.
enum OnboardingSlideDirection {
    /// First mount; no transition fires.
    case none
    /// `push` — new step enters from trailing, old leaves to leading.
    case forward
    /// `pop` — new step enters from leading, old leaves to trailing.
    case back
}

/// Owns the single Milk page surface and animates step swaps in place.
///
/// Why not `NavigationStack`: a NavigationStack push slides both source and
/// destination as opaque view-controller rects, which makes the shared Milk
/// page appear to translate between steps even though it never actually
/// changes. `OnboardingFlow` paints the page once at the root and slides only
/// the step content layer — header, body, sticky CTA — over a still surface.
///
/// Reduce Motion: the slide collapses to a pure cross-fade. Per AppMotion
/// doctrine, no horizontal translation when the user has the system
/// preference on.
struct OnboardingFlow<StepContent: View>: View {
    let step: OnboardingStep
    let direction: OnboardingSlideDirection
    @ViewBuilder let stepContent: (OnboardingStep) -> StepContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            stepContent(step)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(step)
                .transition(stepTransition)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? .appReveal : .appEnter, value: step)
        // No `.toolbar(.hidden)` here: each `OnboardingShell` step wants the
        // host `NavigationStack`'s nav bar visible to host its real back-
        // button `ToolbarItem`. Steps that don't use `OnboardingShell` (the
        // splash) hide the nav bar at their own level.
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        switch direction {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .back:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .none:
            return .opacity
        }
    }
}
