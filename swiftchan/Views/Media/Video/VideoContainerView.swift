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

    enum DownloadState: Equatable {
        case idle
        case downloading(progress: Double)
        case ready
        case error(String)

        static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.downloading(let a), .downloading(let b)): return a == b
            case (.ready, .ready): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
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
                    onSeekChanged: onSeekChanged
                )
                .opacity(showControls ? 1 : 0)
            }

            // Download progress overlay
            if case .downloading(let progress) = downloadState {
                VStack {
                    Text("Downloading")
                        .foregroundColor(.white)
                    Text("\(Int(progress * 100))%")
                        .foregroundColor(.white)
                        .font(.title)
                }
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
            await download()
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

    private func download() async {
        // Skip if already downloaded or downloading
        if case .ready = downloadState { return }
        if case .downloading = downloadState { return }
        if fileURL != nil { return }

        let cacheURL = CacheManager.shared.cacheURL(url)

        // Check cache first
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
        debugPrint("🎬 Cache miss, downloading: \(url.lastPathComponent)")

        // Download with retry logic
        var retryCount = 0
        let maxRetries = 3

        while retryCount < maxRetries {
            do {
                downloadState = .downloading(progress: 0)

                // Use delegate-based download for progress tracking
                let (tempURL, response) = try await downloadWithProgress(url: url) { progress in
                    Task { @MainActor in
                        self.downloadState = .downloading(progress: progress)
                    }
                }

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }

                // Cache and validate
                guard let cached = CacheManager.shared.cache(tempURL, cacheURL, originalURL: url) else {
                    throw URLError(.cannotCreateFile)
                }

                guard CacheManager.shared.isValidVideoFile(file: cached) else {
                    try? FileManager.default.removeItem(at: cached)
                    throw URLError(.cannotParseResponse)
                }

                fileURL = cached
                downloadState = .ready
                return

            } catch {
                retryCount += 1
                if retryCount >= maxRetries {
                    downloadState = .error("Download failed")
                    return
                }
                let delay = Double(retryCount) * 1.0
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    private func downloadWithProgress(url: URL, onProgress: @escaping (Double) -> Void) async throws -> (URL, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = DownloadDelegate(onProgress: onProgress) { result in
                continuation.resume(with: result)
            }

            let task = URLSession.shared.downloadTask(with: url)
            objc_setAssociatedObject(task, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            task.delegate = delegate
            task.resume()
        }
    }

    private func ksOptions() -> KSOptions {
        let options = KSOptions()
        options.isLoopPlay = true
        return options
    }

    private func toggleControls() {
        controlsHideTask?.cancel()
        withAnimation(.linear(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls {
            controlsHideTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.linear(duration: 0.2)) {
                        showControls = false
                    }
                }
            }
        }
    }
}

// MARK: - Download Delegate
private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Double) -> Void
    let onCompletion: (Result<(URL, URLResponse), Error>) -> Void

    init(onProgress: @escaping (Double) -> Void, completion: @escaping (Result<(URL, URLResponse), Error>) -> Void) {
        self.onProgress = onProgress
        self.onCompletion = completion
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move to a persistent temp location before the system deletes it
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(downloadTask.originalRequest?.url?.pathExtension ?? "tmp")
        do {
            try FileManager.default.moveItem(at: location, to: tempURL)
            if let response = downloadTask.response {
                onCompletion(.success((tempURL, response)))
            } else {
                onCompletion(.failure(URLError(.badServerResponse)))
            }
        } catch {
            onCompletion(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            onProgress(progress)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onCompletion(.failure(error))
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
