//
//  Board.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import Foundation

struct Board: Decodable {
    let name: String
    let title: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case name = "board"
        case title
        case description = "meta_description"
    }

    static func examples() -> [Board] {
        let boards = [
            Board(name: "3", title: "3DCG", description: "/3/ - 3DCG is 4chan's board for 3D modeling and imagery."),
            Board(name: "a", title: "Anime & Manga", description: "/a/ - Anime  Manga is 4chan's imageboard dedicated to the discussion of Japanese animation and manga.")
        ]
        return boards
    }
}

extension Board {
  var descriptionText: String {
    return description
        .replacingOccurrences(of: "&amp;", with: "")
        .replacingOccurrences(of: "&quot;", with: "")
  }
}

extension Board: Hashable {
}
