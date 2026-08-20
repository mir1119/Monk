import SwiftUI
import MonkCore

struct OnboardingView: View {
    @Binding var state: MonkState
    private let store: MonkStore
    @State private var step = 0
    @State private var showWelcome = true
    @State private var draft = OnboardingDraft(inputs: MonkState.defaultTrackedAppNames.map { OnboardingInput(appName: $0, dailyUsageMinutes: 30, preset: .standard) })

    init(state: Binding<MonkState>) {
        self._state = state
        self.store = MonkStore(fileURL: MonkStore.defaultStoreURL())
    }

    var body: some View {
        Group {
            if showWelcome {
                WelcomeView { withAnimation { showWelcome = false } }
            } else {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    ParticleField(count: 16).ignoresSafeArea().opacity(0.6)
                    VStack {
                        switch step {
                        case 0: usageStep
                        case 1: wastedStep
                        case 2: limitStep
                        default: usageStep
                        }
                    }
                    .padding()
                }
                .navigationTitle("Monk Mode")
            }
        }
    }

    private var usageStep: some View {
        VStack(spacing: 12) {
            Text("DAILY USAGE // PER APP").font(.monkMonoBold(size: 13)).tracking(1)
            Text("SLIDE TO SET CURRENT DAILY USAGE").font(.monkMono(size: 9)).foregroundStyle(.secondary).tracking(1)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach($draft.inputs, id: \.appName) { $input in
                        HStack(spacing: 12) {
                            AppIcon.view(for: input.appName)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(input.appName).font(.subheadline.bold())
                                    Spacer()
                                    Text("\(input.dailyUsageMinutes) min/day").font(.caption.bold().monospacedDigit())
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.14), in: Capsule())
                                }
                                Slider(value: Binding(
                                    get: { Double(input.dailyUsageMinutes) },
                                    set: { input.dailyUsageMinutes = Int($0) }
                                ), in: 0...180, step: 5)
                                .tint(sliderTint(for: input.dailyUsageMinutes))
                                HStack {
                                    Text("0m").font(.caption2).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("3h").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.vertical, 4)
            }
            Button("See yearly cost") { step = 2 }.buttonStyle(.borderedProminent)
        }
    }

    private var wastedStep: some View {
        VStack(spacing: 12) {
            Text("ANNUALIZED WASTED TIME").font(.monkMonoBold(size: 13)).tracking(1)
            Text("VS CHOSEN LIMIT — EXCESS × 365").font(.monkMono(size: 9)).foregroundStyle(.secondary).tracking(1)
            ForEach(draft.wastedTimeReport(), id: \.appName) { entry in
                HStack(spacing: 10) {
                    AppIcon.view(for: entry.appName)
                    Text(entry.appName).font(.subheadline)
                    Spacer()
                    Text(entry.isWasting ? String(format: "%.1f h/year", entry.annualizedWastedHours) : "—")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(entry.isWasting ? .red : .secondary)
                }
                .padding(8).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
            Text(String(format: "Total: %.1f h/year", Double(draft.totalAnnualizedWastedMinutes()) / 60.0))
                .font(.headline)
            Button("Choose Limits") { step = 3 }.buttonStyle(.borderedProminent)
        }
    }

    private var limitStep: some View {
        VStack(spacing: 12) {
            Text("DAILY LIMIT // PER APP").font(.monkMonoBold(size: 13)).tracking(1)
            Text("PICK A PRESET OR FINE-TUNE PER APP").font(.monkMono(size: 9)).foregroundStyle(.secondary).tracking(1)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach($draft.inputs, id: \.appName) { $input in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                AppIcon.view(for: input.appName)
                                Text(input.appName).font(.subheadline.bold())
                                Spacer()
                                Text("\((input.effectiveLimit ?? .preset(.standard)).dailyTotalMinutes) min/day").font(.caption.bold().monospacedDigit())
                            }
                            Slider(value: Binding(
                                get: { Double((input.effectiveLimit ?? .preset(.standard)).dailyTotalMinutes) },
                                set: { input.customLimit = AppLimit(dailyTotalMinutes: Int($0), singleSessionMinutes: max(5, Int($0/2))) ; input.preset = nil }
                            ), in: 5...120, step: 5)
                            .tint(.monkPrimary)
                            Picker("Preset", selection: Binding(get: { input.preset ?? .standard }, set: { input.preset = $0; input.customLimit = nil })) {
                                Text("Light 60/20").tag(LimitPreset.light)
                                Text("Standard 30/15").tag(LimitPreset.standard)
                                Text("Strict 15/10").tag(LimitPreset.strict)
                            }.pickerStyle(.segmented)
                            if input.customLimit != nil {
                                Text("Custom \(input.customLimit!.dailyTotalMinutes)m / \(input.customLimit!.singleSessionMinutes)m").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .padding(12).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            Button("Start Monk Mode") {
                if let completed = try? OnboardingCompletion.complete(draft: draft, store: store) {
                    state = completed
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!draft.isValid)
        }
    }

    private func sliderTint(for minutes: Int) -> Color {
        if minutes >= 90 { return .red }
        if minutes >= 45 { return .orange }
        return .monkPrimary
    }
}
