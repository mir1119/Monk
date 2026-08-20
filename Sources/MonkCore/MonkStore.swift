import Foundation

public final class MonkStore: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    public static func defaultStoreURL() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("Monk/monk-state.json", isDirectory: false)
    }

    public func load() -> MonkState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return MonkState() }
        guard let data = try? Data(contentsOf: fileURL) else { return MonkState() }
        guard let state = try? decoder.decode(MonkState.self, from: data) else { return MonkState() }
        return state
    }

    public func save(_ state: MonkState) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }

    public var privacyCopy: String { "All data is stored locally on-device. No account, no cloud." }
}
