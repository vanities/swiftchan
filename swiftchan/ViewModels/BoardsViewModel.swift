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
            // Phase 1: Fetching board list (0-60%)
            await updateProgress(20, message: "Fetching board list...")

            let result = try await FourChanAsyncService.shared.getBoards { progress in
                // Map API progress to our 20-60% range
                let mappedProgress = Int64(20 + (progress * 40))
                self.downloadProgress.completedUnitCount = mappedProgress
            }

            // Phase 2: Processing boards (60-90%)
            await updateProgress(60, message: "Processing boards...")

            // Simulate processing time for board data
            let boardCount = result.boards.count
            for (index, _) in result.boards.enumerated() {
                if index % max(1, boardCount / 10) == 0 {
                    let processingProgress = 60 + Int64((Double(index) / Double(boardCount)) * 30)
                    await updateProgress(processingProgress, message: "Processing boards...")
                }
            }

            boards = result.boards

            // Phase 3: Complete (100%)
            await updateProgress(100, message: "Complete!")
            state = boards.isEmpty ? .error : .loaded
        } catch {
            boards = []
            state = .error
        }
    }

    private func updateProgress(_ progress: Int64, message: String) async {
        downloadProgress.completedUnitCount = progress
        progressText = message
        // Small delay to make progress visible
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
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
