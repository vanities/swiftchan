//
//  swiftchanApp.swift
//  swiftchan
//
//  Created on 10/30/20.
//

import SwiftUI
import SwiftData
import Kingfisher

@main
struct SwiftchanApp: App {
    init() {
        // Configure Kingfisher memory cache limit (150MB)
        ImageCache.default.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024
        // Keep at most 100 images in memory
        ImageCache.default.memoryStorage.config.countLimit = 100
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FavoriteThread.self, RecurringFavorite.self])
    }
}
