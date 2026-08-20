import Foundation
import MonkCore
func check(_ n:String,_ c:Bool){ if c{ print("✓ \(n)") } else { print("✗ FAIL: \(n)"); exit(1)} }
func tempURL()->URL{ FileManager.default.temporaryDirectory.appendingPathComponent("monk-\(UUID().uuidString).json")}
do{
 let engine=BlockEngine()
 let app=TrackedApp(displayName:"IG", limit: AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 15), isCustom:false)
 let now=Date(timeIntervalSince1970: 1_000_000)
 check("block none", engine.decide(app:app, todayMinutes:5, sessionMinutes:5, cooldownUntil:nil, dailyLockedUntil:nil, emergencyUnlockUntil:nil, now:now).block==BlockType.none)
 // BlockStateStore
 let url=tempURL()
 let store=BlockStateStore(fileURL: url)
 let appId=UUID()
 check("initial empty", store.load(appId: appId)==BlockAppState())
 try store.triggerCooldown(appId: appId, now: now)
 check("cooldown set", store.load(appId: appId).cooldownUntil==now.addingTimeInterval(3600))
 // emergency once per day
 check("can emergency initially", store.canEmergencyUnlock(appId: appId, now: now))
 check("use emergency", try store.useEmergencyUnlock(appId: appId, now: now))
 check("in emergency", store.isInEmergencyUnlock(appId: appId, now: now))
 check("cannot reuse same day", !store.canEmergencyUnlock(appId: appId, now: now))
 check("second use fails", try !store.useEmergencyUnlock(appId: appId, now: now))
 // next day can again
 let nextDay=now.addingTimeInterval(86400+60)
 check("next day can emergency", store.canEmergencyUnlock(appId: appId, now: nextDay))
 check("next day use", try store.useEmergencyUnlock(appId: appId, now: nextDay))
 // daily lock
 let appId2=UUID()
 let until=now.addingTimeInterval(3600*5)
 try store.triggerDailyLock(appId: appId2, until: until)
 check("daily lock set", store.load(appId: appId2).dailyLockedUntil==until)
 // cleanup expired
 let expiredURL=tempURL()
 let expiredStore=BlockStateStore(fileURL: expiredURL)
 let aid=UUID()
 try expiredStore.triggerCooldown(appId: aid, now: now.addingTimeInterval(-7200))
 check("expired cooldown exists", expiredStore.load(appId: aid).cooldownUntil != nil)
 try expiredStore.cleanupExpired(now: now)
 check("cleanup cleared", expiredStore.load(appId: aid).cooldownUntil==nil)
 // engine integration with store state
 let s=store.load(appId: appId)
 let dec=engine.decide(app:app, todayMinutes:100, sessionMinutes:100, cooldownUntil:s.cooldownUntil, dailyLockedUntil:s.dailyLockedUntil, emergencyUnlockUntil:s.emergencyUnlockUntil, now:now)
 check("engine respects emergency", !dec.isBlocked)
 print("All verification passed.")
}catch{ print("✗ FAIL: \(error)"); exit(1)}
