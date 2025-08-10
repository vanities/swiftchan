import SwiftUI

extension Color {
    func lighter(by amount: Double = 0.2) -> Color {
        return self.opacity(1.0 - amount)
    }
}

struct RefreshProgressBar: View {
    let progress: Double
    let total: Double
    let isPaused: Bool

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, (total - progress) / total))
    }

    private var barColor: Color {
        if isPaused {
            return Color.gray.opacity(0.7)
        }

        // Gradient from cyan -> purple -> pink as time runs out
        switch percentage {
        case 0.7...1.0:
            return Color.green
        case 0.5..<0.7:
            return Color.teal
        case 0.3..<0.5:
            return Color.purple
        case 0.15..<0.3:
            return Color.pink
        default:
            return Color(red: 1.0, green: 0.2, blue: 0.4) // Hot pink when almost out
        }
    }
    
    private var glowOpacity: Double {
        0.3 + 0.3 * sin(progress * .pi)
    }
    
    private var glowRadius: Double {
        6 + 4 * sin(progress * .pi)
    }
    
    private var pulseOpacity: Double {
        isPaused ? 0.5 : (percentage < 0.2 ? 0.85 + (0.15 * sin(progress * .pi * 4)) : 1.0)
    }
    
    @ViewBuilder
    private func makeProgressBar(width: CGFloat) -> some View {
        ZStack {
            // Base bar
            CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            barColor.opacity(0.7),
                            barColor,
                            barColor.opacity(0.8),
                            barColor.lighter(by: 0.1),
                            barColor
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: 30)
        }
    }
    
    @ViewBuilder
    private func makeShimmer(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: max(0, width * percentage - 20))
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 20, height: 30)
            
            Spacer()
        }
        .frame(width: width * percentage, height: 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progressWidth = width * percentage
            
            ZStack(alignment: .leading) {
                // Background
                backgroundBar(width: width)
                
                // Progress bar with effects
                progressBarWithEffects(width: width, progressWidth: progressWidth)
            }
        }
        .frame(height: 30)
        .opacity(pulseOpacity)
        .animation(.linear(duration: 0.1), value: percentage)
    }
    
    @ViewBuilder
    private func backgroundBar(width: CGFloat) -> some View {
        CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
            .fill(Color.gray.opacity(0.1))
            .frame(width: width, height: 30)
    }
    
    @ViewBuilder
    private func progressBarWithEffects(width: CGFloat, progressWidth: CGFloat) -> some View {
        makeProgressBar(width: width)
            .mask(
                Rectangle()
                    .frame(width: progressWidth, height: 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
            .overlay(
                ZStack {
                    makeShimmer(width: width)
                }
            )
            .mask(
                CornerWrapShape(isIPhone: UIDevice.current.userInterfaceIdiom == .phone)
                    .frame(width: width, height: 30)
            )
            .shadow(color: barColor.opacity(glowOpacity), radius: glowRadius, x: 0, y: 0)
            .animation(.linear(duration: 0.1), value: percentage)
    }
}

struct CornerWrapShape: Shape {
    let isIPhone: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isIPhone {
            let cornerRadius: CGFloat = 75
            let barHeight: CGFloat = 3
            
            // Start from bottom left, wrap up the corner
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: rect.height - barHeight),
                control: CGPoint(x: 0, y: rect.height - barHeight)
            )
            
            // Straight line across the bottom
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height - barHeight))
            
            // Wrap up the right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height - cornerRadius),
                control: CGPoint(x: rect.width, y: rect.height - barHeight)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            
            // Close the path along the bottom
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        } else {
            // Simple rectangle for non-iPhone devices
            let barHeight: CGFloat = 6
            path.addRect(CGRect(x: 0, y: rect.height - barHeight, width: rect.width, height: barHeight))
        }
        
        return path
    }
}
