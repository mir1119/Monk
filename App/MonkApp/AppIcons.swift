import SwiftUI

enum AppIcon {
    static func view(for name: String) -> some View {
        let key = name.lowercased()
        let base: (String, Color) = {
            if key.contains("instagram") { return ("camera.fill", Color.pink) }
            if key.contains("youtube") { return ("play.rectangle.fill", Color.red) }
            if key.contains("tiktok") { return ("music.note", Color.black) }
            if key == "x" { return ("xmark", Color.black) }
            if key.contains("threads") { return ("at", Color.black) }
            if key.contains("reddit") { return ("ant.fill", Color.orange) }
            if key.contains("facebook") { return ("f.circle.fill", Color.blue) }
            return ("app.fill", Color.gray)
        }()
        return ZStack {
            RoundedRectangle(cornerRadius: 10).fill(base.1.opacity(0.14))
            Image(systemName: base.0).foregroundStyle(base.1).font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 36, height: 36)
    }
}
