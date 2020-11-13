//
//  ThreadViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation

extension ThreadView {
    final class ViewModel: ObservableObject {
        let boardName: String
        let id: Int

        @Published private(set) var posts = [Post]()
        @Published private(set) var mediaUrls = [URL]()

        init(boardName: String, id: Int) {
            self.boardName = boardName
            self.id = id
            self.load()
        }

        func load() {
            FourchanService.getPosts(boardName: self.boardName,
                                     id: self.id) { [weak self] (result, mediaUrls) in
                self?.posts = result
                self?.mediaUrls = mediaUrls

            }
        }
    }
}
