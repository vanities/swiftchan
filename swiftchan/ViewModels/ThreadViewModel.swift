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
        }
        let (result, mediaUrls, thumbnailMediaUrls, postMediaMapping, comments, replies) = await FourchanService.getPosts(
            boardName: boardName,
            id: id
        )
        let posts = result
        if posts.count > 0 {
            self.posts = posts
            self.postMediaMapping = postMediaMapping
            self.comments = comments
            self.replies = replies
            setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
            state = .loaded
        } else if posts.count == 0, self.posts.count == 0 {
            state = .error
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
