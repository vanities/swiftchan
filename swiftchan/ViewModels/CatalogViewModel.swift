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

extension CatalogView {
    final class CatalogViewModel: ObservableObject {
        // swiftlint:disable nesting
        enum LoadingState {
            case loading
            case loaded
        }
        // swiftlint:enable nesting

        var boardName: String
        let prefetcher = Prefetcher()

        @Published private(set) var posts = [SwiftchanPost]()
        @Published var state: LoadingState = .loading

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

        func load() async {
            let posts = await FourchanService.getCatalog(boardName: boardName)
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.posts = posts
                strongSelf.state = .loaded
                strongSelf.handleSorting(value: Defaults.sortFilesBy(boardName: strongSelf.boardName), attributeKey: "files")
                strongSelf.handleSorting(value: Defaults.sortRepliesBy(boardName: strongSelf.boardName), attributeKey: "replies")
            }
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
}
