//
//  VideoContainerView.swift
//  swiftchan
//
//  Created on 2/5/26.
//

import SwiftUI
import KSPlayer

struct VideoContainerView: View {
    let url: URL
    let isSelected: Bool
    var onSeekChanged: ((Bool) -> Void)?

    @State private var downloadState: DownloadState = .idle
    @State private var fileURL: URL?
    @StateObject private var coordinator = KSVideoPlayer.Coordinator()
    @State private var showControls = false
    @State private var controlsHideTask: Task<Void, Never>?
    @State private var isPlaying = false
    @State private var isSeeking = false

    enum DownloadState {
        case idle
        case ready
        case error(String)
    }

    var body: some View {
        ZStack {
            if let fileURL {
                KSVideoPlayer(coordinator: coordinator, url: fileURL, options: ksOptions())
                    .onStateChanged { playerLayer, state in
                        // Defer state updates to avoid "Publishing changes from within view updates"
                        DispatchQueue.main.async {
                            switch state {
                            case .readyToPlay:
                                if isSelected {
                                    playerLayer.play()
                                }
                            case .bufferFinished:
                                isPlaying = playerLayer.player.isPlaying
                            case .paused:
                                isPlaying = false
                            case .error:
                                isPlaying = false
                            default:
                                break
                            }
                        }
                    }
                    .onBufferChanged { _, _ in
                        // Buffering handled by KSPlayer
                    }

                // Controls overlay
                VideoPlayerControlsView(
                    coordinator: coordinator,
                    isPlaying: $isPlaying,
                    onSeekChanged: { seeking in
                        isSeeking = seeking
                        if seeking {
                            // Keep controls visible during seek
                            controlsHideTask?.cancel()
                        } else {
                            // Restart hide timer after seek completes
                            scheduleControlsHide()
                        }
                        onSeekChanged?(seeking)
                    }
                )
                .opacity(showControls ? 1 : 0)
            }

            if case .error(let msg) = downloadState {
                Text(msg)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    toggleControls()
                }
        )
        .task {
            await loadVideo()
        }
        .onChange(of: isSelected) { _, selected in
            if !selected {
                coordinator.playerLayer?.pause()
                isPlaying = false
            } else if fileURL != nil {
                // Debounce play to avoid triggering during drag
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    if isSelected {
                        coordinator.playerLayer?.play()
                        isPlaying = true
                    }
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            coordinator.playerLayer?.pause()
            isPlaying = false
        }
    }

    private func loadVideo() async {
        // Skip if already ready
        if case .ready = downloadState { return }
        if fileURL != nil { return }

        let cacheURL = CacheManager.shared.cacheURL(url)

        // Check cache first - instant local playback
        if CacheManager.shared.cacheHit(file: cacheURL) {
            if CacheManager.shared.isValidVideoFile(file: cacheURL) {
                debugPrint("🎬 Cache hit for \(url.lastPathComponent)")
                fileURL = cacheURL
                downloadState = .ready
                return
            } else {
                debugPrint("🎬 Invalid cache file, removing: \(cacheURL.lastPathComponent)")
                try? FileManager.default.removeItem(at: cacheURL)
            }
        }

        debugPrint("🎬 Cache miss, streaming: \(url.lastPathComponent)")

        // Stream immediately from remote URL - KSPlayer handles buffering
        fileURL = url
        downloadState = .ready

        // Cache in background for future plays
        await cacheInBackground(remoteURL: url, cacheURL: cacheURL)
    }

    private func cacheInBackground(remoteURL: URL, cacheURL: URL) async {
        // Skip if already cached (prefetcher may have finished)
        guard !CacheManager.shared.cacheHit(file: cacheURL) else { return }

        do {
            let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let persistentTemp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(remoteURL.pathExtension)
            try FileManager.default.moveItem(at: tempURL, to: persistentTemp)

            if let cached = CacheManager.shared.cache(persistentTemp, cacheURL, originalURL: remoteURL),
               CacheManager.shared.isValidVideoFile(file: cached) {
                debugPrint("🎬 Background cached: \(cached.lastPathComponent)")
            }
        } catch {
            // Non-critical - video is already streaming
            debugPrint("🎬 Background cache failed: \(error.localizedDescription)")
        }
    }

    private func ksOptions() -> KSOptions {
        let options = KSOptions()
        options.isLoopPlay = true
        return options
    }

    private func toggleControls() {
        // Don't toggle off while seeking
        if isSeeking && showControls { return }

        controlsHideTask?.cancel()
        withAnimation(.linear(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls {
            scheduleControlsHide()
        }
    }

    private func scheduleControlsHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            // Don't hide while seeking
            guard !isSeeking else { return }
            await MainActor.run {
                withAnimation(.linear(duration: 0.2)) {
                    showControls = false
                }
            }
        }
    }
}

extension VideoContainerView: Buildable {
    func onSeekChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onSeekChanged, value: callback)
    }
}

#if DEBUG
#Preview {
    Group {
        VideoContainerView(
            url: URLExamples.webm,
            isSelected: false
        )
        .background(Color.black)

        VideoContainerView(
            url: URLExamples.webm,
            isSelected: true
        )
        .background(Color.black)
    }
}
#endif
