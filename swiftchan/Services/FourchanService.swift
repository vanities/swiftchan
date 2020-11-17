//
//  FourchanService.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import Alamofire

class FourchanService {
    static let headers: HTTPHeaders = [
        .accept("application/json")
    ]

    class func getBoards(complete: @escaping ([Board]) -> Void) {
        let url = "https://a.4cdn.org/boards.json"

        AF.request(url, headers: self.headers)
            .validate()
            .responseDecodable(of: Boards.self) { (response) in
                guard let boards = response.value else { return }
                complete(boards.all)
            }
    }

    class func getPosts(boardName: String, id: Int, complete: @escaping ([Post], [URL], [URL], [Int: Int]) -> Void) {
        let url = "https://a.4cdn.org/\(boardName)/thread/\(String(id)).json"

        AF.request(url)
            .validate()
            .responseDecodable(of: ThreadPage.self) { (response) in
                guard let data = response.value else { return }
                let posts = data.posts

                var mediaUrls: [URL] = []
                var thumbnailMediaUrls: [URL] = []
                var postMediaMapping: [Int: Int] = [:]
                var postIndex = 0
                var mediaIndex = 0
                for post in posts {
                    if let mediaUrl = post.getMediaUrl(boardId: boardName),
                       let thumbnailMediaUrl = post.getMediaUrl(boardId: boardName, thumbnail: true) {
                        postMediaMapping[postIndex] = mediaIndex
                        mediaIndex += 1
                        mediaUrls.append(mediaUrl)
                        thumbnailMediaUrls.append(thumbnailMediaUrl)
                    }
                    postIndex += 1
                }

                complete(posts, mediaUrls, thumbnailMediaUrls, postMediaMapping)
            }
    }

    class func getCatalog(boardName: String, complete: @escaping ([Page]) -> Void) {
        let url = "https://a.4cdn.org/\(boardName)/catalog.json"

        AF.request(url)
            .validate()
            .responseDecodable(of: [Page].self) { (response) in
                guard let data = response.value else { return }
                complete(data)
            }
    }

}
