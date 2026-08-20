import SwiftUI
import MonkCore

struct BlockOverlayView: View {
    let appName: String
    let block: BlockType
    let canEmergency: Bool
    var onEmergency: () -> Void
    var onAlternative: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("\(appName) is blocked").font(.title2.bold())
            switch block {
            case .cooldown(let s): Text("Cooldown: \(s/60)m \(s%60)s remaining").font(.headline)
            case .dailyLocked: Text("Daily limit reached — unlocks at next Daily Reset").font(.headline)
            case .none: Text("You are good to go.").foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button("Take a walk") { onAlternative("walk") }
                Button("Breathe 1 min") { onAlternative("breathe") }
                Button("View tasks") { onAlternative("tasks") }
            }.buttonStyle(.bordered)
            if canEmergency {
                Button("Emergency unlock 5 min (1/day)") { onEmergency() }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("Emergency unlock used today").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
