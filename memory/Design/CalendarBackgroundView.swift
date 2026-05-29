import SwiftUI

struct CalendarBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 0.99),
                    Color(red: 0.93, green: 0.97, blue: 0.98),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            WeekdayLettersBackdrop()
                .opacity(0.35)
                .allowsHitTesting(false)
        }
    }
}

private struct WeekdayLettersBackdrop: View {
    private let columns: [(String, String, String)] = [
        ("S", "u", "n"),
        ("M", "o", "n"),
        ("T", "u", "e"),
        ("W", "e", "d"),
        ("T", "h", "u"),
        ("F", "r", "i"),
        ("S", "a", "t"),
    ]

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let top = proxy.safeAreaInsets.top
            let xStep = w / 8

            ZStack {
                ForEach(Array(columns.enumerated()), id: \.offset) { idx, col in
                    VStack(spacing: 9) {
                        Text(col.0)
                        Text(col.1)
                        Text(col.2)
                    }
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .foregroundStyle(Color.black.opacity(0.22))
                    .position(x: xStep * CGFloat(idx + 1), y: top + 150)
                }
            }
        }
    }
}
