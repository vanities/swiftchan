//
//  VideoPrefetcher.swift
//  swiftchan
//
//  Created on 5/3/21.
//

import Foundation

@MainActor
class VideoPrefetcher {
    // Active downloads keyed by URL
    private var activeTasks: [URL: URLSessionDownloadTask] = [:]

    // Queued downloads waiting for a slot
    private var pendingDownloads: [(url: URL, session: URLSession,
                                    completion: @Sendable (URL?, URLResponse?, Error?) -> Void)] = []

    private let maxConcurrent = 4

    func addDownload(session: URLSession, url: URL,
                     completion: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) {
        // Already downloading this URL
        guard activeTasks[url] == nil else { return }

        if activeTasks.count >= maxConcurrent {
            // Don't double-queue
            guard !pendingDownloads.contains(where: { $0.url == url }) else { return }
            pendingDownloads.append((url: url, session: session, completion: completion))
            return
        }

        startDownload(session: session, url: url, completion: completion)
    }

    func removeDownload(for url: URL) {
        pendingDownloads.removeAll { $0.url == url }
    }

    func cancelDownloadsOutside(videoUrls: [URL], currentIndex: Int, windowSize: Int) {
        let startIndex = max(0, currentIndex)
        let endIndex = min(videoUrls.count, currentIndex + windowSize)
        guard startIndex < endIndex else { return }

        let videosInWindow = Set(videoUrls[startIndex..<endIndex])

        let urlsToCancel = activeTasks.keys.filter { !videosInWindow.contains($0) }

        if !urlsToCancel.isEmpty {
            debugPrint("🎯 Canceling \(urlsToCancel.count) downloads outside prefetch window (index \(currentIndex), window \(startIndex)-\(endIndex))")
        }

        for url in urlsToCancel {
            activeTasks[url]?.cancel()
            activeTasks.removeValue(forKey: url)
        }

        pendingDownloads.removeAll { !videosInWindow.contains($0.url) }
    }

    func cancelAllDownloads() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        pendingDownloads.removeAll()
    }

    // MARK: - Private

    private func startDownload(session: URLSession, url: URL,
                               completion: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) {
        let task = session.downloadTask(with: url) { [weak self] localURL, response, error in
            completion(localURL, response, error)
            Task { @MainActor [weak self] in
                self?.taskCompleted(url: url)
            }
        }
        activeTasks[url] = task
        debugPrint("downloading \(url.absoluteString)")
        task.resume()
    }

    private func taskCompleted(url: URL) {
        activeTasks.removeValue(forKey: url)
        startNextPending()
    }

    private func startNextPending() {
        while activeTasks.count < maxConcurrent, !pendingDownloads.isEmpty {
            let next = pendingDownloads.removeFirst()
            guard activeTasks[next.url] == nil else { continue }
            startDownload(session: next.session, url: next.url, completion: next.completion)
        }
    }
}
