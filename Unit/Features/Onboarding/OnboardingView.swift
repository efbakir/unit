//
//  OnboardingView.swift
//  Unit
//
//  Root coordinator for the onboarding flow.
//
//  Routing is state-driven in every build: this view appears when there is no
//  program data. The commit writes real data (Split, DayTemplate, etc.), and
//  ContentView advances to the access gate from that persisted state.
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
    static let hasSelectedImportMethod = "onboarding.hasSelectedImportMethod"
    static let hasSelectedUnit = "onboarding.hasSelectedUnit"
    static let unitSystem = "onboarding.unitSystem"
    static let pickedProgramID = "onboarding.pickedProgramID"
    static let preferredGoal = "onboarding.preferredGoal"
    static let preferredLevel = "onboarding.preferredLevel"
    static let preferredDaysPerWeek = "onboarding.preferredDaysPerWeek"
    static let dayExercises = "onboarding.dayExercises"
    static let pastedProgramText = "onboarding.pastedProgramText"
    static let currentStep = "onboarding.currentStep"
    static let stepHistory = "onboarding.stepHistory"
}

/// Persists the in-flight onboarding state to UserDefaults so a quit-and-relaunch
/// (notably mid-paste, after the Vision OCR parse has populated the viewmodel)
/// doesn't reset the user to the splash with empty hands. `OnboardingView` writes
/// a snapshot on every step transition and clears it after a successful commit.
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
        defaults.set(
            viewModel.hasSelectedImportMethod,
            forKey: OnboardingPreferencesKeys.hasSelectedImportMethod
        )
        defaults.set(viewModel.hasSelectedUnit, forKey: OnboardingPreferencesKeys.hasSelectedUnit)
        defaults.set(viewModel.unitSystem, forKey: OnboardingPreferencesKeys.unitSystem)
        if let pickedProgramID = viewModel.pickedProgram?.id.uuidString {
            defaults.set(pickedProgramID, forKey: OnboardingPreferencesKeys.pickedProgramID)
        } else {
            defaults.removeObject(forKey: OnboardingPreferencesKeys.pickedProgramID)
        }
        if let preferredGoal = viewModel.preferredGoal?.rawValue {
            defaults.set(preferredGoal, forKey: OnboardingPreferencesKeys.preferredGoal)
        } else {
            defaults.removeObject(forKey: OnboardingPreferencesKeys.preferredGoal)
        }
        if let preferredLevel = viewModel.preferredLevel?.rawValue {
            defaults.set(preferredLevel, forKey: OnboardingPreferencesKeys.preferredLevel)
        } else {
            defaults.removeObject(forKey: OnboardingPreferencesKeys.preferredLevel)
        }
        if let preferredDaysPerWeek = viewModel.preferredDaysPerWeek {
            defaults.set(preferredDaysPerWeek, forKey: OnboardingPreferencesKeys.preferredDaysPerWeek)
        } else {
            defaults.removeObject(forKey: OnboardingPreferencesKeys.preferredDaysPerWeek)
        }
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
        // Drafts saved by earlier builds may sit on the retired unit or
        // weekday steps (2026-10-23 simplification). Resume on the step that
        // replaced them and drop them from Back history.
        let resumed: OnboardingStep = switch step {
        case .unitPicker: .importMethod
        case .schedule: .exercises
        default: step
        }
        return (resumed, history.filter { $0 != .unitPicker && $0 != .schedule })
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
            OnboardingPreferencesKeys.hasSelectedImportMethod,
            OnboardingPreferencesKeys.hasSelectedUnit,
            OnboardingPreferencesKeys.unitSystem,
            OnboardingPreferencesKeys.pickedProgramID,
            OnboardingPreferencesKeys.preferredGoal,
            OnboardingPreferencesKeys.preferredLevel,
            OnboardingPreferencesKeys.preferredDaysPerWeek,
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

        if defaults.object(forKey: OnboardingPreferencesKeys.hasSelectedImportMethod) != nil {
            viewModel.hasSelectedImportMethod = defaults.bool(
                forKey: OnboardingPreferencesKeys.hasSelectedImportMethod
            )
        }

        if defaults.object(forKey: OnboardingPreferencesKeys.hasSelectedUnit) != nil {
            viewModel.hasSelectedUnit = defaults.bool(forKey: OnboardingPreferencesKeys.hasSelectedUnit)
        }

        if let unitSystem = defaults.string(forKey: OnboardingPreferencesKeys.unitSystem),
           unitSystem == "kg" || unitSystem == "lb" {
            viewModel.unitSystem = unitSystem
        }

        if viewModel.importMethod == .library,
           let rawProgramID = defaults.string(forKey: OnboardingPreferencesKeys.pickedProgramID),
           let programID = UUID(uuidString: rawProgramID) {
            viewModel.pickedProgram = ProgramCatalog.all.first { $0.id == programID }
        }

        if let rawGoal = defaults.string(forKey: OnboardingPreferencesKeys.preferredGoal) {
            viewModel.preferredGoal = ProgramTemplate.Goal(rawValue: rawGoal)
        }
        if let rawLevel = defaults.string(forKey: OnboardingPreferencesKeys.preferredLevel) {
            viewModel.preferredLevel = ProgramTemplate.Level(rawValue: rawLevel)
        }
        if defaults.object(forKey: OnboardingPreferencesKeys.preferredDaysPerWeek) != nil {
            let days = defaults.integer(forKey: OnboardingPreferencesKeys.preferredDaysPerWeek)
            if ProgramCatalog.supportedDays.contains(days) {
                viewModel.preferredDaysPerWeek = days
            }
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

    /// Controlled step name for the anonymous onboarding funnel.
    var analyticsStep: AnalyticsOnboardingStep? {
        switch self {
        case .splash, .splitBuilder: nil
        case .unitPicker: .unit
        case .importMethod: .method
        case .programImport: .paste
        case .libraryPicker: .library
        case .schedule: .schedule
        case .exercises: .review
        }
    }
}

