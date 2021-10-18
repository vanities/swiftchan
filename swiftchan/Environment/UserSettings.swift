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
}

extension Defaults {
    static func sortRepliesBy(boardName: String) -> SortRow.SortType {
        return Defaults[.sortRepliesBy(boardName: boardName)]
    }
    static func sortFilesBy(boardName: String) -> SortRow.SortType {
        return Defaults[.sortFilesBy(boardName: boardName)]
    }
}
