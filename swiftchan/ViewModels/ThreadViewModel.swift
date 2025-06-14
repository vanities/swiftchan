//
//  ThreadViewModel.swift
//  swiftchan
//
//  Created on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan

@Observable
final class ThreadViewModel {
    enum State {
        case initial, loading, loaded, error
    }
    let prefetcher = Prefetcher.shared
    let boardName: String
    let id: Int

    private(set) var posts = [Post]()
    var media = [Media]()
    private(set) var postMediaMapping = [Int: Int]()
    private(set) var comments = [AttributedString]()
    private(set) var replies = [Int: [Int]]()
    private(set) var state = State.initial
    private(set) var progressText = ""

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
    }

    @MainActor
    func getPosts() async {
        if state != .loaded {
            state = .loading
            progressText = "Loading thread 0%"
        }

        do {
            let thread = try await FourChanAsyncService.shared.getThread(boardName: boardName, no: id) { [weak self] progress in
                await MainActor.run {
                    self?.progressText = "Loading thread \(Int(progress * 100))%"
                }
            }
            let posts = thread.posts

            if posts.count > 0 {
                var mediaUrls: [URL] = []
                var thumbnailMediaUrls: [URL] = []
                var mapping: [Int: Int] = [:]
                var comments: [AttributedString] = []
                var postReplies: [Int: [String]] = [:]
                var postIndex = 0
                var mediaIndex = 0

                for post in posts {
                    if let mediaUrl = post.getMediaUrl(boardId: boardName), let thumbnailUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                        mapping[postIndex] = mediaIndex
                        mediaUrls.append(mediaUrl)
                        thumbnailMediaUrls.append(thumbnailUrl)
                        mediaIndex += 1
                    }
                    if let comment = post.com {
                        let parser = CommentParser(comment: comment)
                        comments.append(parser.getComment())
                        postReplies[postIndex] = parser.replies
                    } else {
                        comments.append(AttributedString())
                    }
                    postIndex += 1
                }

                let replies = FourchanService.getReplies(postReplies: postReplies, posts: posts)

                self.posts = posts
                self.postMediaMapping = mapping
                self.comments = comments
                self.replies = replies
                setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
                state = .loaded
            } else if self.posts.isEmpty {
                state = .error
            }
        } catch {
            state = .error
        }
        print("Thread /\(boardName)/-\(id) successfully got \(self.posts.count) posts.")
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

    @MainActor
    func setMedia(mediaUrls: [URL], thumbnailMediaUrls: [URL]) {
        media = getMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
    }

    @MainActor
    func prefetch() {
        let urls = media.flatMap { media in
            return [media.thumbnailUrl, media.url]
        }
        prefetcher.prefetch(urls: urls)
    }

    @MainActor
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
