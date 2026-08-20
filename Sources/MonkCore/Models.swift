import Foundation

public enum LimitPreset: String, Codable, Sendable, CaseIterable {
    case light
    case standard
    case strict

    public var dailyTotalMinutes: Int {
        switch self {
        case .light: return 60
        case .standard: return 30
        case .strict: return 15
        }
    }

    public var singleSessionMinutes: Int {
        switch self {
        case .light: return 20
        case .standard: return 15
        case .strict: return 10
        }
    }
}

public struct AppLimit: Codable, Sendable, Equatable {
    public var dailyTotalMinutes: Int
    public var singleSessionMinutes: Int

    public init(dailyTotalMinutes: Int, singleSessionMinutes: Int) {
        self.dailyTotalMinutes = dailyTotalMinutes
        self.singleSessionMinutes = singleSessionMinutes
    }

    public static func preset(_ preset: LimitPreset) -> AppLimit {
        AppLimit(dailyTotalMinutes: preset.dailyTotalMinutes, singleSessionMinutes: preset.singleSessionMinutes)
    }

    public var isValid: Bool {
        dailyTotalMinutes > 0 && singleSessionMinutes > 0 && dailyTotalMinutes <= 1440 && singleSessionMinutes <= 1440
    }
}

public struct TrackedApp: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var displayName: String
    public var bundleIdentifier: String?
    public var limit: AppLimit
    public var isCustom: Bool

    public init(id: UUID = UUID(), displayName: String, bundleIdentifier: String? = nil, limit: AppLimit, isCustom: Bool) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.limit = limit
        self.isCustom = isCustom
    }
}

public enum DailyResetOption: String, Codable, Sendable, CaseIterable {
    case midnight
    case fourAM
    case fiveAM

    public var hour: Int {
        switch self {
        case .midnight: return 0
        case .fourAM: return 4
        case .fiveAM: return 5
        }
    }
}

public struct Baseline: Codable, Sendable, Equatable {
    public var dailyMinutesByApp: [String: Int]
    public var createdAt: Date

    public init(dailyMinutesByApp: [String: Int], createdAt: Date = Date()) {
        self.dailyMinutesByApp = dailyMinutesByApp
        self.createdAt = createdAt
    }
}

public enum Appearance: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

public struct MonkState: Codable, Sendable, Equatable {
    public var trackedApps: [TrackedApp]
    public var baseline: Baseline?
    public var dailyReset: DailyResetOption
    public var hasCompletedOnboarding: Bool
    public var appearance: Appearance

    public init(
        trackedApps: [TrackedApp] = [],
        baseline: Baseline? = nil,
        dailyReset: DailyResetOption = .midnight,
        hasCompletedOnboarding: Bool = false,
        appearance: Appearance = .system
    ) {
        self.trackedApps = trackedApps
        self.baseline = baseline
        self.dailyReset = dailyReset
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.appearance = appearance
    }

    public static let defaultTrackedAppNames = ["Instagram", "TikTok", "X", "Threads", "YouTube Shorts", "Reddit", "Facebook"]
}

public enum WastedTimeCalculator {
    public static func annualizedWastedMinutes(dailyUsageMinutes: Int, limitDailyMinutes: Int) -> Int {
        let excess = max(0, dailyUsageMinutes - limitDailyMinutes)
        return excess * 365
    }

    public static func annualizedWastedHours(dailyUsageMinutes: Int, limitDailyMinutes: Int) -> Double {
        Double(annualizedWastedMinutes(dailyUsageMinutes: dailyUsageMinutes, limitDailyMinutes: limitDailyMinutes)) / 60.0
    }
}
