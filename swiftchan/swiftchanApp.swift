//
//  swiftchanApp.swift
//  swiftchan
//
//  Created by vanities on 10/30/20.
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
