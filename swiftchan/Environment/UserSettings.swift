//
//  UserSettings.swift
//  swiftchan
//
//  Created by vanities on 11/23/20.
//

import Foundation
import Combine
import FourChan

class UserSettings: ObservableObject {
    @Published var favoriteBoards: [String] {
        didSet {
            UserDefaults.standard.set(favoriteBoards, forKey: "favoriteBoards")
        }
    }
    @Published var deletedBoards: [String] {
        didSet {
            UserDefaults.standard.set(deletedBoards, forKey: "deletedBoards")
        }
    }

    init() {
        self.favoriteBoards = UserDefaults.standard.object(forKey: "favoriteBoards") as? [String] ?? []
        self.deletedBoards = UserDefaults.standard.object(forKey: "deletedBoards") as? [String] ?? []
    }
}
