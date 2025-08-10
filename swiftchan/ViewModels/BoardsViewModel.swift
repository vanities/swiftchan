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
    private(set) var progressText = ""

    @MainActor
    func load() async {
        state = .loading
        progressText = "Loading boards 0%"
        do {
            let result = try await FourChanAsyncService.shared.getBoards { progress in
                self.progressText = "Loading boards \(Int(progress * 100))%"
            }
            boards = result.boards
            state = boards.isEmpty ? .error : .loaded
        } catch {
            boards = []
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
