import SwiftUI
import MonkCore
import Charts

struct DashboardView: View {
    @Binding var state: MonkState
    @State private var now = Date()
    @State private var ticker: Timer?

    private var demoUsages: [UUID: AppUsage] {
        let adapter = UsageTrackingAdapter.default()
        var d: [UUID: AppUsage] = [:]
        for app in state.trackedApps { d[app.id] = adapter.usage(for: app) }
        return d
    }

    private var baseline: Baseline? { state.baseline }

    private var thisWeekTotal: Int {
        demoUsages.values.reduce(0) { $0 + $1.todayMinutes } * 7 / max(1, demoUsages.count)
    }

    private var calc: DashboardData {
        let blockStore = BlockStateStore(fileURL: BlockStateStore.defaultURL())
        var blockStates: [UUID: BlockAppState] = [:]
        for app in state.trackedApps { blockStates[app.id] = blockStore.load(appId: app.id) }
        let usages = demoUsages
        let last7: [DailyUsage] = (0..<7).map { i in
            DailyUsage(date: Calendar.current.date(byAdding: .day, value: -6+i, to: now) ?? now, minutes: demoUsages.values.map(\.todayMinutes).max() ?? 0)
        }
        return DashboardCalculator().build(trackedApps: state.trackedApps, usages: usages, baseline: baseline, thisWeekTotal: thisWeekTotal, lastWeekTotal: baseline.map { $0.dailyMinutesByApp.values.reduce(0,+) * 7 }, last7Days: last7, now: now, blockStates: blockStates)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            gridBackground
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    appsList
                    weekChart
                    privacy
                }
                .padding()
            }
        }
        .navigationTitle("Monk")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { Text("MONK").font(.monkMonoBold(size: 14)).tracking(3).foregroundStyle(Color(red: 0.42, green: 0.28, blue: 0.92)) } }
        .onAppear { ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in now = Date() } }
        .onDisappear { ticker?.invalidate() }
    }

    private var gridBackground: some View {
        Canvas { ctx, size in
            let step: CGFloat = 20
            for x in stride(from: 0, through: size.width, by: step) {
                ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) }, with: .color(Color.monkGrid), lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: step) {
                ctx.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) }, with: .color(Color.monkGrid), lineWidth: 0.5)
            }
        }.ignoresSafeArea().opacity(0.5)
    }

    private var hero: some View {
        let free = calc.weeklyFreeMinutes
        let vsBase = calc.freeVsBaseline
        let vsLast = calc.freeVsLastWeek
        return VStack(spacing: 10) {
            Text("FREE TIME // THIS WEEK").font(.monkMono(size: 10)).foregroundStyle(.secondary).tracking(2)
            Text(String(format: "%02d:%02d", free/60, free%60))
                .font(.monkDisplay(size: 52))
            Rectangle().fill(Color.monkHairline).frame(height: 1).padding(.horizontal, 24)
            HStack(spacing: 16) {
                Label("BASELINE +\(vsBase) MIN", systemImage: "arrow.up.right").font(.monkMono(size: 10))
                Label("LAST WK +\(vsLast) MIN", systemImage: "arrow.up.forward").font(.monkMono(size: 10))
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(22)
        .background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.monkHairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }

    private var appsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY // TRACKED").font(.monkMono(size: 11)).foregroundStyle(.secondary).tracking(1.5)
            ForEach(state.trackedApps) { app in
                let usage = demoUsages[app.id]
                let today = usage?.todayMinutes ?? 0
                let sess = usage?.currentSessionMinutes ?? 0
                let remaining = max(0, app.limit.dailyTotalMinutes - today)
                let block = calc.blockedStates[app.id] ?? .none
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.displayName.uppercased()).font(.monkMonoBold(size: 13)).tracking(0.5)
                        Text("\(today)/\(app.limit.dailyTotalMinutes) MIN · SESSION \(sess)/\(app.limit.singleSessionMinutes)")
                            .font(.monkMono(size: 10)).foregroundStyle(.secondary)
                        ProgressView(value: Double(today), total: Double(app.limit.dailyTotalMinutes))
                            .tint(remaining < 6 ? .orange : .monkPrimary)
                    }
                    Spacer()
                    switch block {
                    case .none:
                        Text("\(remaining)M LEFT").font(.monkMonoBold(size: 10)).padding(.horizontal, 8).padding(.vertical, 5)
                            .background(Color.monkPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 2))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.monkPrimary.opacity(0.3), lineWidth: 1))
                    case .cooldown(let s):
                        Text(String(format: "%02d:%02d", s/60, s%60)).font(.monkMonoBold(size: 10)).padding(6)
                            .background(.orange.opacity(0.16), in: RoundedRectangle(cornerRadius: 2))
                    case .dailyLocked:
                        Text("LOCKED").font(.monkMonoBold(size: 10)).padding(6).background(.red.opacity(0.14), in: RoundedRectangle(cornerRadius: 2))
                    }
                }
                .padding(12)
                .background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 2))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.monkHairline, lineWidth: 1))
            }
            if state.trackedApps.isEmpty {
                Text("NO TRACKED APPS — ADD IN SETTINGS").font(.monkMono(size: 10)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding()
            }
        }
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST 7 DAYS").font(.monkMono(size: 11)).foregroundStyle(.secondary).tracking(1)
            Chart(calc.last7Days, id: \.date) { d in
                BarMark(x: .value("day", d.date, unit: .day), y: .value("min", d.minutes))
                    .foregroundStyle(Color(red: 0.42, green: 0.28, blue: 0.92).gradient).cornerRadius(2)
            }.frame(height: 110)
            Text("LOCAL-ONLY · \(MonkStore(fileURL: MonkStore.defaultStoreURL()).privacyCopy)")
                .font(.monkMono(size: 9)).foregroundStyle(.secondary)
        }
        .padding(14).background(Color(.systemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.monkHairline, lineWidth: 1))
    }

    private var privacy: some View {
        Text("// ALL DATA ON-DEVICE · NO ACCOUNT · NO CLOUD")
            .font(.monkMono(size: 9)).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }
}
