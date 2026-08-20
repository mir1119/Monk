import Foundation

public struct BlockAppState: Codable, Sendable, Equatable {
    public var cooldownUntil: Date?
    public var dailyLockedUntil: Date?
    public var emergencyUnlockUntil: Date?
    public var emergencyUsedDay: String?

    public init(cooldownUntil: Date? = nil, dailyLockedUntil: Date? = nil, emergencyUnlockUntil: Date? = nil, emergencyUsedDay: String? = nil) {
        self.cooldownUntil = cooldownUntil; self.dailyLockedUntil = dailyLockedUntil
        self.emergencyUnlockUntil = emergencyUnlockUntil; self.emergencyUsedDay = emergencyUsedDay
    }
}

public final class BlockStateStore: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601; enc.outputFormatting = [.prettyPrinted, .sortedKeys]; self.encoder = enc
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601; self.decoder = dec
    }

    public static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Monk/block-state.json", isDirectory: false)
    }

    public func loadAll() -> [String: BlockAppState] {
        guard let data = try? Data(contentsOf: fileURL),
              let d = try? decoder.decode([String: BlockAppState].self, from: data) else { return [:] }
        return d
    }

    public func load(appId: UUID) -> BlockAppState { loadAll()[appId.uuidString] ?? BlockAppState() }

    public func save(appId: UUID, state: BlockAppState) throws {
        var all = loadAll(); all[appId.uuidString] = state
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try encoder.encode(all).write(to: fileURL, options: [.atomic])
    }

    public func triggerCooldown(appId: UUID, now: Date = Date()) throws {
        var s = load(appId: appId); s.cooldownUntil = now.addingTimeInterval(3600); try save(appId: appId, state: s)
    }

    public func triggerDailyLock(appId: UUID, until: Date) throws {
        var s = load(appId: appId); s.dailyLockedUntil = until; try save(appId: appId, state: s)
    }

    public func canEmergencyUnlock(appId: UUID, now: Date = Date()) -> Bool {
        let s = load(appId: appId)
        let day = dayString(now)
        if s.emergencyUsedDay == day { return false }
        return true
    }

    @discardableResult
    public func useEmergencyUnlock(appId: UUID, now: Date = Date()) throws -> Bool {
        guard canEmergencyUnlock(appId: appId, now: now) else { return false }
        var s = load(appId: appId)
        s.emergencyUnlockUntil = now.addingTimeInterval(300)
        s.emergencyUsedDay = dayString(now)
        try save(appId: appId, state: s)
        return true
    }

    public func isInEmergencyUnlock(appId: UUID, now: Date = Date()) -> Bool {
        guard let until = load(appId: appId).emergencyUnlockUntil else { return false }
        return now < until
    }

    public func cleanupExpired(now: Date = Date()) throws {
        var all = loadAll()
        for (k, v) in all {
            var s = v
            if let u = s.cooldownUntil, now >= u { s.cooldownUntil = nil }
            if let u = s.dailyLockedUntil, now >= u { s.dailyLockedUntil = nil }
            if let u = s.emergencyUnlockUntil, now >= u { s.emergencyUnlockUntil = nil }
            all[k] = s
        }
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try encoder.encode(all).write(to: fileURL, options: [.atomic])
    }

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = TimeZone.current; return f.string(from: date)
    }
}
