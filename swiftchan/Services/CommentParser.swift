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
    var commentViews: [AnyView] = []

    init(comment: String) {
        self.comment = comment
    }
    
    func getViews() -> [AnyView] {
        let document = self.parseComment()
        
        if let document = document {
            let documentText = try! document.text()
            let text = documentText.replacingOccurrences(of: "/n", with: "\n")
            
            let components = text.components(separatedBy: " ")
            for s in components {
                if s.starts(with: ">>") {
                    self.joinBuffer()

                    // post link
                    self.commentViews.append(AnyView(
                        Text(s)
                            .foregroundColor(.blue)
                    ))
                }
                else if s.starts(with: ">") {
                    self.joinBuffer()

                    // quote
                    self.commentViews.append(AnyView(
                        Text(s)
                            .foregroundColor(.green)
                    ))
                }
                else {
                    self.textBuffer.append(s)
                }
            }
        }
        return []
    }
    
    private func joinBuffer() {
        self.commentViews.append(
            AnyView(
                Text(self.textBuffer.joined(separator: " "))
            )
        )
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
