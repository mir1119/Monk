import Foundation
import MonkCore
func check(_ n:String,_ c:Bool){ if c{ print("✓ \(n)") } else { print("✗ FAIL: \(n)"); exit(1)} }
func tempURL()->URL{ FileManager.default.temporaryDirectory.appendingPathComponent("monk-\(UUID().uuidString).json")}
do{
 let app=TrackedApp(displayName:"IG", limit: AppLimit(dailyTotalMinutes: 30, singleSessionMinutes: 15), isCustom:false)
 let engine=BlockEngine()
 let now=Date()
 // Dashboard
 let calc=DashboardCalculator()
 check("remaining 30-10=20", calc.todayRemaining(app:app, todayMinutes:10)==20)
 check("remaining capped", calc.todayRemaining(app:app, todayMinutes:40)==0)
 let baseline=Baseline(dailyMinutesByApp:["IG":90])
 let (vsBase, vsLast, weekly)=calc.weeklyFreeMinutes(baseline: baseline, thisWeekTotal: 100, lastWeekTotal: 200)
 check("free vs baseline 630-100=530", vsBase==530)
 check("free vs last 100", vsLast==100)
 check("weekly==vsBase", weekly==vsBase)
 let usages:[UUID:AppUsage]=[app.id: AppUsage(trackedAppId: app.id, todayMinutes:10, currentSessionMinutes:5, mode:.local)]
 let data=calc.build(trackedApps:[app], usages:usages, baseline:baseline, thisWeekTotal:100, lastWeekTotal:200, last7Days:[DailyUsage(date:now, minutes:10)], now:now)
 check("dashboard remaining", data.todayRemainingByApp[app.id]==20)
 check("dashboard blocked none", data.blockedStates[app.id]==BlockType.none)
 // Notifications
 let sched=NotificationScheduler()
 // 80% case: 24/30
 let u80:[UUID:AppUsage]=[app.id: AppUsage(trackedAppId:app.id, todayMinutes:24, currentSessionMinutes:5, mode:.local)]
 check("80% notification", sched.notifications(usages:u80, trackedApps:[app], freeMinutesToday:0).contains(where:{$0.kind==NotificationKind.daily80Percent}))
 // pre-cooldown: 13/15
 let uPre:[UUID:AppUsage]=[app.id: AppUsage(trackedAppId:app.id, todayMinutes:10, currentSessionMinutes:13, mode:.local)]
 check("pre cooldown", sched.notifications(usages:uPre, trackedApps:[app], freeMinutesToday:0).contains(where:{$0.kind==NotificationKind.sessionPreCooldown}))
 // evening summary
 check("evening summary", sched.notifications(usages:usages, trackedApps:[app], freeMinutesToday:30).contains(where:{$0.kind==NotificationKind.eveningSummary}))
 check("no evening when 0", !sched.notifications(usages:usages, trackedApps:[app], freeMinutesToday:0).contains(where:{$0.kind==NotificationKind.eveningSummary}))
 // Settings + DailyReset
 let url=tempURL()
 let store=MonkStore(fileURL: url)
 let settings=SettingsManager(store: store)
 let s1=try settings.updateDailyReset(.fourAM)
 check("dailyReset 4am", s1.dailyReset==DailyResetOption.fourAM)
 let s2=try settings.addTrackedApp(displayName:"MyApp", limit:.preset(.light))
 check("add via settings", s2.trackedApps.count==1)
 let addedId=s2.trackedApps[0].id
 let s3=try settings.updateLimit(id: addedId, limit:.preset(.strict))
 check("update via settings", s3.trackedApps[0].limit==AppLimit.preset(.strict))
 let s4=try settings.removeTrackedApp(id: addedId)
 check("remove via settings", s4.trackedApps.isEmpty)
 // BlockState still works
 let bStore=BlockStateStore(fileURL: tempURL())
 let bid=UUID()
 try bStore.triggerCooldown(appId: bid, now: now)
 check("blockState cooldown", bStore.load(appId: bid).cooldownUntil != nil)
 print("All verification passed.")
}catch{ print("✗ FAIL: \(error)"); exit(1)}
