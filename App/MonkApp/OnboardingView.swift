import SwiftUI
import MonkCore

struct OnboardingView: View {
    @Binding var state: MonkState
    private let store: MonkStore
    @State private var step = 0
    @State private var draft = OnboardingDraft(inputs: MonkState.defaultTrackedAppNames.map { OnboardingInput(appName: $0, dailyUsageMinutes: 30, preset: .standard) })

    init(state: Binding<MonkState>) {
        self._state = state
        self.store = MonkStore(fileURL: MonkStore.defaultStoreURL())
    }

    var body: some View {
        VStack {
            switch step {
            case 0: introStep
            case 1: usageStep
            case 2: wastedStep
            case 3: limitStep
            default: introStep
            }
        }
        .padding()
        .navigationTitle("Monk Mode")
    }

    private var introStep: some View {
        VStack(spacing: 16) {
            Text("Monk Mode").font(.largeTitle.bold())
            Text("Live like a monk — strict limits on dopamine intake to reclaim Free Time.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Text(store.privacyCopy).font(.footnote).foregroundStyle(.secondary)
            Button("Continue") { step = 1 }
                .buttonStyle(.borderedProminent)
        }
    }

    private var usageStep: some View {
        VStack {
            Text("How much do you use each app per day?").font(.headline)
            List {
                ForEach($draft.inputs, id: \.appName) { $input in
                    HStack {
                        Text(input.appName)
                        Spacer()
                        TextField("min", value: $input.dailyUsageMinutes, format: .number)
                            .frame(width: 80).textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Text("min")
                    }
                }
            }
            Button("Next") { step = 2 }.buttonStyle(.borderedProminent).disabled(draft.inputs.contains { $0.dailyUsageMinutes < 0 })
        }
    }

    private var wastedStep: some View {
        VStack(spacing: 12) {
            Text("Your annualized Wasted Time").font(.headline)
            ForEach(draft.wastedTimeReport(), id: \.appName) { entry in
                HStack {
                    Text(entry.appName)
                    Spacer()
                    Text(entry.isWasting ? String(format: "%.1f h/year", entry.annualizedWastedHours) : "—")
                        .foregroundStyle(entry.isWasting ? .red : .secondary)
                }
            }
            Text(String(format: "Total: %.1f h/year", Double(draft.totalAnnualizedWastedMinutes()) / 60.0))
                .font(.headline)
            Button("Choose Limits") { step = 3 }.buttonStyle(.borderedProminent)
        }
    }

    private var limitStep: some View {
        VStack {
            Text("Choose a Limit for each app").font(.headline)
            List {
                ForEach($draft.inputs, id: \.appName) { $input in
                    VStack(alignment: .leading) {
                        Text(input.appName).font(.subheadline.bold())
                        Picker("Preset", selection: Binding(get: { input.preset ?? .standard }, set: { input.preset = $0; input.customLimit = nil })) {
                            Text("Light 60/20").tag(LimitPreset.light)
                            Text("Standard 30/15").tag(LimitPreset.standard)
                            Text("Strict 15/10").tag(LimitPreset.strict)
                        }.pickerStyle(.segmented)
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
}
