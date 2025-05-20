//
//  swiftchanApp.swift
//  swiftchan
//
//  Created on 10/30/20.
//

import SwiftUI

@main
struct SwiftchanApp: App {
    init() {
        CacheManager.shared.deleteAll { _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
