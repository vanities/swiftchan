//
//  RefreshProgressBar.swift
//  swiftchan
//
//  Ultra-minimal progress bar for thread refresh timer
//

import SwiftUI

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
            return Color.gray
        }
        
        switch percentage {
        case 0.5...1.0:
            return Color.green
        case 0.25..<0.5:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track (very subtle)
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 2)
                
                // Progress bar
                Rectangle()
                    .fill(barColor)
                    .frame(width: geometry.size.width * percentage, height: 2)
                    .animation(.linear(duration: 0.5), value: percentage)
            }
        }
        .frame(height: 2)
        .opacity(isPaused ? 0.5 : 1.0)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        RefreshProgressBar(progress: 0, total: 10, isPaused: false)
        RefreshProgressBar(progress: 5, total: 10, isPaused: false)
        RefreshProgressBar(progress: 7.5, total: 10, isPaused: false)
        RefreshProgressBar(progress: 9, total: 10, isPaused: false)
        RefreshProgressBar(progress: 5, total: 10, isPaused: true)
    }
    .padding()
}
#endif