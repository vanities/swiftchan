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

struct SearchFilters: Equatable {
    var hasMedia: Bool = false
    var posterID: String?
    var hasReplies: Bool = false
}

@Observable @MainActor
final class ThreadViewModel {
    enum State {
        case initial, loading, loaded, error
    }

    enum ErrorType {
        case generic
        case notFound
        case network
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
    private(set) var errorType = ErrorType.generic
    private(set) var isArchiveThread = false
    private(set) var progressText = ""
    private(set) var downloadProgress = Progress()
    private var cancellables: Set<AnyCancellable> = []

    var searchText = ""
    var searchFilters = SearchFilters()
    private(set) var currentSearchResultIndex = 0
    private(set) var searchResultIndices: [Int] = []

    var url: URL {
        return URL(string: "https://boards.4chan.org/\(self.boardName)/thread/\(self.id)")!
    }

    var title: String {
        posts.first?.sub?.clean ?? ""
    }

    var canLoadFromArchive: Bool {
        FourplebsService.isSupported(board: boardName)
    }

    init(boardName: String, id: Int, replies: [Int: [Int]] = [Int: [Int]]()) {
        self.boardName = boardName
        self.id = id
        self.replies = replies
        setupProgressTracking()
    }

    private func setupProgressTracking() {
        // Cancel any existing subscriptions
        cancellables.removeAll()

        // Set up reactive progress tracking
        downloadProgress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] fractionCompleted in
                guard let self else { return }
                // Only log if we're actually downloading
                if self.state == .loading {
                    // Only update if we don't have a custom message
                    if self.progressText.isEmpty || self.progressText.hasPrefix("Loading thread") {
                        self.progressText = "Loading thread..."
                    }
                    debugPrint("📥 Thread download progress: \(Int(fractionCompleted * 100))%")
                }
            }
            .store(in: &cancellables)
    }

    func getPosts() async {
        // Reset progress without creating new object
        downloadProgress.totalUnitCount = 100
        downloadProgress.completedUnitCount = 0
        setupProgressTracking()

        if state != .loaded {
            state = .loading
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
                errorType = .notFound
                state = .error
            }
        } catch {
            // Determine error type based on the error
            if let urlError = error as? URLError {
                switch urlError.code {
                case .resourceUnavailable, .fileDoesNotExist, .cannotFindHost:
                    errorType = .notFound
                default:
                    errorType = .network
                }
            } else {
                // Check if error message indicates not found
                let errorString = error.localizedDescription.lowercased()
                if errorString.contains("404") || errorString.contains("not found") {
                    errorType = .notFound
                } else {
                    errorType = .generic
                }
            }
            state = .error
        }
        print("Thread /\(boardName)/-\(id) successfully got \(self.posts.count) posts.")
    }

    func loadFromArchive() async {
        guard canLoadFromArchive else { return }

        isArchiveThread = true
        state = .loading

        // Reset progress
        downloadProgress.totalUnitCount = 100
        downloadProgress.completedUnitCount = 0
        setupProgressTracking()

        do {
            await updateProgress(20, message: "Fetching from archive...")

            let archivePosts = try await FourplebsService.shared.getThread(
                board: boardName,
                threadNum: id
            )

            await updateProgress(50, message: "Processing archived posts...")

            if !archivePosts.isEmpty {
                var mediaUrls: [URL] = []
                var thumbnailMediaUrls: [URL] = []
                var mapping: [Int: Int] = [:]
                var comments: [AttributedString] = []
                var postReplies: [Int: [String]] = [:]
                var postIndex = 0
                var mediaIndex = 0

                for (index, post) in archivePosts.enumerated() {
                    if index % max(1, archivePosts.count / 10) == 0 {
                        let processingProgress = 50 + Int64((Double(index) / Double(archivePosts.count)) * 30)
                        await updateProgress(processingProgress, message: "Processing archived posts...")
                    }

                    // Use archive media URLs (i.4pcdn.org)
                    if let mediaUrl = post.getArchiveMediaUrl(boardId: boardName),
                       let thumbnailUrl = post.getArchiveMediaUrl(boardId: boardName, thumbnail: true) {
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

                await updateProgress(85, message: "Processing replies...")
                let replies = FourchanService.getReplies(postReplies: postReplies, posts: archivePosts)

                await updateProgress(95, message: "Loading media...")
                self.posts = archivePosts
                self.postMediaMapping = mapping
                self.comments = comments
                self.replies = replies
                setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)

                await updateProgress(100, message: "Complete!")
                state = .loaded
            } else {
                errorType = .notFound
                state = .error
            }
        } catch let error as FourplebsService.FourplebsError {
            switch error {
            case .notFound, .unsupportedBoard:
                errorType = .notFound
            case .networkError, .decodingError, .invalidResponse:
                errorType = .network
            }
            state = .error
        } catch {
            errorType = .generic
            state = .error
        }

        print("Archive thread /\(boardName)/-\(id) got \(self.posts.count) posts.")
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

    func setMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) {
        media = getMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
    }

    func prefetch(currentIndex: Int = 0) {
        let urls = media.flatMap { media in
            return [media.thumbnailUrl, media.url]
        }
        prefetcher.prefetch(urls: urls, currentIndex: currentIndex)
    }

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

    func getFilteredPostIndices() -> [Int] {
        guard !searchText.isEmpty || searchFilters != SearchFilters() else {
            return Array(0..<posts.count)
        }

        var filteredIndices: [Int] = []
        let searchTextLowercased = searchText.lowercased()

        for (index, post) in posts.enumerated() {
            var matchesSearch = true

            if !searchText.isEmpty {
                let comment = index < comments.count ? String(comments[index].characters) : ""
                let subject = post.sub?.clean.lowercased() ?? ""
                let name = post.name?.lowercased() ?? ""
                let trip = post.trip?.lowercased() ?? ""
                let filename = post.filename?.lowercased() ?? ""
                let postNumber = String(post.no)
                let posterID = post.pid?.lowercased() ?? ""

                let searchableText = "\(comment.lowercased()) \(subject) \(name) \(trip) \(filename) \(postNumber) \(posterID)"
                matchesSearch = searchableText.contains(searchTextLowercased)
            }

            if searchFilters.hasMedia && post.tim == nil {
                matchesSearch = false
            }

            if let filterPosterID = searchFilters.posterID, !filterPosterID.isEmpty {
                if post.pid?.lowercased() != filterPosterID.lowercased() {
                    matchesSearch = false
                }
            }

            if searchFilters.hasReplies {
                if replies[index] == nil || replies[index]?.isEmpty == true {
                    matchesSearch = false
                }
            }

            if matchesSearch {
                filteredIndices.append(index)
            }
        }

        return filteredIndices
    }

    func updateSearchResults() {
        searchResultIndices = getFilteredPostIndices()
        if currentSearchResultIndex >= searchResultIndices.count {
            currentSearchResultIndex = max(0, searchResultIndices.count - 1)
        }
    }

    func jumpToNextSearchResult() {
        guard !searchResultIndices.isEmpty else { return }
        currentSearchResultIndex = (currentSearchResultIndex + 1) % searchResultIndices.count
    }

    func jumpToPreviousSearchResult() {
        guard !searchResultIndices.isEmpty else { return }
        if currentSearchResultIndex == 0 {
            currentSearchResultIndex = searchResultIndices.count - 1
        } else {
            currentSearchResultIndex -= 1
        }
    }

    func getCurrentSearchResultPostIndex() -> Int? {
        guard !searchResultIndices.isEmpty,
              currentSearchResultIndex < searchResultIndices.count else { return nil }
        return searchResultIndices[currentSearchResultIndex]
    }

    func shouldShowPost(at index: Int) -> Bool {
        if searchText.isEmpty && searchFilters == SearchFilters() {
            return true
        }
        return searchResultIndices.contains(index)
    }

}
