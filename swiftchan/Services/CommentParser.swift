//
//  CommentParser.swift
//  swiftchan
//
//  Created by vanities on 11/3/20.
//

import SwiftUI
import SwiftSoup

class CommentParser {
    var comment: String
    var textBuffer: [String] = []

    init(comment: String) {
        self.comment = comment
    }

    func getComment() -> Text {
        let document = self.parseComment()
        var comment = Text("")

        if let document = document {
            let documentText = try! document.text()
            let text = documentText.replacingOccurrences(of: "/n", with: "\n")

            let components = text.components(separatedBy: "\n")
            for s in components {
                if s.starts(with: ">>") {
                    // post link
                    comment = comment + Text(s + "\n").foregroundColor(.blue)
                } else if s.starts(with: ">") {
                    // quote
                    comment = comment + Text(s + "\n").foregroundColor(.green)
                } else {
                    comment = comment + Text(s + "\n")
                }
            }
        }
        return comment
    }

    private func parseComment() -> Document? {
        print(comment)
        do {
            return try SwiftSoup.parse(comment.replacingOccurrences(of: "<br>", with: "/n"))
        } catch Exception.Error(let type, let message) {
            print(type, message)
        } catch {
            print("error")
        }
        return nil
    }
}
