import Foundation
import XCTest
@testable import MonkCore

final class MonkStoreTests: XCTestCase {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("monk-test-\(UUID().uuidString).json")
    }

    func testLoadReturnsDefaultWhenMissing() {
        let store = MonkStore(fileURL: tempURL())
        let state = store.load()
        XCTAssertTrue(state.trackedApps.isEmpty)
        XCTAssertNil(state.baseline)
        XCTAssertEqual(state.dailyReset, .midnight)
        XCTAssertFalse(state.hasCompletedOnboarding)
    }

    func testSaveAndLoadRoundTrip() throws {
        let url = tempURL()
        let store = MonkStore(fileURL: url)
        var state = MonkState()
        state.trackedApps = [
            TrackedApp(displayName: "Instagram", limit: .preset(.standard), isCustom: false),
            TrackedApp(displayName: "MyGame", bundleIdentifier: "com.example.game", limit: AppLimit(dailyTotalMinutes: 20, singleSessionMinutes: 10), isCustom: true),
        ]
        state.baseline = Baseline(dailyMinutesByApp: ["Instagram": 90], createdAt: Date(timeIntervalSince1970: 0))
        state.dailyReset = .fourAM
        state.hasCompletedOnboarding = true
        try store.save(state)
        let loaded = store.load()
        XCTAssertEqual(loaded, state)
    }

    func testPersistsAcrossInstance() throws {
        let url = tempURL()
        try MonkStore(fileURL: url).save(MonkState(trackedApps: [TrackedApp(displayName: "TikTok", limit: .preset(.light), isCustom: false)], hasCompletedOnboarding: true))
        let second = MonkStore(fileURL: url).load()
        XCTAssertEqual(second.trackedApps.count, 1)
        XCTAssertEqual(second.trackedApps.first?.displayName, "TikTok")
    }

    func testAppLimitValidation() {
        XCTAssertTrue(AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 15).isValid)
        XCTAssertFalse(AppLimit(dailyTotalMinutes: 0, singleSessionMinutes: 15).isValid)
        XCTAssertFalse(AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 0).isValid)
        XCTAssertFalse(AppLimit(dailyTotalMinutes: 2000, singleSessionMinutes: 15).isValid)
    }

    func testPresetValues() {
        XCTAssertEqual(LimitPreset.light.dailyTotalMinutes, 60)
        XCTAssertEqual(LimitPreset.light.singleSessionMinutes, 20)
        XCTAssertEqual(LimitPreset.standard.dailyTotalMinutes, 30)
        XCTAssertEqual(LimitPreset.standard.singleSessionMinutes, 15)
        XCTAssertEqual(LimitPreset.strict.dailyTotalMinutes, 15)
        XCTAssertEqual(LimitPreset.strict.singleSessionMinutes, 10)
    }

    func testWastedTime() {
        XCTAssertEqual(WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 90, limitDailyMinutes: 30), 60 * 365)
        XCTAssertEqual(WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 20, limitDailyMinutes: 30), 0)
        XCTAssertEqual(WastedTimeCalculator.annualizedWastedMinutes(dailyUsageMinutes: 30, limitDailyMinutes: 30), 0)
    }

    func testPrivacyCopy() {
        let store = MonkStore(fileURL: tempURL())
        XCTAssertTrue(store.privacyCopy.contains("locally"))
    }
}
