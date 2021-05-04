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
    final class ViewModel: ObservableObject {
        let boardName: String
        @Published private(set) var posts = [Post]()
        @Published private(set) var comments = [NSAttributedString]()

        init(boardName: String) {
            self.boardName = boardName
            self.load()
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
            let thumbnailUrls = self.posts.compactMap { [weak self] post in
                return post.getMediaUrl(boardId: self?.boardName ?? "", thumbnail: true)
            }
            Prefetcher.shared.prefetch(urls: urls + thumbnailUrls)
        }
    }
}
