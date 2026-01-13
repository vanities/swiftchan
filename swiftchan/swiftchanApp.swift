//
//  swiftchanApp.swift
//  swiftchan
//
//  Created on 10/30/20.
//

import SwiftUI
import SwiftData

@main
struct SwiftchanApp: App {
    init() {
        // Cache now persists between sessions
        // LRU eviction handles cleanup automatically
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FavoriteThread.self)
    }
}
