//
//  BoardsViewModel.swift
//  swiftchan
//
//  Created on 11/12/20.
//

import Foundation
import FourChan

@Observable @MainActor
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

    func getAllBoards(favorites: [String], searchText: String) -> [Board] {
        return getFavoriteBoards(favorites) + getFilteredBoards(searchText: searchText)
    }

    func getFilteredBoards(searchText: String) -> [Board] {
        boards
            .filter { board in
                return board.board.starts(with: searchText.lowercased()) && !UserDefaults.getFavoriteBoards().contains(board.board)
            }
            .filter { board in
                guard !UserDefaults.getShowNSFWBoards() else { return true }
                return !board.isNSFW
            }
    }

    func getFavoriteBoards(_ favorites: [String]) -> [Board] {
        boards
            .filter { board in
                favorites.contains(board.board)
            }
    }
}
