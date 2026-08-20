import Foundation

public struct AppUsage: Sendable, Equatable {
    public var trackedAppId: UUID
    public var todayMinutes: Int
    public var currentSessionMinutes: Int
    public var mode: TrackingMode

    public init(trackedAppId: UUID, todayMinutes: Int, currentSessionMinutes: Int, mode: TrackingMode) {
        self.trackedAppId = trackedAppId
        self.todayMinutes = todayMinutes
        self.currentSessionMinutes = currentSessionMinutes
        self.mode = mode
    }
}

public enum TrackingMode: String, Sendable, Equatable {
    case system
    case local
}

public protocol UsageSource: Sendable {
    func todayMinutes(for app: TrackedApp) -> Int?
    func currentSessionMinutes(for app: TrackedApp) -> Int?
}

public struct LocalUsageStore: Sendable {
    private let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Monk/local-usage.json", isDirectory: false)
    }

    public func record(appId: UUID, todayMinutes: Int, sessionMinutes: Int) throws {
        var dict = loadRaw()
        dict[appId.uuidString] = ["today": todayMinutes, "session": sessionMinutes]
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: fileURL, options: [.atomic])
    }

    public func todayMinutes(for appId: UUID) -> Int? { (loadRaw()[appId.uuidString] as? [String: Int])?["today"] }
    public func sessionMinutes(for appId: UUID) -> Int? { (loadRaw()[appId.uuidString] as? [String: Int])?["session"] }

    private func loadRaw() -> [String: Any] {
        guard let data = try? Data(contentsOf: fileURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return obj
    }
}

public struct LocalUsageSource: UsageSource {
    let store: LocalUsageStore
    public init(store: LocalUsageStore) { self.store = store }
    public func todayMinutes(for app: TrackedApp) -> Int? { store.todayMinutes(for: app.id) }
    public func currentSessionMinutes(for app: TrackedApp) -> Int? { store.sessionMinutes(for: app.id) }
}

public struct SystemUsageSourceStub: UsageSource {
    let authorized: Bool
    var values: [UUID: (today: Int, session: Int)]
    public init(authorized: Bool, values: [UUID: (today: Int, session: Int)] = [:]) {
        self.authorized = authorized; self.values = values
    }
    public func todayMinutes(for app: TrackedApp) -> Int? { guard authorized else { return nil }; return values[app.id]?.today }
    public func currentSessionMinutes(for app: TrackedApp) -> Int? { guard authorized else { return nil }; return values[app.id]?.session }
}

public struct UsageTrackingAdapter: Sendable {
    let systemSource: any UsageSource
    let localSource: any UsageSource

    public init(systemSource: any UsageSource, localSource: any UsageSource) {
        self.systemSource = systemSource
        self.localSource = localSource
    }

    public static func `default`() -> UsageTrackingAdapter {
        UsageTrackingAdapter(systemSource: SystemUsageSourceStub(authorized: false), localSource: LocalUsageSource(store: LocalUsageStore(fileURL: LocalUsageStore.defaultURL())))
    }

    public func usage(for app: TrackedApp) -> AppUsage {
        if let today = systemSource.todayMinutes(for: app), let session = systemSource.currentSessionMinutes(for: app) {
            return AppUsage(trackedAppId: app.id, todayMinutes: today, currentSessionMinutes: session, mode: .system)
        }
        let today = localSource.todayMinutes(for: app) ?? 0
        let session = localSource.currentSessionMinutes(for: app) ?? 0
        return AppUsage(trackedAppId: app.id, todayMinutes: today, currentSessionMinutes: session, mode: .local)
    }

    public var permissionCopy: String {
        "Monk needs Screen Time permission (FamilyControls / DeviceActivity) for system-level tracking. Without it, local self-report mode keeps working. Request at onboarding and first block."
    }
}
