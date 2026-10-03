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
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: width, height: 4)

                // Progress fill
                Capsule()
                    .fill(barColor)
                    .frame(width: width * min(1, max(0, progress)), height: 4)
                    .animation(.linear(duration: 1), value: progress)
            }
        }
        .frame(height: 4)
    }
}
