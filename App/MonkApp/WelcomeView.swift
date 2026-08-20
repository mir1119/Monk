import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ParticleField(count: 18).ignoresSafeArea().opacity(0.7)
            Canvas { ctx, size in
                let step: CGFloat = 22
                for x in stride(from: 0, through: size.width, by: step) {
                    ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) }, with: .color(Color.monkGrid), lineWidth: 0.5)
                }
                for y in stride(from: 0, through: size.height, by: step) {
                    ctx.stroke(Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) }, with: .color(Color.monkGrid), lineWidth: 0.5)
                }
            }.ignoresSafeArea().opacity(0.4)
            VStack(spacing: 18) {
                Spacer()
                VStack(spacing: 10) {
                    Text("WELCOME TO MONK").font(.monkDisplay(size: 28)).tracking(3).multilineTextAlignment(.center)
                    Text("GET YOUR TIME BACK AND BE THE TOP 1%").font(.monkMono(size: 11)).foregroundStyle(.secondary).tracking(1.5).multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                Spacer().frame(height: 20)
                Button(action: onGetStarted) {
                    Text("GET STARTED").font(.monkMonoBold(size: 14)).tracking(1)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.monkPrimary, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                Spacer().frame(height: 40)
            }
            .padding(.vertical, 24)
        }
    }
}
