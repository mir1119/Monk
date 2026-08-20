import SwiftUI
import MonkCore

extension Color {
    static let monkPrimary = Color(red: 0.42, green: 0.28, blue: 0.92)
    static let monkPrimaryLight = Color(red: 0.58, green: 0.44, blue: 0.96)
    static let monkAccent = Color(red: 0.72, green: 0.52, blue: 1.0)
    static let monkGrid = Color.white.opacity(0.06)
    static let monkHairline = Color.white.opacity(0.12)
}

extension Font {
    static func monkDisplay(size: CGFloat) -> Font { .custom("Inconsolata", size: size).weight(.black) }
    static func monkMono(size: CGFloat) -> Font { .custom("Inconsolata", size: size) }
    static func monkMonoBold(size: CGFloat) -> Font { .custom("Inconsolata", size: size).weight(.semibold) }
    static func monkMonoLight(size: CGFloat) -> Font { .custom("Inconsolata", size: size).weight(.light) }
}

struct ParticleField: View {
    var count = 22
    @State private var t: CGFloat = 0
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let time = tl.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let seed = Double(i) * 1.37
                    let x = fmod(time * 8 + seed * 73, Double(size.width))
                    let y = fmod(Double(i) * 29 + sin(time * 0.6 + seed) * 12 + Double(size.height) * (Double(i)/Double(count)), Double(size.height))
                    let alpha = 0.18 + 0.12 * sin(time + seed)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(Color.monkPrimary.opacity(alpha)))
                }
                for i in 0..<(count/2) {
                    let seed = Double(i) * 2.1
                    let x = fmod(time * -6 + seed * 91, Double(size.width))
                    let y = fmod(Double(i) * 53 + cos(time * 0.4 + seed) * 10, Double(size.height))
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(Color.white.opacity(0.08)))
                }
            }
        }
        .allowsHitTesting(false)
        .opacity(0.9)
    }
}

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
