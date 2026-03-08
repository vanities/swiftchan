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
    @State private var isSeeking = false
    @State private var seekRetryCount = 0
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
        if editing {
            isSeeking = true
            seekRetryCount = 0
            onSeekChanged?(true)
            coordinator.playerLayer?.pause()
        } else {
            performSeek()
        }
    }

    private func performSeek() {
        guard let playerLayer = coordinator.playerLayer else {
            finishSeeking(success: false)
            return
        }
        let duration = playerLayer.player.duration
        guard duration > 0, !duration.isNaN, !duration.isInfinite else {
            finishSeeking(success: false)
            return
        }
        let seekTime = min(duration * sliderValue, duration - 0.1)
        playerLayer.seek(time: seekTime, autoPlay: true) { [self] finished in
            Task { @MainActor in
                if finished {
                    finishSeeking(success: true)
                } else if seekRetryCount < 3 {
                    // Seek failed (player not ready/seekable yet) — retry after a short delay
                    seekRetryCount += 1
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    performSeek()
                } else {
                    // Retries exhausted — resume playback at whatever position the player is at
                    finishSeeking(success: false)
                }
            }
        }
    }

    private func finishSeeking(success: Bool) {
        isSeeking = false
        seekRetryCount = 0
        if success {
            isPlaying = true
        } else {
            // Seek failed — resume playback from current position rather than leaving paused
            coordinator.playerLayer?.play()
            isPlaying = coordinator.playerLayer?.player.isPlaying ?? false
        }
        onSeekChanged?(false)
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
        guard duration > 0, !duration.isNaN, !duration.isInfinite else { return }

        if !isSeeking {
            sliderValue = current / duration
        }

        let displayTime = isSeeking ? duration * sliderValue : current
        let remaining = displayTime - duration
        currentTimeText = formatTime(displayTime)
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
