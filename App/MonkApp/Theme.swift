import SwiftUI
import MonkCore

extension Appearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct AppearancePicker: View {
    @Binding var state: MonkState
    private var store: MonkStore { MonkStore(fileURL: MonkStore.defaultStoreURL()) }
    var body: some View {
        Picker("Appearance", selection: Binding(
            get: { state.appearance },
            set: { new in
                state.appearance = new
                try? store.save(state)
            }
        )) {
            Text("System").tag(Appearance.system)
            Text("Light").tag(Appearance.light)
            Text("Dark").tag(Appearance.dark)
        }
        .pickerStyle(.segmented)
    }
}
