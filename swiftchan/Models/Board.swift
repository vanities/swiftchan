//
//  Board.swift
//  swiftchan
//
//  Created by vanities on 11/18/20.
//

import Foundation
import FourChan

extension Board: Equatable {
    public static func == (lhs: Board, rhs: Board) -> Bool {
        return lhs.board == rhs.board
    }

    static func examples() -> [Board] {
        let json: [String: Any] = [
            "boards": [
                [
                    "board": "3",
                    "title": "3DCG",
                    "ws_board": 1,
                    "per_page": 15,
                    "pages": 10,
                    "max_filesize": 4194304,
                    "max_webm_filesize": 3145728,
                    "max_comment_chars": 2000,
                    "max_webm_duration": 120,
                    "bump_limit": 310,
                    "image_limit": 150,
                    "cooldowns": [
                        "threads": 600,
                        "replies": 60,
                        "images": 60
                    ],
                    "meta_description": "&quot;/3/ - 3DCG&quot; is 4chan's board for 3D modeling and imagery.",
                    "is_archived": 1
                ],
                [
                    "board": "a",
                    "title": "Anime & Manga",
                    "ws_board": 1,
                    "per_page": 15,
                    "pages": 10,
                    "max_filesize": 4194304,
                    "max_webm_filesize": 3145728,
                    "max_comment_chars": 2000,
                    "max_webm_duration": 120,
                    "bump_limit": 500,
                    "image_limit": 300,
                    "cooldowns": [
                        "threads": 600,
                        "replies": 60,
                        "images": 60
                    ],
                    "meta_description": "&quot;/a/ - Anime &amp; Manga&quot; is 4chan's imageboard dedicated to the discussion of Japanese animation and manga.",
                    "spoilers": 1,
                    "custom_spoilers": 1,
                    "is_archived": 1
                ]
            ]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        return try! JSONDecoder().decode(Boards.self, from: jsonData).boards
    }

    var descriptionText: String {
        return self.meta_description
            .replacingOccurrences(of: "&amp;", with: "")
            .replacingOccurrences(of: "&quot;", with: "")
    }
}
