import Foundation
import MonkCore
func check(_ name: String, _ c: Bool){ if c{ print("✓ \(name)") } else { print("✗ FAIL: \(name)"); exit(1)} }
func tempURL()->URL{ FileManager.default.temporaryDirectory.appendingPathComponent("monk-\(UUID().uuidString).json")}
do{
 check("preset", LimitPreset.standard.dailyTotalMinutes==30)
 let url=tempURL()
 let store=MonkStore(fileURL: url)
 _=try TrackedAppManager(store: store).add(displayName:"IG", limit:.preset(.standard), isCustom:false)
 let mgr=TrackedAppManager(store: store)
 check("mgr add", mgr.list().count==1)
 let app=mgr.list()[0]
 // #5 adapter
 let localURL=tempURL()
 let localStore=LocalUsageStore(fileURL: localURL)
 try localStore.record(appId: app.id, todayMinutes: 10, sessionMinutes: 5)
 check("local record", localStore.todayMinutes(for: app.id)==10 && localStore.sessionMinutes(for: app.id)==5)
 let localSource=LocalUsageSource(store: localStore)
 let sysUnauthorized=SystemUsageSourceStub(authorized: false, values:[app.id:(today: 99, session: 99)])
 let adapterLocal=UsageTrackingAdapter(systemSource: sysUnauthorized, localSource: localSource)
 let u1=adapterLocal.usage(for: app)
 check("fallback to local when unauthorized", u1.todayMinutes==10 && u1.currentSessionMinutes==5 && u1.mode==TrackingMode.local)
 let sysAuthorized=SystemUsageSourceStub(authorized: true, values:[app.id:(today: 42, session: 12)])
 let adapterSystem=UsageTrackingAdapter(systemSource: sysAuthorized, localSource: localSource)
 let u2=adapterSystem.usage(for: app)
 check("uses system when authorized", u2.todayMinutes==42 && u2.currentSessionMinutes==12 && u2.mode==TrackingMode.system)
 let emptyLocal=LocalUsageSource(store: LocalUsageStore(fileURL: tempURL()))
 let adapterSystemOnly=UsageTrackingAdapter(systemSource: sysAuthorized, localSource: emptyLocal)
 check("system only", adapterSystemOnly.usage(for: app).mode==TrackingMode.system)
 check("system wins over local", u2.mode==TrackingMode.system)
 // when system returns nil for missing app, falls back to local 0
 let otherApp=TrackedApp(displayName:"Other", limit:.preset(.light), isCustom:true)
 check("fallback zero", UsageTrackingAdapter(systemSource: sysUnauthorized, localSource: emptyLocal).usage(for: otherApp).todayMinutes==0)
 check("permission copy", UsageTrackingAdapter.default().permissionCopy.contains("Screen Time"))
 // onboarding still works smoke
 check("onboarding", (try? OnboardingCompletion.complete(draft: OnboardingDraft(inputs:[OnboardingInput(appName:"X", dailyUsageMinutes:30, preset:.standard)]), store: MonkStore(fileURL: tempURL()))) != nil)
 print("All verification passed.")
}catch{ print("✗ FAIL: \(error)"); exit(1)}
