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
        let prefetcher = Prefetcher.shared
        let boardName: String
        let id: Int

        @Published private(set) var posts = [Post]()
        @Published var media = [Media]()
        // @Published private(set) var media = [Media]()
        @Published private(set) var postMediaMapping = [Int: Int]()
        @Published private(set) var comments = [AttributedString]()
        @Published private(set) var replies = [Int: [Int]]()

        var url: URL {
            return URL(string: "https://boards.4chan.org/\(self.boardName)/thread/\(self.id)")!
        }

        var title: String {
            posts.first?.sub?.clean ?? ""
        }

        init(boardName: String, id: Int, replies: [Int: [Int]] = [Int: [Int]]()) {
            self.boardName = boardName
            self.id = id
            self.replies = replies
            Task {
                await load()
            }
        }

        deinit {
            prefetcher.stopPrefetching()
        }

        func load() async {
            let (result, mediaUrls, thumbnailMediaUrls, postMediaMapping, comments, replies) = await FourchanService.getPosts(
                boardName: boardName,
                id: id
            )
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.posts = result
                strongSelf.postMediaMapping = postMediaMapping
                strongSelf.comments = comments
                strongSelf.replies = replies
                strongSelf.setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
            }
            print("Thread /\(boardName)/-\(id) successfully got \(posts.count) posts.")
        }

        private func getMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) -> [Media] {
            var mediaList = [Media]()
            var index = 0
            for (mediaUrl, thumbnailMediaUrl) in zip(mediaUrls, thumbnailMediaUrls) {
                var media = Media(index: index, url: mediaUrl, thumbnailUrl: thumbnailMediaUrl)
                if media.format == .webm {
                    if let cacheUrl = CacheManager.shared.getCacheValue(media.url) {
                        media = Media(index: index, url: cacheUrl, thumbnailUrl: thumbnailMediaUrl)
                    }
                }

                mediaList.append(media)
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

        func getPostIndexFromId(_ id: String) -> Int {
            var index = 0
            for post in posts {
                if id.contains(String(post.id)) {
                    return index
                }
                index += 1
            }
            return 0
        }
    }
}
