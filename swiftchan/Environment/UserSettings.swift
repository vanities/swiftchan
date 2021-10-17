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
    static func sortFilesBoard(boardName: String) -> Key<SortRow.SortType> {
        return Key<SortRow.SortType>(
            "sortFilesBoard\(boardName)",
            default: .none
        )
    }
}

extension Defaults {
    static func sortFilesBoard(boardName: String) -> SortRow.SortType {
        return Defaults[.sortFilesBoard(boardName: boardName)]
    }
}
