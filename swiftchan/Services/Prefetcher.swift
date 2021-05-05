//
//  Prefetcher.swift
//  swiftchan
//
//  Created by vanities on 5/2/21.
//

import Foundation
import Kingfisher

class Prefetcher {
    static let shared = Prefetcher()

    func prefetch(urls: [URL]) {
        let imageUrls = urls.filter { url in url.isImage() || url.isGif()}
        prefetchImages(urls: imageUrls)
        let videoUrls = urls.filter { url in url.isWebm() }
        prefetchVideos(urls: videoUrls)
    }

    func prefetchImages(urls: [URL]) {
        let prefetcher = ImagePrefetcher(
            urls: urls,
            options: [
                .retryStrategy(DelayRetryStrategy(maxRetryCount: 5, retryInterval: .seconds(1)))
                // .processingQueue(.mainAsync)
            ]
        ) { _, _, _ in
            /*
             debugPrint(
             "These image resources are prefetched: \(completedResources), " +
             "skipped: \(skippedResources), " +
             "failed: \(failedResources)"
             )
             */
        }
        prefetcher.start()
    }
    func prefetchVideos(urls: [URL]) {
        for url in urls {
            let cacheURL = CacheManager.shared.cacheURL(stringURL: url.absoluteString)
            guard !CacheManager.shared.cacheHit(file: cacheURL) else { continue }
            let operation = DownloadOperation(session: URLSession.shared, downloadTaskURL: url, completionHandler: { (tempURL, _, _) in
                if let tempURL = tempURL {
                    CacheManager.shared.cache(tempURL: tempURL, cacheURL: cacheURL) { _ in
                        print("finished downloading \(url.absoluteString)")
                    }
                }
            })

            DownloadQueue.queue.addOperation(operation)
        }

    }

    func stopPrefetching() {
        DownloadQueue.queue.cancelAllOperations()
    }
}
