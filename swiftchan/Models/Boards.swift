//
//  Boards.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
//

import Foundation

struct Boards: Decodable {
  let all: [Board]

  enum CodingKeys: String, CodingKey {
    case all = "boards"
  }
}
