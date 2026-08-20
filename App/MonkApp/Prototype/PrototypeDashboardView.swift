import SwiftUI
import MonkCore

// PROTOTYPE — throwaway, answers "what should polished dashboard + demo blocking look like?"
// Three variants on the same data, switchable via segment + floating bar. Demo simulation below lets you verify Hard Block without installing target apps.

struct PrototypeDashboardView: View {
    @State private var variant: PrototypeVariant = .a
    @State private var demo = DemoState()
    @State private var showBlock: SimBlock?
    @State private var ticker: Timer?

    struct SimBlock: Identifiable { var id = UUID(); var appIndex: Int; var block: BlockType }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Picker("Variant", selection: $variant) {
                    Text("A Zen").tag(PrototypeVariant.a)
                    Text("B Dense").tag(PrototypeVariant.b)
                    Text("C Timeline").tag(PrototypeVariant.c)
                }.pickerStyle(.segmented).padding(.horizontal).padding(.top, 8)

                Group {
                    switch variant {
                    case .a: VariantA(demo: demo)
                    case .b: VariantB(demo: demo)
                    case .c: VariantC(demo: demo)
                    }
                }
                .animation(.easeInOut, value: variant)

                demoPanel

                PrototypeSwitcher(variant: $variant)
            }

            if let sb = showBlock {
                let app = demo.apps[sb.appIndex]
                BlockOverlayView(appName: app.name, block: sb.block, canEmergency: demo.apps[sb.appIndex].blockState.emergencyUsedDay != dayString(demo.now)) {
                    if demo.emergencyUnlock(appIndex: sb.appIndex) { showBlock = nil }
                } onAlternative: { _ in showBlock = nil }
                .transition(.opacity)
            }
        }
        .navigationTitle("Prototype — Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in demo.tick() } }
        .onDisappear { ticker?.invalidate() }
    }

    private var demoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Demo simulation — adjust usage to trigger Hard Block").font(.caption.bold()).foregroundStyle(.secondary)
            ForEach(Array(demo.apps.enumerated()), id: \.element.id) { idx, app in
                let dec = demo.decision(for: app)
                HStack(spacing: 8) {
                    Text(app.name).font(.caption.bold()).frame(width: 90, alignment: .leading)
                    Stepper("", value: Binding(get: { app.todayMinutes }, set: { demo.apps[idx].todayMinutes = $0 }), in: 0...120, step: 5)
                        .labelsHidden().scaleEffect(0.8).frame(width: 70)
                    Text("\(app.todayMinutes)m").font(.caption2.monospacedDigit()).frame(width: 40)
                    Button("Session +2") { demo.addMinutes(appIndex: idx, delta: 2); checkBlock(idx: idx) }.font(.caption2)
                    if dec.isBlocked {
                        Button("Show Block") { showBlock = SimBlock(appIndex: idx, block: dec.block) }.font(.caption2.bold()).tint(.orange)
                    }
                }
                .padding(6).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            HStack(spacing: 8) {
                Button("Trigger cooldown on TikTok") { demo.triggerCooldown(appIndex: 1) }.font(.caption2)
                Button("Daily lock X") { demo.triggerDailyLock(appIndex: 3) }.font(.caption2)
                Button("Reset sessions") { for i in demo.apps.indices { demo.resetSession(appIndex: i) } }.font(.caption2)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    private func checkBlock(idx: Int) {
        let dec = demo.decision(for: demo.apps[idx])
        if dec.isBlocked { showBlock = SimBlock(appIndex: idx, block: dec.block) }
    }

    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat="yyyy-MM-dd"; f.timeZone = .current; return f.string(from: d)
    }
}

private extension BlockDecision { var isBlocked: Bool { if case .none = block { return false }; return true } }
