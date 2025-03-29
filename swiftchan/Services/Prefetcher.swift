//
//  Prefetcher.swift
//  swiftchan
//
//  Created by vanities on 5/2/21.
//

import Foundation
import Kingfisher

@MainActor
class Prefetcher {
    static let shared: Prefetcher = Prefetcher()
    var imagePrefetcher = ImagePrefetcher(urls: [])
    let videoPrefetcher = VideoPrefetcher()

    func prefetch(urls: [URL]) {
        let imageUrls = urls.filter { url in url.isImage() || url.isGif()}
        prefetchImages(urls: imageUrls)
        let videoUrls = urls.filter { url in url.isWebm() }
        prefetchVideos(urls: videoUrls)
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
            guard !CacheManager.shared.cacheHit(file: cacheURL) else {
                continue
            }
            let operation = DownloadOperation(session: URLSession.shared, downloadTaskURL: url, completionHandler: { [weak self] (tempURL, _, _) in
                guard let self = self else { return }
                if let tempURL = tempURL,
                   let result = CacheManager.shared.cache(tempURL, cacheURL) {
                    debugPrint("successfully cached video url \(result)")
                }
            })
            if operation.isFinished || operation.isCancelled {
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
    }
}
