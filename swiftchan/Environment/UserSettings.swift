//
//  UserSettings.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import Defaults
import FourChan
import CoreGraphics

extension Defaults.Keys {
    static let favoriteBoards = Key<[String]>("favoriteBoards", default: [])
    static let deletedBoards = Key<[String]>("deletedBoards", default: [])
    static func sortRepliesBy(boardName: String) -> Key<SortRow.SortType> {
        return Key<SortRow.SortType>(
            "sortRepliesBy\(boardName)",
            default: .none
        )
    }
    static func sortFilesBy(boardName: String) -> Key<SortRow.SortType> {
        return Key<SortRow.SortType>(
            "sortFilesBoard\(boardName)",
            default: .none
        )
    }
    static let fullImagesForThumbanails = Key<Bool>("fullImagesForThumbnails", default: false)
    static let showGifThumbnails = Key<Bool>("showGifThumbnails", default: false)
    static let showGalleryPreview = Key<Bool>("showGalleryPreview", default: false)
    static let autoRefreshThreadTime = Key<Int>("autoRefreshThreadTime", default: 10)
    static let autoRefreshEnabled = Key<Bool>("autoRefreshEnabled", default: true)

    static func scrollViewThreadPosition(_ threadId: Int) -> Key<CGFloat> {
        return Key<CGFloat>(
            "scrollViewThreadPosition\(threadId)",
            default: 0.0
        )
    }
}

extension Defaults {
    static func sortRepliesBy(boardName: String) -> SortRow.SortType {
        return Defaults[.sortRepliesBy(boardName: boardName)]
    }
    static func sortFilesBy(boardName: String) -> SortRow.SortType {
        return Defaults[.sortFilesBy(boardName: boardName)]
    }
    static func scrollViewThreadPosition(_ threadId: Int) -> CGFloat {
        return Defaults[.scrollViewThreadPosition(threadId)]
    }
}
