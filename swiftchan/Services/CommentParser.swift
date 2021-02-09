//
//  CommentParser.swift
//  swiftchan
//
//  Created by vanities on 11/3/20.
//

import SwiftUI
import SwiftSoup
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
        print(comment)
        let result = NSMutableAttributedString()
        let parser = PostTextParser()
        parser.parse(text: comment) { element in
            var part = NSMutableAttributedString()
            switch element {
            case .anchor(text: let text, href: let href):
                // >>307241251 (OP)
                // and links to self hosted files
                let font = UIFont.preferredFont(forTextStyle: .body)
                part = NSMutableAttributedString(string: text)
                part.addAttributes(
                    [.font: font,
                     .foregroundColor: UIColor.blue],
                    range: NSRange(location: 0, length: part.length))
            case .plain(text: let text):
                // plain
                let font = UIFont.preferredFont(forTextStyle: .body)
                part = NSMutableAttributedString(string: text)
                part.addAttribute(.font, value: font, range: NSRange(location: 0, length: part.length))
            case .bold(text: let text):
                // 𝐛𝐨𝐥𝐝
                part = NSMutableAttributedString(string: text)
                let font = UIFont(descriptor: UIFont.preferredFont(forTextStyle: .body)
                                    .fontDescriptor
                                    .withSymbolicTraits(.traitBold)!,
                                  size: 0)
                part.addAttribute(.font, value: font, range: NSRange(location: 0, length: part.length))
            case .strikethrough(text: let text):
                // s̶t̶r̶i̶k̶e̶t̶h̶r̶o̶u̶g̶h̶
                part = NSMutableAttributedString(string: text)
                part.addAttribute(.strikethroughStyle, value: 2, range: NSRange(location: 0, length: part.length))
            case .quote(text: let text):
                // >implying
                part = NSMutableAttributedString(string: text)
                let font = UIFont.preferredFont(forTextStyle: .body)
                part.addAttributes(
                    [.font: font,
                     .foregroundColor: UIColor.green],
                    range: NSRange(location: 0, length: part.length))
            case .deakLink(text: let text):
                // >>307241251 (OP)
                self.replies.append(text)
                part = NSMutableAttributedString(string: text)
                let font = UIFont.preferredFont(forTextStyle: .body)
                part.addAttributes(
                    [.font: font,
                     .foregroundColor: UIColor.systemPink],
                    range: NSRange(location: 0, length: part.length))
            case .hyperLink(url: let url):
                // http://......
                part = NSMutableAttributedString(string: url.absoluteString)
                let font = UIFont.preferredFont(forTextStyle: .body)
                part.addAttributes(
                    [.font: font,
                     .foregroundColor: UIColor.blue,
                     .link: url
                    ],
                    range: NSRange(location: 0, length: part.length))
            }
            result.append(part)
        }
        return result
    }
}

public class PostTextParser {
  public enum Element {
    case plain(text: String)
    case bold(text: String)
    case strikethrough(text: String)
    case quote(text: String)
    case deakLink(text: String)
    case anchor(text: String, href: String)
    case hyperLink(url: URL)
  }

  public init() {}

  public func parse(text: String, consumer: (Element) -> Void) {
    var tagStack: [String] = []
    textCoalescingTokenizer(text: text) {
      switch $0 {
      case .text(let text):
        if let context = tagStack.last {
          switch context {
          case "<b>":
            consumer(.bold(text: text))
          case "<s>":
            consumer(.strikethrough(text: text))
          case #"<span class="quote">"#:
            consumer(.quote(text: text))
          case #"<span class="deadlink">"#:
            consumer(.deakLink(text: text))
          default:
            if context.starts(with: "<a ") {
              var hrefText = ""
              if let hrefRange = context.range(
                of: #"href="[^"]*""#,
                options: .regularExpression) {
                let start = context.index(hrefRange.lowerBound, offsetBy: 6)
                let end = context.index(hrefRange.upperBound, offsetBy: -1)
                hrefText = String(context[start..<end])
              }
              consumer(.anchor(text: text, href: hrefText))
            }
          }
        } else {
            if let url = URL(string: text) {
                consumer(.hyperLink(url: url))
            } else {
                consumer(.plain(text: text))
            }
        }
      case .start(let text):
        tagStack.append(text)
      case .end:
        _ = tagStack.popLast()
      }
    }
  }

  private enum Token {
    case text(text: String)
    case start(tag: String)
    case end(tag: String)
  }

  private let entityDictionary: [String: Character] = [
    "&#039;": "'",
    "&#044;": ",",
    "&amp;": "&",
    "&gt;": ">",
    "&lt;": "<",
    "&quot;": "\""
  ]

  private func tokenize(text: String, consumer: (Token) -> Void) {
    var chunk = text[...]
    while !chunk.isEmpty {
      if let splitRange = chunk.range(of: #"<|&"#, options: .regularExpression) {
        let prefix = chunk[..<splitRange.lowerBound]
        if !prefix.isEmpty {
          consumer(.text(text: String(prefix)))
        }
        let remainder = chunk[splitRange.lowerBound...]
        let splitChar = remainder.prefix(1)
        if splitChar == "<" {
          if let tagRange = remainder.range(of: #"<[^>]*>"#, options: .regularExpression) {
            let tag = remainder[tagRange]
            if tag.prefix(2) == "</" {
              consumer(.end(tag: String(tag)))
            } else {
              consumer(.start(tag: String(tag)))
            }
            chunk = remainder[tagRange.upperBound...]
          } else {
            // Error condition, report remainder as plain text
            consumer(.text(text: String(remainder)))
            break
          }
        } else {
          if let entityRange = remainder.range(of: #"&[^;]*;"#, options: .regularExpression) {
            let entity = String(remainder[entityRange])
            if let decodedEntity = entityDictionary[entity] {
              consumer(.text(text: String(decodedEntity)))
            } else {
              // Unknown entity
              consumer(.text(text: entity))
            }
            chunk = remainder[entityRange.upperBound...]
          } else {
            // Error condition, report remainder as plain text
            consumer(.text(text: String(remainder)))
            break
          }
        }
      } else {
        consumer(.text(text: String(chunk)))
        break
      }
    }
  }

  // Handles <br>, <wbr>, and combines sequences of text into one text.
  private func textCoalescingTokenizer(text: String, consumer: (Token) -> Void) {
    var textBuffer = ""
    tokenize(text: text) {
      switch $0 {
      case .text(let text):
        textBuffer += text
      case .start(let text):
        switch text {
        case "<br>":
          textBuffer += "\n"
        case "<wbr>":
          textBuffer += "\u{200b}"
        default:
          if !textBuffer.isEmpty {
            consumer(.text(text: textBuffer))
            textBuffer = ""
          }
          consumer(.start(tag: text))
        }
      case .end(let text):
        if !textBuffer.isEmpty {
          consumer(.text(text: textBuffer))
          textBuffer = ""
        }
        consumer(.end(tag: text))
      }
    }
    if !textBuffer.isEmpty {
      consumer(.text(text: textBuffer))
    }
  }
}
