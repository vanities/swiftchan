//
//  ThreadViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan

extension ThreadView {
    final class ViewModel: ObservableObject {
        let boardName: String
        let id: Int

        @Published private(set) var posts = [Post]()
        @Published private(set) var mediaUrls = [URL]()
        @Published private(set) var thumbnailMediaUrls = [URL]()
        @Published private(set) var postMediaMapping = [Int: Int]()
        @Published private(set) var comments = [NSAttributedString]()
        @Published private(set) var replies = [Int: [Int]]()

        var url: URL {
            return URL(string: "https://boards.4chan.org/\(self.boardName)/thread/\(self.id)")!
        }

        init(boardName: String, id: Int) {
            self.boardName = boardName
            self.id = id
            self.load()
        }

        func load(_ complete: (() -> Void)? = nil) {
            FourchanService.getPosts(boardName: self.boardName,
                                     id: self.id) { [weak self] ( result, mediaUrls, thumbnailMediaUrls, postMediaMapping, comments, replies) in
                self?.posts = result
                self?.mediaUrls = mediaUrls
                self?.thumbnailMediaUrls = thumbnailMediaUrls
                self?.postMediaMapping = postMediaMapping
                self?.comments = comments
                self?.replies = replies
                complete?()
            }
        }

        func prefetch() {
            Prefetcher.shared.prefetch(urls: mediaUrls + thumbnailMediaUrls)
        }
    }
}
