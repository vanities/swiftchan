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

    func prefetch(urls: [URL], currentIndex: Int = 0, prefetchWindow: Int = 5) {
        let imageUrls = urls.filter { url in url.isImage() || url.isGif()}
        prefetchImages(urls: imageUrls)

        // Smart video prefetching: only prefetch next N videos
        let videoUrls = urls.filter { url in url.isWebm() || url.isMP4() }

        // Calculate prefetch window
        let startIndex = max(0, currentIndex)
        let endIndex = min(videoUrls.count, currentIndex + prefetchWindow)

        guard startIndex < endIndex else { return }

        let videosToPreload = Array(videoUrls[startIndex..<endIndex])
        prefetchVideos(urls: videosToPreload)
    }

    func prefetchImages(urls: [URL]) {
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

            let operation = DownloadOperation(session: URLSession.shared, downloadTaskURL: url, completionHandler: { [weak self] (tempURL, _, _) in
                guard let self = self else { return }

                // Remove from active downloads when complete
                Task { @MainActor in
                    self.activeDownloads.remove(url)
                }

                if let tempURL = tempURL,
                   let result = CacheManager.shared.cache(tempURL, cacheURL, originalURL: url) {
                    debugPrint("successfully cached video url \(result)")
                }
            })

            if operation.isFinished || operation.isCancelled {
                activeDownloads.remove(url)
                continue // Skip this operation but continue the loop
            }

            DispatchQueue.main.async { [weak self] in
                self?.videoPrefetcher.queue.addOperation(operation)
            }
        }
    }

    func stopPrefetching() {
        imagePrefetcher.stop()
        videoPrefetcher.queue.cancelAllOperations()

        // Clear active downloads when stopping
        activeDownloads.removeAll()
    }
}
