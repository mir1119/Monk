import Foundation
import MonkCore
func check(_ n:String,_ c:Bool){ if c{ print("✓ \(n)") } else { print("✗ FAIL: \(n)"); exit(1)} }
func tempURL()->URL{ FileManager.default.temporaryDirectory.appendingPathComponent("monk-\(UUID().uuidString).json")}
do{
 let app=TrackedApp(displayName:"IG", limit: AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 15), isCustom:false)
 let engine=BlockEngine()
 let now=Date(timeIntervalSince1970: 1_000_000)
 // not blocked
 check("none", engine.decide(app:app, todayMinutes:10, sessionMinutes:5, cooldownUntil:nil, dailyLockedUntil:nil, emergencyUnlockUntil:nil, now:now).block==BlockType.none)
 // session threshold -> cooldown 1hr
 let d1=engine.decide(app:app, todayMinutes:10, sessionMinutes:15, cooldownUntil:nil, dailyLockedUntil:nil, emergencyUnlockUntil:nil, now:now)
 if case .cooldown(let s)=d1.block{ check("session cooldown 3600", s==3600)} else{ check("session cooldown", false)}
 // daily threshold -> dailyLocked
 let d2=engine.decide(app:app, todayMinutes:30, sessionMinutes:5, cooldownUntil:nil, dailyLockedUntil:nil, emergencyUnlockUntil:nil, now:now)
 if case .dailyLocked=d2.block{ check("daily locked", true)} else{ check("daily locked", false)}
 // already in cooldown
 let cdUntil=now.addingTimeInterval(1800)
 let d3=engine.decide(app:app, todayMinutes:10, sessionMinutes:5, cooldownUntil:cdUntil, dailyLockedUntil:nil, emergencyUnlockUntil:nil, now:now)
 if case .cooldown(let s)=d3.block{ check("existing cooldown remaining ~1800", s>=1799 && s<=1800)} else{ check("existing cooldown", false)}
 // dailyLocked existing
 let dlUntil=now.addingTimeInterval(3600)
 let d4=engine.decide(app:app, todayMinutes:0, sessionMinutes:0, cooldownUntil:nil, dailyLockedUntil:dlUntil, emergencyUnlockUntil:nil, now:now)
 check("existing dailyLocked", d4.block==BlockType.dailyLocked(untilReset: dlUntil))
 // emergency unlock overrides
 let eu=now.addingTimeInterval(200)
 let d5=engine.decide(app:app, todayMinutes:100, sessionMinutes:100, cooldownUntil:cdUntil, dailyLockedUntil:dlUntil, emergencyUnlockUntil:eu, now:now)
 check("emergency overrides", d5.isInEmergencyUnlock && !d5.isBlocked)
 // emergency expired -> back to blocked
 let euExpired=now.addingTimeInterval(-10)
 let d6=engine.decide(app:app, todayMinutes:10, sessionMinutes:15, cooldownUntil:nil, dailyLockedUntil:nil, emergencyUnlockUntil:euExpired, now:now)
 check("emergency expired re-block", d6.isBlocked)
 // expired cooldown -> re-evaluates
 let expiredCd=now.addingTimeInterval(-10)
 let d7=engine.decide(app:app, todayMinutes:10, sessionMinutes:5, cooldownUntil:expiredCd, dailyLockedUntil:nil, emergencyUnlockUntil:nil, now:now)
 check("expired cooldown none", d7.block==BlockType.none)
 // nearing helpers
 check("nearing daily 80%", engine.isNearingDailyLimit(todayMinutes:24, limit:30))
 check("not nearing daily under", !engine.isNearingDailyLimit(todayMinutes:10, limit:30))
 check("not nearing daily at limit", !engine.isNearingDailyLimit(todayMinutes:30, limit:30))
 check("nearing session -2", engine.isNearingSessionCooldown(sessionMinutes:13, limit:15))
 check("not nearing session far", !engine.isNearingSessionCooldown(sessionMinutes:5, limit:15))
 // smoke: adapter + onboarding still ok
 let store=MonkStore(fileURL: tempURL())
 _=try TrackedAppManager(store: store).add(displayName:"IG", limit:.preset(.standard), isCustom:false)
 check("smoke mgr", true)
 print("All verification passed.")
}catch{ print("✗ FAIL: \(error)"); exit(1)}
