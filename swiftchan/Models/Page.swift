//
//  Page.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import Foundation

struct Page: Decodable {
    let number: Int
    let threads: [Post]

    enum CodingKeys: String, CodingKey {
        case number = "page"
        case threads
    }

    static func example() -> Page {
        return Page(number: 0, threads: [
            Post.example(sticky: 1,
                           closed: 1,
                           subject: LoremLipsum.full,
                           comment: LoremLipsum.full
            ),
            Post.example(sticky: 0,
                           closed: 0,
                           subject: "",
                           comment: LoremLipsum.full
            )
        ])
    }
}

struct ThreadPage: Decodable {
    let posts: [Post]

    enum CodingKeys: String, CodingKey {
        case posts
    }
}
