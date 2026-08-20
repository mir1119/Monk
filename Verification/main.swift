import Foundation
import MonkCore

func check(_ name: String, _ condition: Bool) {
    if condition { print("✓ \(name)") } else { print("✗ FAIL: \(name)"); exit(1) }
}
func tempURL() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("monk-\(UUID().uuidString).json") }

do {
    // Basis — keep existing checks smoke
    check("preset 60/20", LimitPreset.light.dailyTotalMinutes == 60)
    check("wasted 60*365", WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 90, limitDailyMinutes: 30) == 60*365)
    check("completion", (try? OnboardingCompletion.complete(draft: OnboardingDraft(inputs: [OnboardingInput(appName: "IG", dailyUsageMinutes: 90, preset: .standard)]), store: MonkStore(fileURL: tempURL()))) != nil)

    // Ticket #4 — TrackedAppManager
    let url = tempURL()
    let mgr = TrackedAppManager(store: MonkStore(fileURL: url))
    check("list empty initially", mgr.list().isEmpty)
    let s1 = try mgr.add(displayName: "Instagram", limit: .preset(.standard), isCustom: false)
    check("add 1", s1.trackedApps.count == 1 && s1.trackedApps[0].displayName == "Instagram")
    check("add persisted", mgr.list().count == 1)
    let s2 = try mgr.add(displayName: "MyGame", bundleIdentifier: "com.example.game", limit: AppLimit(dailyTotalMinutes: 20, singleSessionMinutes: 10), isCustom: true)
    check("add custom", s2.trackedApps.count == 2 && s2.trackedApps[1].isCustom)
    do { _ = try mgr.add(displayName: "instagram", limit: .preset(.standard), isCustom: false); check("duplicate case-insensitive", false) } catch TrackedAppError.duplicateName { check("duplicate rejected", true) } catch { check("duplicate wrong error", false) }
    do { _ = try mgr.add(displayName: "  ", limit: .preset(.standard), isCustom: false); check("empty name", false) } catch TrackedAppError.invalidName { check("invalidName rejected", true) } catch { check("invalidName wrong", false) }
    do { _ = try mgr.add(displayName: "Bad", limit: AppLimit(dailyTotalMinutes: 0, singleSessionMinutes: 10), isCustom: false); check("invalid limit", false) } catch TrackedAppError.invalidLimit { check("invalidLimit rejected", true) } catch { check("invalidLimit wrong", false) }
    let id = s2.trackedApps.first(where: { $0.displayName == "Instagram" })!.id
    let s3 = try mgr.updateLimit(id: id, limit: AppLimit(dailyTotalMinutes: 15, singleSessionMinutes: 10))
    check("updateLimit", s3.trackedApps.first(where: { $0.id == id })?.limit.dailyTotalMinutes == 15)
    do { _ = try mgr.updateLimit(id: id, limit: AppLimit(dailyTotalMinutes: 0, singleSessionMinutes: 10)); check("update invalid limit", false) } catch TrackedAppError.invalidLimit { check("update invalidLimit", true) } catch { check("update wrong", false) }
    let s4 = try mgr.updateLimitPreset(id: id, preset: .light)
    check("updatePreset light", s4.trackedApps.first(where: { $0.id == id })?.limit.dailyTotalMinutes == 60)
    let s5 = try mgr.remove(id: id)
    check("remove", s5.trackedApps.count == 1 && s5.trackedApps[0].displayName == "MyGame")
    do { _ = try mgr.remove(id: UUID()); check("remove notFound", false) } catch TrackedAppError.notFound { check("notFound", true) } catch { check("notFound wrong", false) }
    check("remove persisted", mgr.list().count == 1)
    // addDefaultsIfNeeded
    let url2 = tempURL()
    let mgr2 = TrackedAppManager(store: MonkStore(fileURL: url2))
    let def = try mgr2.addDefaultsIfNeeded()
    check("defaults 7", def.trackedApps.count == 7)
    check("defaults not overwrite", (try mgr2.addDefaultsIfNeeded()).trackedApps.count == 7)
    check("defaults persisted", TrackedAppManager(store: MonkStore(fileURL: url2)).list().count == 7)
    print("All verification passed.")
} catch {
    print("✗ FAIL: threw \(error)"); exit(1)
}
