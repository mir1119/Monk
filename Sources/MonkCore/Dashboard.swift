import Foundation

public struct DailyUsage: Sendable, Equatable {
    public var date: Date
    public var minutes: Int
    public init(date: Date, minutes: Int) { self.date = date; self.minutes = minutes }
}

public struct DashboardData: Sendable, Equatable {
    public var weeklyFreeMinutes: Int
    public var freeVsBaseline: Int
    public var freeVsLastWeek: Int
    public var todayRemainingByApp: [UUID: Int]
    public var last7Days: [DailyUsage]
    public var blockedStates: [UUID: BlockType]
}

public struct DashboardCalculator: Sendable {
    public init() {}

    public func weeklyFreeMinutes(baseline: Baseline?, thisWeekTotal: Int, lastWeekTotal: Int?) -> (freeVsBaseline: Int, freeVsLastWeek: Int, weeklyFree: Int) {
        let baselineWeekly = (baseline?.dailyMinutesByApp.values.reduce(0, +) ?? 0) * 7
        let freeVsBaseline = max(0, baselineWeekly - thisWeekTotal)
        let freeVsLastWeek = lastWeekTotal.map { max(0, $0 - thisWeekTotal) } ?? 0
        return (freeVsBaseline, freeVsLastWeek, freeVsBaseline)
    }

    public func todayRemaining(app: TrackedApp, todayMinutes: Int) -> Int {
        max(0, app.limit.dailyTotalMinutes - todayMinutes)
    }

    public func build(
        trackedApps: [TrackedApp],
        usages: [UUID: AppUsage],
        baseline: Baseline?,
        thisWeekTotal: Int,
        lastWeekTotal: Int?,
        last7Days: [DailyUsage],
        now: Date = Date(),
        blockStates: [UUID: BlockAppState] = [:]
    ) -> DashboardData {
        let engine = BlockEngine()
        var remaining: [UUID: Int] = [:]
        var blocked: [UUID: BlockType] = [:]
        for app in trackedApps {
            let u = usages[app.id]
            remaining[app.id] = todayRemaining(app: app, todayMinutes: u?.todayMinutes ?? 0)
            let s = blockStates[app.id] ?? BlockAppState()
            let dec = engine.decide(app: app, todayMinutes: u?.todayMinutes ?? 0, sessionMinutes: u?.currentSessionMinutes ?? 0, cooldownUntil: s.cooldownUntil, dailyLockedUntil: s.dailyLockedUntil, emergencyUnlockUntil: s.emergencyUnlockUntil, now: now)
            blocked[app.id] = dec.block
        }
        let (vsBase, vsLast, weekly) = weeklyFreeMinutes(baseline: baseline, thisWeekTotal: thisWeekTotal, lastWeekTotal: lastWeekTotal)
        return DashboardData(weeklyFreeMinutes: weekly, freeVsBaseline: vsBase, freeVsLastWeek: vsLast, todayRemainingByApp: remaining, last7Days: last7Days, blockedStates: blocked)
    }
}
