import Foundation
import MonkCore

func check(_ name: String, _ condition: Bool) {
    if condition { print("✓ \(name)") } else { print("✗ FAIL: \(name)"); exit(1) }
}

func tempURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("monk-verify-\(UUID().uuidString).json")
}

do {
    let store = MonkStore(fileURL: tempURL())
    let state = store.load()
    check("load returns default when missing", state.trackedApps.isEmpty && state.baseline == nil && state.dailyReset == .midnight && !state.hasCompletedOnboarding)
    let url = tempURL()
    var state2 = MonkState()
    state2.trackedApps = [TrackedApp(displayName: "Instagram", limit: .preset(.standard), isCustom: false)]
    state2.baseline = Baseline(dailyMinutesByApp: ["Instagram": 90], createdAt: Date(timeIntervalSince1970: 0))
    state2.dailyReset = .fourAM
    state2.hasCompletedOnboarding = true
    try MonkStore(fileURL: url).save(state2)
    check("save/load round-trip", MonkStore(fileURL: url).load() == state2)
    check("AppLimit valid", AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 15).isValid)
    check("preset light 60/20", LimitPreset.light.dailyTotalMinutes == 60 && LimitPreset.light.singleSessionMinutes == 20)
    check("wasted 90-30 = 60*365", WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 90, limitDailyMinutes: 30) == 60 * 365)

    let draft = OnboardingDraft(inputs: [
        OnboardingInput(appName: "Instagram", dailyUsageMinutes: 90, preset: .standard),
        OnboardingInput(appName: "TikTok", dailyUsageMinutes: 20, preset: .standard),
    ])
    check("draft valid", draft.isValid)
    check("draft wasted report Instagram 60*365", draft.wastedTimeReport().first(where: { $0.appName == "Instagram" })?.annualizedWastedMinutes == 60*365)
    check("draft wasted report TikTok 0", draft.wastedTimeReport().first(where: { $0.appName == "TikTok" })?.annualizedWastedMinutes == 0)
    check("draft total wasted", draft.totalAnnualizedWastedMinutes() == 60*365)
    check("draft invalid when empty", !OnboardingDraft().isValid)
    check("draft invalid when missing limit", !OnboardingDraft(inputs: [OnboardingInput(appName: "X", dailyUsageMinutes: 30)]).isValid)
    check("draft invalid over 1440", !OnboardingDraft(inputs: [OnboardingInput(appName: "X", dailyUsageMinutes: 2000, preset: .standard)]).isValid)
    let customDraft = OnboardingDraft(inputs: [OnboardingInput(appName: "MyApp", dailyUsageMinutes: 40, customLimit: AppLimit(dailyTotalMinutes: 20, singleSessionMinutes: 10))])
    check("custom limit effective", customDraft.inputs.first?.effectiveLimit == AppLimit(dailyTotalMinutes: 20, singleSessionMinutes: 10))
    check("custom draft wasted 20*365", customDraft.wastedTimeReport().first?.annualizedWastedMinutes == 20*365)

    let completeURL = tempURL()
    let completeStore = MonkStore(fileURL: completeURL)
    let completed = try OnboardingCompletion.complete(draft: draft, store: completeStore)
    check("completion sets onboarding true", completed.hasCompletedOnboarding)
    check("completion writes baseline", completed.baseline?.dailyMinutesByApp["Instagram"] == 90)
    check("completion writes tracked apps", completed.trackedApps.count == 2)
    check("completion persisted", MonkStore(fileURL: completeURL).load().hasCompletedOnboarding == true)
    do { _ = try OnboardingCompletion.complete(draft: OnboardingDraft(), store: MonkStore(fileURL: tempURL())); check("invalid draft throws", false) } catch { check("invalid draft throws", (error as? OnboardingError) == .invalidDraft) }
    check("privacy copy local", MonkStore(fileURL: tempURL()).privacyCopy.contains("locally"))

    print("All verification passed.")
} catch {
    print("✗ FAIL: threw \(error)")
    exit(1)
}
