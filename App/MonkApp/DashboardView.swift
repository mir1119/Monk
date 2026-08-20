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
        ScrollView {
            VStack(spacing: 20) {
                hero
                appsList
                weekChart
                privacy
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Monk")
        .onAppear { ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in now = Date() } }
        .onDisappear { ticker?.invalidate() }
    }

    private var hero: some View {
        let free = calc.weeklyFreeMinutes
        let vsBase = calc.freeVsBaseline
        let vsLast = calc.freeVsLastWeek
        return VStack(spacing: 8) {
            Text("FREE TIME THIS WEEK").font(.caption).foregroundStyle(.secondary).tracking(1)
            Text(String(format: "%dh %02dm", free/60, free%60))
                .font(.system(size: 44, weight: .bold, design: .rounded))
            HStack(spacing: 14) {
                Label("vs baseline +\(vsBase) min", systemImage: "arrow.up.right")
                Label("vs last week +\(vsLast) min", systemImage: "arrow.up.forward")
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var appsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today").font(.headline)
            ForEach(state.trackedApps) { app in
                let usage = demoUsages[app.id]
                let today = usage?.todayMinutes ?? 0
                let sess = usage?.currentSessionMinutes ?? 0
                let remaining = max(0, app.limit.dailyTotalMinutes - today)
                let block = calc.blockedStates[app.id] ?? .none
                let isBlocked: Bool = {
                    if case .none = block { return false }; return true
                }()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.displayName).font(.subheadline.bold())
                        Text("\(today)/\(app.limit.dailyTotalMinutes) min · session \(sess)/\(app.limit.singleSessionMinutes)")
                            .font(.caption).foregroundStyle(.secondary)
                        ProgressView(value: Double(today), total: Double(app.limit.dailyTotalMinutes))
                            .tint(remaining < 6 ? .orange : .green)
                    }
                    Spacer()
                    switch block {
                    case .none:
                        Text("\(remaining)m left").font(.caption2.bold()).padding(6).background(.green.opacity(0.15), in: Capsule())
                    case .cooldown(let s):
                        Text(String(format: "%02d:%02d", s/60, s%60)).font(.caption2.bold()).padding(6).background(.orange.opacity(0.2), in: Capsule())
                    case .dailyLocked:
                        Text("LOCKED").font(.caption2.bold()).padding(6).background(.red.opacity(0.15), in: Capsule())
                    }
                }
                .padding(12)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
                .opacity(isBlocked ? 0.9 : 1)
            }
            if state.trackedApps.isEmpty {
                Text("No tracked apps yet — add some in Settings.").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding()
            }
        }
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days").font(.headline)
            Chart(calc.last7Days, id: \.date) { d in
                BarMark(x: .value("day", d.date, unit: .day), y: .value("min", d.minutes))
                    .foregroundStyle(Color.orange.gradient).cornerRadius(4)
            }.frame(height: 120)
            Text("Local-only · \(MonkStore(fileURL: MonkStore.defaultStoreURL()).privacyCopy)")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var privacy: some View {
        Text("All data is stored locally on-device. No account, no cloud.")
            .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }
}
