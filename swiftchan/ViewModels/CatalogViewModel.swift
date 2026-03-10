//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created on 11/12/20.
//

import SwiftUI
import FourChan
import Combine

struct CatalogSearchFilters: Equatable {
    var hasMedia: Bool = false
    var minReplies: Int?
    var maxReplies: Int?
    var minImages: Int?
    var maxImages: Int?
}

@Observable @MainActor
class CatalogViewModel {
    enum LoadingState {
        case initial, loading, loaded, error

    }

    var boardName: String
    let prefetcher = Prefetcher.shared

    private(set) var posts = [SwiftchanPost]()
    var state = LoadingState.initial
    private(set) var progressText = ""
    private(set) var downloadProgress = Progress()
    private var cancellables: Set<AnyCancellable> = []

    var searchText = ""
    var searchFilters = CatalogSearchFilters()
    private(set) var currentSearchResultIndex = 0
    private(set) var searchResultIndices: [Int] = []

    // Memoized filter cache
    @ObservationIgnored private var cachedFilteredPosts: [SwiftchanPost]?
    @ObservationIgnored private var cachedFilterSearchText: String = ""
    @ObservationIgnored private var cachedFilterFilters: CatalogSearchFilters = CatalogSearchFilters()
    @ObservationIgnored private var cachedFilterPostsCount: Int = 0

    func getFilteredPosts(searchText: String) -> [SwiftchanPost] {
        return getFilteredPostsWithFilters(searchText: searchText, filters: CatalogSearchFilters())
    }

    func getFilteredPostsWithFilters(searchText: String = "", filters: CatalogSearchFilters = CatalogSearchFilters()) -> [SwiftchanPost] {
        // Return cached result if inputs haven't changed
        if let cached = cachedFilteredPosts,
           cachedFilterSearchText == searchText,
           cachedFilterFilters == filters,
           cachedFilterPostsCount == posts.count {
            return cached
        }

        var filteredPosts = posts

        if !searchText.isEmpty {
            let searchTextLowercased = searchText.lowercased()
            filteredPosts = filteredPosts.filter { swiftChanPost in
                let comment = swiftChanPost.post.com?.clean.lowercased() ?? ""
                let subject = swiftChanPost.post.sub?.clean.lowercased() ?? ""
                let name = swiftChanPost.post.name?.lowercased() ?? ""
                let filename = swiftChanPost.post.filename?.lowercased() ?? ""
                let postNumber = String(swiftChanPost.post.no)

                let searchableText = "\(comment) \(subject) \(name) \(filename) \(postNumber)"
                return searchableText.contains(searchTextLowercased)
            }
        }

        if filters.hasMedia {
            filteredPosts = filteredPosts.filter { $0.post.tim != nil }
        }

        if let minReplies = filters.minReplies {
            filteredPosts = filteredPosts.filter { ($0.post.replies ?? 0) >= minReplies }
        }

        if let maxReplies = filters.maxReplies {
            filteredPosts = filteredPosts.filter { ($0.post.replies ?? 0) <= maxReplies }
        }

        if let minImages = filters.minImages {
            filteredPosts = filteredPosts.filter { ($0.post.images ?? 0) >= minImages }
        }

        if let maxImages = filters.maxImages {
            filteredPosts = filteredPosts.filter { ($0.post.images ?? 0) <= maxImages }
        }

        // Cache the result
        cachedFilteredPosts = filteredPosts
        cachedFilterSearchText = searchText
        cachedFilterFilters = filters
        cachedFilterPostsCount = posts.count

        return filteredPosts
    }

    func updateSearchResults() {
        let filteredPosts = getFilteredPostsWithFilters(searchText: searchText, filters: searchFilters)
        searchResultIndices = filteredPosts.map { $0.index }

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

    init(boardName: String) {
        self.boardName = boardName

        // Set up reactive progress tracking
        downloadProgress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] fractionCompleted in
                guard let self else { return }
                // Only update if we don't have a custom message
                if self.progressText.isEmpty || self.progressText.hasPrefix("Loading /\(self.boardName)/") {
                    self.progressText = "Loading /\(self.boardName)/..."
                }
                debugPrint("📥 Catalog download progress: \(Int(fractionCompleted * 100))%")
            }
            .store(in: &cancellables)
    }

    func load() async {
        state = .loading
        downloadProgress.totalUnitCount = 100
        downloadProgress.completedUnitCount = 0
        progressText = "Fetching /\(boardName)/ catalog..."

        do {
            let catalog = try await FourChanAsyncService.shared.getCatalog(boardName: boardName) { @Sendable progress in
                let mappedProgress = Int64(20 + (progress * 40))
                Task { @MainActor [weak self] in
                    self?.downloadProgress.completedUnitCount = mappedProgress
                }
            }

            var tempPosts: [SwiftchanPost] = []
            var index = 0

            for page in catalog {
                for thread in page.threads {
                    let comment: AttributedString
                    if let com = thread.com {
                        comment = CommentParser(comment: com).getComment()
                    } else {
                        comment = AttributedString()
                    }
                    tempPosts.append(SwiftchanPost(post: thread, boardName: boardName, comment: comment, index: index))
                    index += 1
                }
            }

            posts = tempPosts
            downloadProgress.completedUnitCount = 100

            if posts.count > 0 {
                state = .loaded
                handleSorting(value: UserDefaults.getSortFilesBy(boardName: boardName), attributeKey: "files")
                handleSorting(value: UserDefaults.getSortRepliesBy(boardName: boardName), attributeKey: "replies")

                NotificationCenter.default.publisher(for: .sortingRepliesDidChange)
                    .sink { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.handleSorting(value: UserDefaults.getSortRepliesBy(boardName: self!.boardName), attributeKey: "replies")
                        }
                    }
                    .store(in: &cancellables)

                NotificationCenter.default.publisher(for: .sortingFilesDidChange)
                    .sink { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.handleSorting(value: UserDefaults.getSortFilesBy(boardName: self!.boardName), attributeKey: "files")
                        }
                    }
                    .store(in: &cancellables)
            } else {
                state = .error
            }
        } catch {
            state = .error
        }
    }

    func handleSorting(value: SortRow.SortType, attributeKey: String) {
        guard value != .none else {
            return
        }
        posts.sort { (lhs: SwiftchanPost, rhs: SwiftchanPost) -> Bool in
            // https://stackoverflow.com/questions/26829304/assigning-operator-function-in-variable
            let operation: (Int, Int) -> Bool = value == .ascending ? (<) : (>)
            return operation(
                lhs.post.valueByPropertyName(name: attributeKey),
                rhs.post.valueByPropertyName(name: attributeKey)
            )
        }
        cachedFilteredPosts = nil
    }

    func prefetch() {
        let urls = posts.compactMap { post in
            return post.post.getMediaUrl(boardId: boardName, thumbnail: !UserDefaults.getFullImagesForThumbanails())
        }
        prefetcher.prefetchImages(urls: urls)
    }

    func stopPrefetching() {
        prefetcher.stopPrefetching()
    }

}
