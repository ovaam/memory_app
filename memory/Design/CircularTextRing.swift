import SwiftUI

struct CircularTextRing: View {
    var text: String
    var radius: CGFloat
    var font: Font
    var color: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let characters = Array(text.uppercased())
            guard !characters.isEmpty else { return }

            let angleStep = (2 * Double.pi) / Double(characters.count)
            let startAngle = -Double.pi / 2

            for (index, ch) in characters.enumerated() {
                let angle = startAngle + Double(index) * angleStep
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)

                var t = context
                t.translateBy(x: x, y: y)
                t.rotate(by: .radians(angle + Double.pi / 2))

                let resolved = t.resolve(Text(String(ch)).font(font).foregroundStyle(color))
                t.draw(resolved, at: .zero, anchor: .center)
            }
        }
        .frame(width: radius * 2 + 24, height: radius * 2 + 24)
    }
}
