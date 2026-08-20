import Foundation

public struct OnboardingInput: Sendable, Equatable {
    public var appName: String
    public var dailyUsageMinutes: Int
    public var preset: LimitPreset?
    public var customLimit: AppLimit?

    public init(appName: String, dailyUsageMinutes: Int, preset: LimitPreset? = nil, customLimit: AppLimit? = nil) {
        self.appName = appName
        self.dailyUsageMinutes = dailyUsageMinutes
        self.preset = preset
        self.customLimit = customLimit
    }

    public var effectiveLimit: AppLimit? {
        if let customLimit { return customLimit }
        if let preset { return AppLimit.preset(preset) }
        return nil
    }
}

public struct OnboardingDraft: Sendable, Equatable {
    public var inputs: [OnboardingInput]

    public init(inputs: [OnboardingInput] = []) {
        self.inputs = inputs
    }

    public var isValid: Bool {
        guard !inputs.isEmpty else { return false }
        for input in inputs {
            if input.appName.trimmingCharacters(in: .whitespaces).isEmpty { return false }
            if input.dailyUsageMinutes < 0 || input.dailyUsageMinutes > 1440 { return false }
            guard let limit = input.effectiveLimit, limit.isValid else { return false }
        }
        return true
    }

    public func baseline() -> Baseline {
        var dict: [String: Int] = [:]
        for input in inputs { dict[input.appName] = input.dailyUsageMinutes }
        return Baseline(dailyMinutesByApp: dict)
    }

    public func trackedApps() -> [TrackedApp] {
        inputs.map { input in
            let limit = input.effectiveLimit ?? AppLimit.preset(.standard)
            return TrackedApp(displayName: input.appName, limit: limit, isCustom: false)
        }
    }

    public func wastedTimeReport() -> [WastedTimeEntry] {
        inputs.compactMap { input in
            guard let limit = input.effectiveLimit else { return nil }
            let wasted = WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: input.dailyUsageMinutes, limitDailyMinutes: limit.dailyTotalMinutes)
            return WastedTimeEntry(appName: input.appName, dailyUsageMinutes: input.dailyUsageMinutes, limitDailyMinutes: limit.dailyTotalMinutes, annualizedWastedMinutes: wasted)
        }
    }

    public func totalAnnualizedWastedMinutes() -> Int {
        wastedTimeReport().reduce(0) { $0 + $1.annualizedWastedMinutes }
    }
}

public struct WastedTimeEntry: Sendable, Equatable {
    public var appName: String
    public var dailyUsageMinutes: Int
    public var limitDailyMinutes: Int
    public var annualizedWastedMinutes: Int

    public var annualizedWastedHours: Double { Double(annualizedWastedMinutes) / 60.0 }
    public var isWasting: Bool { annualizedWastedMinutes > 0 }
}

public enum OnboardingCompletion {
    public static func complete(draft: OnboardingDraft, store: MonkStore) throws -> MonkState {
        guard draft.isValid else { throw OnboardingError.invalidDraft }
        var state = store.load()
        state.trackedApps = draft.trackedApps()
        state.baseline = draft.baseline()
        state.hasCompletedOnboarding = true
        try store.save(state)
        return state
    }
}

public enum OnboardingError: Error, Equatable {
    case invalidDraft
}
