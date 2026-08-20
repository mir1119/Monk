import SwiftUI
import MonkCore

@main
struct MonkApp: App {
    @State private var state = MonkStore(fileURL: MonkStore.defaultStoreURL()).load()

    var body: some Scene {
        WindowGroup {
            ContentView(state: $state)
        }
    }
}

struct ContentView: View {
    @Binding var state: MonkState

    var body: some View {
        NavigationStack {
            if state.hasCompletedOnboarding {
                DashboardPlaceholder(state: state)
            } else {
                OnboardingPlaceholder()
            }
        }
    }
}

struct OnboardingPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Monk Mode").font(.largeTitle.bold())
            Text("Live like a monk — reduce dopamine intake and reclaim Free Time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Local-only. \(MonkStore(fileURL: MonkStore.defaultStoreURL()).privacyCopy)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct DashboardPlaceholder: View {
    let state: MonkState
    var body: some View {
        List {
            Section("Tracked Apps") {
                ForEach(state.trackedApps) { app in
                    HStack {
                        Text(app.displayName)
                        Spacer()
                        Text("\(app.limit.dailyTotalMinutes)m / \(app.limit.singleSessionMinutes)m")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Privacy") {
                Text(MonkStore(fileURL: MonkStore.defaultStoreURL()).privacyCopy)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Monk")
    }
}
