//
//  Page.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import Foundation

struct Page: Decodable {
    let number: Int
    let threads: [Thread]

    enum CodingKeys: String, CodingKey {
        case number = "page"
        case threads
    }
}
