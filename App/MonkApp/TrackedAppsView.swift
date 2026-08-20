import SwiftUI
import MonkCore

struct TrackedAppsView: View {
    @Binding var state: MonkState
    private var manager: TrackedAppManager { TrackedAppManager(store: MonkStore(fileURL: MonkStore.defaultStoreURL())) }
    @State private var newName = ""
    @State private var error: String?

    var body: some View {
        List {
            Section("Tracked Apps") {
                ForEach(state.trackedApps) { app in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(app.displayName)
                            Text("\(app.limit.dailyTotalMinutes)m daily / \(app.limit.singleSessionMinutes)m session")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu("Limit") {
                            Button("Light 60/20") { applyPreset(.light, id: app.id) }
                            Button("Standard 30/15") { applyPreset(.standard, id: app.id) }
                            Button("Strict 15/10") { applyPreset(.strict, id: app.id) }
                        }
                    }
                }
                .onDelete { idx in
                    for i in idx { try? remove(state.trackedApps[i].id) }
                }
            }
            Section("Add Custom") {
                HStack {
                    TextField("App name", text: $newName)
                    Button("Add") { add() }.disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let error { Text(error).font(.caption).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Tracked Apps")
    }

    private func add() {
        error = nil
        do { state = try manager.add(displayName: newName, limit: .preset(.standard), isCustom: true); newName = "" }
        catch TrackedAppError.duplicateName { error = "Already exists." }
        catch let err { error = err.localizedDescription }
    }
    private func remove(_ id: UUID) throws { state = try manager.remove(id: id) }
    private func applyPreset(_ p: LimitPreset, id: UUID) { if let s = try? manager.updateLimitPreset(id: id, preset: p) { state = s } }
}
