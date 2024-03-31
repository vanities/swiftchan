//
//  BoardsViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import FourChan
import Defaults

@Observable
final class BoardsViewModel {
    enum State {
        case initial, loading, loaded, error
    }

    private(set) var boards = [Board]()
    private(set) var state = State.initial

    @MainActor
    func load() async {
        state = .loading
        boards = await FourchanService.getBoards()
        if boards.count > 0 {
            state = .loaded
        } else {
           state = .error
        }
    }

    func getAllBoards(searchText: String) -> [Board] {
        return getFavoriteBoards() + getFilteredBoards(searchText: searchText)
    }

    func getFilteredBoards(searchText: String) -> [Board] {
        boards
            .filter { board in
                board.board.starts(with: searchText.lowercased()) && !Defaults[.favoriteBoards].contains(board.board)
            }
            .filter { board in
                guard !Defaults[.showNSFWBoards] else { return true }
                return !board.isNSFW
            }
    }

    func getFavoriteBoards() -> [Board] {
        boards
            .filter { board in
                Defaults[.favoriteBoards].contains(board.board)
            }
    }
}
