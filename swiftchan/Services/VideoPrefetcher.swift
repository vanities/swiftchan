//
//  DownloadQueue.swift
//  swiftchan
//
//  Created on 5/3/21.
//

import Foundation

@MainActor
class VideoPrefetcher {
    let queue = OperationQueue()

    // Track active operations by URL for smart cancellation
    private var activeOperations: [URL: DownloadOperation] = [:]

    init() {
        queue.maxConcurrentOperationCount = 4
        queue.qualityOfService = .utility
    }

    func addOperation(_ operation: DownloadOperation, for url: URL) {
        activeOperations[url] = operation
        queue.addOperation(operation)
    }

    func removeOperation(for url: URL) {
        activeOperations.removeValue(forKey: url)
    }

    func cancelOperationsOutside(videoUrls: [URL], currentIndex: Int, windowSize: Int) {
        let startIndex = max(0, currentIndex)
        let endIndex = min(videoUrls.count, currentIndex + windowSize)

        guard startIndex < endIndex else { return }

        let videosInWindow = Set(videoUrls[startIndex..<endIndex])

        let operationsToCancel = activeOperations.filter { url, _ in
            !videosInWindow.contains(url)
        }

        guard !operationsToCancel.isEmpty else { return }

        debugPrint("🎯 Canceling \(operationsToCancel.count) downloads outside prefetch window (index \(currentIndex), window \(startIndex)-\(endIndex))")

        for (url, operation) in operationsToCancel {
            operation.cancel()
            activeOperations.removeValue(forKey: url)
        }
    }

    func cancelAllOperations() {
        queue.cancelAllOperations()
        activeOperations.removeAll()
    }
}
