//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation

extension CatalogView {
    final class ViewModel: ObservableObject {
        let boardName: String
        @Published private(set) var pages = [Page]()

        init(boardName: String) {
            self.boardName = boardName
            self.load()
        }

        func load() {
            FourchanService.getCatalog(boardName: self.boardName) { [weak self] result in
                self?.pages = result

            }
        }
    }
}
