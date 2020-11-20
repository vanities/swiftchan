//
//  FourchanService.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan

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

    class func getPosts(boardName: String, id: Int, complete: @escaping ([Post], [URL], [URL], [Int: Int], [Text]) -> Void) {
        var mediaUrls: [URL] = []
        var thumbnailMediaUrls: [URL] = []
        var postMediaMapping: [Int: Int] = [:]
        var comments: [Text] = []
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
                        
                        if let comment = post.com {
                            let parser = CommentParser(comment: comment)
                            comments.append(parser.getComment())
                            postReplies[postIndex] = parser.replies
                        }
                    }
                    postIndex += 1
                }

                complete(thread.posts, mediaUrls, thumbnailMediaUrls, postMediaMapping, comments)
            case .failure(let error):
                print(error)
            }
        }
    }

    class func getCatalog(boardName: String, complete: @escaping ([Page], [Text]) -> Void) {
        FourChanAPIService.shared.GET(endpoint: .catalog(board: boardName)) { (result: Result<Catalog, FourChanAPIService.APIError>) in
            switch result {
            case .success(let pages):
                var comments: [Text] = []
                for page in pages {
                    for thread in page.threads {
                        if let comment = thread.com {
                            let parser = CommentParser(comment: comment)
                            comments.append(parser.getComment())
                        }
                    }
                }
                complete(pages, comments)
            case .failure(let error):
                print(error)
            }
        }
    }

}
