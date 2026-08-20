import SwiftUI
import MonkCore
import Charts

// Variant C — Timeline Focus: vertical timeline + horizontal app strips
struct VariantC: View {
    @Bindable var demo: DemoState
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                timeline
                appsTimeline
            }.padding()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("This week").font(.caption).foregroundStyle(.secondary)
                Text("Saved \(demo.freeVsBaseline) min").font(.title3.bold())
                Text("+\(demo.freeVsLastWeek) vs last week").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "hourglass").font(.title2).foregroundStyle(.orange)
        }
        .padding(14).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("7-day timeline").font(.subheadline.bold())
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(demo.last7Days, id: \.date) { d in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6).fill(Color.orange.gradient).frame(height: CGFloat(max(8, d.minutes)))
                        Text(dayLabel(d.date)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }.frame(height: 110)
        }
        .padding(12).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var appsTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apps today").font(.subheadline.bold())
            ForEach(Array(demo.apps.enumerated()), id: \.element.id) { idx, app in
                let dec = demo.decision(for: app)
                HStack(spacing: 8) {
                    Text(app.name).font(.caption.bold()).frame(width: 90, alignment: .leading)
                    GeometryReader { geo in
                        let w = geo.size.width
                        let filled = w * min(1, CGFloat(app.todayMinutes)/CGFloat(app.limit.dailyTotalMinutes))
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.08)).frame(height: 10)
                            Capsule().fill(dec.isBlocked ? Color.red : Color.green).frame(width: filled, height: 10)
                            if app.sessionMinutes >= app.limit.singleSessionMinutes - 2 && dec.isBlocked == false {
                                Circle().fill(.orange).frame(width: 10, height: 10).offset(x: filled - 5)
                            }
                        }
                    }.frame(height: 10)
                    Text(blockShort(dec.block)).font(.caption2.bold()).foregroundStyle(dec.isBlocked ? .red : .green)
                }
            }
        }
        .padding(12).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func dayLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat="E"; return f.string(from: d)
    }
    private func blockShort(_ b: BlockType) -> String {
        switch b { case .none: return "OK"; case .cooldown(let s): return String(format: "%d:%02d", s/60, s%60); case .dailyLocked: return "LOCK" }
    }
}
private extension BlockType { var isBlocked: Bool { if case .none = self { return false }; return true } }
