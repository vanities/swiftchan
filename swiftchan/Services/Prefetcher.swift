//
//  Prefetcher.swift
//  swiftchan
//
//  Created on 5/2/21.
//

import Foundation
import Kingfisher

@MainActor
class Prefetcher {
    static let shared: Prefetcher = Prefetcher()
    var imagePrefetcher = ImagePrefetcher(urls: [])
    let videoPrefetcher = VideoPrefetcher()

    // Track in-progress downloads to prevent duplicates
    private var activeDownloads: Set<URL> = []

    // Track last prefetch position to avoid redundant updates
    private var lastPrefetchIndex: Int = -1
    private var lastVideoUrls: [URL] = []
    private var lastImageUrls: [URL] = []

    func prefetch(urls: [URL], currentIndex: Int = 0, prefetchWindow: Int = 8) {
        let imageUrls = urls.filter { url in url.isImage() || url.isGif()}
        prefetchImages(urls: imageUrls)

        // Smart video prefetching: only prefetch next N videos
        let videoUrls = urls.filter { url in url.isWebm() || url.isMP4() }

        // Debounce: Only update if user moved 2+ videos from last update
        let shouldUpdate = abs(currentIndex - lastPrefetchIndex) >= 2 || lastVideoUrls != videoUrls

        if shouldUpdate {
            updatePrefetchWindow(videoUrls: videoUrls, currentIndex: currentIndex, prefetchWindow: prefetchWindow)
            lastPrefetchIndex = currentIndex
            lastVideoUrls = videoUrls
        }
    }

    private func updatePrefetchWindow(videoUrls: [URL], currentIndex: Int, prefetchWindow: Int) {
        // Calculate prefetch window
        let startIndex = max(0, currentIndex)
        let endIndex = min(videoUrls.count, currentIndex + prefetchWindow)

        guard startIndex < endIndex else { return }

        // Cancel downloads outside the new window
        videoPrefetcher.cancelDownloadsOutside(videoUrls: videoUrls, currentIndex: currentIndex, windowSize: prefetchWindow)

        let videosToPreload = Array(videoUrls[startIndex..<endIndex])

        if !videosToPreload.isEmpty {
            debugPrint("📥 Prefetch window updated: videos \(startIndex)-\(endIndex-1)")
        }

        prefetchVideos(urls: videosToPreload)
    }

    func prefetchImages(urls: [URL]) {
        guard urls != lastImageUrls else { return }
        imagePrefetcher.stop()
        lastImageUrls = urls
        imagePrefetcher = ImagePrefetcher(
            urls: urls,
            options: [
                .alsoPrefetchToMemory,
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 5, retryInterval: .seconds(1)))
            ]
        ) { completedResources, skippedResources, failedResources in
             debugPrint(
                "These image resources are prefetched: \(completedResources.count), " +
                    "skipped: \(skippedResources.count), " +
                    "failed: \(failedResources.count)"
             )
        }
        imagePrefetcher.start()
    }
    func prefetchVideos(urls: [URL]) {
        for url in urls {
            let cacheURL = CacheManager.shared.cacheURL(url)

            // Skip if already cached or currently downloading
            guard !CacheManager.shared.cacheHit(file: cacheURL),
                  !activeDownloads.contains(url) else {
                continue
            }

            // Mark as downloading
            activeDownloads.insert(url)

            videoPrefetcher.addDownload(session: URLSession.shared, url: url) { [weak self] (tempURL, _, _) in
                guard let self = self else { return }

                // Remove from active downloads when complete
                Task { @MainActor in
                    self.activeDownloads.remove(url)
                    self.videoPrefetcher.removeDownload(for: url)
                }

                if let tempURL = tempURL,
                   let result = CacheManager.shared.cache(tempURL, cacheURL, originalURL: url) {
                    debugPrint("successfully cached video url \(result)")
                }
            }
        }
    }

    func stopPrefetching() {
        imagePrefetcher.stop()
        videoPrefetcher.cancelAllDownloads()

        // Clear active downloads when stopping
        activeDownloads.removeAll()

        // Reset tracking
        lastPrefetchIndex = -1
        lastVideoUrls = []
        lastImageUrls = []
    }
}
