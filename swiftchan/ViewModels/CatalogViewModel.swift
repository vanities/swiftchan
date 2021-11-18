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
        enum LoadingState {
            case loading
            case loaded
        }

        let boardName: String
        let prefetcher = Prefetcher()

        @Published private(set) var posts = [SwiftchanPost]()
        @Published var state: LoadingState = .loading

        private var cancellable = Set<AnyCancellable>()

        init(boardName: String) {
            self.boardName = boardName
        }

        deinit {
            stopPrefetching()
        }

        func load(_ complete: (() -> Void)? = nil) {
            state = .loading
            FourchanService.getCatalog(boardName: boardName) { [weak self] posts in
                guard let self = self else {
                    return
                }
                self.posts = posts
                self.prefetch()
                self.handleSorting(value: Defaults.sortFilesBy(boardName: self.boardName), attributeKey: "files")
                self.handleSorting(value: Defaults.sortRepliesBy(boardName: self.boardName), attributeKey: "replies")
                self.state = .loaded
                complete?()
            }

            Defaults.publisher(.sortFilesBy(boardName: boardName))
                .sink { [weak self] change in
                    self?.handleSorting(value: change.newValue, attributeKey: "files")
                }
                .store(in: &cancellable)

            Defaults.publisher(.sortRepliesBy(boardName: boardName))
                .sink { [weak self] change in
                    self?.handleSorting(value: change.newValue, attributeKey: "replies")
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

        func prefetch() {
            let thumbnailUrls = posts.compactMap { [weak self] post in
                return post.post.getMediaUrl(boardId: self?.boardName ?? "")
            }
            // don't prefetch webms here.. for now
            prefetcher.prefetchImages(urls: thumbnailUrls)
        }

        func stopPrefetching() {
            prefetcher.stopPrefetching()
        }
    }
}
