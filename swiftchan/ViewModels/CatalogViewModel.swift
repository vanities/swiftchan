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
        let boardName: String
        let prefetcher = Prefetcher()
        @Published private(set) var sortedPosts = [SwiftchanPost]()
        @Published private(set) var posts = [SwiftchanPost]()
        private var cancellable = Set<AnyCancellable>()

        init(boardName: String, _ complete: (() -> Void)? = nil) {
            self.boardName = boardName
            self.load {
                complete?()
            }
        }

        deinit {
            stopPrefetching()
        }

        func load(_ complete: (() -> Void)? = nil) {
            FourchanService.getCatalog(boardName: boardName) { [weak self] posts in
                self?.posts = posts
                self?.sortedPosts = posts
                complete?()
                self?.prefetch()
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
                sortedPosts = posts // this may reorder values back unintentionally
                return
            }
            sortedPosts.sort { (lhs: SwiftchanPost, rhs: SwiftchanPost) -> Bool in
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
