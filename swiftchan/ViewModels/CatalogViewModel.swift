//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan

extension CatalogView {
    final class CatalogViewModel: ObservableObject {
        let boardName: String
        let prefetcher = Prefetcher()
        @Published private(set) var posts = [Post]()
        @Published private(set) var comments = [NSAttributedString]()

        init(boardName: String) {
            self.boardName = boardName
            self.load()
        }

        deinit {
            stopPrefetching()
        }

        func load(_ complete: (() -> Void)? = nil) {
            FourchanService.getCatalog(boardName: self.boardName) { [weak self] (posts, comments) in
                self?.posts = posts
                self?.comments = comments
                complete?()
                self?.prefetch()
            }
        }

        func prefetch() {
            let urls = posts.compactMap { [weak self] post in
                return post.getMediaUrl(boardId: self?.boardName ?? "")
            }
            // don't prefetch webms here.. for now
            prefetcher.prefetchImages(urls: urls)
        }

        func stopPrefetching() {
            prefetcher.stopPrefetching()
        }
    }
}
