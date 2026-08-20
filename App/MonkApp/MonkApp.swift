import SwiftUI
import MonkCore

@main
struct MonkApp: App {
    @State private var state = MonkStore(fileURL: MonkStore.defaultStoreURL()).load()

    var body: some Scene {
        WindowGroup {
            ContentView(state: $state)
                .preferredColorScheme(state.appearance.colorScheme)
                .tint(.monkPrimary)
        }
    }
}

struct ContentView: View {
    @Binding var state: MonkState
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                if state.hasCompletedOnboarding {
                    DashboardView(state: $state)
                } else {
                    OnboardingView(state: $state)
                }
            }
            .tabItem { Label("Monk", systemImage: "house.fill") }.tag(0)

            NavigationStack {
                SettingsView(state: $state)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }.tag(1)

            #if DEBUG
            NavigationStack {
                PrototypeDashboardView()
            }
            .tabItem { Label("Prototype", systemImage: "sparkles.rectangle.stack") }.tag(2)
            #endif
        }
    }
}
