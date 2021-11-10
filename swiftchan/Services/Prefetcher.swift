//
//  Prefetcher.swift
//  swiftchan
//
//  Created by vanities on 5/2/21.
//

import Foundation
import Kingfisher

class Prefetcher {
    var imagePrefetcher = ImagePrefetcher(urls: [])
    let videoPrefetcher = VideoPrefetcher()

    func prefetch(urls: [URL], videoComplete: ((URL, URL) -> Void)?) {
        let imageUrls = urls.filter { url in url.isImage() || url.isGif()}
        prefetchImages(urls: imageUrls)
        let videoUrls = urls.filter { url in url.isWebm() }
        prefetchVideos(urls: videoUrls) { url, cacheUrl in
            videoComplete?(url, cacheUrl)
        }
    }

    func prefetchImages(urls: [URL]) {
        imagePrefetcher = ImagePrefetcher(
            urls: urls,
            options: [
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
    func prefetchVideos(urls: [URL], videoComplete: ((URL, URL) -> Void)?) {
        for url in urls {
            let cacheURL = CacheManager.shared.cacheURL(url)
            guard !CacheManager.shared.cacheHit(file: cacheURL) else { continue }
            let operation = DownloadOperation(session: URLSession.shared, downloadTaskURL: url, completionHandler: { (tempURL, _, _) in
                if let tempURL = tempURL {
                    CacheManager.shared.cache(tempURL: tempURL, cacheURL: cacheURL) { result in
                        switch result {
                        case .success(let cacheSuccessUrl):
                            videoComplete?(url, cacheSuccessUrl)
                            return
                        case .failure(_):
                            return
                        }
                    }
                }
            })

            videoPrefetcher.queue.addOperation(operation)
        }

    }

    func stopPrefetching() {
        imagePrefetcher.stop()
        videoPrefetcher.queue.cancelAllOperations()
    }
}
