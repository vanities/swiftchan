//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import SwiftUI
import FourChan
import Combine

@Observable
class CatalogViewModel {
    enum LoadingState {
        case initial, loading, loaded, error

    }

    var boardName: String
    let prefetcher = Prefetcher()

    private(set) var posts = [SwiftchanPost]()
    var state = LoadingState.initial
    private var cancellables: Set<AnyCancellable> = []

    func getFilteredPosts(searchText: String) -> [SwiftchanPost] {
        if searchText.isEmpty {
            return posts
        } else {
            return posts.compactMap { swiftChanPost in
                let commentAndSubject = "\(swiftChanPost.post.com?.clean.lowercased() ?? "") \(swiftChanPost.post.sub?.clean.lowercased() ?? "")"
                return commentAndSubject.contains(searchText.lowercased()) ? swiftChanPost : nil
            }
        }
    }

    init(boardName: String) {
        self.boardName = boardName
    }

    deinit {
        stopPrefetching()
    }

    @MainActor
    func load() async {
        state = .loading
        posts = await FourchanService.getCatalog(boardName: boardName)

        if posts.count > 0 {
            state = .loaded
            handleSorting(value: UserDefaults.getSortFilesBy(boardName: boardName), attributeKey: "files")
            handleSorting(value: UserDefaults.getSortRepliesBy(boardName: boardName), attributeKey: "replies")

            NotificationCenter.default.publisher(for: .sortingRepliesDidChange)
                .sink { [weak self] newValue in
                    DispatchQueue.main.async {
                        self?.handleSorting(value: UserDefaults.getSortRepliesBy(boardName: self!.boardName), attributeKey: "replies")
                    }
                }
                .store(in: &cancellables)

            NotificationCenter.default.publisher(for: .sortingFilesDidChange)
                .sink { [weak self] newValue in
                    DispatchQueue.main.async {
                        self?.handleSorting(value: UserDefaults.getSortFilesBy(boardName: self!.boardName), attributeKey: "files")
                    }
                }
                .store(in: &cancellables)
        } else {
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
