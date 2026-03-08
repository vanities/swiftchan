//
//  BoardsViewModel.swift
//  swiftchan
//
//  Created on 11/12/20.
//

import Foundation
import FourChan
import Combine

@Observable @MainActor
final class BoardsViewModel {
    enum State {
        case initial, loading, loaded, error
    }

    private(set) var boards = [Board]()
    private(set) var state = State.initial
    private(set) var progressText = ""
    private(set) var downloadProgress = Progress()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Set up reactive progress tracking
        downloadProgress.publisher(for: \.fractionCompleted)
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] fractionCompleted in
                guard let self else { return }
                // Only update if we don't have a custom message
                if self.progressText.isEmpty || self.progressText.hasPrefix("Loading boards") {
                    self.progressText = "Loading boards \(Int(fractionCompleted * 100))%"
                }
                debugPrint("📥 Boards download progress: \(Int(fractionCompleted * 100))%")
            }
            .store(in: &cancellables)
    }

    @MainActor
    func load() async {
        state = .loading
        downloadProgress.totalUnitCount = 100
        downloadProgress.completedUnitCount = 0

        do {
            progressText = "Fetching board list..."

            let result = try await FourChanAsyncService.shared.getBoards { progress in
                let mappedProgress = Int64(20 + (progress * 40))
                self.downloadProgress.completedUnitCount = mappedProgress
            }

            boards = result.boards
            downloadProgress.completedUnitCount = 100
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
