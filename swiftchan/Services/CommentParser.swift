//
//  CommentParser.swift
//  swiftchan
//
//  Created by vanities on 11/3/20.
//

import SwiftUI
import FourChan

class CommentParser {
    var comment: String
    var replies: [String] = []

    init(comment: String) {
        self.comment = comment
    }

    func getComment() -> NSMutableAttributedString {
        let nsText = self.parseComment(self.comment)
        return nsText
    }

    func parseComment(_ comment: String) -> NSMutableAttributedString {
        // print(comment)
        let result = NSMutableAttributedString()
        let parser = PostTextParser()
        parser.parse(text: comment) { element in
            var part = NSMutableAttributedString()
            switch element {
            case .anchor(text: let text, href: let href):
                let font = UIFont.preferredFont(forTextStyle: .body)
                part = NSMutableAttributedString(string: text)

                // in-thread reply
                // >>798116 #p798116
                if href.starts(with: "#p") {
                    self.replies.append(text
                                            .replacingOccurrences(of: ">>", with: "")
                                            .replacingOccurrences(of: "(OP)", with: "")
                    )
                    part.addAttributes(
                        [.font: font,
                         .foregroundColor: UIColor.blue],
                        range: NSRange(location: 0, length: part.length))
                }
                // self-served url
                // readme.txt http://freetexthost.com/nzjanyanw0
                else if href.starts(with: "http") || href.starts(with: "https") {
                    if let urlString = href.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: urlString) {
                        part.addAttributes(
                            [.font: font,
                             .foregroundColor: UIColor.link,
                             .link: url
                            ],
                            range: NSRange(location: 0, length: part.length))
                    }
                }
                // TODO: get cross thread replies
                // >>794515 /3/thread/794515#p794515
                else {
                    part.addAttributes(
                        [.font: font,
                         .foregroundColor: UIColor.blue],
                        range: NSRange(location: 0, length: part.length))
                }

            case .plain(text: let text):
                // plain
                let font = UIFont.preferredFont(forTextStyle: .body)
                part = NSMutableAttributedString(string: text)
                part.addAttributes([.font: font,
                                    .foregroundColor: UIColor.label],
                                   range: NSRange(location: 0, length: part.length))
                // http://......
                self.checkForUrls(text).forEach { (url, range) in
                    part.addAttributes(
                        [.font: font,
                         .foregroundColor: UIColor.link,
                         .link: url
                        ],
                        range: range)
                }
            case .bold(text: let text):
                // 𝐛𝐨𝐥𝐝
                part = NSMutableAttributedString(string: text)
                let font = UIFont(descriptor: UIFont.preferredFont(forTextStyle: .body)
                                    .fontDescriptor
                                    .withSymbolicTraits(.traitBold)!,
                                  size: 0)
                part.addAttributes([.font: font,
                                    .foregroundColor: UIColor.label],
                                   range: NSRange(location: 0, length: part.length))
            case .strikethrough(text: let text):
                // s̶t̶r̶i̶k̶e̶t̶h̶r̶o̶u̶g̶h̶
                part = NSMutableAttributedString(string: text)
                part.addAttributes([.strikethroughStyle: 2,
                                    .foregroundColor: UIColor.label],
                                   range: NSRange(location: 0, length: part.length))
            case .quote(text: let text):
                // >implying
                part = NSMutableAttributedString(string: text)
                let font = UIFont.preferredFont(forTextStyle: .body)
                part.addAttributes(
                    [.font: font,
                     .foregroundColor: UIColor.green],
                    range: NSRange(location: 0, length: part.length))
            case .deadLink(text: let text):
                // >>791225
                part = NSMutableAttributedString(string: text)
                let font = UIFont.preferredFont(forTextStyle: .body)
                part.addAttributes(
                    [.font: font,
                     .foregroundColor: UIColor.systemPink],
                    range: NSRange(location: 0, length: part.length))
            }
            result.append(part)
        }
        return result
    }

    func checkForUrls(_ text: String) -> [(URL, NSRange)] {
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
                    let stringUrl = String(text[range])
                    if let escapedStringUrl = stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: escapedStringUrl) {
                        return (url, match.range)
                    }
                }
                return nil
            }

        } catch let error {
            debugPrint(error.localizedDescription)
        }
        return []

    }
}
