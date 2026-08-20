import Foundation

public enum TrackedAppError: Error, Equatable {
    case invalidName
    case invalidLimit
    case duplicateName
    case notFound
}

public struct TrackedAppManager: Sendable {
    private let store: MonkStore

    public init(store: MonkStore) {
        self.store = store
    }

    public func list() -> [TrackedApp] { store.load().trackedApps }

    @discardableResult
    public func add(displayName: String, bundleIdentifier: String? = nil, limit: AppLimit, isCustom: Bool) throws -> MonkState {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw TrackedAppError.invalidName }
        guard limit.isValid else { throw TrackedAppError.invalidLimit }
        var state = store.load()
        guard !state.trackedApps.contains(where: { $0.displayName.lowercased() == trimmed.lowercased() }) else {
            throw TrackedAppError.duplicateName
        }
        let app = TrackedApp(displayName: trimmed, bundleIdentifier: bundleIdentifier, limit: limit, isCustom: isCustom)
        state.trackedApps.append(app)
        try store.save(state)
        return state
    }

    @discardableResult
    public func addDefaultsIfNeeded() throws -> MonkState {
        var state = store.load()
        guard state.trackedApps.isEmpty else { return state }
        state.trackedApps = MonkState.defaultTrackedAppNames.map { name in
            TrackedApp(displayName: name, limit: .preset(.standard), isCustom: false)
        }
        try store.save(state)
        return state
    }

    @discardableResult
    public func remove(id: UUID) throws -> MonkState {
        var state = store.load()
        guard let idx = state.trackedApps.firstIndex(where: { $0.id == id }) else { throw TrackedAppError.notFound }
        state.trackedApps.remove(at: idx)
        try store.save(state)
        return state
    }

    @discardableResult
    public func updateLimit(id: UUID, limit: AppLimit) throws -> MonkState {
        guard limit.isValid else { throw TrackedAppError.invalidLimit }
        var state = store.load()
        guard let idx = state.trackedApps.firstIndex(where: { $0.id == id }) else { throw TrackedAppError.notFound }
        state.trackedApps[idx].limit = limit
        try store.save(state)
        return state
    }

    @discardableResult
    public func updateLimitPreset(id: UUID, preset: LimitPreset) throws -> MonkState {
        try updateLimit(id: id, limit: .preset(preset))
    }
}
