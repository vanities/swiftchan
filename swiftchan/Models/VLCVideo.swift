//
//  VLCVideo.swift
//  swiftchan
//
//  Created by vanities on 5/1/21.
//

import SwiftUI
import MobileVLCKit

struct VLCVideo: Equatable, Identifiable, Sendable {
    let id: String
    // weak var urlSessionDelegate: URLSessionDownloadDelegate?
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
        self.downloadProgress.completedUnitCount = 0
        self.downloadProgress.totalUnitCount = 1
    }

    enum MediaControlState: Equatable, Hashable {
        case play
        case resume
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
        let cacheURL = CacheManager.shared.cacheURL(url)
        guard !CacheManager.shared.cacheHit(file: cacheURL) else {
            await setDownloadProgressFinished()
            return cacheURL
        }

        debugPrint("Downloading webm: \(cacheURL)")
        let (tempURL, _) = try await URLSession.shared.download(from: url, progress: downloadProgress)
        debugPrint("Completed Downloading webm: \(cacheURL)")
        let cached = CacheManager.shared.cache(tempURL, cacheURL)
        await setDownloadProgressFinished()
        return cached
    }


    mutating func setDownloadProgressFinished() async {
        DispatchQueue.main.async { [self] in
            self.downloadProgress.completedUnitCount = 1
            self.downloadProgress.totalUnitCount = 1
        }
    }
}

extension VLCVideo: Hashable {
    static func == (lhs: VLCVideo, rhs: VLCVideo) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

