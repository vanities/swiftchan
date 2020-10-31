//
//  Thread.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import Foundation

struct Thread: Decodable {
    let number: Int
    let sticky: Int?
    let closed: Int?
    let name: String
    let id: String?
    let subject: String?
    let comment: String?
    let trip: String?
    let capcode: String? // admin/mod status
    let country: String? // Poster's ISO 3166-1 alpha-2 country code https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    let time: Int // UNIX timestamp the post was created
    
    enum CodingKeys: String, CodingKey {
        case number = "no"
        case sticky
        case closed
        case name
        case id
        case subject = "sub"
        case comment = "com"
        case trip
        case capcode
        case country
        case time
    }
}
