//
//  VideoPlayerControlsView.swift
//  swiftchan
//
//  Created on 2/5/26.
//

import SwiftUI
import KSPlayer

struct VideoPlayerControlsView: View {
    @ObservedObject var coordinator: KSVideoPlayer.Coordinator
    @Binding var isPlaying: Bool
    var onSeekChanged: ((Bool) -> Void)?

    @State private var sliderValue: Double = 0
    @State private var isDragging = false
    @State private var currentTimeText: String = "--:--"
    @State private var remainingTimeText: String = "--:--"
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center) {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause" : "play")
                        .font(.system(size: 25))
                        .padding()
                }

                Text(currentTimeText)
                    .fixedSize()

                Slider(value: $sliderValue, in: 0...1, onEditingChanged: sliderEditingChanged)

                Text(remainingTimeText)
                    .fixedSize()
            }
            .foregroundColor(.white)
            .padding(.trailing, 20)
            .padding(.bottom, 25)
        }
        .onAppear {
            startTimeUpdates()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    private func togglePlayback() {
        guard let playerLayer = coordinator.playerLayer else { return }
        if playerLayer.player.isPlaying {
            playerLayer.pause()
            isPlaying = false
        } else {
            playerLayer.play()
            isPlaying = true
        }
    }

    private func sliderEditingChanged(editing: Bool) {
        isDragging = editing
        if editing {
            onSeekChanged?(true)
            coordinator.playerLayer?.pause()
        } else {
            if let playerLayer = coordinator.playerLayer {
                let duration = playerLayer.player.duration
                let seekTime = duration * sliderValue
                playerLayer.seek(time: seekTime, autoPlay: true) { _ in
                    Task { @MainActor in
                        self.isPlaying = true
                    }
                }
            }
            onSeekChanged?(false)
        }
    }

    private func startTimeUpdates() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    updateTimeDisplay()
                }
            }
        }
    }

    private func updateTimeDisplay() {
        guard let playerLayer = coordinator.playerLayer else { return }
        let current = playerLayer.player.currentPlaybackTime
        let duration = playerLayer.player.duration
        guard duration > 0 else { return }

        if !isDragging {
            sliderValue = current / duration
        }

        let remaining = current - duration
        currentTimeText = formatTime(current)
        remainingTimeText = formatTime(remaining)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let isNegative = seconds < 0
        let absSeconds = abs(Int(seconds))
        let mins = absSeconds / 60
        let secs = absSeconds % 60
        return "\(isNegative ? "-" : "")\(mins):\(String(format: "%02d", secs))"
    }
}
