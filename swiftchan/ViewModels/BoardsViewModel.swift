//
//  BoardsViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation

extension BoardsView {
    final class ViewModel: ObservableObject {
        @Published private(set) var boards = [Board]()

        init() {
            self.load()
        }

        func load() {
            FourchanService.getBoards { [weak self] result in
                self?.boards = result

            }
        }
    }
}
