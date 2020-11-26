//
//  ContentView.swift
//  swiftchan
//
//  Created by vanities on 10/31/20.
//

import SwiftUI
import FourChan

struct ContentView: View {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var appState = AppState()

    var body: some View {
        ZStack {
            BoardsView(viewModel: BoardsView.ViewModel())
                .environmentObject(self.userSettings)
                .environmentObject(self.appState)

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
