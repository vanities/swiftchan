//
//  FavoriteThread.swift
//  swiftchan
//
//  SwiftData model for saving favorite threads.
//

import Foundation
import SwiftData

@Model
final class FavoriteThread {
    @Attribute(.unique) var threadId: Int
    var boardName: String
    var title: String
    var thumbnailUrlString: String?
    var replyCount: Int
    var imageCount: Int
    var createdTime: Date
    var savedAt: Date

    var thumbnailUrl: URL? {
        guard let urlString = thumbnailUrlString else { return nil }
        return URL(string: urlString)
    }

    init(
        threadId: Int,
        boardName: String,
        title: String,
        thumbnailUrlString: String? = nil,
        replyCount: Int = 0,
        imageCount: Int = 0,
        createdTime: Date,
        savedAt: Date = Date()
    ) {
        self.threadId = threadId
        self.boardName = boardName
        self.title = title
        self.thumbnailUrlString = thumbnailUrlString
        self.replyCount = replyCount
        self.imageCount = imageCount
        self.createdTime = createdTime
        self.savedAt = savedAt
    }
}
