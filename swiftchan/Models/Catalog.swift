//
//  Catalog.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import Foundation

struct Catalog: Decodable {
    let pages: [Page]

    enum CodingKeys: String, CodingKey {
        case pages = "."
    }
}
