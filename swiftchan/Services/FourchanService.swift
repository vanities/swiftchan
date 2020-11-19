//
//  FourchanService.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
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

    class func getPosts(boardName: String, id: Int, complete: @escaping ([Post], [URL], [URL], [Int: Int]) -> Void) {
        var mediaUrls: [URL] = []
        var thumbnailMediaUrls: [URL] = []
        var postMediaMapping: [Int: Int] = [:]
        var comments: [String] = []
        var postReplies: [Int: String] = [:]
        
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
                    postIndex += 1
                }

                complete(thread.posts, mediaUrls, thumbnailMediaUrls, postMediaMapping)
            case .failure(let error):
                print(error)
            }
        }
    }

    class func getCatalog(boardName: String, complete: @escaping ([Page]) -> Void) {
        FourChanAPIService.shared.GET(endpoint: .catalog(board: boardName)) { (result: Result<Catalog, FourChanAPIService.APIError>) in
            switch result {
            case .success(let catalog):
                complete(catalog)
            case .failure(let error):
                print(error)
            }
        }
    }

}
