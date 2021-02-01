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
    var replies: [String] = []

    init(comment: String) {
        self.comment = comment
    }

    func getComment() -> Text {
        let document = self.parseComment()
        var comment = Text("")
        var documentText: String = ""

        if let document = document {
            do {
                documentText = try document.text()
            } catch {
                print("could not get text")
            }
            let text = documentText.replacingOccurrences(of: "/n", with: "\n")

            // let re = https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)
            let lines = text.components(separatedBy: "\n")
            for line in lines {
                if line.starts(with: ">>") {
                    // post link
                    self.replies.append(line.replacingOccurrences(of: ">>", with: ""))
                    comment = comment + Text(line + "\n").foregroundColor(.blue)
                } else if line.starts(with: ">") {
                    // quote
                    comment = comment + Text(line + "\n").foregroundColor(.green)
                } else {
                    comment = comment + Text(line + "\n")
                }
            }
        }
        return comment
    }

    private func parseComment() -> Document? {
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
