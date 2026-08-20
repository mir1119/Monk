import Foundation
import MonkCore

@Observable
final class DemoState {
    struct SimApp: Identifiable {
        var id = UUID()
        var name: String
        var todayMinutes: Int
        var sessionMinutes: Int
        var limit: AppLimit
        var blockState = BlockAppState()
    }

    var apps: [SimApp] = [
        .init(name: "Instagram", todayMinutes: 18, sessionMinutes: 8, limit: .preset(.standard)),
        .init(name: "TikTok", todayMinutes: 24, sessionMinutes: 13, limit: .preset(.standard)),
        .init(name: "YouTube Shorts", todayMinutes: 8, sessionMinutes: 3, limit: .preset(.light)),
        .init(name: "X", todayMinutes: 30, sessionMinutes: 2, limit: .preset(.standard)),
    ]
    var baseline: Baseline = Baseline(dailyMinutesByApp: ["Instagram": 55, "TikTok": 50, "YouTube Shorts": 30, "X": 25])
    var thisWeekTotal = 420
    var lastWeekTotal = 620
    var last7Days: [DailyUsage] = (0..<7).map { i in DailyUsage(date: Date().addingTimeInterval(Double(-6+i)*86400), minutes: [58, 72, 45, 80, 62, 55, 48][i]) }

    var now = Date()

    func tick() { now = Date() }

    func addMinutes(appIndex: Int, delta: Int) {
        apps[appIndex].todayMinutes = max(0, min(1440, apps[appIndex].todayMinutes + delta))
        apps[appIndex].sessionMinutes = max(0, min(1440, apps[appIndex].sessionMinutes + delta))
    }

    func resetSession(appIndex: Int) { apps[appIndex].sessionMinutes = 0 }

    func triggerCooldown(appIndex: Int) {
        apps[appIndex].blockState.cooldownUntil = now.addingTimeInterval(3600)
    }

    func triggerDailyLock(appIndex: Int) {
        apps[appIndex].blockState.dailyLockedUntil = now.addingTimeInterval(3600*8)
    }

    func emergencyUnlock(appIndex: Int) -> Bool {
        let day = dayString(now)
        if apps[appIndex].blockState.emergencyUsedDay == day { return false }
        apps[appIndex].blockState.emergencyUnlockUntil = now.addingTimeInterval(300)
        apps[appIndex].blockState.emergencyUsedDay = day
        return true
    }

    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat="yyyy-MM-dd"; f.timeZone = .current; return f.string(from: d)
    }

    var freeVsBaseline: Int { max(0, (baseline.dailyMinutesByApp.values.reduce(0,+) * 7) - thisWeekTotal) }
    var freeVsLastWeek: Int { max(0, lastWeekTotal - thisWeekTotal) }

    func decision(for sim: SimApp) -> BlockDecision {
        let tracked = TrackedApp(displayName: sim.name, limit: sim.limit, isCustom: false)
        return BlockEngine().decide(app: tracked, todayMinutes: sim.todayMinutes, sessionMinutes: sim.sessionMinutes, cooldownUntil: sim.blockState.cooldownUntil, dailyLockedUntil: sim.blockState.dailyLockedUntil, emergencyUnlockUntil: sim.blockState.emergencyUnlockUntil, now: now)
    }
}
