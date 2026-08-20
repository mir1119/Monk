import SwiftUI
import MonkCore
import Charts

// Variant A — Minimal Zen: big hero Free Time card, sparse spacing, lots of whitespace
struct VariantA: View {
    @Bindable var demo: DemoState
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                appsList
                weekChart
                stateStrip
            }
            .padding()
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Text("Free Time this week").font(.caption).foregroundStyle(.secondary).textCase(.uppercase)
            Text("\(demo.freeVsBaseline/60)h \(demo.freeVsBaseline%60)m").font(.system(size: 42, weight: .bold, design: .rounded))
            HStack(spacing: 12) {
                Label("vs baseline +\(demo.freeVsBaseline) min", systemImage: "arrow.up.right")
                Label("vs last week +\(demo.freeVsLastWeek) min", systemImage: "arrow.up.forward")
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
            ForEach(Array(demo.apps.enumerated()), id: \.element.id) { idx, app in
                let dec = demo.decision(for: app)
                let remaining = max(0, app.limit.dailyTotalMinutes - app.todayMinutes)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name).font(.subheadline.bold())
                        Text("\(app.todayMinutes)/\(app.limit.dailyTotalMinutes) min • session \(app.sessionMinutes)/\(app.limit.singleSessionMinutes)").font(.caption).foregroundStyle(.secondary)
                        ProgressView(value: Double(app.todayMinutes), total: Double(app.limit.dailyTotalMinutes)).tint(remaining < 6 ? .orange : .green)
                    }
                    Spacer()
                    if case .cooldown(let s) = dec.block { Text(cooldownText(s)).font(.caption2.bold()).padding(6).background(.orange.opacity(0.2), in: Capsule()) }
                    else if case .dailyLocked = dec.block { Text("LOCKED").font(.caption2.bold()).padding(6).background(.red.opacity(0.15), in: Capsule()) }
                    else { Text("\(remaining)m left").font(.caption2.bold()).padding(6).background(.green.opacity(0.15), in: Capsule()) }
                }
                .padding(12).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 days").font(.headline)
            Chart(demo.last7Days, id: \.date) { d in
                BarMark(x: .value("day", d.date, unit: .day), y: .value("min", d.minutes))
                    .foregroundStyle(Color.orange.gradient)
            }.frame(height: 120)
        }
        .padding(14).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var stateStrip: some View {
        Text("Demo controls below adjust simulated usage — try pushing TikTok to 15m session to trigger cooldown.")
            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }

    private func cooldownText(_ s: Int) -> String { String(format: "%02d:%02d", s/60, s%60) }
}
