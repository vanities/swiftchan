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
    let tim: Int
    let ext: String
    let replyCount: Int
    let imageCount: Int
    
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
    
    func getMediaUrl(boardId: String) -> URL {
        return URL(string: "https://i.4cdn.org/" + boardId + "/" + String(tim) + ext)!
    }
    
    func getDatePosted() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self.time))
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" //Specify your format that you want
        return dateFormatter.string(from: date)
    }
}
