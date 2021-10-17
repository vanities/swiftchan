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
        private var cancellable: AnyCancellable?

        init(boardName: String, _ complete: (() -> Void)? = nil) {
            self.boardName = boardName
            self.load {
                complete?()
            }
        }

        deinit {
            stopPrefetching()
            cancellable?.cancel()
        }

        func load(_ complete: (() -> Void)? = nil) {
            FourchanService.getCatalog(boardName: boardName) { [weak self] posts in
                self?.posts = posts
                self?.sortedPosts = posts
                complete?()
                self?.prefetch()
            }

            cancellable?.cancel()
            let publisher = Defaults.publisher(.sortFilesBoard(boardName: boardName))
            cancellable = publisher.sink { [weak self] change in
                //change.newValue
                guard change.newValue != .none else {
                    self?.sortedPosts = self?.posts ?? []
                    return
                }
                self?.sortedPosts.sort { (lhs: SwiftchanPost, rhs: SwiftchanPost) -> Bool in
                    // https://stackoverflow.com/questions/26829304/assigning-operator-function-in-variable
                    let operation: (Int, Int) -> Bool = change.newValue == .ascending ? (<) : (>)
                    return operation(lhs.post.replies ?? 0, rhs.post.replies ?? 0)
                }
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
