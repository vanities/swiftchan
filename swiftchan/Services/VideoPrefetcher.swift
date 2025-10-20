//
//  DownloadQueue.swift
//  swiftchan
//
//  Created on 5/3/21.
//

import Foundation

class VideoPrefetcher {
    let queue = OperationQueue()

    // Track active operations by URL for smart cancellation
    private var activeOperations: [URL: DownloadOperation] = [:]
    private let operationsQueue = DispatchQueue(label: "com.swiftchan.videoprefetcher", attributes: .concurrent)

    init() {
        queue.maxConcurrentOperationCount = 3
        queue.underlyingQueue = .global()
    }

    func addOperation(_ operation: DownloadOperation, for url: URL) {
        operationsQueue.async(flags: .barrier) { [weak self] in
            self?.activeOperations[url] = operation
        }
        queue.addOperation(operation)
    }

    func removeOperation(for url: URL) {
        operationsQueue.async(flags: .barrier) { [weak self] in
            self?.activeOperations.removeValue(forKey: url)
        }
    }

    func cancelOperationsOutside(videoUrls: [URL], currentIndex: Int, windowSize: Int) {
        let startIndex = max(0, currentIndex)
        let endIndex = min(videoUrls.count, currentIndex + windowSize)

        guard startIndex < endIndex else { return }

        let videosInWindow = Set(videoUrls[startIndex..<endIndex])

        var operationsToCancel: [URL: DownloadOperation] = [:]
        operationsQueue.sync {
            operationsToCancel = activeOperations.filter { url, _ in
                !videosInWindow.contains(url)
            }
        }

        guard !operationsToCancel.isEmpty else { return }

        debugPrint("🎯 Canceling \(operationsToCancel.count) downloads outside prefetch window (index \(currentIndex), window \(startIndex)-\(endIndex))")

        for (url, operation) in operationsToCancel {
            operation.cancel()
            removeOperation(for: url)
        }
    }

    func cancelAllOperations() {
        queue.cancelAllOperations()
        operationsQueue.async(flags: .barrier) { [weak self] in
            self?.activeOperations.removeAll()
        }
    }
}
