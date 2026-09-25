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
    private let modelContainer: ModelContainer

    init() {
        do {
            #if DEBUG
            let configuration = ModelConfiguration(isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("--ui-testing"))
            #else
            let configuration = ModelConfiguration()
            #endif
            modelContainer = try FavoritesStore.makeContainer(configuration: configuration)
        } catch {
            fatalError("Could not open saved favorites: \(error)")
        }
        // Configure Kingfisher memory cache limit (150MB)
        ImageCache.default.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024
        // Keep at most 100 images in memory
        ImageCache.default.memoryStorage.config.countLimit = 100
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
