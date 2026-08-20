import SwiftUI
import MonkCore
import Charts

// Variant B — Dense Stats: compact grid, numeric hierarchy, progress rings
struct VariantB: View {
    @Bindable var demo: DemoState
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsRow
                gridApps
                chartRow
            }.padding()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(title: "Free Time", value: "\(demo.freeVsBaseline) min", sub: "vs baseline")
            statCard(title: "Vs last week", value: "+\(demo.freeVsLastWeek)", sub: "min saved")
            statCard(title: "This week", value: "\(demo.thisWeekTotal)", sub: "min used")
        }
    }
    private func statCard(title: String, value: String, sub: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
            Text(sub).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var gridApps: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(demo.apps.enumerated()), id: \.element.id) { idx, app in
                let dec = demo.decision(for: app)
                let pct = min(1, Double(app.todayMinutes)/Double(max(1, app.limit.dailyTotalMinutes)))
                VStack(spacing: 8) {
                    HStack {
                        Text(app.name).font(.caption.bold()).lineLimit(1)
                        Spacer()
                        Circle().fill(colorFor(dec: dec.block)).frame(width: 8, height: 8)
                    }
                    ZStack {
                        Circle().stroke(Color.black.opacity(0.08), lineWidth: 6)
                        Circle().trim(from: 0, to: pct).stroke(colorFor(dec: dec.block), style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                        Text("\(Int(pct*100))%").font(.caption2.bold())
                    }.frame(width: 56, height: 56)
                    Text("\(app.todayMinutes)/\(app.limit.dailyTotalMinutes) • \(app.sessionMinutes)/\(app.limit.singleSessionMinutes)").font(.caption2).foregroundStyle(.secondary)
                    statusLabel(dec.block)
                }
                .padding(10).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var chartRow: some View {
        Chart(demo.last7Days, id: \.date) {
            LineMark(x: .value("d", $0.date, unit: .day), y: .value("m", $0.minutes)).foregroundStyle(.orange)
            AreaMark(x: .value("d", $0.date, unit: .day), y: .value("m", $0.minutes)).foregroundStyle(.orange.opacity(0.15))
        }.frame(height: 100).padding(10).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func colorFor(dec: BlockType) -> Color {
        switch dec { case .none: return .green; case .cooldown: return .orange; case .dailyLocked: return .red }
    }
    @ViewBuilder private func statusLabel(_ b: BlockType) -> some View {
        switch b {
        case .none: Text("OK").font(.caption2.bold()).foregroundStyle(.green)
        case .cooldown(let s): Text(String(format: "COOLDOWN %02d:%02d", s/60, s%60)).font(.caption2.bold()).foregroundStyle(.orange)
        case .dailyLocked: Text("DAILY LOCKED").font(.caption2.bold()).foregroundStyle(.red)
        }
    }
}
