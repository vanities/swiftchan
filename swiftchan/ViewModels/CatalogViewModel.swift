//
//  CatalogViewModel.swift
//  swiftchan
//
//  Created by vanities on 11/12/20.
//

import Foundation
import SwiftUI
import FourChan

extension CatalogView {
    final class ViewModel: ObservableObject {
        let boardName: String
        @Published private(set) var pages = [Page]()
        @Published private(set) var comments = [Text]()

        init(boardName: String) {
            self.boardName = boardName
            self.load()
        }

        func load() {
            FourchanService.getCatalog(boardName: self.boardName) { [weak self] (pages, comments) in
                self?.pages = pages
                self?.comments = comments
            }
        }
    }
}
