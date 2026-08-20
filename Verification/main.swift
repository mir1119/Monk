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
    state2.trackedApps = [
        TrackedApp(displayName: "Instagram", limit: .preset(.standard), isCustom: false),
        TrackedApp(displayName: "MyGame", bundleIdentifier: "com.example.game", limit: AppLimit(dailyTotalMinutes: 20, singleSessionMinutes: 10), isCustom: true),
    ]
    state2.baseline = Baseline(dailyMinutesByApp: ["Instagram": 90], createdAt: Date(timeIntervalSince1970: 0))
    state2.dailyReset = .fourAM
    state2.hasCompletedOnboarding = true
    try MonkStore(fileURL: url).save(state2)
    check("save/load round-trip", MonkStore(fileURL: url).load() == state2)

    let url2 = tempURL()
    try MonkStore(fileURL: url2).save(MonkState(trackedApps: [TrackedApp(displayName: "TikTok", limit: .preset(.light), isCustom: false)], hasCompletedOnboarding: true))
    check("persists across instance", MonkStore(fileURL: url2).load().trackedApps.first?.displayName == "TikTok")

    check("AppLimit valid", AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 15).isValid)
    check("AppLimit invalid zero daily", !AppLimit(dailyTotalMinutes: 0, singleSessionMinutes: 15).isValid)
    check("AppLimit invalid zero session", !AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 0).isValid)
    check("AppLimit invalid over 1440", !AppLimit(dailyTotalMinutes: 2000, singleSessionMinutes: 15).isValid)

    check("preset light 60/20", LimitPreset.light.dailyTotalMinutes == 60 && LimitPreset.light.singleSessionMinutes == 20)
    check("preset standard 30/15", LimitPreset.standard.dailyTotalMinutes == 30 && LimitPreset.standard.singleSessionMinutes == 15)
    check("preset strict 15/10", LimitPreset.strict.dailyTotalMinutes == 15 && LimitPreset.strict.singleSessionMinutes == 10)

    check("wasted 90-30 = 60*365", WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 90, limitDailyMinutes: 30) == 60 * 365)
    check("wasted 20-30 = 0", WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 20, limitDailyMinutes: 30) == 0)
    check("wasted 30-30 = 0", WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 30, limitDailyMinutes: 30) == 0)
    check("privacy copy local", MonkStore(fileURL: tempURL()).privacyCopy.contains("locally"))

    print("All verification passed.")
} catch {
    print("✗ FAIL: threw \(error)")
    exit(1)
}
