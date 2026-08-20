import Foundation

public enum NotificationKind: String, Sendable, Equatable {
    case daily80Percent
    case sessionPreCooldown
    case eveningSummary
}

public struct ScheduledNotification: Sendable, Equatable {
    public var kind: NotificationKind
    public var title: String
    public var body: String
    public init(kind: NotificationKind, title: String, body: String) { self.kind = kind; self.title = title; self.body = body }
}

public struct NotificationScheduler: Sendable {
    public init() {}

    public func notifications(
        usages: [UUID: AppUsage],
        trackedApps: [TrackedApp],
        freeMinutesToday: Int
    ) -> [ScheduledNotification] {
        var out: [ScheduledNotification] = []
        let engine = BlockEngine()
        for app in trackedApps {
            guard let u = usages[app.id] else { continue }
            if engine.isNearingDailyLimit(todayMinutes: u.todayMinutes, limit: app.limit.dailyTotalMinutes) {
                out.append(ScheduledNotification(kind: .daily80Percent, title: "\(app.displayName) 80% used", body: "You have used 80% of today's Limit."))
            }
            if engine.isNearingSessionCooldown(sessionMinutes: u.currentSessionMinutes, limit: app.limit.singleSessionMinutes) {
                out.append(ScheduledNotification(kind: .sessionPreCooldown, title: "\(app.displayName) almost at session Limit", body: "2 minutes until cooldown. Consider pausing now."))
            }
        }
        if freeMinutesToday > 0 {
            out.append(ScheduledNotification(kind: .eveningSummary, title: "Today you saved \(freeMinutesToday) min", body: "Free Time reclaimed vs Baseline."))
        }
        return out
    }
}
