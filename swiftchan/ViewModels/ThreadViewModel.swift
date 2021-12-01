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
        let prefetcher = Prefetcher()
        let boardName: String
        let id: Int

        @Published private(set) var posts = [Post]()
        @Published var media = [Media]()
        @Published private(set) var postMediaMapping = [Int: Int]()
        @Published private(set) var comments = [AttributedString]()
        @Published private(set) var replies = [Int: [Int]]()

        var url: URL {
            return URL(string: "https://boards.4chan.org/\(self.boardName)/thread/\(self.id)")!
        }

        init(boardName: String, id: Int, replies: [Int: [Int]] = [Int: [Int]]()) {
            self.boardName = boardName
            self.id = id
            self.replies = replies
            self.load()
        }

        deinit {
            prefetcher.stopPrefetching()
        }

        func load(_ complete: (() -> Void)? = nil) {
            FourchanService.getPosts(boardName: self.boardName,
                                     id: self.id) { [weak self] ( result, mediaUrls, thumbnailMediaUrls, postMediaMapping, comments, replies) in
                self?.posts = result
                self?.postMediaMapping = postMediaMapping
                self?.comments = comments
                self?.replies = replies
                self?.setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
                complete?()
            }
        }

        private func getMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) -> [Media] {
            var mediaList = [Media]()
            var index = 0
            for (mediaUrl, thumbnailMediaUrl) in zip(mediaUrls, thumbnailMediaUrls) {
                mediaList.append(Media(index: index, url: mediaUrl, thumbnailUrl: thumbnailMediaUrl))
                index += 1
            }
            return mediaList
        }

        func setMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) {
            self.media = self.getMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
        }

        func prefetch() {
            let urls = media.flatMap { media in
                return [media.thumbnailUrl, media.url]
            }
            prefetcher.prefetch(urls: urls)

        }
        func stopPrefetching() {
            prefetcher.stopPrefetching()
        }
    }
}
