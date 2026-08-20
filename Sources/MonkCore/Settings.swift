import Foundation

public struct SettingsManager: Sendable {
    private let store: MonkStore
    public init(store: MonkStore) { self.store = store }

    public func updateDailyReset(_ option: DailyResetOption) throws -> MonkState {
        var s = store.load(); s.dailyReset = option; try store.save(s); return s
    }

    public func addTrackedApp(displayName: String, limit: AppLimit, isCustom: Bool = true) throws -> MonkState {
        try TrackedAppManager(store: store).add(displayName: displayName, limit: limit, isCustom: isCustom)
    }

    public func removeTrackedApp(id: UUID) throws -> MonkState {
        try TrackedAppManager(store: store).remove(id: id)
    }

    public func updateLimit(id: UUID, limit: AppLimit) throws -> MonkState {
        try TrackedAppManager(store: store).updateLimit(id: id, limit: limit)
    }
}
