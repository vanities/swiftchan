//
//  FourchanService.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan
import Combine

class FourchanService {
    class func getBoards(complete: @escaping ([Board]) -> Void) {
        FourChanAPIService.shared.GET(endpoint: .boards) { (result: Result<Boards, FourChanAPIService.APIError>) in
            switch result {
            case .success(let boards):
                complete(boards.boards)
            case .failure(let error):
                print(error)
            }
        }
    }

    class func getPosts(
        boardName: String,
        id: Int,
        complete: @escaping (
            [Post],
            [URL],
            [URL],
            [Int: Int],
            [AttributedString],
            [Int: [Int]]
        ) -> Void) {
            var mediaUrls: [URL] = []
        var thumbnailMediaUrls: [URL] = []
        var postMediaMapping: [Int: Int] = [:]
        var comments: [AttributedString] = []
        var postReplies: [Int: [String]] = [:]

        FourChanAPIService.shared.GET(endpoint: .thread(board: boardName, no: id)) { (result: Result<ChanThread, FourChanAPIService.APIError>) in
            switch result {
            case .success(let thread):
                var postIndex = 0
                var mediaIndex = 0
                for post in thread.posts {
                    if let mediaUrl = post.getMediaUrl(boardId: boardName),
                       let thumbnailMediaUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                        postMediaMapping[postIndex] = mediaIndex
                        mediaIndex += 1
                        mediaUrls.append(mediaUrl)
                        thumbnailMediaUrls.append(thumbnailMediaUrl)
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
                let replies = self.getReplies(postReplies: postReplies, posts: thread.posts)
                complete(thread.posts, mediaUrls, thumbnailMediaUrls, postMediaMapping, comments, replies)
            case .failure(let error):
                print(error)
            }
        }
    }

    class func getCatalog(boardName: String, complete: @escaping ([SwiftchanPost]) -> Void) {
        FourChanAPIService.shared.GET(endpoint: .catalog(board: boardName)) { (result: Result<Catalog, FourChanAPIService.APIError>) in
            var posts: [SwiftchanPost] = []

            switch result {
            case .success(let pages):
                for page in pages {
                    for thread in page.threads {
                        var comment: AttributedString

                        if let com = thread.com {
                            comment = CommentParser(comment: com).getComment()
                        } else {
                            comment = AttributedString()
                        }
                        posts.append(SwiftchanPost(post: thread, comment: comment))
                    }
                }
                complete(posts)
            case .failure(let error):
                print(error)
            }
        }
    }

    static func getReplies(postReplies: [Int: [String]], posts: [Post]) -> [Int: [Int]] {
        var replies: [Int: [Int]] = [:]
        var postIndex = 0

        for (i, r) in postReplies {
            for reply in r {
                postIndex = 0
                for post in posts {
                    if Int(reply) == post.id {
                        if replies[postIndex] == nil {
                            replies[postIndex] = [i]
                        } else {
                            replies[postIndex]?.append(i)
                        }
                    }
                    postIndex += 1
                }
            }
        }
        return replies
    }
}
