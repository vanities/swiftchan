//
//  ThreadViewModel.swift
//  swiftchan
//
//  Created on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan
import Combine

@Observable
final class ThreadViewModel {
    enum State {
        case initial, loading, loaded, error
    }
    let prefetcher = Prefetcher.shared
    let boardName: String
    let id: Int

    private(set) var posts = [Post]()
    var media = [Media]()
    private(set) var postMediaMapping = [Int: Int]()
    private(set) var comments = [AttributedString]()
    private(set) var replies = [Int: [Int]]()
    private(set) var state = State.initial
    private(set) var progressText = ""
    private(set) var downloadProgress = Progress()
    private var cancellables: Set<AnyCancellable> = []

    var url: URL {
        return URL(string: "https://boards.4chan.org/\(self.boardName)/thread/\(self.id)")!
    }

    var title: String {
        posts.first?.sub?.clean ?? ""
    }

    init(boardName: String, id: Int, replies: [Int: [Int]] = [Int: [Int]]()) {
        self.boardName = boardName
        self.id = id
        self.replies = replies

        // Set up reactive progress tracking similar to VLCVideoViewModel
        downloadProgress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] fractionCompleted in
                guard let self else { return }
                // Only update if we don't have a custom message
                if self.progressText.isEmpty || self.progressText.hasPrefix("Loading thread") {
                    self.progressText = "Loading thread \(Int(fractionCompleted * 100))%"
                }
                debugPrint("📥 Thread download progress: \(Int(fractionCompleted * 100))%")
            }
            .store(in: &cancellables)
    }

    @MainActor
    func getPosts() async {
        if state != .loaded {
            state = .loading
            downloadProgress.totalUnitCount = 100
            downloadProgress.completedUnitCount = 0
        }

        do {
            // Phase 1: Fetching thread data (0-40%)
            await updateProgress(30, message: "Fetching thread data...")

            let thread = try await FourChanAsyncService.shared.getThread(boardName: boardName, no: id) { [weak self] progress in
                // Map API progress to our 0-40% range
                let mappedProgress = Int64(30 + (progress * 10))
                self?.downloadProgress.completedUnitCount = mappedProgress
            }
            let posts = thread.posts

            if posts.count > 0 {
                // Phase 2: Processing posts (40-80%)
                await updateProgress(40, message: "Processing posts...")

                var mediaUrls: [URL] = []
                var thumbnailMediaUrls: [URL] = []
                var mapping: [Int: Int] = [:]
                var comments: [AttributedString] = []
                var postReplies: [Int: [String]] = [:]
                var postIndex = 0
                var mediaIndex = 0

                for (index, post) in posts.enumerated() {
                    // Update progress during post processing
                    if index % max(1, posts.count / 10) == 0 {
                        let processingProgress = 40 + Int64((Double(index) / Double(posts.count)) * 40)
                        await updateProgress(processingProgress, message: "Processing posts...")
                    }
                    if let mediaUrl = post.getMediaUrl(boardId: boardName), let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                        mapping[postIndex] = mediaIndex
                        mediaUrls.append(mediaUrl)
                        thumbnailMediaUrls.append(thumbnailUrl)
                        mediaIndex += 1
                    }
                    if let comment = post.com {
                        let parser = CommentParser(comment: comment)
                        comments.append(parser.getComment())
                        postReplies[postIndex] = parser.replies
                    } else {
                        comments.append(AttributedString())
                    }
                    postIndex += 1
                }

                // Phase 3: Processing replies (80-90%)
                await updateProgress(80, message: "Processing replies...")
                let replies = FourchanService.getReplies(postReplies: postReplies, posts: posts)

                // Phase 4: Loading media (90-100%)
                await updateProgress(90, message: "Loading media...")
                self.posts = posts
                self.postMediaMapping = mapping
                self.comments = comments
                self.replies = replies
                setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)

                // Phase 5: Complete
                await updateProgress(100, message: "Complete!")
                state = .loaded
            } else if self.posts.isEmpty {
                state = .error
            }
        } catch {
            state = .error
        }
        print("Thread /\(boardName)/-\(id) successfully got \(self.posts.count) posts.")
    }

    private func updateProgress(_ progress: Int64, message: String) async {
        downloadProgress.completedUnitCount = progress
        progressText = message
        // Small delay to make progress visible
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }

    private func getMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) -> [Media] {
        var mediaList = [Media]()
        var index = 0
        for (mediaUrl, thumbnailMediaUrl) in zip(mediaUrls, thumbnailMediaUrls) {
            var media = Media(index: index, url: mediaUrl, thumbnailUrl: thumbnailMediaUrl)
            if media.format == .webm {
                if let cacheUrl = CacheManager.shared.getCacheValue(media.url) {
                    media = Media(index: index, url: cacheUrl, thumbnailUrl: thumbnailMediaUrl)
                }
            }

            mediaList.append(media)
            index += 1
        }
        return mediaList
    }

    @MainActor
    func setMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) {
        media = getMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
    }

    @MainActor
    func prefetch() {
        let urls = media.flatMap { media in
            return [media.thumbnailUrl, media.url]
        }
        prefetcher.prefetch(urls: urls)
    }

    @MainActor
    func stopPrefetching() {
        prefetcher.stopPrefetching()
    }

    func getPostIndexFromId(_ id: String) -> Int {
        var index = 0
        for post in posts {
            if id.contains(String(post.id)) {
                return index
            }
            index += 1
        }
        return 0
    }

}
