import SwiftUI
import MonkCore

struct SettingsView: View {
    @Binding var state: MonkState
    var body: some View {
        List {
            Section("Appearance") {
                AppearancePicker(state: $state)
                Text("System follows iOS setting. Light/Dark overrides it.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Tracked Apps") {
                NavigationLink("Manage Apps") { TrackedAppsView(state: $state) }
            }
            Section("Privacy") {
                Text(MonkStore(fileURL: MonkStore.defaultStoreURL()).privacyCopy)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("About") {
                Text("Aurel — Free Time over streaks · Hard Block with 1h cooldown")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
