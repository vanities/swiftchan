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
    typealias ThreadLoader = (String, Int, @escaping @Sendable (Double) -> Void) async throws -> ChanThread
    typealias ArchiveLoader = (String, Int) async throws -> FourplebsThread
    @ObservationIgnored private let fetchThread: ThreadLoader
    @ObservationIgnored private let fetchArchive: ArchiveLoader
    @ObservationIgnored private var isLoading = false
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
    private(set) var replies = [Int: [Int]]()
    private(set) var state = State.initial
    private(set) var errorType = ErrorType.generic
    private(set) var refreshError: String?
    private(set) var isArchived = false
    private(set) var progressText = ""
    private(set) var downloadProgress = Progress()
    private var cancellables: Set<AnyCancellable> = []

    // Lazy comment parsing: store raw HTML, parse AttributedString on demand
    @ObservationIgnored private var rawComments = [String?]()
    @ObservationIgnored private var commentCache = [Int: AttributedString]()
    @ObservationIgnored private var searchableComments = [String]()

    var searchText = ""
    var searchFilters = SearchFilters()
    private(set) var currentSearchResultIndex = 0
    private(set) var searchResultIndices: [Int] = []
    @ObservationIgnored private var searchResultIndexSet = Set<Int>()
    @ObservationIgnored private var postIdToIndex = [Int: Int]()

    var url: URL {
        return URL(string: "https://boards.4chan.org/\(self.boardName)/thread/\(self.id)")!
    }

    func postURL(_ postID: Int) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = "p\(postID)"
        return components?.url ?? url
    }

    var title: String {
        posts.first?.sub?.clean ?? ""
    }

    var canLoadFromArchive: Bool {
        FourplebsService.isSupported(board: boardName)
    }

    var archiveUrl: URL? {
        FourplebsService.archiveUrl(board: boardName, threadNum: id)
    }

    /// Lazily parses and caches the AttributedString for a post's comment.
    func comment(at index: Int) -> AttributedString {
        if let cached = commentCache[index] {
            return cached
        }
        guard rawComments.indices.contains(index), let raw = rawComments[index] else {
            return AttributedString()
        }
        let parsed = CommentParser(comment: raw).getComment()
        commentCache[index] = parsed
        return parsed
    }

    init(
        boardName: String,
        id: Int,
        replies: [Int: [Int]] = [:],
        fetchThread: @escaping ThreadLoader = { board, id, progress in
            #if DEBUG
            if let fixture = try ThreadUITestFixture.load(board: board, id: id) { return fixture }
            #endif
            return try await FourChanAsyncService.shared.getThread(boardName: board, no: id, progress: progress)
        },
        fetchArchive: @escaping ArchiveLoader = { board, id in
            try await FourplebsService.shared.getThread(board: board, threadNum: id)
        }
    ) {
        self.boardName = boardName
        self.id = id
        self.replies = replies
        self.fetchThread = fetchThread
        self.fetchArchive = fetchArchive
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

    @discardableResult
    func getPosts() async -> Bool {
        guard beginLoading() else { return false }
        defer { isLoading = false }

        do {
            updateProgress(30, message: "Fetching thread data...")
            let thread = try await fetchThread(boardName, id) { @Sendable progress in
                Task { @MainActor [weak self] in
                    self?.downloadProgress.completedUnitCount = Int64(30 + progress * 10)
                }
            }
            try Task.checkCancellation()
            guard !thread.posts.isEmpty else {
                reportFailure(.notFound)
                return false
            }
            let contents = thread.posts.map { post in
                LoadedPost(post: post, mediaURL: post.getMediaUrl(boardId: boardName),
                           thumbnailURL: post.getMediaUrl(boardId: boardName, thumbnail: true))
            }
            apply(contents, archived: false)
            return true
        } catch {
            handleFailure(error)
            return false
        }
    }

    @discardableResult
    func loadFromArchive() async -> Bool {
        guard canLoadFromArchive, beginLoading() else { return false }
        defer { isLoading = false }

        do {
            updateProgress(20, message: "Fetching from archive...")
            let thread = try await fetchArchive(boardName, id)
            try Task.checkCancellation()
            let contents = thread.getAllPosts().compactMap { archivedPost -> LoadedPost? in
                guard let post = archivedPost.toPost(board: boardName) else { return nil }
                return LoadedPost(post: post,
                                  mediaURL: archivedPost.media?.mediaLink.flatMap(URL.init(string:)),
                                  thumbnailURL: archivedPost.media?.thumbLink.flatMap(URL.init(string:)))
            }
            guard !contents.isEmpty else {
                reportFailure(.notFound)
                return false
            }
            apply(contents, archived: true)
            return true
        } catch {
            handleFailure(error)
            return false
        }
    }

    private func beginLoading() -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        refreshError = nil
        if posts.isEmpty { state = .loading }
        downloadProgress.totalUnitCount = 100
        downloadProgress.completedUnitCount = 0
        return true
    }

    private struct LoadedPost {
        let post: Post
        let mediaURL: URL?
        let thumbnailURL: URL?
    }

    /// Install live and archived responses together so every index refers to the same snapshot.
    private func apply(_ contents: [LoadedPost], archived: Bool) {
        updateProgress(50, message: "Processing posts...")
        var mediaURLs: [URL] = []
        var thumbnailURLs: [URL] = []
        var mapping: [Int: Int] = [:]
        var postReplies: [Int: [String]] = [:]
        for (index, content) in contents.enumerated() {
            if let mediaURL = content.mediaURL, let thumbnailURL = content.thumbnailURL {
                mapping[index] = mediaURLs.count
                mediaURLs.append(mediaURL)
                thumbnailURLs.append(thumbnailURL)
            }
            if let comment = content.post.com {
                postReplies[index] = CommentParser.extractReplyIds(from: comment)
            }
        }
        posts = contents.map(\.post)
        postMediaMapping = mapping
        rawComments = posts.map(\.com)
        searchableComments = rawComments.map { $0?.clean ?? "" }
        commentCache.removeAll()
        replies = FourchanService.getReplies(postReplies: postReplies, posts: posts)
        buildPostIdIndex()
        setMedia(mediaUrls: mediaURLs, thumbnailMediaUrls: thumbnailURLs)
        isArchived = archived
        errorType = .generic
        updateSearchResults()
        updateProgress(100, message: "Complete!")
        state = .loaded
    }

    private func handleFailure(_ error: Error) {
        if error is CancellationError || (error as? URLError)?.code == .cancelled {
            state = posts.isEmpty ? .initial : .loaded
            return
        }
        if let archiveError = error as? FourplebsService.FourplebsError {
            switch archiveError {
            case .notFound, .unsupportedBoard:
                reportFailure(.notFound)
            case .antiBot, .networkError, .decodingError, .invalidResponse:
                reportFailure(.network)
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .resourceUnavailable, .fileDoesNotExist:
                reportFailure(.notFound)
            default:
                reportFailure(.network)
            }
        } else if error is DecodingError {
            // The current API package surfaces non-JSON 404 responses as decoding failures.
            reportFailure(.notFound)
        } else {
            let description = error.localizedDescription.lowercased()
            reportFailure(description.contains("404") || description.contains("not found") ? .notFound : .generic)
        }
    }

    private func reportFailure(_ type: ErrorType) {
        errorType = type
        state = posts.isEmpty ? .error : .loaded
        if !posts.isEmpty {
            refreshError = type == .notFound
                ? "This thread is no longer available. Showing previously loaded posts."
                : "Couldn’t refresh the thread. Pull down to try again."
        }
    }

    private func updateProgress(_ progress: Int64, message: String) {
        downloadProgress.completedUnitCount = progress
        progressText = message
    }

    private func getMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) -> [Media] {
        var mediaList = [Media]()
        var index = 0
        for (mediaUrl, thumbnailMediaUrl) in zip(mediaUrls, thumbnailMediaUrls) {
            var media = Media(index: index, url: mediaUrl, thumbnailUrl: thumbnailMediaUrl)
            if media.format == .webm || media.format == .mp4 {
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

    private func buildPostIdIndex() {
        postIdToIndex.removeAll()
        postIdToIndex.reserveCapacity(posts.count)
        for (index, post) in posts.enumerated() {
            postIdToIndex[post.id] = index
        }
    }

    func getPostIndexFromId(_ id: String) -> Int? {
        guard let postID = Int(id), postID > 0 else { return nil }
        return postIdToIndex[postID]
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
                let comment = index < searchableComments.count ? searchableComments[index] : ""
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
        searchResultIndexSet = Set(searchResultIndices)
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
        return searchResultIndexSet.contains(index)
    }

}
