import Foundation

public enum BlockType: Sendable, Equatable {
    case none
    case cooldown(remainingSeconds: Int)
    case dailyLocked(untilReset: Date)
}

public enum DailyLimitState: Sendable, Equatable {
    case under
    case atOrOver
}

public struct BlockDecision: Sendable, Equatable {
    public var block: BlockType
    public var isInEmergencyUnlock: Bool
    public init(block: BlockType, isInEmergencyUnlock: Bool = false) {
        self.block = block; self.isInEmergencyUnlock = isInEmergencyUnlock
    }
    public var isBlocked: Bool {
        if isInEmergencyUnlock { return false }
        switch block { case .none: return false; default: return true }
    }
}

public struct BlockEngine: Sendable {
    public init() {}

    public func decide(
        app: TrackedApp,
        todayMinutes: Int,
        sessionMinutes: Int,
        cooldownUntil: Date?,
        dailyLockedUntil: Date?,
        emergencyUnlockUntil: Date?,
        now: Date = Date()
    ) -> BlockDecision {
        if let until = emergencyUnlockUntil, now < until {
            return BlockDecision(block: .none, isInEmergencyUnlock: true)
        }
        if let until = cooldownUntil, now < until {
            let rem = Int(until.timeIntervalSince(now).rounded(.up))
            return BlockDecision(block: .cooldown(remainingSeconds: max(1, rem)))
        }
        if let until = dailyLockedUntil, now < until {
            return BlockDecision(block: .dailyLocked(untilReset: until))
        }
        if sessionMinutes >= app.limit.singleSessionMinutes {
            let until = now.addingTimeInterval(3600)
            return BlockDecision(block: .cooldown(remainingSeconds: 3600))
        }
        if todayMinutes >= app.limit.dailyTotalMinutes {
            let until = nextDailyReset(after: now, option: .midnight)
            return BlockDecision(block: .dailyLocked(untilReset: until))
        }
        return BlockDecision(block: .none)
    }

    public func nextDailyReset(after date: Date, option: DailyResetOption) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = option.hour; comps.minute = 0; comps.second = 0
        guard let todayReset = cal.date(from: comps) else { return date.addingTimeInterval(86400) }
        if date < todayReset { return todayReset }
        return cal.date(byAdding: .day, value: 1, to: todayReset) ?? date.addingTimeInterval(86400)
    }

    public func isNearingDailyLimit(todayMinutes: Int, limit: Int) -> Bool {
        guard limit > 0 else { return false }
        return Double(todayMinutes) >= Double(limit) * 0.8 && todayMinutes < limit
    }

    public func isNearingSessionCooldown(sessionMinutes: Int, limit: Int) -> Bool {
        guard limit > 2 else { return false }
        return sessionMinutes >= limit - 2 && sessionMinutes < limit
    }
}
