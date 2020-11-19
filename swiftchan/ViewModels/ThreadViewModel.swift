//
//  ThreadViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import FourChan

extension ThreadView {
    final class ViewModel: ObservableObject {
        let boardName: String
        let id: Int

        @Published private(set) var posts = [Post]()
        @Published private(set) var mediaUrls = [URL]()
        @Published private(set) var thumbnailMediaUrls = [URL]()
        @Published private(set) var postMediaMapping = [Int: Int]()

        init(boardName: String, id: Int) {
            self.boardName = boardName
            self.id = id
            self.load()
        }

        func load() {
            FourchanService.getPosts(boardName: self.boardName,
                                     id: self.id) { [weak self] (result, mediaUrls, thumbnailMediaUrls, postMediaMapping) in
                self?.posts = result
                self?.mediaUrls = mediaUrls
                self?.thumbnailMediaUrls = thumbnailMediaUrls
                self?.postMediaMapping = postMediaMapping

            }
        }
    }
}
