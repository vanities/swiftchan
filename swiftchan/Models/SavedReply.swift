import Foundation
import SwiftData

@Model
final class SavedReply {
    #Unique<SavedReply>([\.boardName, \.postID])

    var boardName: String
    var threadID: Int
    var postID: Int
    var threadTitle: String
    var text: String
    var savedAt: Date

    init(boardName: String, threadID: Int, postID: Int, threadTitle: String, text: String, savedAt: Date = Date()) {
        self.boardName = boardName
        self.threadID = threadID
        self.postID = postID
        self.threadTitle = threadTitle
        self.text = text
        self.savedAt = savedAt
    }

    var url: URL {
        URL(string: "https://boards.4chan.org/\(boardName)/thread/\(threadID)#p\(postID)")!
    }
}
