//
//  UserSettings.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import Defaults
import FourChan

extension Defaults.Keys {
    static let favoriteBoards = Key<[String]>("favoriteBoards", default: [])
    static let deletedBoards = Key<[String]>("deletedBoards", default: [])
    static let fullImagesForThumbanails = Key<Bool>("fullImagesForThumbnails", default: false)
    static let showGifThumbnails = Key<Bool>("showGifThumbnails", default: false)
    static let showGalleryPreview = Key<Bool>("showGalleryPreview", default: false)
    static let autoRefreshThreadTime = Key<Int>("autoRefreshThreadTime", default: 10)
    static let autoRefreshEnabled = Key<Bool>("autoRefreshEnabled", default: true)
    static let biometricsEnabled = Key<Bool>("biometricsEnabled", default: false)
    static let didUnlockBiometrics = Key<Bool>("didUnlokcBiometrics", default: false)

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
    static func hiddenPosts(boardName: String, postId: Int) -> Key<Bool?> {
        return Key<Bool?>(
            "hiddenPosts board=\(boardName) postId=\(postId)",
            default: nil
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
    static func hiddenPosts(boardName: String, postId: Int) -> Bool? {
        return Defaults[.hiddenPosts(boardName: boardName, postId: postId)]
    }
}
