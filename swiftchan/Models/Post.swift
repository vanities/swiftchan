//
//  Post.swift
//  swiftchan
//
//  Created by vanities on 11/18/20.
//

import Foundation
import FourChan

extension Post: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    public static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
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
        var datePosted = ""
        if let time = self.time {
            let date = Date(timeIntervalSince1970: TimeInterval(time))
            datePosted = DateFormatterService.shared.dateFormatter.string(from: date)
        }
        return datePosted
    }

    static func example() -> Post {
        let json: [String: Any] = [
            "no": 570368,
            "sticky": 1,
            "closed": 1,
            "now": "12/31/18(Mon)17:05:48",
            "name": "Anonymous",
            "sub": "Welcome to /po/!",
            "com": "Welcome to /po/! We specialize in origami, papercraft, and everything that’s relevant to paper engineering. This board is also an great library of relevant PDF books and instructions, one of the best resource of its kind on the internet.<br><br>Questions and discussions of papercraft and origami are welcome. Threads for topics covered by paper engineering in general are also welcome, such as kirigami, bookbinding, printing technology, sticker making, gift boxes, greeting cards, and more.<br><br>Requesting is permitted, even encouraged if it’s a good request; fulfilled requests strengthens this board’s role as a repository of books and instructions. However do try to keep requests in relevant threads, if you can.<br><br>/po/ is a slow board! Do not needlessly bump threads.",
            "filename": "yotsuba_folding",
            "ext": ".png",
            "w": 530,
            "h": 449,
            "tn_w": 250,
            "tn_h": 211,
            "tim": 1546293948883,
            "time": 1546293948,
            "md5": "uZUeZeB14FVR+Mc2ScHvVA==",
            "fsize": 516657,
            "resto": 0,
            "capcode": "mod",
            "semantic_url": "welcome-to-po",
            "replies": 2,
            "images": 2,
            "unique_ips": 1
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        return try! JSONDecoder().decode(Post.self, from: jsonData)
    }

}
