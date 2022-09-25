//
//  ThreadViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan

final class ThreadViewModel: ObservableObject {
    enum State {
        case initial, loading, loaded, error
    }
    let prefetcher = Prefetcher.shared
    let boardName: String
    let id: Int

    @Published private(set) var posts = [Post]()
    @Published var media = [Media]()
    // @Published private(set) var media = [Media]()
    @Published private(set) var postMediaMapping = [Int: Int]()
    @Published private(set) var comments = [AttributedString]()
    @Published private(set) var replies = [Int: [Int]]()
    @Published private(set) var state = State.initial

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

    deinit {
        prefetcher.stopPrefetching()
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
        posts = result
        self.postMediaMapping = postMediaMapping
        self.comments = comments
        self.replies = replies
        setMedia(mediaUrls: mediaUrls, thumbnailMediaUrls: thumbnailMediaUrls)
        if posts.count > 1 {
            state = .loaded
        } else {
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
