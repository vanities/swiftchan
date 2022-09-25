//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan
import Defaults
import Combine

class CatalogViewModel: ObservableObject {
    enum LoadingState {
        case initial, loading, loaded, error

    }

    var boardName: String
    let prefetcher = Prefetcher()

    @Published private(set) var posts = [SwiftchanPost]()
    @Published var state = LoadingState.initial

    private var cancellable = Set<AnyCancellable>()

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
            handleSorting(value: Defaults.sortFilesBy(boardName: boardName), attributeKey: "files")
            handleSorting(value: Defaults.sortRepliesBy(boardName: boardName), attributeKey: "replies")
            prefetch(boardName: boardName)

            Defaults.publisher(.sortFilesBy(boardName: boardName))
                .sink { change in
                    DispatchQueue.main.async { [weak self] in
                        self?.handleSorting(value: change.newValue, attributeKey: "files")
                    }
                }
                .store(in: &cancellable)

            Defaults.publisher(.sortRepliesBy(boardName: boardName))
                .sink { change in
                    DispatchQueue.main.async { [weak self] in
                        self?.handleSorting(value: change.newValue, attributeKey: "replies")
                    }
                }
                .store(in: &cancellable)
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

    func prefetch(boardName: String) {
        let urls = posts.compactMap { post in
            return post.post.getMediaUrl(boardId: boardName, thumbnail: !Defaults[.fullImagesForThumbanails])
        }
        prefetcher.prefetchImages(urls: urls)
    }

    func stopPrefetching() {
        prefetcher.stopPrefetching()
    }
}
