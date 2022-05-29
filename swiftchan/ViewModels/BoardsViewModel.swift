//
//  BoardsViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import FourChan
import Defaults

final class BoardsViewModel: ObservableObject {
    @Published private(set) var boards = [Board]()

    init() {
        self.load()
    }

    func load() {
        FourchanService.getBoards { [weak self] result in
            self?.boards = result
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
