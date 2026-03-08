import SwiftUI

struct RefreshProgressBar: View {
    let progress: Double // 0.0 to 1.0, time remaining fraction
    let isPaused: Bool
    let secondsRemaining: Int

    private var barColor: Color {
        if isPaused {
            return .gray
        }
        switch progress {
        case 0.5...1.0:
            return .accentColor
        case 0.25..<0.5:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                // Background track
                CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: width, height: 4)

                // Progress fill
                CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                    .fill(barColor)
                    .frame(width: width * progress, height: 4)
                    .animation(.linear(duration: 1), value: progress)
            }
        }
        .frame(height: 4)
    }
}

struct CornerWrapShape: Shape {
    let isIPhone: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isIPhone {
            let cornerRadius: CGFloat = 75
            let barHeight: CGFloat = rect.height

            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: rect.height - barHeight),
                control: CGPoint(x: 0, y: rect.height - barHeight)
            )
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height - barHeight))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height - cornerRadius),
                control: CGPoint(x: rect.width, y: rect.height - barHeight)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        } else {
            path.addRect(CGRect(x: 0, y: rect.height - rect.height, width: rect.width, height: rect.height))
        }

        return path
    }
}
