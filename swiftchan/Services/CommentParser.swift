//
//  CommentParser.swift
//  swiftchan
//
//  Created on 11/3/20.
//

import SwiftUI
import FourChan

class CommentParser {
    var comment: String
    var replies: [String] = []

    init(comment: String) {
        self.comment = comment
    }

    func getComment() -> AttributedString {
        let nsText = parseComment(comment)
        return nsText
    }

    // swiftlint:disable all
    func parseComment(_ comment: String) -> AttributedString {
        // debugPrint(comment)
        var result = AttributedString()
        let parser = PostTextParser()
        parser.parse(text: comment) { element in
            var part = AttributedString()
            switch element {
            case .anchor(text: let text, href: let href):
                let font = UIFont.preferredFont(forTextStyle: .body)
                part = AttributedString(text)

                // in-thread reply
                // >>798116 #p798116
                if href.starts(with: "#p") {
                    let bareText = text
                        .replacingOccurrences(of: ">>", with: "")
                        .replacingOccurrences(of: "(OP)", with: "")
                    replies.append(bareText)
                    part.foregroundColor = Colors.Text.reply
                    part.font = font
                    part.link = URL.inThreadReply(id: bareText)
                }
                // self-served url
                // readme.txt http://freetexthost.com/nzjanyanw0
                else if href.starts(with: "http") || href.starts(with: "https") {
                    if let urlString = href.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: urlString) {
                        part.foregroundColor = Colors.Text.link
                        part.font = font
                        part.link = url
                    }
                }
                else {
                    part.foregroundColor = Colors.Text.crossThreadReply
                    part.font = font

                    // text: >>>/pol/ or >>>/g/123456
                    if text.starts(with: ">>>") {
                        let trimmed = text.replacingOccurrences(of: ">>>/", with: "")
                        let components = trimmed.split(separator: "/")
                        if components.count >= 2 {
                            let board = String(components[0])
                            let id = String(components[1])
                            part.link = URL.thread(board: board, id: id)
                        } else {
                            part.link = URL.board(name: trimmed.replacingOccurrences(of: "/", with: ""))
                        }
                    }
                    // text: >>794515 with cross thread href
                    else if text.starts(with: ">>") {
                        if href.contains("/thread/") {
                            // Handle various href formats:
                            // - //boards.4chan.org/pol/thread/12345
                            // - /pol/thread/12345
                            // - pol/thread/12345
                            let components = href.split(separator: "/").filter { !$0.isEmpty }
                            if let threadIndex = components.firstIndex(of: "thread"),
                               threadIndex > 0,
                               threadIndex + 1 < components.count {
                                // Board is right before "thread"
                                let board = String(components[threadIndex - 1])
                                // ID is right after "thread", strip any #fragment
                                let idComponent = String(components[threadIndex + 1])
                                let id = idComponent.split(separator: "#").first.map(String.init) ?? ""
                                // Only use if board looks valid (not a domain)
                                if !board.contains(".") {
                                    part.link = URL.thread(board: board, id: id)
                                } else if threadIndex >= 2 {
                                    // Domain case: //boards.4chan.org/pol/thread/123
                                    let actualBoard = String(components[threadIndex - 1])
                                    part.link = URL.thread(board: actualBoard, id: id)
                                } else {
                                    part.link = URL(string: href)
                                }
                            } else {
                                part.link = URL(string: href)
                            }
                        } else {
                            part.link = URL(string: "swiftchan:Post?id=\(text.replacingOccurrences(of: ">>", with: ""))")
                        }
                    }
                    // link without protocol
                    else {
                        part.link = URL(string: href)
                    }
                }

            case .plain(text: let text):
                // plain
                let font = UIFont.preferredFont(forTextStyle: .body)
                part = AttributedString(text)
                part.foregroundColor = Colors.Text.plain
                part.font = font

                // http://......
                self.checkForUrls(text).forEach { (url, originalString, range) in
                    var urlString = AttributedString(url.absoluteString)
                    urlString.font = font
                    urlString.link = url
                    urlString.foregroundColor = Colors.Text.link
                    if let urlRange = part.range(of: originalString) {
                        part.replaceSubrange(urlRange, with: urlString)
                    } else {
                        // why is this not finding the range?
                        debugPrint("could not find range for url", range, urlString)
                    }
                }

            case .bold(text: let text):
                // 𝐛𝐨𝐥𝐝
                part = AttributedString("**\(text)**")
                part.foregroundColor = Colors.Text.plain

            case .strikethrough(text: let text):
                // s̶t̶r̶i̶k̶e̶t̶h̶r̶o̶u̶g̶h̶
                part = AttributedString(text)
                part.strikethroughStyle = try? AttributeScopes.UIKitAttributes.StrikethroughStyleAttribute.value(for: 2)
                part.foregroundColor = Colors.Text.plain
            case .quote(text: let text):
                // >implying
                part = AttributedString(text)
                part.foregroundColor = Colors.Text.quote
                part.font = .body
            case .deadLink(text: let text):
                // >>791225 (link no longer is active)
                part = AttributedString(text)
                part.font = .body
                part.foregroundColor = Colors.Text.deadLink
            case .code(text: let text):
                debugPrint("code! \(text)")
            }
            result.append(part)
        }
        return result
    }
    // swiftlint:enable all

    // swiftlint:disable all
    func checkForUrls(_ text: String) -> [(URL, String, NSRange)] {
        // let regexString = "@^(https?|ftp)://[^\\s/$.?#].[^\\s]*$@iS" // i like
        let regexString = "(https?://[^\\s]*)(\\r|\\n|\\s|)" // basic

        do {
            let regex = try NSRegularExpression(pattern: regexString, options: [])
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            /*
            // doesn't capture urls correctly
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: text, options: [.reportCompletion], range: NSRange(text.startIndex..., in: text))

            return matches.compactMap { match in
                return (match.url!, match.range)
            }
            */
            return matches.compactMap { match in
                if let range = Range(match.range(at: 1), in: text) {
                    let stringUrl = String(text[range]).fixZeroWidthSpace

                    // url might be good
                    if let url = URL(string: stringUrl) {
                        return (url, String(text[range]), match.range)
                    }
                    // % encode it
                    else if let escapedStringUrl = stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: escapedStringUrl) {
                        return (url, String(text[range]), match.range)
                    }
                }
                return nil
            }
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        return []
    }
    // swiftlint:enable all
}