// MARK: - Root View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    var onCompletion: () -> Void = { }

    @AppStorage("unitSystem") private var storedUnitSystem: String = "kg"

    @State private var vm = OnboardingViewModel()
    @State private var step: OnboardingStep = .splash
    @State private var history: [OnboardingStep] = []
    @State private var direction: OnboardingSlideDirection = .none
    @State private var commitError: Bool = false
    @State private var didLoadPreferences = false
    @State private var isCommitting: Bool = false
    @State private var didTrackOnboardingStart = false

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
            if !didTrackOnboardingStart {
                didTrackOnboardingStart = true
                UnitAnalytics.shared.track(.onboardingStarted)
            }
            guard !didLoadPreferences else { return }
            vm.unitSystem = UserDefaults.standard.object(forKey: "unitSystem") == nil
                ? OnboardingViewModel.regionDefaultUnitSystem
                : storedUnitSystem
            OnboardingPreferences.load(into: vm)
            let navigation = OnboardingPreferences.loadNavigation()
            step = navigation.step
            history = navigation.history
            didLoadPreferences = true
        }
        .onChange(of: vm.pastedProgramText) { _, _ in persistDraft() }
        .onChange(of: vm.dayExercises) { _, _ in persistDraft() }
        .onChange(of: vm.dayNames) { _, _ in persistDraft() }
        .onChange(of: vm.dayWeekdays) { _, _ in persistDraft() }
        .onChange(of: vm.useFlexibleSchedule) { _, _ in persistDraft() }
        .onChange(of: vm.customDate) { _, _ in persistDraft() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { persistDraft() }
        }
    }

    private func persistDraft() {
        guard didLoadPreferences, !isCommitting else { return }
        persistProgress()
    }

    // MARK: - Step → View

    @ViewBuilder
    private func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .splash:
            OnboardingSplashView(
                onSlideViewed: { id in
                    UnitAnalytics.shared.track(.onboardingSlideViewed(id: id))
                },
                onGetStarted: { push(.importMethod) }
            )

        case .unitPicker:
            // Retired from the flow on 2026-10-23; only reachable from a
            // legacy draft, which `loadNavigation` already remaps.
            OnboardingUnitPickerView(
                progressStep: 1,
                progressTotal: totalRequiredSteps,
                selectedUnit: vm.hasSelectedUnit ? vm.unitSystem : nil,
                onSelect: { unit in
                    let shouldAutoAdvance = !vm.hasSelectedUnit
                    vm.unitSystem = unit
                    UnitAnalytics.shared.track(.weightUnitSelected(unit: unit))
                    vm.hasSelectedUnit = true
                    persistProgress()
                    if shouldAutoAdvance {
                        push(.importMethod)
                    }
                },
                onContinue: { push(.importMethod) },
                onBack: pop
            )

        case .importMethod:
            OnboardingImportMethodView(
                progressStep: 1,
                progressTotal: totalRequiredSteps,
                selectedMethod: vm.hasSelectedImportMethod ? vm.importMethod : nil,
                onSelect: { method in
                    let shouldAutoAdvance = !vm.hasSelectedImportMethod
                    vm.importMethod = method
                    UnitAnalytics.shared.track(
                        .programSourceSelected(source: method == .paste ? "paste" : "library")
                    )
                    vm.hasSelectedImportMethod = true
                    persistProgress()
                    if shouldAutoAdvance {
                        continueFromImportMethod()
                    }
                },
                onContinue: continueFromImportMethod,
                onBack: pop
            )

        case .programImport:
            OnboardingProgramImportView(
                progressStep: 2,
                progressTotal: totalRequiredSteps,
                onContinue: { push(.exercises) },
                onBack: pop
            )

        case .libraryPicker:
            OnboardingLibraryPickerView(
                progressStep: 2,
                progressTotal: totalRequiredSteps,
                onUpdate: persistProgress,
                onContinue: { push(.exercises) },
                onBack: pop
            )

        case .splitBuilder:
            OnboardingSplitBuilderView(
                progressStep: 2,
                progressTotal: totalRequiredSteps,
                onContinue: { push(.exercises) },
                onBack: pop
            )

        case .schedule:
            // Retired from the flow on 2026-10-23 (new programs start on a
            // flexible rotation); only reachable from a legacy draft.
            OnboardingScheduleView(
                progressStep: 2,
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

    /// Both paths use three stable steps: path, program, review (2026-10-23).
    /// The weight unit comes from the phone region or the pasted text and can
    /// be changed on review; weekdays default to a flexible rotation so Today
    /// offers the first workout right after purchase.
    private var totalRequiredSteps: Int { 3 }

    private var exercisesProgressStep: Int { totalRequiredSteps }

    private func continueFromImportMethod() {
        switch vm.importMethod {
        case .library:
            push(.libraryPicker)
        case .paste:
            push(.programImport)
        }
    }

    // MARK: - Step navigation

    private func push(_ next: OnboardingStep) {
        history.append(step)
        direction = .forward
        step = next
        if let analyticsStep = next.analyticsStep {
            UnitAnalytics.shared.track(.onboardingStepViewed(step: analyticsStep))
        }
        // Snapshot on every transition: a quit-and-relaunch (notably mid-paste,
        // after the Vision OCR parse populated the viewmodel) restores the
        // user's work on the next entry instead of dropping them at splash.
        OnboardingPreferences.save(from: vm, currentStep: step, history: history)
    }

    private func persistProgress() {
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
        // No weekday step: every new program starts as a flexible rotation,
        // so Today always shows the next workout. Weekdays can be set later
        // in Programs.
        vm.useFlexibleSchedule = true
        do {
            try vm.commit(modelContext: modelContext)
            ProgramSetupContextStore.save(
                ProgramSetupContext(
                    source: vm.importMethod == .paste ? .paste : .matchedLibrary,
                    matchProfile: vm.importMethod == .library ? vm.programMatchProfile : nil
                )
            )
            UnitAnalytics.shared.track(
                .programSetupCompleted(source: vm.importMethod == .paste ? "paste" : "library")
            )
            storedUnitSystem = vm.unitSystem
            OnboardingPreferences.clear()
            onCompletion()
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

/// Owns the still Milk page. Animation belongs to the transition, so new step
/// layout and caller-owned drafts update immediately. Native chrome stays native.
struct OnboardingFlow<StepContent: View>: View {
    let step: OnboardingStep
    let direction: OnboardingSlideDirection
    @ViewBuilder let stepContent: (OnboardingStep) -> StepContent

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            stepContent(step)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(step)
                .transition(AppBlurTransition().animation(.appReveal))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
