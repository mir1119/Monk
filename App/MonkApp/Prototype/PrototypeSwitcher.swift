import SwiftUI

enum PrototypeVariant: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    var label: String {
        switch self {
        case .a: return "A — Minimal Zen"
        case .b: return "B — Dense Stats"
        case .c: return "C — Timeline Focus"
        }
    }
}

struct PrototypeSwitcher: View {
    @Binding var variant: PrototypeVariant
    var body: some View {
        HStack(spacing: 12) {
            Button { variant = prev(variant) } label: { Image(systemName: "chevron.left").font(.headline) }
            Text(variant.label).font(.caption.bold()).lineLimit(1)
            Button { variant = next(variant) } label: { Image(systemName: "chevron.right").font(.headline) }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 8)
        .padding(.bottom, 12)
    }
    private func prev(_ v: PrototypeVariant) -> PrototypeVariant {
        let all = PrototypeVariant.allCases; let i = all.firstIndex(of: v)!; return all[(i - 1 + all.count) % all.count]
    }
    private func next(_ v: PrototypeVariant) -> PrototypeVariant {
        let all = PrototypeVariant.allCases; let i = all.firstIndex(of: v)!; return all[(i + 1) % all.count]
    }
}
