//
//  URLExamples.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import Foundation

class URLExamples {
    static let image = URL(string: "https://picsum.photos/1020/900.jpg")!
    static let gif = URL(string: "https://sample-videos.com/gif/1.gif")!
    static let webm = URL(string: "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm")!

    static let imageSet = [URL(string: "https://picsum.photos/300/300.jpg")!,
                           URL(string: "https://picsum.photos/300/300.jpg")!,
                           URL(string: "https://picsum.photos/300/300.jpg")!]
    static let gifSet = Array(repeating: URL(string: "https://sample-videos.com/gif/1.gif")!, count: 3)
    static let webmSet = Array(repeating: URL(string: "http://dl5.webmfiles.org/big-buck-bunny_trailer.webm")!, count: 3)
}
