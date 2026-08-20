import SwiftUI

struct ZeitlyMark: View {
    var size: CGFloat = 28
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(LinearGradient(colors: [Color.monkPrimary, Color.monkPrimaryLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Text("Z")
                .font(.system(size: size * 0.58, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
        .shadow(color: .monkPrimary.opacity(0.35), radius: 6, y: 3)
    }
}

struct ZeitlyIconSet {
    static func generate() {
        let sizes = [1024, 512, 180, 120, 60]
        for s in sizes {
            print("Generate \(s)x\(s) via Xcode asset or sips")
        }
    }
}
