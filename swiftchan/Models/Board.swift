//
//  Board.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import Foundation

struct Board: Decodable {
    let board: String
    let title: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case board
        case title
        case description = "meta_description"
    }
}

extension Board {
  var descriptionText: String {
    return description
        .replacingOccurrences(of: "&amp;", with: "")
        .replacingOccurrences(of: "&quot;", with: "")
  }
}
