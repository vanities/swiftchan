//
//  VLCVideo.swift
//  swiftchan
//
//  Created by vanities on 5/1/21.
//

import SwiftUI
import MobileVLCKit

struct VLCVideo: Equatable, Identifiable {
    let id: String
    var url: URL
    var mediaControlState: MediaControlState = .initialize
    var mediaPlayerState: VLCMediaPlayerState = .buffering
    var mediaState: VLCMediaState = .buffering
    var currentTime: VLCTime = VLCTime(int: 0)
    var remainingTime: VLCTime = VLCTime(int: 0)
    var totalTime: VLCTime = VLCTime(int: 0)
    var seeking: Bool = false
    var initializing: Bool = true
    var downloadProgress = Progress()

    init(url: URL) {
        self.url = url
        self.id = url.lastPathComponent.components(separatedBy: ".")[0]
    }

    enum MediaControlState: Equatable, Hashable {
        case play
        case pause
        case seek(VLCTime)
        case jump(MediaControlDirection, Int32)

        static func == (lhs: MediaControlState, rhs: MediaControlState) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        case initialize
    }
    enum MediaControlDirection: String {
        case forward
        case backward
    }

    mutating func download() async throws -> URL? {
        downloadProgress.completedUnitCount = 0
        downloadProgress.totalUnitCount = 1

        let cacheURL = CacheManager.shared.cacheURL(url)
        guard !CacheManager.shared.cacheHit(file: cacheURL) else {
            downloadProgress.completedUnitCount = 1
            return cacheURL
        }

        if let existingOperation = Prefetcher.shared.videoPrefetcher.queue.operations.first(where: {
            ($0 as? DownloadOperation)?.downloadTaskURL == url
        }), let operation = existingOperation as? DownloadOperation {

            if operation.isExecuting,
               let data = await operation.task.cancelByProducingResumeData() {
                let (tempURL, _) = try await URLSession.shared.download(resumeFrom: data)
                return CacheManager.shared.cache(tempURL, cacheURL)
            }
        }

        debugPrint("Downloading webm: \(cacheURL)")
        let (tempURL, _) = try await URLSession.shared.download(from: url, progress: downloadProgress)
        debugPrint("Completed Downloading webm: \(cacheURL)")
        return CacheManager.shared.cache(tempURL, cacheURL)
    }
}

extension VLCVideo: Hashable {
    static func == (lhs: VLCVideo, rhs: VLCVideo) -> Bool {
        lhs.url == rhs.url
    }
}
