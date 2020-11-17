//
//  Thread.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import Foundation

struct Post: Decodable {
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
    let tim: Int?
    let ext: String?
    let replyCount: Int?
    let imageCount: Int?

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
        case tim
        case ext
        case replyCount = "replies"
        case imageCount = "images"
    }

    func getMediaUrl(boardId: String, thumbnail: Bool = false) -> URL? {
        let thumb = thumbnail ? "s" : ""
        if let filename = tim,
           let extens = ext {
            let extens = thumbnail ? ".jpg" : extens
            return URL(string: "https://i.4cdn.org/\(boardId)/\(String(filename))\(thumb)\(extens)")!
        }
        return nil
    }

    func getDatePosted() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self.time))
        return DateFormatterService.shared.dateFormatter.string(from: date)
    }

    static func example(sticky: Int, closed: Int, subject: String, comment: String) -> Post {
        return self.init(number: Int.random(in: 0..<9999999),
                       sticky: sticky,
                       closed: closed,
                       name: "Anonymous",
                       id: "12345",
                       subject: subject,
                       comment: comment,
                       trip: "",
                       capcode: "",
                       country: "",
                       time: 1604547871,
                       tim: 1358180697001,
                       ext: ".jpg",
                       replyCount: 5,
                       imageCount: 10
        )
    }
}
